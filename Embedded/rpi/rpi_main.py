# version 1.2 13/5/2026 6:57 PM

import logging
import time
import queue
import sys
import datetime
import math
import threading

from uart_controller import UARTCarController
from mqtt_controller import MQTTController
from console_interface import SharedState, ConsoleMonitor
from functons import (
    setup_gpio,
)
from camera_module import read_room_number

try:
    from smbus2 import SMBus
except ImportError:
    try:
        from smbus import SMBus
    except ImportError:
        print("Error: smbus2 or smbus not installed. Run: pip install smbus2")
        sys.exit(1)

# =========================
# Logging Setup
# =========================
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - [%(levelname)s] - %(message)s'
)

# =========================
# Constants
# =========================
CAR_ID = "3"
LOOP_DELAY = 0.05

# =========================
# IMU Constants
# =========================
MPU_ADDR          = 0x68
PWR_MGMT_1        = 0x6B
CONFIG_REG        = 0x1A
GYRO_CONFIG       = 0x1B
SMPLRT_DIV        = 0x19
ACCEL_XOUT_H      = 0x3B
GYRO_XOUT_H       = 0x43
ACCEL_SCALE       = 16384.0
GYRO_SCALE        = 131.0
GYRO_SCALE_CORRECTION = 1.0
GYRO_DEADBAND     = 0.5   # deg/s

# =========================
# IMU Functions  (UNCHANGED)
# =========================

def init_imu(bus):
    try:
        bus.write_byte_data(MPU_ADDR, PWR_MGMT_1, 0)
        time.sleep(0.1)
        bus.write_byte_data(MPU_ADDR, SMPLRT_DIV, 0x04)   # 200 Hz sample rate
        bus.write_byte_data(MPU_ADDR, CONFIG_REG,  0x03)   # DLPF ~44 Hz
        bus.write_byte_data(MPU_ADDR, GYRO_CONFIG, 0x00)   # ±250°/s
        time.sleep(0.5)
        logging.info("[IMU] MPU6050 initialized (200 Hz, DLPF 44 Hz, ±250°/s)")
        return True
    except Exception as e:
        logging.error(f"[IMU] Initialization failed: {e}")
        return False


def read_raw_data(bus, addr):
    high  = bus.read_byte_data(MPU_ADDR, addr)
    low   = bus.read_byte_data(MPU_ADDR, addr + 1)
    value = (high << 8) | low
    if value > 32768:
        value -= 65536
    return value


def get_accel(bus):
    ax = read_raw_data(bus, ACCEL_XOUT_H)     / ACCEL_SCALE
    ay = read_raw_data(bus, ACCEL_XOUT_H + 2) / ACCEL_SCALE
    az = read_raw_data(bus, ACCEL_XOUT_H + 4) / ACCEL_SCALE
    return ax, ay, az


def get_gyro(bus, offsets):
    gx = (read_raw_data(bus, GYRO_XOUT_H)     - offsets[0]) / GYRO_SCALE
    gy = (read_raw_data(bus, GYRO_XOUT_H + 2) - offsets[1]) / GYRO_SCALE
    gz = (read_raw_data(bus, GYRO_XOUT_H + 4) - offsets[2]) / GYRO_SCALE

    gx *= GYRO_SCALE_CORRECTION
    gy *= GYRO_SCALE_CORRECTION
    gz *= GYRO_SCALE_CORRECTION

    if abs(gx) < GYRO_DEADBAND: gx = 0.0
    if abs(gy) < GYRO_DEADBAND: gy = 0.0
    if abs(gz) < GYRO_DEADBAND: gz = 0.0

    return gx, gy, gz


def calculate_angles(ax, ay, az):
    try:
        roll  = math.degrees(math.atan2(ay, math.sqrt(ax**2 + az**2)))
        pitch = math.degrees(math.atan2(-ax, math.sqrt(ay**2 + az**2)))
    except Exception:
        roll, pitch = 0.0, 0.0
    return roll, pitch


class MovingAverage:
    def __init__(self, size=5):
        self.size   = size
        self.values = []

    def update(self, value):
        self.values.append(value)
        if len(self.values) > self.size:
            self.values.pop(0)
        return sum(self.values) / len(self.values)


def calibrate_gyro(bus):
    SAMPLES = 500
    logging.info("[IMU] Keep IMU PERFECTLY STILL — calibrating gyroscope (%d samples)...", SAMPLES)

    readings = [[], [], []]
    for _ in range(SAMPLES):
        readings[0].append(read_raw_data(bus, GYRO_XOUT_H))
        readings[1].append(read_raw_data(bus, GYRO_XOUT_H + 2))
        readings[2].append(read_raw_data(bus, GYRO_XOUT_H + 4))
        time.sleep(0.002)

    offsets = []
    for axis_readings in readings:
        axis_sorted = sorted(axis_readings)
        trim    = int(SAMPLES * 0.10)
        trimmed = axis_sorted[trim: SAMPLES - trim]
        offsets.append(sum(trimmed) / len(trimmed))

    logging.info("[IMU] Calibration complete — offsets: X=%.2f  Y=%.2f  Z=%.2f",
                 offsets[0], offsets[1], offsets[2])
    return tuple(offsets)


