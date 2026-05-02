import logging
import serial
import time


logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - [%(levelname)s] - %(message)s'
)


class UARTCarController:
    def __init__(self, port='/dev/serial0', baudrate=9600, timeout=1.0):
        try:
            self.ser = serial.Serial(
                port=port,
                baudrate=baudrate,
                parity=serial.PARITY_NONE,
                stopbits=serial.STOPBITS_ONE,
                bytesize=serial.EIGHTBITS,
                timeout=timeout
            )

            self.state = "SLEEP"

            logging.info(f"[UART] Initialized on {port} @ {baudrate}")

        except Exception as e:
            logging.error(f"[UART] Init failed: {e}")
            raise e

        self.ser.reset_input_buffer()
        self.ser.reset_output_buffer()

    # =========================
    # Core Send Function
    # =========================
    def send_command(self, command: str, max_retries=3):
        attempt = 0

        while attempt < max_retries:
            attempt += 1

            logging.info(f"[UART TX] Attempt {attempt}: {command}")

            self.ser.reset_input_buffer()

            self.ser.write(command.encode("ascii"))
            self.ser.flush()

            response = self._wait_for_response()

            if response == "ACK":
                logging.info(f"[UART] ACK received for {command}")
                return True

            elif response == "ERR":
                logging.warning(f"[UART] ERR received for {command}")

            elif response is None:
                logging.error(f"[UART] Timeout for {command}")

            else:
                logging.warning(f"[UART] Unknown response: {response}")

        logging.critical(f"[UART] Failed command: {command}")
        return False

    # =========================
    # Response Handler
    # =========================
    def _wait_for_response(self):
        start = time.time()

        while (time.time() - start) < self.ser.timeout:
            if self.ser.in_waiting > 0:
                try:
                    line = self.ser.readline().decode("ascii", errors="ignore").strip()

                    if not line:
                        continue

                    logging.debug(f"[UART RX RAW] {line}")

                    if line == "ACK":
                        return "ACK"
                    elif line == "ERR":
                        return "ERR"

                except Exception as e:
                    logging.error(f"[UART RX ERROR] {e}")
                    break

            time.sleep(0.01)

        return None

    # =========================
    # Movement API
    # =========================
    def forward(self):
        return self.send_command("F")

    def backward(self):
        return self.send_command("B")

    def left(self):
        return self.send_command("L")

    def right(self):
        return self.send_command("R")

    def stop(self):
        return self.send_command("S")

    def test(self):
        logging.info("[UART] Testing connection...")
        return self.send_command("T")