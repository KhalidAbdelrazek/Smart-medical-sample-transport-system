import time
import math
import sys

try:
    from smbus2 import SMBus
except ImportError:
    try:
        from smbus import SMBus
    except ImportError:
        print("Error: smbus2 or smbus not installed.")
        print("Install using: pip install smbus2")
        sys.exit(1)

# ==========================================================
# MPU6050 CONFIG
# ==========================================================

MPU_ADDR = 0x68

PWR_MGMT_1   = 0x6B
CONFIG       = 0x1A   # DLPF config register
GYRO_CONFIG  = 0x1B
SMPLRT_DIV   = 0x19   # Sample rate divider

ACCEL_XOUT_H = 0x3B
GYRO_XOUT_H  = 0x43

ACCEL_SCALE  = 16384.0
GYRO_SCALE   = 131.0

# ----------------------------------------------------------
# GYRO SCALE CORRECTION FACTOR
# Compensates for MPU6050 factory scale error (~Â±3%).
# To calibrate: rotate exactly 90Â° and measure the output.
# Then set: GYRO_SCALE_CORRECTION = 90.0 / measured_angle
# Default = 1.0 (no correction) â€” tune after first test.
# ----------------------------------------------------------
GYRO_SCALE_CORRECTION = 1.0

# ----------------------------------------------------------
# DEADBAND â€” gyro readings below this (deg/s) are treated
# as zero. Prevents tiny noise from accumulating into yaw.
# Tune upward if yaw drifts at rest, downward if slow
# rotations are missed.
# ----------------------------------------------------------
GYRO_DEADBAND = 0.5   # deg/s

# ==========================================================
# INIT MPU6050
# ==========================================================

def init_imu(bus):
    try:
        # Wake up MPU6050
        bus.write_byte_data(MPU_ADDR, PWR_MGMT_1, 0)
        time.sleep(0.1)

        # Set sample rate divider: rate = 1kHz / (1 + SMPLRT_DIV)
        # 0x04 â†’ 200 Hz sample rate (tight integration loop)
        bus.write_byte_data(MPU_ADDR, SMPLRT_DIV, 0x04)

        # Enable DLPF (Digital Low Pass Filter) â€” bandwidth ~44Hz
        # Cuts high-frequency vibration noise from gyro readings
        bus.write_byte_data(MPU_ADDR, CONFIG, 0x03)

        # Gyro full-scale range = Â±250Â°/s (GYRO_SCALE = 131.0)
        bus.write_byte_data(MPU_ADDR, GYRO_CONFIG, 0x00)

        time.sleep(0.5)
        print("MPU6050 Initialized Successfully")
        print(f"  DLPF:       Enabled (~44 Hz bandwidth)")
        print(f"  Sample Rate: 200 Hz")
        print(f"  Deadband:    Â±{GYRO_DEADBAND} deg/s")
        print(f"  Scale Corr:  {GYRO_SCALE_CORRECTION:.4f}")
        return True

    except Exception as e:
        print(f"Initialization Error: {e}")
        return False

# ==========================================================
# READ RAW DATA
# ==========================================================

def read_raw_data(bus, addr):
    high = bus.read_byte_data(MPU_ADDR, addr)
    low  = bus.read_byte_data(MPU_ADDR, addr + 1)
    value = (high << 8) | low
    if value > 32768:
        value = value - 65536
    return value

# ==========================================================
# ACCELEROMETER
# ==========================================================

def get_accel(bus):
    ax = read_raw_data(bus, ACCEL_XOUT_H)     / ACCEL_SCALE
    ay = read_raw_data(bus, ACCEL_XOUT_H + 2) / ACCEL_SCALE
    az = read_raw_data(bus, ACCEL_XOUT_H + 4) / ACCEL_SCALE
    return ax, ay, az

# ==========================================================
# GYROSCOPE  (with deadband)
# ==========================================================

def get_gyro(bus, offsets):
    gx = (read_raw_data(bus, GYRO_XOUT_H)     - offsets[0]) / GYRO_SCALE
    gy = (read_raw_data(bus, GYRO_XOUT_H + 2) - offsets[1]) / GYRO_SCALE
    gz = (read_raw_data(bus, GYRO_XOUT_H + 4) - offsets[2]) / GYRO_SCALE

    # Apply scale correction
    gx *= GYRO_SCALE_CORRECTION
    gy *= GYRO_SCALE_CORRECTION
    gz *= GYRO_SCALE_CORRECTION

    # Apply deadband â€” zero out sub-threshold noise
    if abs(gx) < GYRO_DEADBAND: gx = 0.0
    if abs(gy) < GYRO_DEADBAND: gy = 0.0
    if abs(gz) < GYRO_DEADBAND: gz = 0.0

    return gx, gy, gz Menna Khaled, [May 11, 2026 at 7:41 PM]
# ==========================================================
# CALIBRATION  (more samples + outlier rejection)
# ==========================================================

