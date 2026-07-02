"""
Configuration parameters for the Smart Medical Transport Robot.
Contains hardware pin definitions, MQTT broker credentials, UART settings, and IMU thresholds.
"""

# General Robot Config
CAR_ID = "3"
LOOP_DELAY = 0.05
VALID_ROOMS = {"1", "2", "3"}

# GPIO / IR Sensors Config
SENSOR_LEFT_PIN = 17
SENSOR_RIGHT_PIN = 27
FILTER_SAMPLES = 5                   # samples per majority-vote read
INTERSECTION_CONFIRM_COUNT = 4        # consecutive confirmed reads before declaring intersection
INTERSECTION_CONFIRM_DELAY = 0.02     # seconds between confirmation reads

# MQTT Controller Config
MQTT_BROKER = "81758f399b5b46b9875ac5e5f1e3ef1e.s1.eu.hivemq.cloud"
MQTT_PORT = 8883
MQTT_USERNAME = "hivemq.webclient.1764285829577"
MQTT_PASSWORD = "bNtHo2#E,9>w18<CcOfF"

# UART Controller Config
UART_PORT = "/dev/serial0"
UART_BAUDRATE = 9600
UART_TIMEOUT = 0.3

# IMU (MPU6050) Config
MPU_ADDR = 0x68
PWR_MGMT_1 = 0x6B
CONFIG_REG = 0x1A
GYRO_CONFIG = 0x1B
SMPLRT_DIV = 0x19
ACCEL_XOUT_H = 0x3B
GYRO_XOUT_H = 0x43

ACCEL_SCALE = 16384.0
GYRO_SCALE = 131.0
GYRO_SCALE_CORRECTION = 1.0
GYRO_DEADBAND = 0.5  # deg/s

# Rotation Target Constants (in degrees)
ROTATION_TARGET_MIN = 85.0   # Acceptable lower bound for 90-degree turn
ROTATION_TARGET_MAX = 90.0   # Stop immediately at/above this
