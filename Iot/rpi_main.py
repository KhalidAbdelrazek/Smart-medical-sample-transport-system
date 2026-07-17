"""
Smart Medical Transport Robot - Main Controller.
Integrates UART connection to ATmega, HiveMQ MQTT broker commands, camera OCR,
and IMU feedback within a robust state machine.
"""

import datetime
import logging
import queue
import sys
import time

import config
from camera_module import read_room_number
from console_interface import ConsoleMonitor, SharedState
from functions import setup_gpio
from imu_controller import IMUController
from mqtt_controller import MQTTController
from uart_controller import UARTCarController

# Set up logging configuration
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - [%(levelname)s] - %(message)s'
)
logger = logging.getLogger(__name__)


class RobotStateMachine:
    """
    Main State Machine managing robot navigation transitions,
    movement decisions, room scanning, and MQTT communication.
    """
    def __init__(self, shared_state: SharedState, dispatch_queue: queue.Queue,
                 control_queue: queue.Queue, car: UARTCarController,
                 mqtt: MQTTController, imu: IMUController):
        self.shared_state = shared_state
        self.dispatch_queue = dispatch_queue
        self.control_queue = control_queue
        self.car = car
        self.mqtt = mqtt
        self.imu = imu
        self.running = False

    def start(self):
        """Starts the robot's main state machine loop."""
        self.running = True
        logger.info("[ROBOT] State machine started.")
        self.run_loop()

    def run_loop(self):
        """Standard polling and processing loop for the state machine."""
        print_state("IDLE", "Waiting for dispatch from backend...")
        self.shared_state.update(current_state="IDLE")

        while self.running:
            # Keep MQTT status updated in the shared state for dashboard
            mqtt_status = "CONNECTED" if self.mqtt.connected else "DISCONNECTED"
            self.shared_state.update(mqtt_status=mqtt_status)

            current_state = self.shared_state.get_snapshot()['state']

            if current_state == "IDLE":
                try:
                    # Blocking get with 1.0s timeout to allow check on self.running
                    payload = self.dispatch_queue.get(timeout=1.0)
                    self._handle_dispatch(payload)
                except queue.Empty:
                    pass

    def _handle_dispatch(self, payload: dict):
        """Processes dispatch command payload, routing through the room list."""
        print_mqtt_event("recv", f"transport/commands/{config.CAR_ID}/dispatch", payload)
        rooms, batch_id = get_rooms(payload)

        if not rooms or not batch_id:
            logger.error("[ROBOT] Invalid dispatch payload — missing rooms or batch_id.")
            return

        print_state("RUNNING_BATCH", f"Batch ID: {batch_id} | Rooms: {rooms}")
        self.shared_state.update(
            current_state="RUNNING_BATCH",
            current_batch=batch_id
        )

        # ACK the batch
        ack_payload = {"status": "OK", "batch_id": batch_id}
        self.mqtt.publish_ack(batch_id)
        print_mqtt_event("pub", f"transport/acks/{config.CAR_ID}", ack_payload)

        go_to_storage = False
        rooms_to_visit = list(rooms)
        i = 0
        needs_forward = True  # Always drive to the first intersection on entry

        # Iterate through rooms in dispatch list
        while i < len(rooms_to_visit):
            if go_to_storage:
                break

            room = rooms_to_visit[i]
            print_state("MOVING_TO_ROOM", f"Target room: {room}")
            self.shared_state.update(
                current_state="MOVING_TO_ROOM",
                current_room=room
            )

            # Room seek loop
            while True:
                if needs_forward:
                    self.car.flush_input()
                    print_uart_send("F\n")
                    self.car.forward()
                    self.wait_for_atmega_stop()
                    needs_forward = False  # Reset until a mismatch advances us

                # Scan room number with camera OCR
                print_state("SCANNING_ROOM", "Intersection reached — scanning camera for room number...")
                self.shared_state.update(current_state="SCANNING_ROOM")

                logger.info("[ROBOT] Starting camera scan for room number...")
                detected_room = read_room_number()
                logger.info(f"[ROBOT] Camera detected room: '{detected_room}' | Expected: '{room}'")
                print(f"  📷 [CAMERA] Detected room: '{detected_room}' | Expected: '{room}'")

                # Room match evaluation
                if str(detected_room) == str(room):
                    # Rotate 90° towards the room
                    self.rotate_to_90()

                    # Move forward after rotation into the room
                    print_state("MOVING_TO_DOOR", f"Moving forward into room {room} after rotation...")
                    self.shared_state.update(current_state="MOVING_TO_DOOR")
                    self.wait_for_atmega_stop()

                    # Transition to ARRIVED and publish MQTT status
                    print_state("ARRIVED", f"Room {room} confirmed! Publishing arrival.")
                    self.shared_state.update(current_state="ARRIVED")

                    request_ids = get_request_ids_for_room(payload, room)
                    arrival_payload = {
                        "room": room,
                        "arrived_request_ids": request_ids
                    }
                    self.mqtt.publish_arrival(room, request_ids)
                    print_mqtt_event("pub", f"transport/arrivals/{config.CAR_ID}", arrival_payload)

                    # Trigger turning buzzer on ATmega
                    self.car.buzzer()

                    # Stop car at door intersection while waiting for proceed cmd
                    print_uart_send("S\n")
                    self.car.stop()

                    print_state("WAITING_FOR_PROCEED", f"Room {room} — awaiting 'proceed' command from backend...")
                    self.shared_state.update(current_state="WAITING_FOR_PROCEED")

                    proceed_received = False

                    # Wait loop for proceed command from the backend
                    while not proceed_received:
                        try:
                            ctrl_msg = self.control_queue.get(timeout=1.0)
                            print_mqtt_event("recv", f"transport/commands/{config.CAR_ID}/control", ctrl_msg)

                            cmd_type = ctrl_msg.get("command", "").lower()
                            cmd_room = str(ctrl_msg.get("room", ""))
                            cmd_car = str(ctrl_msg.get("car_id", config.CAR_ID))

                            if cmd_type != "proceed" or cmd_car != config.CAR_ID:
                                logger.warning(f"[ROBOT] Ignored control msg (wrong type/car): {ctrl_msg}")
                                print(f"  ⚠️  [CONTROL] Ignored msg: {ctrl_msg}")
                                continue

                            next_room = (
                                rooms_to_visit[i + 1]
                                if i + 1 < len(rooms_to_visit)
                                else None
                            )

                            # Step 1: Move BACKWARD out of room until intersection
                            print_state("LEAVING_ROOM", f"Proceed received — moving backward out of room {room}...")
                            self.shared_state.update(current_state="LEAVING_ROOM")
                            self.car.flush_input()
                            print_uart_send("B\n")
                            self.car.backward()
                            self.wait_for_atmega_stop()

                            # Step 2: Rotate +90° using IMU feedback to realign on corridor
                            self.rotate_back_to_corridor(cmd_room, next_room)

                            # Step 3: Wait for ATmega stop signal
                            self.wait_for_atmega_stop()

                            # Action: Proceed to STORAGE
                            if cmd_room.lower() == "storage":
                                self._go_to_storage_action(room)
                                go_to_storage = True
                                proceed_received = True

                            # Action: Proceed to NEXT ROOM
                            elif next_room is not None and cmd_room == str(next_room):
                                print_state("MOVING_TO_ROOM", f"Proceed to next room: {next_room}")
                                self.shared_state.update(
                                    current_state="MOVING_TO_ROOM",
                                    current_room=next_room
                                )
                                proceed_received = True
                                needs_forward = False  # Already aligned on corridor and stopped at next intersection

                            else:
                                logger.warning(f"[ROBOT] Ignored control msg (unexpected room '{cmd_room}'): {ctrl_msg}")
                                print(f"  ⚠️  [CONTROL] Unexpected room '{cmd_room}' in proceed — ignoring.")

                        except queue.Empty:
                            self.car.stop()

                    break  # Exit room seek loop — proceed command processed successfully

                # Room mismatch -> advance past the current intersection
                else:
                    logger.warning(f"[ROBOT] Room mismatch: expected '{room}', got '{detected_room}'. Advancing.")
                    print(f"  ⚠️  [CAMERA] Mismatch — expected '{room}', got '{detected_room}'. Advancing past intersection...")
                    print_state("MOVING_TO_ROOM", f"Target room: {room}")
                    self.shared_state.update(
                        current_state="MOVING_TO_ROOM",
                        current_room=room
                    )
                    needs_forward = True  # Re-arm forward motion for next loop

            if go_to_storage:
                logger.info("[ROBOT] Batch aborted — car returned to STORAGE.")
                print_state("IDLE", "Batch aborted. Car at STORAGE. Returning to IDLE.")
                break

            time.sleep(2.0)
            i += 1  # Advance to next room index

        if not go_to_storage:
            logger.info("[ROBOT] All rooms in batch visited. Batch complete.")
            print_state("IDLE", f"Batch {batch_id} complete. All rooms served.")

        self.shared_state.update(
            current_state="IDLE",
            current_batch=None,
            current_room=None
        )

    def rotate_to_90(self):
        """Triggers negative rotation and blocks until IMU yaw registers ~90°."""
        print_state("ROTATING", "Starting 90° rotation using IMU yaw feedback...")
        self.shared_state.update(current_state="ROTATING")

        # Tell ATmega to start negative rotation
        print_uart_send("N\n")
        self.car.nve_rotate()

        logger.info(f"[ROTATE] Rotating... target {config.ROTATION_TARGET_MIN}°–{config.ROTATION_TARGET_MAX}°")
        last_print_time = time.time()

        while True:
            delta = self.imu.get_rotation_delta()

            # Throttle console prints to 10 Hz
            now = time.time()
            if now - last_print_time >= 0.1:
                print(f"  🔄 [IMU] Yaw delta = {delta:.2f}°  (target: {config.ROTATION_TARGET_MIN}°–{config.ROTATION_TARGET_MAX}°)")
                logger.info(f"[ROTATE] Yaw delta = {delta:.2f}°")
                last_print_time = now

            # Stop rotation once threshold met
            if delta >= config.ROTATION_TARGET_MIN:
                print_uart_send("F\n")
                self.car.forward()  # Exit rotation by sending forward command
                print(f"  ✅ [IMU] Target reached — Yaw delta = {delta:.2f}°. Rotation complete.")
                logger.info(f"[ROTATE] Target reached at {delta:.2f}° — rotation stopped.")
                break

            time.sleep(0.02)  # Polling matching the IMU thread rate

        print_state("AT_DOOR", "Rotation complete. Robot is at the door.")
        self.shared_state.update(current_state="AT_DOOR")

    def rotate_back_to_corridor(self, cmd_room: str, next_room):
        """Triggers positive rotation and blocks until IMU yaw returns to baseline (<= 5°)."""
        print_state("ROTATING", "Starting +90° rotation using IMU yaw feedback...")
        self.shared_state.update(current_state="ROTATING")

        # Tell ATmega to start positive rotation
        print_uart_send("P\n")
        self.car.pve_rotate()

        logger.info(f"[ROTATE] Rotating +ve... target {config.ROTATION_TARGET_MIN}°–{config.ROTATION_TARGET_MAX}°")
        last_print_time = time.time()

        while True:
            delta = self.imu.get_rotation_delta()

            # Throttle console prints to 10 Hz
            now = time.time()
            if now - last_print_time >= 0.1:
                print(f"  🔄 [IMU] Yaw delta = {delta:.2f}°  (target: {config.ROTATION_TARGET_MIN}°–{config.ROTATION_TARGET_MAX}°)")
                logger.info(f"[ROTATE+] Yaw delta = {delta:.2f}°")
                last_print_time = now

            # Aligning back to baseline
            if delta <= 5.0:
                if cmd_room.lower() == "storage":
                    print_uart_send("B\n")
                    self.car.backward()
                else:
                    print_uart_send("F\n")
                    self.car.forward()
                print(f"  ✅ [IMU] +90° target reached — Yaw delta = {delta:.2f}°. Rotation complete.")
                logger.info(f"[ROTATE+] Target reached at {delta:.2f}°")
                break

            time.sleep(0.02)

    def _go_to_storage_action(self, current_room: str):
        """Sends the back-to-storage line skipping routines and registers arrival."""
        print_state("RETURN_TO_STORAGE", "Proceed=STORAGE received — moving backward to storage.")
        self.shared_state.update(current_state="RETURN_TO_STORAGE")

        if int(current_room) == 1:
            # Already at storage intersection after post-rotation backward move
            print_uart_send("S\n")
            self.car.stop()
            logger.info("[ROBOT] Room 1 — already at STORAGE after backward move, stopping.")
        else:
            skip_count = min(int(current_room) - 1, 3)
            print_uart_send(f"{skip_count}\n")
            self.car.skip_lines_backward(skip_count)
            logger.info(f"[ROBOT] Moving BACKWARD toward STORAGE — skip command '{skip_count}' sent (room {current_room})...")
            print(f"  ⏩ [MOVEMENT] Backward skip-{skip_count} command sent to ATmega — waiting for STORAGE intersection signal...")
            self.wait_for_atmega_stop()
            print_uart_send("S\n")
            self.car.stop()

        print_state("ARRIVED", "Arrived at STORAGE. Publishing STORAGE arrival.")
        self.shared_state.update(current_state="ARRIVED")

        storage_topic = f"transport/arrivals/{config.CAR_ID}"
        storage_payload = {
            "car_id": int(config.CAR_ID),
            "room": "STORAGE",
            "timestamp": datetime.datetime.now(datetime.UTC).strftime("%Y-%m-%dT%H:%M:%SZ")
        }
        self.mqtt.publish_raw(storage_topic, storage_payload)
        print_mqtt_event("pub", storage_topic, storage_payload)

    def wait_for_atmega_stop(self):
        """Polls UART for the intersection stop signal ('s') from the ATmega."""
        print("  ⏳ [UART] Waiting for ATmega stop signal ('s')...")
        logger.info("[UART] Listening for ATmega stop signal ('s')...")

        while True:
            resp = self.car.read_and_reconnect_if_failed()
            if resp is not None:
                print_uart_recv(resp)
                if resp.lower() == 's':
                    print("  🛑 [UART] ATmega reported intersection (both IR = BLACK). Car stopped.")
                    logger.info("[UART] Intersection signal 's' received from ATmega.")
                    return
            time.sleep(config.LOOP_DELAY)