def calibrate_gyro(bus):
    SAMPLES = 500

    print("\nKeep IMU PERFECTLY STILL...")
    print(f"Calibrating Gyroscope ({SAMPLES} samples)...\n")

    readings = [[], [], []]

    for i in range(SAMPLES):
        readings[0].append(read_raw_data(bus, GYRO_XOUT_H))
        readings[1].append(read_raw_data(bus, GYRO_XOUT_H + 2))
        readings[2].append(read_raw_data(bus, GYRO_XOUT_H + 4))
        time.sleep(0.002)   # 500 Hz during calibration

    offsets = []
    for axis_readings in readings:
        # Discard top/bottom 10% outliers before averaging
        axis_sorted = sorted(axis_readings)
        trim = int(SAMPLES * 0.10)
        trimmed = axis_sorted[trim: SAMPLES - trim]
        offsets.append(sum(trimmed) / len(trimmed))

    print("Calibration Complete")
    print("--------------------------------------")
    print(f"Gyro X Offset = {offsets[0]:.2f}")
    print(f"Gyro Y Offset = {offsets[1]:.2f}")
    print(f"Gyro Z Offset = {offsets[2]:.2f}")
    print("--------------------------------------\n")

    return tuple(offsets)

# ==========================================================
# ANGLES FROM ACCELEROMETER
# ==========================================================

def calculate_angles(ax, ay, az):
    try:
        roll  = math.degrees(math.atan2(ay, math.sqrt(ax**2 + az**2)))
        pitch = math.degrees(math.atan2(-ax, math.sqrt(ay**2 + az**2)))
    except Exception:
        roll, pitch = 0.0, 0.0
    return roll, pitch

# ==========================================================
# MOVING AVERAGE FILTER
# ==========================================================

class MovingAverage:
    def init(self, size=5):        # Smaller window â†’ less lag
        self.size   = size
        self.values = []

    def update(self, value):
        self.values.append(value)
        if len(self.values) > self.size:
            self.values.pop(0)
        return sum(self.values) / len(self.values)

# ==========================================================
# SCALE CORRECTION HELPER
# Run this function once to measure your correction factor.
# Call it from main() by changing MODE = "calibrate_scale"
# ==========================================================

def calibrate_scale_factor(bus, gyro_offsets):
    """
    Rotate the sensor EXACTLY 90Â° around the Z axis when prompted.
    The function measures the integrated yaw and prints the
    correction factor you should set in GYRO_SCALE_CORRECTION.
    """
    print("\n=== SCALE FACTOR CALIBRATION ===")
    input("Hold the sensor still, then press ENTER and rotate EXACTLY +90Â°...")

    yaw        = 0.0
    prev_time  = time.time()

    print("Rotating... press ENTER when done.")

    import threading
    done = threading.Event()
    threading.Thread(target=lambda: (input(), done.set()), daemon=True).start()

    while not done.is_set():
        gx, gy, gz = get_gyro(bus, gyro_offsets)
        now = time.time()
        dt  = now - prev_time
        prev_time = now
        yaw += gz * dt
        time.sleep(0.005)

    print(f"\nMeasured yaw = {yaw:.2f}Â°  (expected 90Â°)")
    if abs(yaw) > 1.0:
        correction = 90.0 / yaw
        print(f"Set GYRO_SCALE_CORRECTION = {correction:.4f}")
    else:
        print("Rotation too small to calculate correction.")

# ==========================================================
# MAIN
# ==========================================================

# Set to "calibrate_scale" to run the scale calibration helper
MODE = "run"

def main():
    print("\n========== MPU6050 (CORRECTED) ==========\n")

    try:
        bus = SMBus(1)
    except Exception as e:
        print(f"I2C Error: {e}")
        return

    if not init_imu(bus):
        return

    gyro_offsets = calibrate_gyro(bus)

    if MODE == "calibrate_scale":
        calibrate_scale_factor(bus, gyro_offsets)
        bus.close()
        return Menna Khaled, [May 11, 2026 at 7:41 PM]
# Filters (window=5 â€” faster response, less smoothing lag)
    ax_filter = MovingAverage(5)
    ay_filter = MovingAverage(5)
    az_filter = MovingAverage(5)

    yaw           = 0.0
    previous_time = time.time()

    print("Starting Readings...\n")

    try:
        while True:
            # â”€â”€ ACCELEROMETER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            ax, ay, az = get_accel(bus)
            ax = ax_filter.update(ax)
            ay = ay_filter.update(ay)
            az = az_filter.update(az)

            # â”€â”€ GYROSCOPE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            gx, gy, gz = get_gyro(bus, gyro_offsets)

            # â”€â”€ ROLL / PITCH â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            roll, pitch = calculate_angles(ax, ay, az)

            # â”€â”€ YAW  (tighter dt â†’ less integration error)
            current_time  = time.time()
            dt            = current_time - previous_time
            previous_time = current_time

            yaw += gz * dt   # gz is already deadband-filtered

            # â”€â”€ PRINT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            print("[ACCELEROMETER]")
            print(f"X = {ax:.2f} g  |  Y = {ay:.2f} g  |  Z = {az:.2f} g")

            print("[GYROSCOPE]")
            print(f"X = {gx:.2f}Â°/s  |  Y = {gy:.2f}Â°/s  |  Z = {gz:.2f}Â°/s")

            print("[ANGLES]")
            print(f"Roll  = {roll:.2f}Â°   Pitch = {pitch:.2f}Â°   Yaw = {yaw:.2f}Â°")
            print("==========================================\n")

            time.sleep(0.02)   # 50 Hz print rate (integration still runs at full speed)

    except KeyboardInterrupt:
        print("\nProgram Stopped")

    finally:
        bus.close()
        print("I2C Closed")

# ==========================================================
if name == "main":
    main()