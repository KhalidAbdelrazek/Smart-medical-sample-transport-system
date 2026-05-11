import logging
import time
import datetime
import sys

try:
    import serial
except ImportError:
    print("[ERROR] Install pyserial: pip3 install pyserial")
    sys.exit(1)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - [%(levelname)s] - %(message)s'
)

# ── UART Debug Logger ──────────────────────────────────────────────────────
# Prints every attempted / successful / failed UART interaction to stdout
# using ANSI colours so it stands out from normal INFO logs.

class _Colour:
    RESET  = "\033[0m"
    CYAN   = "\033[96m"   # TX attempts
    GREEN  = "\033[92m"   # TX success
    YELLOW = "\033[93m"   # RX data
    RED    = "\033[91m"   # errors / warnings
    GRAY   = "\033[90m"   # no data / skip

_C = _Colour()

# Detect if the terminal supports ANSI (disable on Windows without VT)
_USE_COLOUR = hasattr(sys.stdout, 'isatty') and sys.stdout.isatty()

def _dbg(colour: str, tag: str, msg: str) -> None:
    """Print a debug line to stdout with optional ANSI colour."""
    ts  = datetime.datetime.now().strftime("%H:%M:%S.%f")[:-3]
    if _USE_COLOUR:
        print(f"{colour}[UART-DBG {ts}] {tag}: {msg}{_C.RESET}", flush=True)
    else:
        print(f"[UART-DBG {ts}] {tag}: {msg}", flush=True)



def get_timestamp():
    return datetime.datetime.now().strftime("%H:%M:%S.%f")[:-3]


class UARTCarController:
    def __init__(self, port='/dev/serial0', baudrate=9600, timeout=0.1):
        """
        baudrate=9600  — MUST match ATmega firmware.
          At F_CPU=8MHz with U2X=0: UBRR=51 → actual 9615 baud (0.16% error).
          115200 baud at 8MHz gives 3.5% error — EXCEEDS UART tolerance,
          causing silent bit corruption and lost commands.
        timeout=0.1 (100ms) — slightly longer at 9600 baud.
        """
        self.port = port
        self.baudrate = baudrate
        self.timeout = timeout
        self.ser = None
        self.connect_uart()

    def connect_uart(self):
        while True:
            try:
                logging.info(f"[UART] Connecting to {self.port} @ {self.baudrate} baud  "
                             f"(ATmega must be flashed with 9600-baud firmware)...")
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
        raw = repr(cmd)          # show escape chars e.g. 'F\\n'
        port_ok = self.ser is not None and getattr(self.ser, 'is_open', False)

        _dbg(_C.CYAN, "TX-ATTEMPT",
             f"cmd={raw}  |  port_open={port_ok}  |  port={self.port}")

        if not port_ok:
            _dbg(_C.RED, "TX-BLOCKED",
                 f"Serial port is None or closed — command NOT sent: {raw}")
            return False

        try:
            bytes_written = self.ser.write(cmd.encode())
            # flush() ensures bytes leave the Pi's buffer immediately
            self.ser.flush()
            _dbg(_C.GREEN, "TX-SUCCESS",
                 f"cmd={raw}  bytes_written={bytes_written}  baud={self.baudrate}")
            return True
        except Exception as e:
            _dbg(_C.RED, "TX-ERROR",
                 f"cmd={raw}  error={e}")
            logging.error(f"[UART] Write error: {e}")
            return False

    # ATmega sends these exact strings (see main.c handle_command)
    # OK     — stop / test / duplicate movement
    # OK_F   — forward executed
    # OK_B   — backward executed
    # OK_L   — left executed
    # OK_R   — right executed
    # ERR    — unknown command
    # [BOOT] — boot message (prefix match)
    _VALID_RESPONSES = {"OK", "OK_F", "OK_B", "OK_L", "OK_R", "ERR"}

    def safe_read(self):
        port_ok = self.ser is not None and getattr(self.ser, 'is_open', False)
        if not port_ok:
            _dbg(_C.RED, "RX-BLOCKED", "Serial port is None or closed")
            return "ERROR"
        try:
            waiting = self.ser.in_waiting
            if waiting > 0:
                _dbg(_C.YELLOW, "RX-INCOMING",
                     f"{waiting} bytes waiting in RX buffer")
                line = self.ser.readline().decode(errors='ignore').strip()
                if line == "":
                    _dbg(_C.GRAY, "RX-EMPTY",
                         "readline returned empty string — ignoring")
                    return None
                # Accept boot message as informational (don't treat as ERROR)
                if line.startswith("[BOOT]"):
                    _dbg(_C.GREEN, "RX-BOOT",
                         f"ATmega boot message: '{line}'")
                    return None  # Informational only
                if line in self._VALID_RESPONSES:
                    _dbg(_C.YELLOW, "RX-ACCEPTED",
                         f"ATmega → '{line}'")
                    return line
                _dbg(_C.RED, "RX-DISCARDED",
                     f"Unrecognised ATmega response → '{line}'  "
                     f"(raw bytes: {line.encode()})  "
                     f"Check ATmega baud rate matches 9600!")
                return None
            return None
        except Exception as e:
            _dbg(_C.RED, "RX-ERROR", str(e))
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
        _dbg(_C.CYAN, "CMD", "FORWARD  → sending 'F\\n' to ATmega")
        return self.send_command_and_reconnect_if_failed("F\n")

    def backward(self):
        _dbg(_C.CYAN, "CMD", "BACKWARD → sending 'B\\n' to ATmega")
        return self.send_command_and_reconnect_if_failed("B\n")

    def left(self):
        _dbg(_C.CYAN, "CMD", "LEFT     → sending 'L\\n' to ATmega")
        return self.send_command_and_reconnect_if_failed("L\n")

    def right(self):
        _dbg(_C.CYAN, "CMD", "RIGHT    → sending 'R\\n' to ATmega")
        return self.send_command_and_reconnect_if_failed("R\n")

    def stop(self):
        """
        Sends stop command — called immediately when both IR sensors go HIGH.
        Uses safe_write directly (bypasses reconnect overhead) for minimum latency.
        """
        _dbg(_C.CYAN, "CMD", "STOP     → sending 'S\\n' to ATmega")
        return self.send_command_and_reconnect_if_failed("S\n")

    def cleanup(self):
        try:
            self.safe_write("S\n")
            if self.ser:
                self.ser.close()
        except Exception:
            pass