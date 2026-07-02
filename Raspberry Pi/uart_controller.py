"""
UART Controller Module.
Manages serial communication with the ATmega microcontroller, including command transmission,
acknowledgement verification, and automatic reconnection on link failure.
"""

import logging
import time
import datetime
import config

logger = logging.getLogger(__name__)

# Fallback wrapper for serial to allow development on non-RPi environments
try:
    import serial
except ImportError:
    logger.warning("pyserial is not installed. Using Mock serial for development.")
    class MockSerial:
        def __init__(self, port, baudrate, timeout=0.1):
            self.port = port
            self.baudrate = baudrate
            self.timeout = timeout
            self.is_open = True
            self.in_waiting = 0
            self._write_count = 0

        def write(self, data: bytes) -> int:
            cmd = data.decode(errors='ignore').strip()
            logger.debug(f"[UART MOCK TX] Command: '{cmd}'")
            self._write_count += 1
            return len(data)

        def readline(self) -> bytes:
            # Simulate ACK responses for commands
            time.sleep(0.05)
            return b""

        def reset_input_buffer(self):
            pass

        def close(self):
            self.is_open = False
            
    serial = MockSerial


def get_timestamp() -> str:
    """Returns the current local time formatted as HH:MM:SS.mmm."""
    return datetime.datetime.now().strftime("%H:%M:%S.%f")[:-3]


