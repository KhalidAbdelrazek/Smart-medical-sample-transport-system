import logging
import threading
import time
import paho.mqtt.client as mqtt
from uart_controller import UARTCarController

# =========================
# MQTT Controller
# =========================

# =========================
# Logging Setup
# =========================
logging.basicConfig(
    level=logging.DEBUG,  # Set to DEBUG for detailed UART traces
    format='%(asctime)s - [%(levelname)s] - %(message)s'
)


class MQTTController:
    def __init__(self, car_controller: UARTCarController):
        self.car = car_controller
        self.broker = "81758f399b5b46b9875ac5e5f1e3ef1e.s1.eu.hivemq.cloud"
        self.port = 8883
        self.topic = "carts/1/command"
        self.username = "hivemq.webclient.1764285829577"
        self.password = "bNtHo2#E,9>w18<CcOfF"
        
        # Initialize MQTT client
        self.client = mqtt.Client()
        
        # Enable TLS for secure connection
        self.client.tls_set()
        
        # Set username and password
        self.client.username_pw_set(self.username, self.password)
        
        # Attach callbacks
        self.client.on_connect = self.on_connect
        self.client.on_message = self.on_message
        self.client.on_disconnect = self.on_disconnect

    def on_connect(self, client, userdata, flags, rc):
        if rc == 0:
            logging.info(f"[MQTT] Connected successfully to {self.broker}:{self.port}")
            self.client.subscribe(self.topic)
            logging.info(f"[MQTT] Subscribed to topic: {self.topic}")
        else:
            logging.error(f"[MQTT] Failed to connect, return code {rc}")

    def on_disconnect(self, client, userdata, rc):
        if rc != 0:
            logging.warning(f"[MQTT] Unexpected disconnection (code {rc}). Reconnecting...")
            # Paho-mqtt's loop_start() handles reconnection automatically.

    def on_message(self, client, userdata, msg):
        try:
            payload = msg.payload.decode('utf-8')
            logging.info(f"[MQTT] Received message on {msg.topic}: {payload}")
            
            # Trigger movement in a separate thread to avoid blocking MQTT loop
            threading.Thread(target=self._trigger_movement, daemon=True).start()
        except Exception as e:
            logging.error(f"[MQTT] Error processing message: {e}")

    def _trigger_movement(self):
        logging.info("[MQTT Action] Moving car forward for 2 seconds.")
        self.car.forward()
        time.sleep(2)
        logging.info("[MQTT Action] Stopping car.")
        self.car.stop()

    def start(self):
        logging.info(f"[MQTT] Connecting to broker {self.broker}...")
        try:
            self.client.connect(self.broker, self.port, 60)
            self.client.loop_start()  # Start non-blocking background loop
        except Exception as e:
            logging.error(f"[MQTT] Connection failed: {e}")

    def stop(self):
        logging.info("[MQTT] Stopping client...")
        self.client.loop_stop()
        self.client.disconnect()

