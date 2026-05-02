"""
Real-world Testing Instructions:

1. Hardware:
   - IR sensors -> Raspberry Pi (Default BCM: LEFT=17, RIGHT=27)
   - Raspberry Pi TX -> ATmega RX
   - Raspberry Pi RX -> ATmega TX
   - Common GND

2. Run:
   python3 rpi_line_follower_uart_v2.py
"""

import time
import sys
import datetime

# STRICT REAL HARDWARE IMPORT - CRASHES IF NOT AVAILABLE
import RPi.GPIO as GPIO

# Attempt to import serial
try:
    import serial
except ImportError:
    print("[ERROR] pyserial module not found. Please install using: pip3 install pyserial")
    sys.exit(1)

# ==========================================
# CONFIGURATION
# ==========================================
# GPIO Pins (BCM numbering)
SENSOR_LEFT_PIN = 17
SENSOR_RIGHT_PIN = 27

# UART Configuration
UART_PORT = '/dev/serial0'  # e.g., /dev/ttyUSB0 or /dev/serial0
BAUD_RATE = 9600
TIMEOUT = 0.5  # Timeout for reading ACK

# Loop delay (seconds) for stability
LOOP_DELAY = 0.1  # 0.05 - 0.1s recommended

# Sensor filtering
FILTER_SAMPLES = 3

# ==========================================
# INITIALIZATION
# ==========================================
# Global serial object
ser = None

def get_timestamp():
    return datetime.datetime.now().strftime("%H:%M:%S.%f")[:-3]

def setup_gpio():
    print(f"[{get_timestamp()}] [INIT] Setting up GPIO...")
    GPIO.setwarnings(False)
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(SENSOR_LEFT_PIN, GPIO.IN)
    GPIO.setup(SENSOR_RIGHT_PIN, GPIO.IN)
    print(f"[{get_timestamp()}] [INIT] LEFT SENSOR PIN (BCM): {SENSOR_LEFT_PIN}")
    print(f"[{get_timestamp()}] [INIT] RIGHT SENSOR PIN (BCM): {SENSOR_RIGHT_PIN}")
    print(f"[{get_timestamp()}] [INIT] GPIO initialized successfully")
    print(f"[{get_timestamp()}] [INIT] Using REAL GPIO (no mock mode)")

def setup_uart():
    global ser
    print(f"[{get_timestamp()}] [INIT] Setting up UART on port {UART_PORT} at {BAUD_RATE} baud...")
    try:
        ser = serial.Serial(
            port=UART_PORT,
            baudrate=BAUD_RATE,
            timeout=TIMEOUT
        )
        if ser.is_open:
            print(f"[{get_timestamp()}] [INIT] UART successfully opened and ready.")
    except serial.SerialException as e:
        print(f"[{get_timestamp()}] [ERROR] Failed to open UART port: {e}")
        print(f"[{get_timestamp()}] [ERROR] Please check the UART_PORT configuration, permissions, and connections.")
        sys.exit(1)

# ==========================================
# CORE FUNCTIONS
# ==========================================
def read_sensors():
    """
    Reads the raw IR sensors.
    Returns: (left_val, right_val)
    0 = BLACK detected
    1 = WHITE detected
    """
    left_val = GPIO.input(SENSOR_LEFT_PIN)
    right_val = GPIO.input(SENSOR_RIGHT_PIN)
    # Removed print here to avoid spamming the console 30 times a second during filtering
    return left_val, right_val

def filter_sensors():
    """
    Reads sensors multiple times and returns the majority value for stability.
    """
    left_samples = []
    right_samples = []
    
    for _ in range(FILTER_SAMPLES):
        try:
            l, r = read_sensors()
            left_samples.append(l)
            right_samples.append(r)
        except Exception as e:
            print(f"[{get_timestamp()}] [ERROR] Exception during sensor read: {e}")
            return None, None
        time.sleep(0.01) # Small delay between samples
        
    if not left_samples or not right_samples:
        return None, None
        
    # Calculate majority
    left_majority = max(set(left_samples), key=left_samples.count)
    right_majority = max(set(right_samples), key=right_samples.count)
    
    return left_majority, right_majority

def send_command(command):
    """
    Sends a string command over UART to the ATmega with debug logs.
    """
    if ser is not None and ser.is_open:
        try:
            # IMPORTANT: Do NOT clear the input buffer here!
            # If the ATmega sent an ACK while we were reading sensors,
            # clearing the buffer will delete the ACK and we will freeze!
            # ser.reset_input_buffer()

            # Encode command
            data = command.encode('utf-8')

            # DEBUG PRINT (TX)
            print("--------------------------------------")
            print(f"[{get_timestamp()}] [UART TX] RAW COMMAND  : {repr(command)}")
            print(f"[{get_timestamp()}] [UART TX] BYTES        : {data}")
            print(f"[{get_timestamp()}] [UART TX] HEX BYTES    : {[hex(b) for b in data]}")

            # Send
            ser.write(data)

            return True

        except serial.SerialTimeoutException:
            print(f"[{get_timestamp()}] [UART ERROR] Timeout writing to UART.")
            return False

        except serial.SerialException as e:
            print(f"[{get_timestamp()}] [UART ERROR] Serial exception: {e}")
            return False

    else:
        print(f"[{get_timestamp()}] [UART ERROR] UART not open. Cannot send command.")
        return False