class UARTCarController:
    """
    Communicates with the ATmega over UART.
    Commands sent to ATmega:
        'F'  →  Push_Forward() / Forward_decide_mov()
        'B'  →  Push_Backward() / Backward_decide_mov()
        'P'  →  Pve_Rotate() (Positive/Clockwise)
        'N'  →  Nve_Rotate() (Negative/Counter-Clockwise)
        'S'  →  Stop_Car()
        'O'  →  Blind_Backward()
        '1'  →  skip_lines_backward(1) — stop at 1st line (skip 0)
        '2'  →  skip_lines_backward(2) — stop at 2nd line (skip 1)
        '3'  →  skip_lines_backward(3) — stop at 3rd line (skip 2)
        'X'  →  Buzzer()

    Signals received from ATmega:
        's'  →  Both IR sensors BLACK — intersection detected, car has stopped.
        'OK' →  Generic acknowledgement (e.g. OK:F, OK:B).
    """

    def __init__(self, port: str = config.UART_PORT, baudrate: int = config.UART_BAUDRATE, timeout: float = config.UART_TIMEOUT):
        self.port = port
        self.baudrate = baudrate
        self.timeout = timeout
        self.ser = None
        self.connect_uart()

    def connect_uart(self):
        """Attempts to open/reopen the serial port, retrying on failure."""
        while True:
            try:
                logger.info(f"[UART] Connecting UART → {self.port} @ {self.baudrate} baud...")
                if self.ser is not None:
                    try:
                        self.ser.close()
                    except Exception:
                        pass

                self.ser = serial.Serial(self.port, self.baudrate, timeout=self.timeout)
                time.sleep(2)  # allow ATmega to reset
                self.ser.reset_input_buffer()
                logger.info("[UART] UART connected successfully.")
                return
            except Exception as e:
                logger.error(f"[UART] Connect failed: {e} — retrying in 1s...")
                time.sleep(1)

    def safe_write(self, cmd: str) -> bool:
        """Writes a string command to UART with safety checks."""
        if self.ser is None or not getattr(self.ser, 'is_open', False):
            logger.warning(f"[UART] Cannot write '{cmd.strip()}' — port not open.")
            return False
        try:
            self.ser.write(cmd.encode())
            return True
        except Exception as e:
            logger.error(f"[UART] Write error: {e}")
            return False

    def safe_read(self) -> str | None:
        """
        Reads a line from UART if available.
        Returns:
            str: valid decoded response strip of whitespace
            None: if nothing is waiting or response is empty
            "ERROR": if read failed
        """
        if self.ser is None or not getattr(self.ser, 'is_open', False):
            return "ERROR"

        try:
            if self.ser.in_waiting > 0:
                raw = self.ser.readline()
                line = raw.decode(errors='ignore').strip()
                logger.debug(f"[UART RAW RX] '{line}'")

                if line == "":
                    return None

                # Valid ACKs and Intersection Signals
                if line.startswith("OK:") or line == "s":
                    return line

                logger.debug(f"[UART RX] Ignored garbage: '{line}'")
                return None

            return None
        except Exception as e:
            logger.error(f"[UART] Read error: {e}")
            return "ERROR"

    def send_command_and_reconnect_if_failed(self, cmd: str) -> bool:
        """Sends command and triggers reconnect on write failure."""
        if not self.safe_write(cmd):
            logger.warning(f"[UART] Write failed for '{cmd.strip()}'. Reconnecting...")
            self.connect_uart()
            return False
        return True

    def read_and_reconnect_if_failed(self) -> str | None:
        """Reads response and triggers reconnect on read error."""
        resp = self.safe_read()
        if resp == "ERROR":
            logger.warning("[UART] Read error. Reconnecting...")
            self.connect_uart()
            return None
        return resp

    # ── Movement API ──────────────────────────────────────────

    def forward(self) -> bool:
        """Sends Forward command ('F') to ATmega."""
        logger.info("[UART TX] Sending command 'F' (Forward)")
        return self.send_with_ack("F\n", "OK:F")

    def backward(self) -> bool:
        """Sends Backward command ('B') to ATmega."""
        logger.info("[UART TX] Sending command 'B' (Backward)")
        return self.send_with_ack("B\n", "OK:B")
    
    def blind_backward(self) -> bool:
        """Sends Blind Backward command ('O') to ATmega."""
        logger.info("[UART TX] Sending command 'O' (Blind Backward)")
        return self.send_with_ack("O\n", "OK:O")

    def pve_rotate(self) -> bool:
        """Sends Positive/Clockwise Rotation command ('P') to ATmega."""
        logger.info("[UART TX] Sending command 'P' (Pve Rotate)")
        return self.send_with_ack("P\n", "OK:P")

    def nve_rotate(self) -> bool:
        """Sends Negative/Counter-Clockwise Rotation command ('N') to ATmega."""
        logger.info("[UART TX] Sending command 'N' (Nve Rotate)")
        return self.send_with_ack("N\n", "OK:N")

    def stop(self) -> bool:
        """Sends Stop command ('S') to ATmega."""
        logger.info("[UART TX] Sending command 'S' (Stop)")
        return self.send_with_ack("S\n", "OK:S")

    def skip_lines_backward(self, count: int) -> bool:
        """
        Sends skip command ('1', '2', or '3') to ATmega to move backward
        and stop after crossing (count - 1) black lines.
        """
        count = max(1, min(count, 3))
        cmd = str(count)
        expected_ack = f"OK:{cmd}"

        logger.info(f"[UART TX] Sending command '{cmd}' (skip_lines_backward: {count})")
        return self.send_with_ack(f"{cmd}\n", expected_ack)

    # Legacy Compatibility Aliases
    def left(self) -> bool:
        return self.send_with_ack("L\n", "OK:L")

    def right(self) -> bool:
        return self.send_with_ack("R\n", "OK:R")

    def buzzer(self) -> bool:
        """Sends Buzzer command ('X') to ATmega."""
        logger.info("[UART TX] Sending command 'X' (Buzzer)")
        return self.send_with_ack("X\n", "OK:X")

    # ── Cleanup ───────────────────────────────────────────────

    def cleanup(self):
        """Sends a final stop command and closes the serial port."""
        try:
            self.safe_write("S\n")
            if self.ser:
                self.ser.close()
            logger.info("[UART] Port closed.")
        except Exception as e:
            logger.error(f"[UART] Cleanup failed: {e}")

    def send_with_ack(self, cmd: str, expected_ack: str, timeout: float = 2.0,
                       max_retries: int = 3, retry_delay: float = 0.2) -> bool:
        """
        Sends command and blocks waiting for the expected acknowledgement.
        Retries transmission if timeout occurs.
        """
        for attempt in range(1, max_retries + 1):
            logger.info(f"[UART TX] Attempt {attempt}/{max_retries} — sending: '{cmd.strip()}'")

            # Flush stale bytes to avoid matching old ACKs
            try:
                self.ser.reset_input_buffer()
            except Exception:
                pass

            if not self.send_command_and_reconnect_if_failed(cmd):
                time.sleep(retry_delay)
                continue

            # Wait for expected ACK
            start = time.time()
            while time.time() - start < timeout:
                resp = self.read_and_reconnect_if_failed()
                if resp is not None:
                    logger.info(f"[UART RX] Received: '{resp}'")
                    if resp == expected_ack:
                        logger.info(f"[UART ACK] verified '{expected_ack}' on attempt {attempt}")
                        return True
                time.sleep(0.01)

            logger.warning(f"[UART] ACK TIMEOUT on attempt {attempt}/{max_retries} for '{expected_ack}'")
            if attempt < max_retries:
                time.sleep(retry_delay)

        logger.error(f"[UART] Command failed after {max_retries} attempts: cmd='{cmd.strip()}' expected='{expected_ack}'")
        return False

    def flush_input(self):
        """Flushes the input buffer."""
        if self.ser and getattr(self.ser, 'is_open', False):
            try:
                self.ser.reset_input_buffer()
                logger.info("[UART] Input buffer flushed.")
            except Exception as e:
                logger.error(f"[UART] Flush failed: {e}")