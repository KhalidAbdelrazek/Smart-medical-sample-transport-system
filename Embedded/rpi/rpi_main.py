import logging
import time
import queue
import sys

from uart_controller import UARTCarController
from mqtt_controller import MQTTController
from console_interface import SharedState, ConsoleMonitor
from functons import (
    setup_gpio, 
    filter_sensors, 
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
MOVEMENT_DURATION_PER_ROOM = 5.0  # seconds
LOOP_DELAY = 0.1

def run_line_follower_until_intersection(car: UARTCarController):
    """
    Executes the line follower loop continuously until BOTH sensors detect BLACK.
    """
    logging.info("[ROBOT] Starting continuous line follower until intersection...")
    
    while True:
        left, right = filter_sensors()
        
        # Check intersection condition
        if left == 1 and right == 1:
            logging.info("[ROBOT] Intersection detected (both sensors BLACK). Stopping.")
            car.stop()
            break
            
        action, cmd = decide_movement(left, right)
        
        if not car.send_command_and_reconnect_if_failed(cmd):
            continue
            
        resp = car.read_and_reconnect_if_failed()
        
        time.sleep(LOOP_DELAY)

# =========================
# Main
# =========================
def main():
    # Setup state and queues
    shared_state = SharedState()
    dispatch_queue = queue.Queue()
    control_queue = queue.Queue()
    
    # Initialize components
    car = None
    mqtt_controller = None
    console = ConsoleMonitor(shared_state)
    
    try:
        # Setup GPIO for sensors
        setup_gpio()
        
        # Setup UART Controller
        shared_state.update(uart_status="CONNECTING")
        car = UARTCarController(port='/dev/serial0', baudrate=9600)
        shared_state.update(uart_status="CONNECTED")
        
        # Setup MQTT Controller
        mqtt_controller = MQTTController(dispatch_queue, control_queue)
        mqtt_controller.start()
        
        # Start Console Monitor
        console.start()
        
        # Main State Machine Loop
        while True:
            # Update MQTT connection status in shared state
            mqtt_status = "CONNECTED" if mqtt_controller.connected else "DISCONNECTED"
            shared_state.update(mqtt_status=mqtt_status)

            current_state = shared_state.get_snapshot()['state']
            
            if current_state == "IDLE":
                # Wait for dispatch command
                try:
                    # Check queue with a timeout so we can still loop and update status
                    payload = dispatch_queue.get(timeout=1.0)
                    
                    rooms, batch_id = get_rooms(payload)
                    
                    if not rooms or not batch_id:
                        logging.error("[ROBOT] Invalid dispatch payload.")
                        continue
                        
                    shared_state.update(
                        current_state="RUNNING_BATCH",
                        current_batch=batch_id
                    )
                    
                    # Immediately send ACK
                    mqtt_controller.publish_ack(batch_id)
                    
                    # Process rooms
                    for room in rooms:
                        shared_state.update(
                            current_state="MOVING_TO_ROOM",
                            current_room=room
                        )
                        
                        while True:
                            logging.info(f"[ROBOT] Moving towards room {room}...")
                            run_line_follower_until_intersection(car)
                            
                            # Robot is now stopped at intersection. Scan room.
                            logging.info(f"[ROBOT] Scanning room number...")
                            detected_room = read_room_number()
                            logging.info(f"[ROBOT] Detected room: {detected_room}, Expected: {room}")
                            
                            if str(detected_room) == str(room):
                                logging.info(f"[ROBOT] Room match confirmed. Publishing arrival.")
                                request_ids = get_request_ids_for_room(payload, room)
                                mqtt_controller.publish_arrival(room, request_ids)
                                
                                # Wait for 'proceed' command via MQTT
                                logging.info(f"[ROBOT] WAITING for 'proceed' command for room {room}...")
                                shared_state.update(current_state="WAITING_FOR_PROCEED")
                                
                                proceed_received = False
                                while not proceed_received:
                                    try:
                                        ctrl_msg = control_queue.get(timeout=1.0)
                                        if ctrl_msg.get("command") == "proceed" and str(ctrl_msg.get("room")) == str(room):
                                            logging.info("[ROBOT] Received 'proceed' command. Continuing...")
                                            proceed_received = True
                                        else:
                                            logging.warning(f"[ROBOT] Ignored control msg: {ctrl_msg}")
                                    except queue.Empty:
                                        pass
                                
                                # Move slightly forward to clear the intersection
                                logging.info("[ROBOT] Moving slightly forward to clear current intersection...")
                                car.forward()
                                time.sleep(0.5)
                                car.stop()
                                break
                            else:
                                logging.warning(f"[ROBOT] Room mismatch. Expected {room}, Got {detected_room}. Moving again.")
                                # Move slightly forward to clear the wrong intersection
                                logging.info("[ROBOT] Moving slightly forward to clear wrong intersection...")
                                car.forward()
                                time.sleep(0.5)
                                car.stop()
                        
                        # Small delay before proceeding to the next room in sequence
                        time.sleep(2.0)
                        
                    # All rooms complete
                    logging.info("[ROBOT] Batch complete. Returning to IDLE.")
                    shared_state.update(
                        current_state="IDLE",
                        current_batch=None,
                        current_room=None
                    )
                    
                except queue.Empty:
                    # No dispatch received, continue waiting
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
