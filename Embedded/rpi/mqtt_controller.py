import logging
import json
import queue
import paho.mqtt.client as mqtt

# =========================
# Logging Setup
# =========================
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - [%(levelname)s] - %(message)s'
)

# =========================
# MQTT Controller
# =========================
class MQTTController:
    def __init__(self, dispatch_queue: queue.Queue):
        self.car_id = "3"

        self.broker = "81758f399b5b46b9875ac5e5f1e3ef1e.s1.eu.hivemq.cloud"
        self.port = 8883

        self.username = "hivemq.webclient.1764285829577"
        self.password = "bNtHo2#E,9>w18<CcOfF"

        self.topics = [
            (f"transport/commands/{self.car_id}/dispatch", 0)
        ]

        # Queue to pass data to the main state machine
        self.dispatch_queue = dispatch_queue

        # MQTT client
        self.client = mqtt.Client()
        self.client.tls_set()
        self.client.username_pw_set(self.username, self.password)

        # Callbacks
        self.client.on_connect = self.on_connect
        self.client.on_message = self.on_message
        self.client.on_disconnect = self.on_disconnect
        
        self.connected = False

    # =========================
    # MQTT Callbacks
    # =========================
    def on_connect(self, client, userdata, flags, rc):
        if rc == 0:
            self.connected = True
            logging.info(f"[MQTT] Connected to {self.broker}:{self.port}")
            for topic, qos in self.topics:
                self.client.subscribe(topic, qos)
                logging.info(f"[MQTT] Subscribed to: {topic}")
        else:
            self.connected = False
            logging.error(f"[MQTT] Failed to connect, return code {rc}")

    def on_disconnect(self, client, userdata, rc):
        self.connected = False
        if rc != 0:
            logging.warning(f"[MQTT] Unexpected disconnection (code {rc}). Reconnecting...")

    def on_message(self, client, userdata, msg):
        try:
            topic = msg.topic
            payload = json.loads(msg.payload.decode("utf-8"))

            logging.info(f"[MQTT] Received on {topic}: {payload}")

            if topic == f"transport/commands/{self.car_id}/dispatch":
                # Place payload in queue for the main thread to handle
                self.dispatch_queue.put(payload)
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
            self.client.loop_start()
        except Exception as e:
            logging.error(f"[MQTT] Connection failed: {e}")

    def stop(self):
        logging.info("[MQTT] Stopping MQTT client...")
        self.client.loop_stop()
        self.client.disconnect()

    # =========================
    # Publishers
    # =========================
    def publish_arrival(self, room: str, arrived_request_ids: list[str]) -> bool:
        topic = f"transport/arrivals/{self.car_id}"
        payload = {
            "room": room,
            "arrived_request_ids": arrived_request_ids,
        }
        payload_str = json.dumps(payload)
        logging.info(f"[MQTT] Publishing Arrival to '{topic}': {payload_str}")
        
        result = self.client.publish(topic, payload_str, qos=1)
        if result.rc == mqtt.MQTT_ERR_SUCCESS:
            logging.info(f"[MQTT] Arrival queued successfully (mid={result.mid})")
            return True
        else:
            logging.error(f"[MQTT] Publish Arrival failed — rc={result.rc}")
            return False

    def publish_ack(self, batch_id: str) -> bool:
        topic = f"transport/acks/{self.car_id}"
        payload = json.dumps({"status": "OK", "batch_id": batch_id})
        logging.info(f"[MQTT] Publishing ACK to '{topic}': {payload}")
        
        result = self.client.publish(topic, payload, qos=1)
        if result.rc == mqtt.MQTT_ERR_SUCCESS:
            logging.info(f"[ACK] Published successfully")
            return True
        else:
            logging.error(f"[ACK] Failed to publish (rc={result.rc})")
            return False