# =========================
# IMU Background Thread  (UNCHANGED)
# =========================

def imu_thread_func(stop_event: threading.Event):
    """
    Runs in a daemon thread alongside the main robot loop.
    Reads the MPU6050 at ~50 Hz and logs the readings.
    """
    try:
        bus = SMBus(1)
    except Exception as e:
        logging.error(f"[IMU] Cannot open I2C bus: {e}")
        return

    if not init_imu(bus):
        bus.close()
        return

    gyro_offsets = calibrate_gyro(bus)

    yaw           = 0.0
    previous_time = time.time()

    logging.info("[IMU] Starting continuous readings...")

    try:
        while not stop_event.is_set():
            # Gyroscope
            gx, gy, gz = get_gyro(bus, gyro_offsets)

            # Yaw integration
            current_time  = time.time()
            dt            = current_time - previous_time
            previous_time = current_time
            yaw          += gz * dt

            # Log yaw only
#            logging.info("[IMU] Yaw = %.2f°", yaw)

            time.sleep(0.02)   # 50 Hz

    except Exception as e:
        logging.error(f"[IMU] Thread error: {e}")
    finally:
        bus.close()
        logging.info("[IMU] I2C bus closed.")


# =========================
# MQTT Helpers
# =========================

def get_rooms(json_dispatch_data: dict):
    rooms = list(json_dispatch_data.get("grouped_by_room", {}).keys())
    return rooms, json_dispatch_data.get("batch_id")


def get_request_ids_for_room(json_dispatch_data: dict, room: str) -> list:
    room_data = json_dispatch_data.get("grouped_by_room", {}).get(room, [])
    return [req.get("request_id") for req in room_data if req.get("request_id")]


# =========================
# State Printer
# =========================

def print_state(state: str, extra: str = ""):
    bar = "=" * 50
    msg = f"\n{bar}\n  🚗 STATE → {state}"
    if extra:
        msg += f"\n  ℹ️  {extra}"
    msg += f"\n{bar}"
    print(msg)
    logging.info(f"[STATE] {state}" + (f" | {extra}" if extra else ""))


def print_uart_send(cmd: str):
    label_map = {
        "F\n": "Push_Forward()   → ATmega cmd: 'F'",
        "B\n": "Push_Backward()  → ATmega cmd: 'B'",
        "P\n": "Pve_Rotate()     → ATmega cmd: 'P'",
        "N\n": "Nve_Rotate()     → ATmega cmd: 'N'",
        "S\n": "Stop_Car()       → ATmega cmd: 'S'",
    }
    label = label_map.get(cmd, f"RAW CMD: {repr(cmd)}")
    print(f"  ➤  [UART TX] {label}")
    logging.info(f"[UART TX] {label}")


def print_uart_recv(data: str):
    print(f"  ◀  [UART RX] ATmega replied: '{data}'")
    logging.info(f"[UART RX] ATmega replied: '{data}'")


def print_mqtt_event(direction: str, topic: str, payload):
    arrow = "↑ PUBLISH" if direction == "pub" else "↓ RECEIVED"
    print(f"  {arrow} [{topic}] → {payload}")
    logging.info(f"[MQTT {direction.upper()}] [{topic}] {payload}")



# =========================
# Wait for ATmega stop signal ('s')
# Blocks until ATmega sends 's', meaning both IR sensors read BLACK.
# ATmega is running Push_Forward() / Forward_decide_mov() internally.
# =========================

def wait_for_atmega_stop(car: UARTCarController) -> None:
    """
    Polls UART for the ATmega's stop signal ('s').
    The ATmega is autonomously following the line via Forward_decide_mov().
    When it detects both IR sensors = BLACK it sends 's' to RPi.
    """
    print("  ⏳ [UART] Waiting for ATmega stop signal ('s')...")
    logging.info("[UART] Listening for ATmega stop signal ('s')...")

    while True:
        resp = car.read_and_reconnect_if_failed()
        if resp is not None:
            print_uart_recv(resp)
            if resp.lower() == 's':
                print("  🛑 [UART] ATmega reported intersection (both IR = BLACK). Car stopped.")
                logging.info("[UART] Intersection signal 's' received from ATmega.")
                return
        time.sleep(LOOP_DELAY)


