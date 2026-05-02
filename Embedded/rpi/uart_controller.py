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
    # Core Send Function (Non-blocking)
    # =========================
    def send_command(self, command: str) -> bool:
        if self.ser is not None and self.ser.is_open:
            try:
                # IMPORTANT: Do NOT clear the input buffer here!
                # If the ATmega sent an ACK while we were reading sensors,
                # clearing the buffer will delete the ACK and we will freeze!
                data = command.encode('ascii')
                
                logging.debug(f"[UART TX] RAW: {repr(command)}")
                self.ser.write(data)
                return True
            except serial.SerialTimeoutException:
                logging.error("[UART ERROR] Timeout writing to UART.")
                return False
            except serial.SerialException as e:
                logging.error(f"[UART ERROR] Serial exception: {e}")
                return False
        else:
            logging.error("[UART ERROR] UART not open. Cannot send command.")
            return False

    # =========================
    # Response Handler (Non-blocking)
    # =========================
    def read_uart_response(self) -> str:
        """
        Reads ALL available response bytes from the ATmega.
        Using ser.in_waiting avoids blocking indefinitely.
        """
        if self.ser is not None and self.ser.is_open:
            try:
                # Wait a tiny bit to allow ATmega to respond if it hasn't yet
                time.sleep(0.01) 
                
                response_bytes = b""
                # Read everything currently in the buffer
                while self.ser.in_waiting > 0:
                    response_bytes += self.ser.read(self.ser.in_waiting)
                    time.sleep(0.01) # Allow trailing bytes to arrive
                
                if response_bytes:
                    decoded = response_bytes.decode('ascii', errors='ignore').strip()
                    logging.debug(f"[UART RX] {repr(decoded)}")
                    return decoded
                else:
                    return ""
            except Exception as e:
                logging.error(f"[UART RX ERROR] {e}")
                return ""
        return ""

    # =========================
    # Movement API
    # =========================
    def forward(self):
        return self.send_command("F\n")

    def backward(self):
        return self.send_command("B\n")

    def left(self):
        return self.send_command("L\n")

    def right(self):
        return self.send_command("R\n")

    def stop(self):
        return self.send_command("S\n")

    def test(self):
        logging.info("[UART] Testing connection...")
        return self.send_command("T\n")