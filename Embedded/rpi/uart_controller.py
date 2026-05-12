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
    """
    Communicates with the ATmega over UART.

    Commands sent to ATmega:
        'F'  →  Push_Forward()  / Forward_decide_mov()
        'B'  →  Push_Backward() / Backward_decide_mov()
        'P'  →  Pve_Rotate()
        'N'  →  Nve_Rotate()
        'S'  →  Stop_Car()

    Signals received from ATmega:
        's'  →  Both IR sensors BLACK — intersection detected, car has stopped.
        'OK' →  Generic acknowledgement.
    """

    def __init__(self, port='/dev/serial0', baudrate=9600, timeout=0.3):
        self.port     = port
        self.baudrate = baudrate
        self.timeout  = timeout
        self.ser      = None
        self.connect_uart()

    # ── Connection ───────────────────────────────────────────

    def connect_uart(self):
        while True:
            try:
                logging.info(f"[{get_timestamp()}] Connecting UART → {self.port} @ {self.baudrate} baud...")
                if self.ser is not None and getattr(self.ser, 'is_open', False):
                    try:
                        self.ser.close()
                    except Exception:
                        pass

                self.ser = serial.Serial(self.port, self.baudrate, timeout=self.timeout)
                time.sleep(2)           # allow ATmega to reset
                self.ser.reset_input_buffer()
                logging.info(f"[{get_timestamp()}] ✅ UART connected successfully.")
                return
            except Exception as e:
                logging.error(f"[{get_timestamp()}] UART connect failed: {e} — retrying in 1 s...")
                time.sleep(1)

    # ── Low-level I/O ─────────────────────────────────────────

    def safe_write(self, cmd: str) -> bool:
        if self.ser is None or not getattr(self.ser, 'is_open', False):
            logging.warning(f"[UART] Cannot write '{repr(cmd)}' — port not open.")
            return False
        try:
            self.ser.write(cmd.encode())
            return True
        except Exception as e:
            logging.error(f"[{get_timestamp()}] UART write error: {e}")
            return False

    def safe_read(self):
        """
        Returns:
            str   — a valid token from ATmega ('OK', 'F', 'S', 'L', 'R', 's')
            None  — nothing available yet
            'ERROR' — I/O failure
        """
        if self.ser is None or not getattr(self.ser, 'is_open', False):
            return "ERROR"
        try:
            if self.ser.in_waiting > 0:
                line = self.ser.readline().decode(errors='ignore').strip()
                if line == "":
                    return None
                # Accept: OK, movement echo chars, and the intersection stop signal 's'
                if line in {"OK", "F", "B", "S", "L", "R", "P", "N", "s"}:
                    return line
                logging.debug(f"[UART RX] Ignored garbage: '{line}'")
                return None
            return None
        except Exception as e:
            logging.error(f"[{get_timestamp()}] UART read error: {e}")
            return "ERROR"

    # ── Resilient wrappers ────────────────────────────────────

    def send_command_and_reconnect_if_failed(self, cmd: str) -> bool:
        if not self.safe_write(cmd):
            logging.warning(f"[UART] Write failed for '{repr(cmd)}'. Reconnecting...")
            self.connect_uart()
            return False
        return True

    def read_and_reconnect_if_failed(self):
        resp = self.safe_read()
        if resp == "ERROR":
            logging.warning("[UART] Read error. Reconnecting...")
            self.connect_uart()
            return None
        return resp

    # ── Movement API ──────────────────────────────────────────

    def forward(self) -> bool:
        """Push_Forward() / Forward_decide_mov() on ATmega."""
        logging.info("[UART TX] 'F' → ATmega Push_Forward()")
        return self.send_command_and_reconnect_if_failed("F\n")

    def backward(self) -> bool:
        """Push_Backward() / Backward_decide_mov() on ATmega."""
        logging.info("[UART TX] 'B' → ATmega Push_Backward()")
        return self.send_command_and_reconnect_if_failed("B\n")

    def pve_rotate(self) -> bool:
        """Pve_Rotate() on ATmega (positive / clockwise rotation)."""
        logging.info("[UART TX] 'P' → ATmega Pve_Rotate()")
        return self.send_command_and_reconnect_if_failed("P\n")

    def nve_rotate(self) -> bool:
        """Nve_Rotate() on ATmega (negative / counter-clockwise rotation)."""
        logging.info("[UART TX] 'N' → ATmega Nve_Rotate()")
        return self.send_command_and_reconnect_if_failed("N\n")

    def stop(self) -> bool:
        """Stop_Car() on ATmega."""
        logging.info("[UART TX] 'S' → ATmega Stop_Car()")
        return self.send_command_and_reconnect_if_failed("S\n")

    # Aliases kept for backward compatibility
    def left(self)  -> bool: return self.send_command_and_reconnect_if_failed("L\n")
    def right(self) -> bool: return self.send_command_and_reconnect_if_failed("R\n")

    # ── Cleanup ───────────────────────────────────────────────

    def cleanup(self):
        try:
            self.safe_write("S\n")
            if self.ser:
                self.ser.close()
            logging.info("[UART] Port closed.")
        except Exception:
            pass