# ── MQTT Dispatch Helpers ─────────────────────────────────────

def get_rooms(json_dispatch_data: dict) -> tuple[list[str], str | None]:
    """Extracts the list of rooms and batch_id from the dispatch payload."""
    rooms = list(json_dispatch_data.get("grouped_by_room", {}).keys())
    return rooms, json_dispatch_data.get("batch_id")


def get_request_ids_for_room(json_dispatch_data: dict, room: str) -> list[str]:
    """Extracts all request IDs for a given room."""
    room_data = json_dispatch_data.get("grouped_by_room", {}).get(room, [])
    return [req.get("request_id") for req in room_data if req.get("request_id")]


# ── Console State Printers ────────────────────────────────────

def print_state(state: str, extra: str = ""):
    """Prints a styled box in terminal to draw attention to state changes."""
    bar = "=" * 50
    msg = f"\n{bar}\n  🚗 STATE → {state}"
    if extra:
        msg += f"\n  ℹ️  {extra}"
    msg += f"\n{bar}"
    print(msg)
    logger.info(f"[STATE] {state}" + (f" | {extra}" if extra else ""))


def print_uart_send(cmd: str):
    """Maps short UART commands to readable action labels for debug printing."""
    label_map = {
        "F\n": "Push_Forward()         → ATmega cmd: 'F'",
        "B\n": "Push_Backward()        → ATmega cmd: 'B'",
        "P\n": "Pve_Rotate()           → ATmega cmd: 'P'",
        "N\n": "Nve_Rotate()           → ATmega cmd: 'N'",
        "S\n": "Stop_Car()             → ATmega cmd: 'S'",
        "X\n": "Buzzer()               → ATmega cmd: 'X'",
        "1\n": "skip_lines_backward(1) → ATmega cmd: '1'  (stop at 1st line, skip 0)",
        "2\n": "skip_lines_backward(2) → ATmega cmd: '2'  (skip 1, stop at 2nd line)",
        "3\n": "skip_lines_backward(3) → ATmega cmd: '3'  (skip 2, stop at 3rd line)",
    }
    label = label_map.get(cmd, f"RAW CMD: {repr(cmd)}")
    print(f"  ➤  [UART TX] {label}")
    logger.info(f"[UART TX] {label}")


