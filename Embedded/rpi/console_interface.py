import logging
from uart_controller import UARTCarController

# =========================
# Console Interface
# =========================

# =========================
# Logging Setup
# =========================
logging.basicConfig(
    level=logging.DEBUG,  # Set to DEBUG for detailed UART traces
    format='%(asctime)s - [%(levelname)s] - %(message)s'
)


class ConsoleApp:
    def __init__(self, controller: UARTCarController):
        self.car = controller
        self.running = False

    def start(self):
        self.running = True

        print("\n\n" + "="*30)
        print("🚗 ROBOTIC CAR UART CONTROL")
        print("="*30)
        print("  w -> Forward")
        print("  s -> Stop")
        print("  x -> Backward")
        print("  d -> Right")
        print("  a -> Left")
        print("  t -> enter manual test mode")
        print("  q -> Quit")
        print("-" * 30)

        while self.running:
            try:
                cmd = input("\n[CMD] Enter command: ").strip().lower()

                if cmd == "w":
                    self.car.forward()
                elif cmd == "s":
                    self.car.stop()
                elif cmd == "x":
                    self.car.backward()
                elif cmd == "d":
                    self.car.right()
                elif cmd == "a":
                    self.car.left()
                elif cmd == "t":
                    test_char = input("Enter test character: ")
                    if len(test_char) == 1:
                        self.car.send_command(test_char)
                    else:
                        logging.warning("Please enter exactly one character.")
                elif cmd == "q":
                    logging.info("Exiting system")
                    self.stop()
                else:
                    logging.warning(f"Unknown input: '{cmd}'")

            except KeyboardInterrupt:
                logging.info("Interrupted by user")
                self.stop()
            except Exception as e:
                logging.error(f"Runtime error: {e}")

    def stop(self):
        self.running = False
        self.car.stop()

