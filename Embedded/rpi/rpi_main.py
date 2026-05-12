import logging
import time
import queue
import sys
import datetime

from uart_controller import UARTCarController
from mqtt_controller import MQTTController
from console_interface import SharedState, ConsoleMonitor
from functons import (
    setup_gpio, 
    filter_sensors,
    confirm_intersection,
    decide_movement, 
    get_rooms, 
    get_request_ids_for_room
)
from camera_module import read_room_number

# =========================
# Logging Setup
# =========================
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - [%(levelname)s] - %(message)s'
)

# Constants
CAR_ID = "3"
MOVEMENT_DURATION_PER_ROOM = 5.0
LOOP_DELAY = 0.05

def run_line_follower_until_intersection(car: UARTCarController):
    logging.info("[ROBOT] Starting continuous line follower until intersection...")
    
    while True:
        left, right = filter_sensors()
        
        if left == 1 and right == 1:
            if confirm_intersection():
                logging.info("[ROBOT] Intersection confirmed (both sensors BLACK). Stopping.")
                car.stop()
                break
            
        action, cmd = decide_movement(left, right)
        
        if not car.send_command_and_reconnect_if_failed(cmd):
            continue
            
        car.read_and_reconnect_if_failed()
        
        time.sleep(LOOP_DELAY)

# =========================
# Main
# =========================
def main():
    shared_state = SharedState()
    dispatch_queue = queue.Queue()
    control_queue = queue.Queue()
    
    car = None
    mqtt_controller = None
    console = ConsoleMonitor(shared_state)
    
    try:
        setup_gpio()
        
        shared_state.update(uart_status="CONNECTING")
        car = UARTCarController(port='/dev/serial0', baudrate=9600)
        shared_state.update(uart_status="CONNECTED")
        
        mqtt_controller = MQTTController(CAR_ID, dispatch_queue, control_queue)
        mqtt_controller.start()
        
        console.start()
        
        while True:
            mqtt_status = "CONNECTED" if mqtt_controller.connected else "DISCONNECTED"
            shared_state.update(mqtt_status=mqtt_status)

            current_state = shared_state.get_snapshot()['state']
            
            if current_state == "IDLE":
                try:
                    payload = dispatch_queue.get(timeout=1.0)
                    
                    rooms, batch_id = get_rooms(payload)
                    
                    if not rooms or not batch_id:
                        logging.error("[ROBOT] Invalid dispatch payload.")
                        continue
                        
                    shared_state.update(
                        current_state="RUNNING_BATCH",
                        current_batch=batch_id
                    )
                    
                    mqtt_controller.publish_ack(batch_id)
                    
                    for room in rooms:
                        shared_state.update(
                            current_state="MOVING_TO_ROOM",
                            current_room=room
                        )
                        
                        while True:
                            logging.info(f"[ROBOT] Moving towards room {room}...")
                            run_line_follower_until_intersection(car)
                            
                            logging.info(f"[ROBOT] Scanning room number...")
                            detected_room = read_room_number()
                            logging.info(f"[ROBOT] Detected room: {detected_room}, Expected: {room}")
                            
                            if str(detected_room) == str(room):
                                logging.info(f"[ROBOT] Room match confirmed. Publishing arrival.")
                                request_ids = get_request_ids_for_room(payload, room)
                                mqtt_controller.publish_arrival(room, request_ids)
                                
                                car.stop()
                                
                                logging.info(f"[ROBOT] WAITING for 'proceed' command for room {room}...")
                                shared_state.update(current_state="WAITING_FOR_PROCEED")
                                
                                proceed_received = False
                                go_to_storage = False

                                while not proceed_received:
                                    try:
                                        ctrl_msg = control_queue.get(timeout=1.0)
                                        cmd_type = ctrl_msg.get("command", "").lower()
                                        cmd_room = str(ctrl_msg.get("room", ""))
                                        cmd_car  = str(ctrl_msg.get("car_id", CAR_ID))

                                        if cmd_type != "proceed" or cmd_car != CAR_ID:
                                            logging.warning(f"[ROBOT] Ignored control msg: {ctrl_msg}")
                                            continue

                                        # Determine next room in the batch
                                        current_room_index = rooms.index(room)
                                        next_room = rooms[current_room_index + 1] if current_room_index + 1 < len(rooms) else None

                                        if cmd_room.lower() == "storage":
                                            # Backend says return to storage
                                            logging.info(f"[ROBOT] Received 'proceed' with room=storage → returning to STORAGE.")
                                            shared_state.update(current_state="RETURNING_TO_STORAGE")

                                            car.backward()
                                            logging.info("[ROBOT] Moving BACKWARD for 5 seconds toward STORAGE...")
                                            time.sleep(5)
                                            car.stop()
                                            logging.info("[ROBOT] Stopped at STORAGE. Publishing STORAGE arrival...")

                                            storage_topic = f"transport/arrivals/{CAR_ID}"
                                            storage_payload = {
                                                "car_id": int(CAR_ID),
                                                "room": "STORAGE",
                                                "timestamp": datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")
                                            }
                                            mqtt_controller.publish_raw(storage_topic, storage_payload)
                                            logging.info(f"[ROBOT] STORAGE arrival published: {storage_payload}")

                                            go_to_storage = True
                                            proceed_received = True

                                        elif next_room is not None and cmd_room == str(next_room):
                                            # Next room → continue forward
                                            logging.info(f"[ROBOT] Received 'proceed' for next room {next_room}. Continuing forward.")
                                            proceed_received = True

                                        else:
                                            logging.warning(f"[ROBOT] Ignored control msg (unexpected room {cmd_room}): {ctrl_msg}")

                                    except queue.Empty:
                                        car.stop()

                                if not go_to_storage:
                                    logging.info("[ROBOT] Moving slightly forward to clear current intersection...")
                                    car.forward()
                                    time.sleep(0.5)
                                    car.stop()

                                break

                            else:
                                logging.warning(f"[ROBOT] Room mismatch. Expected {room}, Got {detected_room}. Moving again.")
                                logging.info("[ROBOT] Moving slightly forward to clear wrong intersection...")
                                car.forward()
                                time.sleep(0.5)
                                car.stop()
                        
                        # If we returned to storage, abort remaining rooms in batch
                        if go_to_storage:
                            logging.info("[ROBOT] Batch aborted — car returned to STORAGE.")
                            break

                        time.sleep(2.0)
                        
                    logging.info("[ROBOT] Batch complete. Returning to IDLE.")
                    shared_state.update(
                        current_state="IDLE",
                        current_batch=None,
                        current_room=None
                    )
                    
                except queue.Empty:
                    pass
                
    except KeyboardInterrupt:
        logging.info("\n[SHUTDOWN] Stopping...")
    except Exception as e:
        logging.error(f"[FATAL] System crashed: {e}")
    finally:
        if console:
            console.stop()
        if mqtt_controller:
            mqtt_controller.stop()
        if car:
            car.cleanup()
        
        try:
            import RPi.GPIO as GPIO
            GPIO.cleanup()
        except:
            pass
            
        print("Clean exit")

if __name__ == "__main__":
    main()