def print_uart_recv(data: str):
    """Prints message received from the ATmega."""
    print(f"  ◀  [UART RX] ATmega replied: '{data}'")
    logger.info(f"[UART RX] ATmega replied: '{data}'")


def print_mqtt_event(direction: str, topic: str, payload):
    """Prints incoming or outgoing MQTT message."""
    arrow = "↑ PUBLISH" if direction == "pub" else "↓ RECEIVED"
    print(f"  {arrow} [{topic}] → {payload}")
    logger.info(f"[MQTT {direction.upper()}] [{topic}] {payload}")


# ── Main Entry Point ──────────────────────────────────────────

def main():
    shared_state = SharedState()
    dispatch_queue = queue.Queue()
    control_queue = queue.Queue()

    car = None
    mqtt_controller = None
    imu = None
    console = ConsoleMonitor(shared_state)

    try:
        setup_gpio()

        # Start IMU controller
        imu = IMUController(bus_num=1)
        if not imu.start():
            logger.error("[MAIN] Failed to start IMU controller. Exiting.")
            sys.exit(1)

        # Wait for IMU to calibrate and stabilize, then capture absolute baseline
        logger.info("[MAIN] Waiting for IMU to stabilize before locking yaw baseline...")
        time.sleep(2.0)
        imu.set_baseline()
        logger.info("[MAIN] Yaw baseline locked at IDLE — will not change again.")

        # UART Setup
        shared_state.update(uart_status="CONNECTING")
        print_state("UART CONNECTING", f"Port {config.UART_PORT} @ {config.UART_BAUDRATE} baud")
        car = UARTCarController(port=config.UART_PORT, baudrate=config.UART_BAUDRATE, timeout=config.UART_TIMEOUT)
        shared_state.update(uart_status="CONNECTED")
        print_state("UART CONNECTED")

        # MQTT Setup
        mqtt_controller = MQTTController(config.CAR_ID, dispatch_queue, control_queue)
        mqtt_controller.start()

        console.start()

        # Initialize State Machine and run it
        state_machine = RobotStateMachine(
            shared_state=shared_state,
            dispatch_queue=dispatch_queue,
            control_queue=control_queue,
            car=car,
            mqtt=mqtt_controller,
            imu=imu
        )
        state_machine.start()

    except KeyboardInterrupt:
        logger.info("[SHUTDOWN] Keyboard interrupt — stopping...")
        print("\n  🔴 [SHUTDOWN] Keyboard interrupt received.")
    except Exception as e:
        logger.error(f"[FATAL] System crashed: {e}")
        print(f"  💥 [FATAL] {e}")
    finally:
        # Stop state machine execution loop
        if 'state_machine' in locals():
            state_machine.running = False

        if imu:
            imu.stop()

        if console:
            console.stop()

        if mqtt_controller:
            mqtt_controller.stop()

        if car:
            print_uart_send("S\n")
            car.cleanup()

        try:
            import RPi.GPIO as GPIO
            GPIO.cleanup()
        except Exception:
            pass

        print("  ✅ Clean exit")


if __name__ == "__main__":
    main()