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
    level=logging.INFO,
    format='%(asctime)s - [%(levelname)s] - %(message)s'
)


def get_timestamp():
    return datetime.datetime.now().strftime("%H:%M:%S.%f")[:-3]


class UARTCarController:
    def __init__(self, port='/dev/serial0', baudrate=115200, timeout=0.05):
        """
        baudrate=115200 for maximum speed — critical for near-instant stop commands.
        timeout=0.05 (50ms) keeps reads non-blocking but responsive.
        """
        self.port = port
        self.baudrate = baudrate
        self.timeout = timeout
        self.ser = None
        self.connect_uart()

    def connect_uart(self):
        while True:
            try:
                logging.info(f"[UART] Connecting to {self.port} @ {self.baudrate} baud...")
                if self.ser is not None and getattr(self.ser, 'is_open', False):
                    try:
                        self.ser.close()
                    except Exception:
                        pass

                self.ser = serial.Serial(
                    self.port,
                    self.baudrate,
                    timeout=self.timeout,
                    write_timeout=0.1   # Don't block forever on write
                )

                time.sleep(2)  # Wait for Arduino reset
                self.ser.reset_input_buffer()
                self.ser.reset_output_buffer()

                logging.info(f"[UART] Connected successfully")
                return
            except Exception as e:
                logging.error(f"[UART] Connect failed: {e} — retrying in 1s...")
                time.sleep(1)

    def safe_write(self, cmd: str) -> bool:
        if self.ser is None or not getattr(self.ser, 'is_open', False):
            return False
        try:
            self.ser.write(cmd.encode())
            # flush() ensures bytes leave the Pi's buffer immediately
            self.ser.flush()
            return True
        except Exception as e:
            logging.error(f"[UART] Write error: {e}")
            return False

    def safe_read(self):
        if self.ser is None or not getattr(self.ser, 'is_open', False):
            return "ERROR"
        try:
            if self.ser.in_waiting > 0:
                line = self.ser.readline().decode(errors='ignore').strip()
                if line == "":
                    return None
                if line in ["OK", "F", "S", "L", "R", "B"]:
                    return line
                return None  # Discard garbage
            return None
        except Exception as e:
            logging.error(f"[UART] Read error: {e}")
            return "ERROR"

    def send_command_and_reconnect_if_failed(self, cmd: str) -> bool:
        if not self.safe_write(cmd):
            logging.warning("[UART] Write failed — reconnecting...")
            self.connect_uart()
            return False
        return True

    def read_and_reconnect_if_failed(self):
        resp = self.safe_read()
        if resp == "ERROR":
            logging.warning("[UART] Read error — reconnecting...")
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
        """
        Sends stop command — called immediately when both IR sensors go HIGH.
        Uses safe_write directly (bypasses reconnect overhead) for minimum latency.
        """
        return self.send_command_and_reconnect_if_failed("S\n")

    def cleanup(self):
        try:
            self.safe_write("S\n")
            if self.ser:
                self.ser.close()
        except Exception:
            pass