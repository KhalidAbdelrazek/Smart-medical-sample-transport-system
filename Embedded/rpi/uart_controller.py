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
        '1'  →  skip_lines_backward(1) — stop at 1st line  (skip 0)
        '2'  →  skip_lines_backward(2) — stop at 2nd line  (skip 1)
        '3'  →  skip_lines_backward(3) — stop at 3rd line  (skip 2)

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
            str   — valid UART response
            None  — nothing available
            "ERROR" — UART failure
        """

        if self.ser is None or not getattr(self.ser, 'is_open', False):
            return "ERROR"

        try:
            if self.ser.in_waiting > 0:

                raw = self.ser.readline()
                line = raw.decode(errors='ignore').strip()

                print(f"[UART RAW RX] {repr(line)}")

                if line == "":
                    return None

                # Valid ACKs from ATmega
                if line.startswith("OK:"):
                    return line

                # Intersection signal
                if line == "s":
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
        return self.send_with_ack("F\n","OK:F")

    def backward(self) -> bool:
        """Push_Backward() / Backward_decide_mov() on ATmega."""
        logging.info("[UART TX] 'B' → ATmega Push_Backward()")
        return self.send_with_ack("B\n","OK:B")
    
    def blind_backward(self) -> bool:
        """Blind_Backward() on ATmega — timed backward move, no line detection."""
        logging.info("[UART TX] 'O' → ATmega Blind_Backward()")
        return self.send_with_ack("O\n", "OK:O")

    def pve_rotate(self) -> bool:
        """Pve_Rotate() on ATmega (positive / clockwise rotation)."""
        logging.info("[UART TX] 'P' → ATmega Pve_Rotate()")
        return self.send_with_ack("P\n","OK:P")

    def nve_rotate(self) -> bool:
        """Nve_Rotate() on ATmega (negative / counter-clockwise rotation)."""
        logging.info("[UART TX] 'N' → ATmega Nve_Rotate()")
        return self.send_with_ack("N\n","OK:N")

    def stop(self) -> bool:
        """Stop_Car() on ATmega."""
        logging.info("[UART TX] 'S' → ATmega Stop_Car()")
        return self.send_with_ack("S\n", "OK:S")

    def skip_lines_backward(self, count: int) -> bool:
        """
        Send '1', '2', or '3' to ATmega to move backward and stop after
        crossing (count - 1) black lines, stopping at the count-th line.
          count=1 → '1' → stop at 1st line  (skip 0)
          count=2 → '2' → stop at 2nd line  (skip 1)
          count=3 → '3' → stop at 3rd line  (skip 2)
        """
        count        = max(1, min(count, 3))    # clamp to valid range 1–3
        cmd          = str(count)               # '1', '2', or '3'
        expected_ack = f"OK:{cmd}"              # 'OK:1', 'OK:2', or 'OK:3'

        logging.info(f"[UART TX] '{cmd}' → ATmega skip_lines_backward({count})")
        return self.send_with_ack(f"{cmd}\n", expected_ack)

    # Aliases kept for backward compatibility
    def left(self)  -> bool: return self.send_with_ack("L\n","OK:L")
    def right(self) -> bool: return self.send_with_ack("R\n","OK:R")

    # ── Cleanup ───────────────────────────────────────────────

    def cleanup(self):
        try:
            self.safe_write("S\n")
            if self.ser:
                self.ser.close()
            logging.info("[UART] Port closed.")
        except Exception:
            pass

    def send_with_ack(self, cmd: str, expected_ack: str, timeout: float = 2.0,
                      max_retries: int = 3, retry_delay: float = 0.2) -> bool:
        """
        Send UART command and wait for ATmega ACK.
        If no ACK arrives within `timeout` seconds, the command is resent
        automatically up to `max_retries` times before giving up.

        Args:
            cmd:          Command string to send (e.g. "F\\n").
            expected_ack: ACK string to wait for  (e.g. "OK:F").
            timeout:      Seconds to wait for ACK per attempt  (default 2.0).
            max_retries:  Total send attempts including the first (default 3).
            retry_delay:  Pause between a timeout and the next resend (default 0.2 s).

        Returns:
            True  — ACK received and verified.
            False — All retries exhausted without a valid ACK.
        """

        for attempt in range(1, max_retries + 1):

            logging.info(f"[UART TX] Attempt {attempt}/{max_retries} — sending: {repr(cmd)}")
            print(f"  ➤  [UART TX] Attempt {attempt}/{max_retries} — cmd: {repr(cmd)}  expect: {expected_ack}")

            # Flush stale bytes before every send so an old ACK from a previous
            # attempt cannot accidentally satisfy this one.
            try:
                self.ser.reset_input_buffer()
            except Exception:
                pass

            if not self.send_command_and_reconnect_if_failed(cmd):
                # write itself failed — reconnect already triggered inside
                # wait a moment then retry the whole loop
                time.sleep(retry_delay)
                continue

            # ── Wait for ACK ──────────────────────────────────
            start = time.time()
            while time.time() - start < timeout:
                resp = self.read_and_reconnect_if_failed()

                if resp is not None:
                    print(f"[UART RX] {resp}")
                    logging.info(f"[UART RX] {resp}")

                    if resp == expected_ack:
                        print(f"[UART ACK] ✅ VERIFIED {expected_ack}  (attempt {attempt})")
                        logging.info(f"[UART ACK] VERIFIED {expected_ack} on attempt {attempt}")
                        return True

                time.sleep(0.01)

            # ── Timeout on this attempt ───────────────────────
            logging.warning(
                f"[UART] ACK TIMEOUT on attempt {attempt}/{max_retries} "
                f"waiting for '{expected_ack}'"
            )
            print(
                f"  ⚠️  [UART] No ACK for {repr(cmd)} after {timeout:.1f}s "
                f"(attempt {attempt}/{max_retries})"
                + ("  — retrying..." if attempt < max_retries else "  — giving up.")
            )

            if attempt < max_retries:
                time.sleep(retry_delay)

        # ── All retries exhausted ─────────────────────────────
        logging.error(
            f"[UART] FAILED after {max_retries} attempts — "
            f"cmd={repr(cmd)}  expected={expected_ack}"
        )
        print(f"  💥 [UART ERROR] Command {repr(cmd)} failed after {max_retries} attempts.")
        return False

    def flush_input(self):
        if self.ser and self.ser.is_open:
            self.ser.reset_input_buffer()
            logging.info("[UART] Input buffer flushed.")

    def buzzer(self) -> bool:
        """Buzzer() on ATmega (turn buzzer ON)."""
        logging.info("[UART TX] 'X' → ATmega Buzzer()")
        return self.send_with_ack("X\n", "OK:X")