# =========================
# Main
# =========================

def main():
    shared_state   = SharedState()
    dispatch_queue = queue.Queue()
    control_queue  = queue.Queue()

    car             = None
    mqtt_controller = None
    console         = ConsoleMonitor(shared_state)

    # IMU stop signal
    imu_stop_event = threading.Event()
    imu_thread     = threading.Thread(
        target=imu_thread_func,
        args=(imu_stop_event,),
        daemon=True,
        name="IMU-Thread"
    )

    try:
        setup_gpio()

        # Start IMU thread before the main loop
        imu_thread.start()
        logging.info("[MAIN] IMU thread started.")

        # ── UART ──────────────────────────────────────────────
        shared_state.update(uart_status="CONNECTING")
        print_state("UART CONNECTING", f"Port /dev/serial0 @ 9600 baud")
        car = UARTCarController(port='/dev/serial0', baudrate=9600)
        shared_state.update(uart_status="CONNECTED")
        print_state("UART CONNECTED")

        # ── MQTT ──────────────────────────────────────────────
        mqtt_controller = MQTTController(CAR_ID, dispatch_queue, control_queue)
        mqtt_controller.start()

        console.start()

        # ── Main state machine ────────────────────────────────
        print_state("IDLE", "Waiting for dispatch from backend...")
        shared_state.update(current_state="IDLE")

        while True:
            mqtt_status = "CONNECTED" if mqtt_controller.connected else "DISCONNECTED"
            shared_state.update(mqtt_status=mqtt_status)

            current_state = shared_state.get_snapshot()['state']

            # ════════════════════════════════════════════
            # IDLE — wait for dispatch
            # ════════════════════════════════════════════
            if current_state == "IDLE":
                try:
                    payload = dispatch_queue.get(timeout=1.0)
                    print_mqtt_event("recv", f"transport/commands/{CAR_ID}/dispatch", payload)

                    rooms, batch_id = get_rooms(payload)

                    if not rooms or not batch_id:
                        logging.error("[ROBOT] Invalid dispatch payload — missing rooms or batch_id.")
                        continue

                    print_state("RUNNING_BATCH", f"Batch ID: {batch_id} | Rooms: {rooms}")
                    shared_state.update(
                        current_state="RUNNING_BATCH",
                        current_batch=batch_id
                    )

                    # ACK the batch
                    ack_payload = {"status": "OK", "batch_id": batch_id}
                    mqtt_controller.publish_ack(batch_id)
                    print_mqtt_event("pub", f"transport/acks/{CAR_ID}", ack_payload)

                    go_to_storage  = False
                    rooms_to_visit = list(rooms)
                    i = 0

                    # ── Iterate through rooms ──────────────────
                    while i < len(rooms_to_visit):
                        if go_to_storage:
                            break

                        room = rooms_to_visit[i]

                        print_state("MOVING_TO_ROOM", f"Target room: {room}")
                        shared_state.update(
                            current_state="MOVING_TO_ROOM",
                            current_room=room
                        )

                        # ── Room seek loop ─────────────────────
                        while True:
                            # Flush stale UART bytes before commanding forward
                            car.flush_input()

                            # Tell ATmega to start forward line-following
                            print_uart_send("F\n")
                            car.forward()

                            # Block until ATmega detects intersection and sends 's'
                            wait_for_atmega_stop(car)

                            # ATmega already stopped itself; RPi records the stop
                            print_state("SCANNING_ROOM", f"Intersection reached — scanning camera for room number...")
                            shared_state.update(current_state="SCANNING_ROOM")

                            # Camera scan
                            logging.info("[ROBOT] Starting camera scan for room number...")
                            detected_room = read_room_number()
                            logging.info(f"[ROBOT] Camera detected room: '{detected_room}' | Expected: '{room}'")
                            print(f"  📷 [CAMERA] Detected room: '{detected_room}' | Expected: '{room}'")

                            # ── Room match ────────────────────
                            if str(detected_room) == str(room):
                                print_state("ARRIVED", f"Room {room} confirmed! Publishing arrival.")
                                shared_state.update(current_state="ARRIVED")

                                request_ids = get_request_ids_for_room(payload, room)
                                arrival_payload = {
                                    "room": room,
                                    "arrived_request_ids": request_ids
                                }
                                mqtt_controller.publish_arrival(room, request_ids)
                                print_mqtt_event("pub", f"transport/arrivals/{CAR_ID}", arrival_payload)

                                # Ensure car is stopped while waiting
                                print_uart_send("S\n")
                                car.stop()

                                print_state("WAITING_FOR_PROCEED", f"Room {room} — awaiting 'proceed' command from backend...")
                                shared_state.update(current_state="WAITING_FOR_PROCEED")

                                proceed_received = False

                                while not proceed_received:
                                    try:
                                        ctrl_msg = control_queue.get(timeout=1.0)
                                        print_mqtt_event("recv", f"transport/commands/{CAR_ID}/control", ctrl_msg)

                                        cmd_type = ctrl_msg.get("command", "").lower()
                                        cmd_room = str(ctrl_msg.get("room", ""))
                                        cmd_car  = str(ctrl_msg.get("car_id", CAR_ID))

                                        if cmd_type != "proceed" or cmd_car != CAR_ID:
                                            logging.warning(f"[ROBOT] Ignored control msg (wrong type/car): {ctrl_msg}")
                                            print(f"  ⚠️  [CONTROL] Ignored msg: {ctrl_msg}")
                                            continue

                                        next_room = (
                                            rooms_to_visit[i + 1]
                                            if i + 1 < len(rooms_to_visit)
                                            else None
                                        )

                                        # ── Proceed to STORAGE ─────────────
                                        if cmd_room.lower() == "storage":
                                            print_state("RETURN_TO_STORAGE", "Proceed=STORAGE received — moving backward to storage.")
                                            shared_state.update(current_state="RETURN_TO_STORAGE")

                                            car.flush_input()
                                            print_uart_send("B\n")
                                            car.backward()
                                            logging.info("[ROBOT] Moving BACKWARD toward STORAGE via ATmega Push_Backward()...")
                                            print(f"  ⏩ [MOVEMENT] Backward command sent to ATmega — waiting for STORAGE intersection signal...")

                                            wait_for_atmega_stop(car)

                                            print_uart_send("S\n")
                                            car.stop()

                                            print_state("ARRIVED", "Arrived at STORAGE. Publishing STORAGE arrival.")
                                            shared_state.update(current_state="ARRIVED")

                                            storage_topic   = f"transport/arrivals/{CAR_ID}"
                                            storage_payload = {
                                                "car_id":    int(CAR_ID),
                                                "room":      "STORAGE",
                                                "timestamp": datetime.datetime.now(datetime.UTC).strftime("%Y-%m-%dT%H:%M:%SZ")
                                            }
                                            mqtt_controller.publish_raw(storage_topic, storage_payload)
                                            print_mqtt_event("pub", storage_topic, storage_payload)

                                            go_to_storage    = True
                                            proceed_received = True

                                        # ── Proceed to next room ────────────
                                        elif next_room is not None and cmd_room == str(next_room):
                                            print_state("MOVING_TO_ROOM", f"Proceed to next room: {next_room}")
                                            shared_state.update(
                                                current_state="MOVING_TO_ROOM",
                                                current_room=next_room
                                            )
                                            proceed_received = True

                                        else:
                                            logging.warning(f"[ROBOT] Ignored control msg (unexpected room '{cmd_room}'): {ctrl_msg}")
                                            print(f"  ⚠️  [CONTROL] Unexpected room '{cmd_room}' in proceed — ignoring.")

                                    except queue.Empty:
                                        car.stop()

                                break  # exit room seek loop — proceed received

                            # ── Room mismatch ─────────────────
                            else:
                                logging.warning(f"[ROBOT] Room mismatch: expected '{room}', got '{detected_room}'. Advancing.")
                                print(f"  ⚠️  [CAMERA] Mismatch — expected '{room}', got '{detected_room}'. Advancing past intersection...")
                                car.flush_input()
                                print_uart_send("F\n")
                                car.forward()
                                time.sleep(0.5)
                                print_uart_send("S\n")
                                car.stop()
                                # Loop back to room seek loop for next intersection

                        if go_to_storage:
                            logging.info("[ROBOT] Batch aborted — car returned to STORAGE.")
                            print_state("IDLE", "Batch aborted. Car at STORAGE. Returning to IDLE.")
                            break

                        time.sleep(2.0)
                        i += 1  # ✅ advance to next room only after fully completing current one

                    if not go_to_storage:
                        logging.info("[ROBOT] All rooms in batch visited. Batch complete.")
                        print_state("IDLE", f"Batch {batch_id} complete. All rooms served.")

                    shared_state.update(
                        current_state="IDLE",
                        current_batch=None,
                        current_room=None
                    )

                except queue.Empty:
                    pass  # still IDLE, keep polling

    except KeyboardInterrupt:
        logging.info("\n[SHUTDOWN] Keyboard interrupt — stopping...")
        print("\n  🔴 [SHUTDOWN] Keyboard interrupt received.")
    except Exception as e:
        logging.error(f"[FATAL] System crashed: {e}")
        print(f"  💥 [FATAL] {e}")
    finally:
        imu_stop_event.set()
        imu_thread.join(timeout=3)
        logging.info("[MAIN] IMU thread stopped.")

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