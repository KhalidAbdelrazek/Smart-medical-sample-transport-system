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
    filter_sensors,
    confirm_intersection,
    decide_movement,
    get_rooms,
    get_request_ids_for_room
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
MOVEMENT_DURATION_PER_ROOM = 5.0
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
# IMU Functions
# =========================

def init_imu(bus):
    try:
        bus.write_byte_data(MPU_ADDR, PWR_MGMT_1, 0)
        time.sleep(0.1)
        bus.write_byte_data(MPU_ADDR, SMPLRT_DIV, 0x04)   # 200 Hz sample rate
        bus.write_byte_data(MPU_ADDR, CONFIG_REG,  0x03)   # DLPF ~44 Hz
        bus.write_byte_data(MPU_ADDR, GYRO_CONFIG, 0x00)   # Â±250Â°/s
        time.sleep(0.5)
        logging.info("[IMU] MPU6050 initialized (200 Hz, DLPF 44 Hz, Â±250Â°/s)")
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
    logging.info("[IMU] Keep IMU PERFECTLY STILL â€” calibrating gyroscope (%d samples)...", SAMPLES)

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

    logging.info("[IMU] Calibration complete â€” offsets: X=%.2f  Y=%.2f  Z=%.2f",
                 offsets[0], offsets[1], offsets[2])
    return tuple(offsets)


# =========================
# IMU Background Thread
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
#            logging.info("[IMU] Yaw = %.2fÂ°", yaw)

            time.sleep(0.02)   # 50 Hz

    except Exception as e:
        logging.error(f"[IMU] Thread error: {e}")
    finally:
        bus.close()
        logging.info("[IMU] I2C bus closed.")


# =========================
# Line Follower
# =========================

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

                            logging.info("[ROBOT] Scanning room number...")
                            detected_room = read_room_number()
                            logging.info(f"[ROBOT] Detected room: {detected_room}, Expected: {room}")

                            if str(detected_room) == str(room):
                                logging.info("[ROBOT] Room match confirmed. Publishing arrival.")
                                request_ids = get_request_ids_for_room(payload, room)
                                mqtt_controller.publish_arrival(room, request_ids)

                                car.stop()

                                logging.info(f"[ROBOT] WAITING for 'proceed' command for room {room}...")
                                shared_state.update(current_state="WAITING_FOR_PROCEED")

                                proceed_received = False
                                go_to_storage    = False

                                while not proceed_received:
                                    try:
                                        ctrl_msg = control_queue.get(timeout=1.0)
                                        cmd_type = ctrl_msg.get("command", "").lower()
                                        cmd_room = str(ctrl_msg.get("room", ""))
                                        cmd_car  = str(ctrl_msg.get("car_id", CAR_ID))

                                        if cmd_type != "proceed" or cmd_car != CAR_ID:
                                            logging.warning(f"[ROBOT] Ignored control msg: {ctrl_msg}")
                                            continue

                                        current_room_index = rooms.index(room)
                                        next_room = (
                                            rooms[current_room_index + 1]
                                            if current_room_index + 1 < len(rooms)
                                            else None
                                        )

                                        if cmd_room.lower() == "storage":
                                            logging.info("[ROBOT] Received 'proceed' with room=storage â†’ returning to STORAGE.")
                                            shared_state.update(current_state="RETURNING_TO_STORAGE")

                                            car.backward()
                                            logging.info("[ROBOT] Moving BACKWARD for 5 seconds toward STORAGE...")
                                            time.sleep(5)
                                            car.stop()
                                            logging.info("[ROBOT] Stopped at STORAGE. Publishing STORAGE arrival...")

                                            storage_topic   = f"transport/arrivals/{CAR_ID}"
                                            storage_payload = {
                                                "car_id":    int(CAR_ID),
                                                "room":      "STORAGE",
                                                "timestamp": datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")
                                            }
                                            mqtt_controller.publish_raw(storage_topic, storage_payload)
                                            logging.info(f"[ROBOT] STORAGE arrival published: {storage_payload}")

                                            go_to_storage    = True
                                            proceed_received = True

                                        elif next_room is not None and cmd_room == str(next_room):
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

                        if go_to_storage:
                            logging.info("[ROBOT] Batch aborted â€” car returned to STORAGE.")
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
        # Stop IMU thread first
        imu_stop_event.set()
        imu_thread.join(timeout=3)
        logging.info("[MAIN] IMU thread stopped.")

        if console:
            console.stop()
        if mqtt_controller:
            mqtt_controller.stop()
        if car:
            car.cleanup()

        try:
            import RPi.GPIO as GPIO
            GPIO.cleanup()
        except Exception:
            pass

        print("Clean exit")


if __name__ == "__main__":
    main()
