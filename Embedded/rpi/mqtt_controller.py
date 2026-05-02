import logging
import threading
import json
import time

import paho.mqtt.client as mqtt
from uart_controller import UARTCarController
from functions import get_rooms


# =========================
# Logging Setup
# =========================
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - [%(levelname)s] - %(message)s'
)


class MQTTController:
    def __init__(self, car_controller: UARTCarController):
        self.car = car_controller
        self.car_id = "3"

        self.broker = "81758f399b5b46b9875ac5e5f1e3ef1e.s1.eu.hivemq.cloud"
        self.port = 8883

        self.username = "hivemq.webclient.1764285829577"
        self.password = "bNtHo2#E,9>w18<CcOfF"

        self.topics = [
            (f"transport/commands/{self.car_id}/dispatch", 0)
        ]

        # MQTT client
        self.client = mqtt.Client()
        
        # Enable TLS for secure connection
        self.client.tls_set()
        
        # Set username and password
        self.client.username_pw_set(self.username, self.password)

        # Callbacks
        self.client.on_connect = self.on_connect
        self.client.on_message = self.on_message
        self.client.on_disconnect = self.on_disconnect

    # =========================
    # MQTT Callbacks
    # =========================
    def on_connect(self, client, userdata, flags, rc):
        if rc == 0:
            logging.info(f"[MQTT] Connected to {self.broker}:{self.port}")

            # Safe subscription
            for topic, qos in self.topics:
                self.client.subscribe(topic, qos)
                logging.info(f"[MQTT] Subscribed to: {topic}")
        else:
            logging.error(f"[MQTT] Failed to connect, return code {rc}")

    def on_disconnect(self, client, userdata, rc):
        if rc != 0:
            logging.warning(f"[MQTT] Unexpected disconnection (code {rc}). Reconnecting...")
            # Paho-mqtt's loop_start() handles reconnection automatically.

    def on_message(self, client, userdata, msg):
        try:
            topic = msg.topic
            payload = json.loads(msg.payload.decode("utf-8"))

            logging.info(f"[MQTT] {topic}: {payload}")

            if topic == f"transport/commands/{self.car_id}/dispatch":
                # Run dispatch in separate thread (IMPORTANT)
                threading.Thread(
                    target=self.handle_dispatch,
                    args=(payload,),
                    daemon=True
                ).start()

            else:
                logging.warning(f"[MQTT] Unknown topic: {topic}")

        except Exception as e:
            logging.error(f"[MQTT] Message handling error: {e}")

    # =========================
    # Lifecycle
    # =========================
    def start(self):
        logging.info(f"[MQTT] Connecting to broker {self.broker}...")
        try:
            self.client.connect(self.broker, self.port, 60)
            self.client.loop_start()  # Start non-blocking background loop
        except Exception as e:
            logging.error(f"[MQTT] Connection failed: {e}")

    def stop(self):
        logging.info("[MQTT] Stopping MQTT client...")
        self.client.loop_stop()
        self.client.disconnect()

    # =========================
    # Robot Logic
    # =========================
    def handle_dispatch(self, payload: dict):
        self.car.state = "DISPATCH"

        rooms, batch_id = get_rooms(payload)

        logging.info(f"[ROBOT] Batch ID: {batch_id}")
        logging.info(f"[ROBOT] Rooms: {rooms}")

        for room in rooms:
            logging.info(f"[ROBOT] Moving to room {room}")

            self.car.forward()
            time.sleep(2)   # simulate movement
            self.car.stop()

        logging.info("[ROBOT] Dispatch complete, returning to idle state")

        self.car.state = "SLEEP"