def read_uart_response():
    """
    Reads ALL available response bytes from the ATmega.
    Using ser.in_waiting avoids blocking indefinitely.
    """
    if ser is not None and ser.is_open:
        try:
            # Wait a tiny bit to allow ATmega to respond if it hasn't yet
            time.sleep(0.05) 
            
            response_bytes = b""
            # Read everything currently in the buffer
            while ser.in_waiting > 0:
                response_bytes += ser.read(ser.in_waiting)
                time.sleep(0.01) # Allow trailing bytes to arrive
            
            if response_bytes:
                # Decode safely, replacing bad characters
                decoded = response_bytes.decode('utf-8', errors='replace').strip()
                return f"{repr(decoded)} (Raw bytes: {response_bytes})"
            else:
                return "<NO RESPONSE BYTES IN BUFFER>"
        except Exception as e:
            return f"<ERROR READING: {e}>"
    return "<UART CLOSED>"

def decide_movement(left, right):
    """
    Decides movement logic based on sensor readings.
    LEFT=0 and RIGHT=0 -> MOVE FORWARD
    LEFT=0 and RIGHT=1 -> TURN LEFT
    LEFT=1 and RIGHT=0 -> TURN RIGHT
    LEFT=1 and RIGHT=1 -> STOP
    """
    if left == 0 and right == 0:
        action = "FORWARD"
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
    print(f"[{get_timestamp()}] [START] Starting Autonomous Line Follower Loop V2 (Debug Mode)")
    print("==================================================")
    
    last_cmd = None
    last_left = None
    last_right = None
    unchanged_count = 0
    
    try:
        while True:
            # 1. Read and filter sensors
            left, right = filter_sensors()
            
            if left is None or right is None:
                print(f"[{get_timestamp()}] [DEBUG] Invalid sensor read (instability). Skipping loop.")
                time.sleep(LOOP_DELAY)
                continue
                
            # Check if values are stuck
            if left == last_left and right == last_right:
                unchanged_count += 1
                if unchanged_count >= 50:  # roughly 5-7 seconds with delay
                    print(f"[{get_timestamp()}] [WARNING] Sensor values not changing -> check wiring")
                    unchanged_count = 0  # Reset to avoid spamming every tick
            else:
                unchanged_count = 0
                last_left = left
                last_right = right
                
            # 2. Decide movement
            action, cmd = decide_movement(left, right)
            
            # Print sensor state EVERY loop for debugging
            print(f"[{get_timestamp()}] [SENSOR] LEFT={left} RIGHT={right} | ACTION={action} | CMD={repr(cmd)}")
            
            # 3. Check for duplicates (Logging only)
            if cmd != last_cmd:
                print(f"[{get_timestamp()}] [STATE] >>> STATE CHANGED from {repr(last_cmd)} to {repr(cmd)} <<<")
                
            # 4. Send command to ATmega ALWAYS (Debug mode: test repeated commands)
            success = send_command(cmd)
            
            # 5. Read response
            if success:
                response = read_uart_response()
                print(f"[{get_timestamp()}] [UART RX] Received: {response}")
                last_cmd = cmd
            else:
                print(f"[{get_timestamp()}] [ERROR] FAILED to send: {repr(cmd)}")
                
            # 6. Stability delay
            time.sleep(LOOP_DELAY)
            
    except KeyboardInterrupt:
        print(f"\n[{get_timestamp()}] [INFO] Keyboard interrupt detected. Stopping the robot...")
    finally:
        # Cleanup
        print(f"[{get_timestamp()}] [INFO] Cleaning up hardware resources...")
        send_command("S\n")  # Attempt to send a final stop command
        
        if ser is not None and ser.is_open:
            # Read any final response from the stop command
            print(f"[{get_timestamp()}] [INFO] Final STOP response: {read_uart_response()}")
            ser.close()
            print(f"[{get_timestamp()}] [INFO] UART port closed successfully.")
            
        try:
            GPIO.cleanup()
            print(f"[{get_timestamp()}] [INFO] GPIO cleanup complete.")
        except Exception as e:
            print(f"[{get_timestamp()}] [WARNING] GPIO cleanup failed: {e}")
            
        print(f"[{get_timestamp()}] [INFO] Exited cleanly.")

if __name__ == '__main__':
    setup_gpio()
    setup_uart()
    main_loop()
