import logging

from uart_controller import UARTCarController
from mqtt_controller import MQTTController
from console_interface import ConsoleApp

# =========================
# Logging Setup
# =========================
logging.basicConfig(
    level=logging.DEBUG,  # Set to DEBUG for detailed UART traces
    format='%(asctime)s - [%(levelname)s] - %(message)s'
)


# =========================
# Main
# =========================
if __name__ == "__main__":
    mqtt_controller = None
    try:
        # Note: Port might be '/dev/ttyAMA0' or '/dev/ttyS0' depending on config.
        # '/dev/serial0' is the symbolic link to the primary UART.
        car = UARTCarController(port='/dev/serial0', baudrate=9600)
        
        # Initialize and start MQTT
        mqtt_controller = MQTTController(car)
        mqtt_controller.start()
        
        app = ConsoleApp(car)
        app.start()
    except Exception as e:
        print(f"\n[FATAL] System failed to start: {e}")
    finally:
        if mqtt_controller:
            mqtt_controller.stop()
