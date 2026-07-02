"""
IMU Controller module.
Handles initialization, gyro calibration, and background thread integration of yaw for the MPU6050 sensor.
"""

import logging
import math
import threading
import time
import sys
import config

logger = logging.getLogger(__name__)

# Fallback wrapper for SMBus to allow development on non-RPi environments
try:
    from smbus2 import SMBus
except ImportError:
    try:
        from smbus import SMBus
    except ImportError:
        logger.warning("smbus2 or smbus not installed. Using mock SMBus for simulation/development.")
        class SMBus:
            def __init__(self, bus):
                self.bus = bus
            def write_byte_data(self, addr, reg, val):
                pass
            def read_byte_data(self, addr, reg):
                # Return dummy values
                return 0
            def close(self):
                pass


class IMUController:
    """
    Manages initialization, calibration, and thread-safe reading of the MPU6050 IMU.
    Integrates the Z-axis gyroscope readings in a background thread to track the robot's yaw.
    """
    def __init__(self, bus_num: int = 1):
        self.bus_num = bus_num
        self.bus = None
        self._shared_yaw = 0.0
        self._yaw_baseline = 0.0
        self._lock = threading.Lock()
        self._stop_event = threading.Event()
        self._thread = None
        self.gyro_offsets = (0.0, 0.0, 0.0)

    def initialize(self) -> bool:
        """Opens I2C bus and initializes the MPU6050 sensor registers."""
        try:
            self.bus = SMBus(self.bus_num)
            
            # Wake up MPU6050
            self.bus.write_byte_data(config.MPU_ADDR, config.PWR_MGMT_1, 0)
            time.sleep(0.1)
            
            # Set sample rate divider (200 Hz sample rate)
            self.bus.write_byte_data(config.MPU_ADDR, config.SMPLRT_DIV, 0x04)
            
            # Set Digital Low Pass Filter (DLPF) to ~44 Hz
            self.bus.write_byte_data(config.MPU_ADDR, config.CONFIG_REG, 0x03)
            
            # Set Gyro Full Scale Range to ±250 deg/s
            self.bus.write_byte_data(config.MPU_ADDR, config.GYRO_CONFIG, 0x00)
            time.sleep(0.5)
            
            logger.info("[IMU] MPU6050 initialized successfully (200 Hz, DLPF 44 Hz, ±250°/s)")
            return True
        except Exception as e:
            logger.error(f"[IMU] Initialization failed: {e}")
            if self.bus:
                try:
                    self.bus.close()
                except Exception:
                    pass
                self.bus = None
            return False

    def _read_raw_data(self, addr: int) -> int:
        """Reads two consecutive bytes from the register address and combines them."""
        if not self.bus:
            return 0
        high = self.bus.read_byte_data(config.MPU_ADDR, addr)
        low = self.bus.read_byte_data(config.MPU_ADDR, addr + 1)
        value = (high << 8) | low
        if value > 32768:
            value -= 65536
        return value

    def get_accel(self) -> tuple[float, float, float]:
        """Reads and returns accelerometer values scaled to g's."""
        ax = self._read_raw_data(config.ACCEL_XOUT_H) / config.ACCEL_SCALE
        ay = self._read_raw_data(config.ACCEL_XOUT_H + 2) / config.ACCEL_SCALE
        az = self._read_raw_data(config.ACCEL_XOUT_H + 4) / config.ACCEL_SCALE
        return ax, ay, az

    def get_gyro(self) -> tuple[float, float, float]:
        """Reads, corrects, and returns gyroscope values in deg/s."""
        gx = (self._read_raw_data(config.GYRO_XOUT_H) - self.gyro_offsets[0]) / config.GYRO_SCALE
        gy = (self._read_raw_data(config.GYRO_XOUT_H + 2) - self.gyro_offsets[1]) / config.GYRO_SCALE
        gz = (self._read_raw_data(config.GYRO_XOUT_H + 4) - self.gyro_offsets[2]) / config.GYRO_SCALE

        gx *= config.GYRO_SCALE_CORRECTION
        gy *= config.GYRO_SCALE_CORRECTION
        gz *= config.GYRO_SCALE_CORRECTION

        # Apply deadband filtering
        if abs(gx) < config.GYRO_DEADBAND:
            gx = 0.0
        if abs(gy) < config.GYRO_DEADBAND:
            gy = 0.0
        if abs(gz) < config.GYRO_DEADBAND:
            gz = 0.0

        return gx, gy, gz

    def calculate_angles(self) -> tuple[float, float]:
        """Calculates roll and pitch angles in degrees based on accelerometer readings."""
        try:
            ax, ay, az = self.get_accel()
            roll = math.degrees(math.atan2(ay, math.sqrt(ax**2 + az**2)))
            pitch = math.degrees(math.atan2(-ax, math.sqrt(ay**2 + az**2)))
        except Exception:
            roll, pitch = 0.0, 0.0
        return roll, pitch

    def calibrate(self, samples: int = 500):
        """Calibrates gyro by averaging readings when the robot is completely still."""
        logger.info(f"[IMU] Keep IMU PERFECTLY STILL — calibrating gyroscope ({samples} samples)...")
        readings = [[], [], []]
        for _ in range(samples):
            readings[0].append(self._read_raw_data(config.GYRO_XOUT_H))
            readings[1].append(self._read_raw_data(config.GYRO_XOUT_H + 2))
            readings[2].append(self._read_raw_data(config.GYRO_XOUT_H + 4))
            time.sleep(0.002)

        offsets = []
        for axis_readings in readings:
            axis_sorted = sorted(axis_readings)
            trim = int(samples * 0.10)
            trimmed = axis_sorted[trim: samples - trim]
            offsets.append(sum(trimmed) / len(trimmed))

        self.gyro_offsets = tuple(offsets)
        logger.info(f"[IMU] Calibration complete — offsets: X={self.gyro_offsets[0]:.2f} Y={self.gyro_offsets[1]:.2f} Z={self.gyro_offsets[2]:.2f}")

    def start(self) -> bool:
        """Starts the continuous IMU reading and integration background thread."""
        if not self.bus:
            if not self.initialize():
                return False

        self.calibrate()
        self._stop_event.clear()
        self._thread = threading.Thread(target=self._run, daemon=True, name="IMU-Thread")
        self._thread.start()
        logger.info("[IMU] continuous reading background thread started.")
        return True

    def _run(self):
        """Continuous polling loop running in the background thread."""
        yaw = 0.0
        previous_time = time.time()
        last_yaw_print = 0.0

        try:
            while not self._stop_event.is_set():
                _, _, gz = self.get_gyro()
                current_time = time.time()
                dt = current_time - previous_time
                previous_time = current_time
                yaw += gz * dt

                with self._lock:
                    self._shared_yaw = yaw

                # Optional debug print (e.g. at 10 Hz)
                now = time.time()
                if now - last_yaw_print >= 0.1:
                    # logger.debug(f"[IMU] Current Yaw = {yaw:.2f}°")
                    last_yaw_print = now

                time.sleep(0.02)  # 50 Hz poll rate
        except Exception as e:
            logger.error(f"[IMU] Background thread error: {e}")
        finally:
            if self.bus:
                self.bus.close()
                logger.info("[IMU] I2C bus closed.")

    def stop(self):
        """Stops the background thread and releases resources."""
        self._stop_event.set()
        if self._thread:
            self._thread.join(timeout=3.0)
            self._thread = None
        self.bus = None

    def get_yaw(self) -> float:
        """Thread-safe retrieval of the integrated yaw."""
        with self._lock:
            return self._shared_yaw

    def set_baseline(self):
        """Snapshots the current yaw to start measuring rotation deltas."""
        with self._lock:
            self._yaw_baseline = self._shared_yaw
        logger.info(f"[IMU] Yaw baseline set to {self._yaw_baseline:.2f}°")

    def get_rotation_delta(self) -> float:
        """Returns the absolute yaw change (in degrees) since set_baseline was called."""
        with self._lock:
            return abs(self._shared_yaw - self._yaw_baseline)
