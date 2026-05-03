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

def run_line_follower_for_duration(car: UARTCarController, duration: float):
    """
    Executes the line follower loop for a specified duration in seconds.
    Uses the exact logic from the reference file.
    """
    start_time = time.time()
    last_cmd = None
    
    logging.info(f"[ROBOT] Starting line follower for {duration} seconds...")
    
    while time.time() - start_time < duration:
        left, right = filter_sensors()
        action, cmd = decide_movement(left, right)
        
        # print(f"[{time.time()}] L={left} R={right} -> {action}")
        
        # إرسال (Send command)
        if not car.send_command_and_reconnect_if_failed(cmd):
            continue
            
        # قراءة (Read response)
        resp = car.read_and_reconnect_if_failed()
        
        if resp:
            # logging.debug(f"[UART RX] {resp}")
            pass
            
        last_cmd = cmd
        time.sleep(LOOP_DELAY)
        
    # Send STOP when duration is reached
    logging.info("[ROBOT] Duration complete. Stopping.")
    car.stop()

# =========================
# Main
# =========================
def main():
    # Setup state and queues
    shared_state = SharedState()
    dispatch_queue = queue.Queue()
    
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
        mqtt_controller = MQTTController(dispatch_queue)
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
                            run_line_follower_for_duration(car, MOVEMENT_DURATION_PER_ROOM)
                            
                            # Robot is now stopped after 5 seconds. Scan room.
                            logging.info(f"[ROBOT] Scanning room number...")
                            detected_room = read_room_number()
                            logging.info(f"[ROBOT] Detected room: {detected_room}, Expected: {room}")
                            
                            if str(detected_room) == str(room):
                                logging.info(f"[ROBOT] Room match confirmed. Publishing arrival.")
                                request_ids = get_request_ids_for_room(payload, room)
                                mqtt_controller.publish_arrival(room, request_ids)
                                break
                            else:
                                logging.warning(f"[ROBOT] Room mismatch. Expected {room}, Got {detected_room}. Moving again.")
                                # Loop repeats, robot moves for 5s again
                        
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
