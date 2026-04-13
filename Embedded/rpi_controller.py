import time
import logging
import subprocess

# =========================
# Logging Setup
# =========================
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - [%(levelname)s] - %(message)s'
)

# =========================
# Car Controller
# =========================
class CarController:
    """
    Controls ATmega via Raspberry Pi GPIO using pinctrl commands.
    """

    def __init__(self):
        self.pins = {
            "forward": 17,
            "backward": 18,
            "right": 27,
            "left": 26
        }

        logging.info("CarController initialized with pinctrl GPIO mapping")

        # Initialize all pins to LOW (safe state)
        self.stop()

    # -------------------------
    # Internal command runner
    # -------------------------
    def _run(self, cmd: str):
        try:
            subprocess.run(cmd, shell=True, check=True)
        except subprocess.CalledProcessError as e:
            logging.error(f"Command failed: {cmd} | {e}")

    # =========================
    # Movement Functions
    # =========================

    def forward(self):
        logging.info("Moving FORWARD")
        self._activate_only("forward")

    def backward(self):
        logging.info("Moving BACKWARD")
        self._activate_only("backward")

    def right(self):
        logging.info("Turning RIGHT")
        self._activate_only("right")

    def left(self):
        logging.info("Turning LEFT")
        self._activate_only("left")

    def stop(self):
        logging.info("STOP ALL MOTORS")
        for pin in self.pins.values():
            self._run(f"pinctrl set {pin} op dl")

    # =========================
    # Helper: only one active pin
    # =========================
    def _activate_only(self, direction: str):
        # Set all LOW first
        self.stop()

        # Set selected HIGH
        pin = self.pins[direction]
        self._run(f"pinctrl set {pin} op dh")

    # =========================
    # Pulse (optional)
    # =========================
    def pulse(self, direction: str, duration=0.5):
        self._activate_only(direction)
        time.sleep(duration)
        self.stop()


# =========================
# Console Interface
# =========================
class ConsoleApp:
    def __init__(self, controller: CarController):
        self.car = controller
        self.running = False

    def start(self):
        self.running = True

        print("\n🚗 Car Control System")
        print("----------------------")
        print("w -> Forward")
        print("s -> Stop")
        print("x -> Backward")
        print("d -> Right")
        print("a -> Left")
        print("q -> Quit")
        print("----------------------\n")

        while self.running:
            try:
                cmd = input("Enter command: ").strip().lower()

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

                elif cmd == "q":
                    logging.info("Exiting system")
                    self.stop()

                else:
                    logging.warning("Unknown command")

            except KeyboardInterrupt:
                logging.info("Interrupted by user")
                self.stop()

    def stop(self):
        self.running = False
        self.car.stop()


# =========================
# Main
# =========================
if __name__ == "__main__":
    car = CarController()
    app = ConsoleApp(car)
    app.start()
