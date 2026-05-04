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
        print("Please install dependencies: pip install smbus2")
        sys.exit(1)

# ==========================================================
# MPU-6050 IMU Test Module
# ==========================================================
# TESTING INSTRUCTIONS:
# 1. Enable I2C on Raspberry Pi:
#    sudo raspi-config -> Interface Options -> I2C -> Enable
# 2. Install dependencies:
#    pip install smbus2
# 3. Verify device connection (should see 68):
#    i2cdetect -y 1
# ==========================================================

# MPU-6050 Registers and Addresses
MPU_ADDR = 0x68
PWR_MGMT_1 = 0x6B
ACCEL_XOUT_H = 0x3B
GYRO_XOUT_H = 0x43

# Sensitivity scale factors (assuming default +/- 2g and +/- 250 degrees/sec)
ACCEL_SCALE = 16384.0
GYRO_SCALE = 131.0

def init_imu(bus):
    """
    Initializes the MPU-6050 IMU sensor by waking it up.
    """
    try:
        # Write 0 to PWR_MGMT_1 to wake up the sensor
        bus.write_byte_data(MPU_ADDR, PWR_MGMT_1, 0)
        return True
    except OSError as e:
        print(f"Error: Failed to initialize MPU-6050 at I2C address 0x{MPU_ADDR:02X}.")
        print(f"Is the sensor connected correctly? Details: {e}")
        return False
    except Exception as e:
        print(f"Unexpected error during initialization: {e}")
        return False

def read_raw_data(bus, addr):
    """
    Reads two bytes of raw data from the given address and combines them.
    MPU-6050 returns 16-bit 2's complement values.
    """
    try:
        high = bus.read_byte_data(MPU_ADDR, addr)
        low = bus.read_byte_data(MPU_ADDR, addr + 1)
        
        # Combine high and low bytes
        value = (high << 8) | low
        
        # Convert to signed 16-bit value
        if value > 32768:
            value = value - 65536
        return value
    except Exception as e:
        print(f"Error reading raw data from register 0x{addr:02X}: {e}")
        return 0

def get_accel(bus):
    """
    Reads X, Y, Z accelerometer values and converts them to g.
    """
    acc_x = read_raw_data(bus, ACCEL_XOUT_H) / ACCEL_SCALE
    acc_y = read_raw_data(bus, ACCEL_XOUT_H + 2) / ACCEL_SCALE
    acc_z = read_raw_data(bus, ACCEL_XOUT_H + 4) / ACCEL_SCALE
    return acc_x, acc_y, acc_z

def get_gyro(bus):
    """
    Reads X, Y, Z gyroscope values and converts them to degrees/second.
    """
    gyro_x = read_raw_data(bus, GYRO_XOUT_H) / GYRO_SCALE
    gyro_y = read_raw_data(bus, GYRO_XOUT_H + 2) / GYRO_SCALE
    gyro_z = read_raw_data(bus, GYRO_XOUT_H + 4) / GYRO_SCALE
    return gyro_x, gyro_y, gyro_z

def calculate_angles(acc_x, acc_y, acc_z):
    """
    Calculates simple Roll and Pitch angles from accelerometer data.
    """
    try:
        # Roll: rotation around X axis
        roll = math.degrees(math.atan2(acc_y, math.sqrt(acc_x**2 + acc_z**2)))
        # Pitch: rotation around Y axis
        pitch = math.degrees(math.atan2(-acc_x, math.sqrt(acc_y**2 + acc_z**2)))
    except Exception:
        roll, pitch = 0.0, 0.0
    return roll, pitch

def main():
    print("Starting MPU-6050 IMU Test...")
    
    try:
        # Initialize I2C bus (bus 1 is standard for Raspberry Pi)
        bus = SMBus(1)
    except FileNotFoundError:
        print("Error: /dev/i2c-1 not found.")
        print("Please enable I2C via raspi-config or check permissions.")
        return
    except Exception as e:
        print(f"Error: Could not open I2C bus. Details: {e}")
        return
        
    if not init_imu(bus):
        print("Warning: Sensor not detected. Please check wiring. Exiting.")
        return
        
    print("MPU-6050 initialized successfully. Starting data loop (Press CTRL+C to stop)...\n")
    
    try:
        while True:
            # 1. Get raw values
            ax, ay, az = get_accel(bus)
            gx, gy, gz = get_gyro(bus)
            
            # 2. Process values (optional calculate simple angles)
            roll, pitch = calculate_angles(ax, ay, az)
            
            # 3. Output
            print(f"[IMU] ACC -> X: {ax:.2f}g | Y: {ay:.2f}g | Z: {az:.2f}g")
            print(f"[IMU] GYRO -> X: {gx:.2f}°/s | Y: {gy:.2f}°/s | Z: {gz:.2f}°/s")
            print(f"[IMU] ANGLES -> Roll: {roll:.1f}° | Pitch: {pitch:.1f}°")
            print("-" * 50)
            
            # Wait 0.5s before next read
            time.sleep(0.5)
            
    except KeyboardInterrupt:
        print("\nTest stopped by user (CTRL+C).")
    except Exception as e:
        print(f"\nUnexpected error during data loop: {e}")
    finally:
        bus.close()
        print("I2C bus closed.")

if __name__ == "__main__":
    main()
