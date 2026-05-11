import logging
import time
import datetime
try:
    import serial
except ImportError:
    import sys
    print("[ERROR] Install pyserial: pip3 install pyserial")
    sys.exit(1)

logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - [%(levelname)s] - %(message)s'
)

def get_timestamp():
    return datetime.datetime.now().strftime("%H:%M:%S.%f")[:-3]

class UARTCarController:
    def __init__(self, port='/dev/serial0', baudrate=9600, timeout=0.3):
        self.port = port
        self.baudrate = baudrate
        self.timeout = timeout
        self.ser = None
        self.state = "SLEEP"
        self.connect_uart()

    def connect_uart(self):
        while True:
            try:
                logging.info(f"[{get_timestamp()}] Connecting UART to {self.port} at {self.baudrate}...")
                # Ensure previous instance is closed before retrying
                if self.ser is not None and getattr(self.ser, 'is_open', False):
                    try:
                        self.ser.close()
                    except Exception:
                        pass

                self.ser = serial.Serial(self.port, self.baudrate, timeout=self.timeout)

                time.sleep(2)  # مهم جدًا (Arduino reset)
                self.ser.reset_input_buffer()

                logging.info(f"[{get_timestamp()}] UART connected successfully")
                return
            except Exception as e:
                logging.error(f"[{get_timestamp()}] UART connect failed: {e}")
                time.sleep(1)

    def safe_write(self, cmd: str) -> bool:
        if self.ser is None or not getattr(self.ser, 'is_open', False):
            return False
            
        try:
            self.ser.write(cmd.encode())
            return True
        except Exception as e:
            logging.error(f"[{get_timestamp()}] UART write error: {e}")
            return False

    def safe_read(self):
        if self.ser is None or not getattr(self.ser, 'is_open', False):
            return "ERROR"
            
        try:
            if self.ser.in_waiting > 0:
                line = self.ser.readline().decode(errors='ignore').strip()

                # فلترة
                if line == "":
                    return None

                if line in ["OK", "F", "S", "L", "R"]:
                    return line

                return None  # ignore garbage
            return None
        except Exception as e:
            logging.error(f"[{get_timestamp()}] UART read error: {e}")
            return "ERROR"

    def send_command_and_reconnect_if_failed(self, cmd: str):
        """Sends command and handles reconnecting if the write fails."""
        if not self.safe_write(cmd):
            logging.warning("Write failed. Reconnecting...")
            self.connect_uart()
            return False
        return True

    def read_and_reconnect_if_failed(self):
        """Reads response and handles reconnecting if it gets an ERROR."""
        resp = self.safe_read()
        if resp == "ERROR":
            logging.warning("Read error. Reconnecting...")
            self.connect_uart()
            return None
        return resp

    # =========================
    # Movement API
    # =========================
    def forward(self):
        return self.send_command_and_reconnect_if_failed("F\n")

    def backward(self):
        return self.send_command_and_reconnect_if_failed("B\n")

    def left(self):
        return self.send_command_and_reconnect_if_failed("L\n")

    def right(self):
        return self.send_command_and_reconnect_if_failed("R\n")

    def stop(self):
        return self.send_command_and_reconnect_if_failed("S\n")

    def cleanup(self):
        try:
            self.safe_write("S\n")
            if self.ser:
                self.ser.close()
        except Exception:
            pass