"""
Real-world Testing Instructions:

1. Hardware setup:
   - Connect the IR sensors (VCC, GND, OUT) to the Raspberry Pi.
     Default GPIOs (BCM mode): LEFT = 23, RIGHT = 24.
   - Connect UART between Raspberry Pi and ATmega (Pi TX -> ATmega RX, Pi RX -> ATmega TX, GND -> GND).
     Make sure the ATmega logic level is 3.3V or use a logic level converter if it's 5V!

2. How to run:
   python3 rpi_line_follower_uart.py

3. Real-world testing:
   - Place robot on a white paper with a black line (as shown in the image).
   - Verify:
     - Robot follows the line.
     - UART commands match movement logic printed in the console.

4. Troubleshooting:
   - If movement is reversed -> swap LEFT/RIGHT logic in decide_movement or swap the sensor pins.
   - If BLACK/WHITE inverted -> invert sensor values (e.g., change 0/1 meaning).
   - If UART not working -> check port (/dev/serial0 or /dev/ttyUSB0) and baud rate.
   - If jittery movement -> suggest filtering or thresholding, or adjust the sleep delay.
"""

import time
import sys

# Attempt to import RPi.GPIO (will fail on non-Raspberry Pi devices)
try:
    import RPi.GPIO as GPIO
    GPIO_AVAILABLE = True
except ImportError:
    print("[WARNING] RPi.GPIO module not found. Using Mock GPIO for testing.")
    GPIO_AVAILABLE = False

# Attempt to import serial
try:
    import serial
    SERIAL_AVAILABLE = True
except ImportError:
    print("[ERROR] pyserial module not found. Please install using: pip3 install pyserial")
    SERIAL_AVAILABLE = False


# ==========================================
# CONFIGURATION
# ==========================================
# GPIO Pins (BCM numbering)
SENSOR_LEFT_PIN = 17
SENSOR_RIGHT_PIN = 27

# UART Configuration
UART_PORT = '/dev/serial0'  # e.g., /dev/ttyUSB0 or /dev/serial0
BAUD_RATE = 9600
TIMEOUT = 1

# Loop delay (seconds) for stability
LOOP_DELAY = 0.1  # 0.05 - 0.1s recommended

# ==========================================
# INITIALIZATION
# ==========================================
# Global serial object
ser = None

def setup_gpio():
    print("[INIT] Setting up GPIO...")
    if GPIO_AVAILABLE:
        GPIO.setwarnings(False)
        GPIO.setmode(GPIO.BCM)
        GPIO.setup(SENSOR_LEFT_PIN, GPIO.IN)
        GPIO.setup(SENSOR_RIGHT_PIN, GPIO.IN)
        print(f"[INIT] LEFT SENSOR PIN (BCM): {SENSOR_LEFT_PIN}")
        print(f"[INIT] RIGHT SENSOR PIN (BCM): {SENSOR_RIGHT_PIN}")
        print("[INIT] GPIO Setup Complete.")
    else:
        print("[INIT] Running with MOCK GPIO.")

def setup_uart():
    global ser
    if not SERIAL_AVAILABLE:
        print("[ERROR] Cannot setup UART because pyserial is not installed.")
        sys.exit(1)

    print(f"[INIT] Setting up UART on port {UART_PORT} at {BAUD_RATE} baud...")
    try:
        ser = serial.Serial(
            port=UART_PORT,
            baudrate=BAUD_RATE,
            timeout=TIMEOUT
        )
        if ser.is_open:
            print("[INIT] UART successfully opened and ready.")
    except serial.SerialException as e:
        print(f"[ERROR] Failed to open UART port: {e}")
        print("[ERROR] Please check the UART_PORT configuration, permissions, and connections.")
        sys.exit(1)

# ==========================================
# CORE FUNCTIONS
# ==========================================
def read_sensors():
    """
    Reads the IR sensors.
    Returns: (left_val, right_val)
    0 = BLACK detected
    1 = WHITE detected
    """
    try:
        if GPIO_AVAILABLE:
            left_val = GPIO.input(SENSOR_LEFT_PIN)
            right_val = GPIO.input(SENSOR_RIGHT_PIN)
        else:
            # Mock values for local testing on a PC
            left_val = 0
            right_val = 1
        return left_val, right_val
    except Exception as e:
        print(f"[ERROR] Exception during sensor read: {e}")
        return None, None

def send_command(command):
    """
    Sends a string command over UART to the ATmega.
    """
    if ser is not None and ser.is_open:
        try:
            # Encode string to bytes and send
            ser.write(command.encode('utf-8'))
            return True
        except serial.SerialTimeoutException:
            print(f"[ERROR] Timeout writing to UART.")
            return False
        except serial.SerialException as e:
            print(f"[ERROR] Failed to write to UART: {e}")
            return False
    else:
        print("[ERROR] UART is not open. Cannot send command.")
        return False

def decide_movement(left, right):
    """
    Decides movement logic based on sensor readings.
    LEFT=0 and RIGHT=0 -> MOVE FORWARD
    LEFT=0 and RIGHT=1 -> TURN LEFT
    LEFT=1 and RIGHT=0 -> TURN RIGHT
    LEFT=1 and RIGHT=1 -> STOP
    """
    if left == 0 and right == 0:
        action = "MOVE FORWARD"
        cmd = "F\n"
    elif left == 0 and right == 1:
        action = "TURN LEFT"
        cmd = "L\n"
    elif left == 1 and right == 0:
        action = "TURN RIGHT"
        cmd = "R\n"
    elif left == 1 and right == 1:
        action = "STOP"
        cmd = "S\n"
    else:
        action = "UNKNOWN"
        cmd = "S\n"
        
    return action, cmd

def main_loop():
    print("==================================================")
    print("[START] Starting Autonomous Line Follower Loop")
    print("==================================================")
    
    try:
        while True:
            # 1. Read sensors
            left, right = read_sensors()
            
            if left is None or right is None:
                print("[DEBUG] Invalid sensor read (instability). Skipping loop.")
                time.sleep(LOOP_DELAY)
                continue
                
            # 2. Decide movement
            action, cmd = decide_movement(left, right)
            
            # 3. Send command to ATmega
            success = send_command(cmd)
            
            # 4. Debug output (prints every loop iteration as required)
            if success:
                print(f"[DEBUG] LEFT={left} RIGHT={right} -> {action} -> Sent: {cmd.strip()}")
            else:
                print(f"[ERROR] LEFT={left} RIGHT={right} -> {action} -> FAILED to send: {cmd.strip()}")
                
            # 5. Stability delay
            time.sleep(LOOP_DELAY)
            
    except KeyboardInterrupt:
        print("\n[INFO] Keyboard interrupt detected. Stopping the robot...")
    finally:
        # Cleanup
        print("[INFO] Cleaning up hardware resources...")
        send_command("S\n")  # Attempt to send a final stop command
        
        if ser is not None and ser.is_open:
            ser.close()
            print("[INFO] UART port closed successfully.")
            
        if GPIO_AVAILABLE:
            GPIO.cleanup()
            print("[INFO] GPIO cleanup complete.")
            
        print("[INFO] Exited cleanly.")

if __name__ == '__main__':
    setup_gpio()
    setup_uart()
    main_loop()
