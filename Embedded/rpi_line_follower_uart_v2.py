import time
import sys
import datetime
import RPi.GPIO as GPIO

try:
    import serial
except ImportError:
    print("[ERROR] Install pyserial: pip3 install pyserial")
    sys.exit(1)

# ================= CONFIG =================
SENSOR_LEFT_PIN = 17
SENSOR_RIGHT_PIN = 27

UART_PORT = '/dev/serial0'
BAUD_RATE = 9600
TIMEOUT = 0.3

LOOP_DELAY = 0.1
FILTER_SAMPLES = 3

ser = None

# ================= UTILS =================
def get_timestamp():
    return datetime.datetime.now().strftime("%H:%M:%S.%f")[:-3]

# ================= GPIO =================
def setup_gpio():
    GPIO.setwarnings(False)
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(SENSOR_LEFT_PIN, GPIO.IN)
    GPIO.setup(SENSOR_RIGHT_PIN, GPIO.IN)
    print(f"[{get_timestamp()}] GPIO ready")

# ================= UART =================
def connect_uart():
    global ser
    while True:
        try:
            print(f"[{get_timestamp()}] Connecting UART...")
            # Ensure previous instance is closed before retrying
            if ser is not None and getattr(ser, 'is_open', False):
                try:
                    ser.close()
                except Exception:
                    pass

            ser = serial.Serial(UART_PORT, BAUD_RATE, timeout=TIMEOUT)

            time.sleep(2)  # مهم جدًا (Arduino reset)
            ser.reset_input_buffer()

            print(f"[{get_timestamp()}] UART connected")
            return
        except Exception as e:
            print(f"[{get_timestamp()}] UART connect failed: {e}")
            time.sleep(1)

def safe_write(cmd):
    global ser
    if ser is None or not getattr(ser, 'is_open', False):
        return False
        
    try:
        ser.write(cmd.encode())
        return True
    except Exception as e:
        print(f"[{get_timestamp()}] UART write error: {e}")
        return False

def safe_read():
    global ser
    if ser is None or not getattr(ser, 'is_open', False):
        return "ERROR"
        
    try:
        if ser.in_waiting > 0:
            line = ser.readline().decode(errors='ignore').strip()

            # فلترة
            if line == "":
                return None

            if line in ["OK", "F", "S", "L", "R"]:
                return line

            return None  # ignore garbage
        return None
    except Exception as e:
        print(f"[{get_timestamp()}] UART read error: {e}")
        return "ERROR"

# ================= SENSORS =================
def read_sensors():
    return GPIO.input(SENSOR_LEFT_PIN), GPIO.input(SENSOR_RIGHT_PIN)

def filter_sensors():
    left_samples = []
    right_samples = []

    for _ in range(FILTER_SAMPLES):
        l, r = read_sensors()
        left_samples.append(l)
        right_samples.append(r)
        time.sleep(0.01)

    left = max(set(left_samples), key=left_samples.count)
    right = max(set(right_samples), key=right_samples.count)

    return left, right

# ================= LOGIC =================
def decide(left, right):
    if left == 0 and right == 0:
        return "FORWARD", "F\n"
    elif left == 0 and right == 1:
        return "LEFT", "L\n"
    elif left == 1 and right == 0:
        return "RIGHT", "R\n"
    else:
        return "STOP", "S\n"

# ================= MAIN =================
def main():
    setup_gpio()
    connect_uart()

    last_cmd = None

    while True:
        try:
            left, right = filter_sensors()
            action, cmd = decide(left, right)

            print(f"[{get_timestamp()}] L={left} R={right} -> {action}")

            # إرسال
            if not safe_write(cmd):
                print("Reconnecting...")
                connect_uart()
                continue

            # قراءة
            resp = safe_read()
            if resp == "ERROR":
                print("Reconnecting...")
                connect_uart()
                continue

            if resp:
                print(f"[UART RX] {resp}")

            last_cmd = cmd
            time.sleep(LOOP_DELAY)

        except KeyboardInterrupt:
            print("\nStopping...")
            break

    # cleanup
    try:
        safe_write("S\n")
        ser.close()
    except:
        pass

    GPIO.cleanup()
    print("Clean exit")

if __name__ == "__main__":
    main()