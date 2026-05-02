import logging
import serial
# =========================
# UART Car Controller
# =========================

# =========================
# Logging Setup
# =========================
logging.basicConfig(
    level=logging.DEBUG,  # Set to DEBUG for detailed UART traces
    format='%(asctime)s - [%(levelname)s] - %(message)s'
)

class UARTCarController:
    """
    Controls ATmega via Raspberry Pi UART with reliable message delivery.
    Protocol:
    - Sends 1-character commands (F, B, L, R, S, T)
    - Waits for "ACK" or "ERR"
    - Retries on timeout or error
    """

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
            logging.info(f"UART initialized on {port} at {baudrate} baud.")
        except Exception as e:
            logging.error(f"Failed to initialize UART: {e}")
            raise e

        # Clear buffers
        self.ser.reset_input_buffer()
        self.ser.reset_output_buffer()

    def send_command(self, command: str, max_retries=3):
        """
        Sends a command and waits for ACK with retry mechanism.
        """
        attempt = 0

        while attempt < max_retries:
            attempt += 1
            logging.info(f"[TX] Attempt {attempt}/{max_retries}: Sending '{command}'")
            logging.info(f"[TX] Sent: '{command}' (ASCII: {ord(command)})")
            
            # Clear input buffer to avoid reading stale data
            self.ser.reset_input_buffer()
            
            # Send command
            self.ser.write(command.encode('ascii'))
            self.ser.flush()

            # Wait for response
            response = self._wait_for_response()

            if response == "ACK":
                logging.info(f"[SUCCESS] Received ACK for '{command}'")
                return True
            elif response == "ERR":
                logging.warning(f"[ERROR] Received ERR from ATmega for '{command}'")
                # Immediate retry
                continue
            elif response is None:
                logging.error(f"[TIMEOUT] No response for '{command}' within timeout")
                # Retry
                continue
            else:
                logging.warning(f"[RX] Received garbage/unknown: {response}")
                # Retry
                continue

        logging.critical(f"[FAILURE] Failed to send '{command}' after {max_retries} attempts.")
        return False

    def _wait_for_response(self):
        """
        Reads from UART until 'ACK' or 'ERR' is found, logging debug messages.
        """
        start_time = time.time()
        timeout = self.ser.timeout or 1.0

        buffer = ""
        while (time.time() - start_time) < timeout:
            if self.ser.in_waiting > 0:
                # Read line-by-line or char-by-char? ATmega sends strings ending with \r\n
                try:
                    line = self.ser.readline().decode('ascii', errors='replace').strip()
                    if not line:
                        continue
                    
                    logging.debug(f"[RAW RX] {line}")

                    # Process the line
                    if line == "ACK":
                        return "ACK"
                    elif line == "ERR":
                        return "ERR"
                    elif "[DEBUG]" in line or "[RX]" in line or "[ERROR]" in line:
                        # Log ATmega debug output
                        logging.info(f"[ATmega] {line}")
                    else:
                        # Might be partial or combined message
                        if "ACK" in line: return "ACK"
                        if "ERR" in line: return "ERR"
                except Exception as e:
                    logging.error(f"Read error: {e}")
                    break
            
            time.sleep(0.01) # Small sleep to prevent CPU hogging

        return None

    # =========================
    # High-level Movement API
    # =========================

    def forward(self):
        return self.send_command('F')

    def backward(self):
        return self.send_command('B')

    def left(self):
        return self.send_command('L')

    def right(self):
        return self.send_command('R')

    def stop(self):
        return self.send_command('S')

    def test(self):
        """Important: Test communication without moving motors."""
        logging.info("Testing communication link...")
        return self.send_command('T')

