import time
import logging

try:
    import RPi.GPIO as GPIO
except ImportError:
    # Mock GPIO for development/testing on non-Raspberry Pi environments
    class DummyGPIO:
        BCM = "BCM"
        OUT = "OUT"
        HIGH = "HIGH"
        LOW = "LOW"
        def setmode(self, mode): pass
        def setwarnings(self, flag): pass
        def setup(self, pin, mode): pass
        def output(self, pin, state): pass
        def cleanup(self): pass
    GPIO = DummyGPIO()
    print("Warning: RPi.GPIO not found. Using Mock GPIO for testing.")

# Configure logging for clear tracking and future observability
logging.basicConfig(level=logging.INFO, format='%(asctime)s - [%(levelname)s] - %(message)s')

class CarController:
    """
    Hardware interaction layer.
    Separates the physical GPIO logic from the user interfaces (Console, MQTT).
    """
    def __init__(self, forward_pin: int):
        self.forward_pin = forward_pin
        
        # Initialize GPIO
        GPIO.setmode(GPIO.BCM)
        GPIO.setwarnings(False) # Turn off warnings for safer re-runs, though cleanup() is preferred
        
        # Set pin as OUTPUT and initialize to LOW (safe state)
        GPIO.setup(self.forward_pin, GPIO.OUT)
        GPIO.output(self.forward_pin, GPIO.LOW)
        
        logging.info(f"CarController initialized. Forward control on BCM Pin {self.forward_pin}")

    def move_forward(self):
        """Send HIGH signal to ATmega to move forward."""
        logging.info("Action: Setting pin HIGH -> MOVING FORWARD")
        GPIO.output(self.forward_pin, GPIO.HIGH)

    def stop(self):
        """Send LOW signal to ATmega to stop."""
        logging.info("Action: Setting pin LOW -> STOPPED")
        GPIO.output(self.forward_pin, GPIO.LOW)

    def trigger_pulse(self, duration: float = 0.5):
        """
        Optional: Sends a timed HIGH pulse instead of continuous HIGH.
        Useful if the ATmega expects a simple trigger command rather than an ongoing level.
        """
        logging.info(f"Action: Pulsing pin HIGH for {duration}s")
        GPIO.output(self.forward_pin, GPIO.HIGH)
        time.sleep(duration)
        GPIO.output(self.forward_pin, GPIO.LOW)
        logging.info("Action: Pulse complete, pin LOW")

    def cleanup(self):
        """Safe teardown of hardware limits."""
        logging.info("Cleaning up GPIO resources to ensure safe hardware state.")
        GPIO.cleanup()


class ConsoleApp:
    """
    Input handling layer.
    This module handles user console input and routes commands to the CarController.
    """
    def __init__(self, controller: CarController):
        self.controller = controller
        self.running = False

    def start(self):
        self.running = True
        print("\n--- Car Control Console ---")
        print("Commands:")
        print("  'w'     : Move Forward (HIGH)")
        print("  's'     : Stop (LOW)")
        print("  'p'     : Send 0.5s Pulse")
        print("  'quit'  : Exit and cleanup")
        print("---------------------------\n")

        while self.running:
            try:
                user_input = input("Enter command: ").strip().lower()
                
                if user_input == 'w':
                    self.controller.move_forward()
                elif user_input == 's':
                    self.controller.stop()
                elif user_input == 'p':
                    self.controller.trigger_pulse()
                elif user_input in ['quit', 'q', 'exit']:
                    logging.info("Exit requested.")
                    self.stop()
                else:
                    logging.warning(f"Unrecognized command: '{user_input}'")

            except KeyboardInterrupt:
                # Catch Ctrl+C gracefully
                logging.info("\nProcess interrupted by user (Ctrl+C).")
                self.stop()
            except Exception as e:
                logging.error(f"Unexpected error in console loop: {e}")
                self.stop()

    def stop(self):
        self.running = False
        self.controller.cleanup()

# ==============================================================================
# FUTURE UPGRADE PLAN: MQTT Integration
# Structuring the code this way makes adding an MQTT layer trivial.
# You would simply create an MQTTApp class that takes the CarController, similar 
# to the ConsoleApp.
#
# class MQTTApp:
#     def __init__(self, controller):
#         self.controller = controller
#         # self.mqtt_client = paho.mqtt.client.Client()
#         # self.mqtt_client.on_message = self.handle_message
#
#     def handle_message(self, client, userdata, msg):
#         command = msg.payload.decode()
#         if command == "FORWARD":
#             self.controller.move_forward()
#         elif command == "STOP":
#             self.controller.stop()
# ==============================================================================

if __name__ == "__main__":
    # Define physical connection parameters
    # Change this to match the physical RPi GPIO pin wired to the ATmega
    FORWARD_GPIO_PIN = 17  
    
    car = None
    try:
        # Initialize controller
        car = CarController(forward_pin=FORWARD_GPIO_PIN)
        
        # Inject controller into the frontend app
        cli = ConsoleApp(controller=car)
        
        # Start input loop
        cli.start()
    
    except Exception as e:
        logging.critical(f"Fatal application error: {e}")
        if car:
            car.cleanup()
