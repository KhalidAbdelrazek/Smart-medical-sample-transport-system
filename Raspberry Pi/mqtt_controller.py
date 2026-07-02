"""
MQTT Controller Module.
Manages subscription to dispatch and control topics and publication of
robot arrivals and acknowledgements to the cloud broker.
"""

import json
import logging
import queue
import time
import config

logger = logging.getLogger(__name__)

# Fallback wrapper for paho-mqtt to allow development on non-RPi environments
try:
    import paho.mqtt.client as mqtt
except ImportError:
    logger.warning("paho-mqtt is not installed. Using Mock MQTT Client for development.")
    class MockMQTTClient:
        def __init__(self, *args, **kwargs):
            self.on_connect = None
            self.on_message = None
            self.on_disconnect = None
            self.connected = False

        def tls_set(self, *args, **kwargs):
            pass

        def username_pw_set(self, username, password):
            pass

        def connect(self, host, port, keepalive=60) -> int:
            logger.info(f"[MQTT MOCK] Connecting to broker {host}:{port}...")
            return 0

        def loop_start(self):
            logger.info("[MQTT MOCK] Loop started.")
            # Simulate a successful connection in a separate thread to match asynchronous behavior
            import threading
            def trigger_connect():
                time.sleep(0.5)
                if self.on_connect:
                    self.on_connect(self, None, None, 0)
            threading.Thread(target=trigger_connect, daemon=True).start()

        def loop_stop(self):
            logger.info("[MQTT MOCK] Loop stopped.")

        def disconnect(self) -> int:
            logger.info("[MQTT MOCK] Disconnected.")
            return 0

        def subscribe(self, topic: str, qos: int = 0):
            logger.info(f"[MQTT MOCK] Subscribed to topic '{topic}' with QoS {qos}")

        def publish(self, topic: str, payload: str, qos: int = 1):
            logger.info(f"[MQTT MOCK] Published to '{topic}': {payload}")
            class PublishResult:
                rc = 0
                mid = 100
            return PublishResult()

    mqtt = MockMQTTClient


class MQTTController:
    """
    Manages connection, subscription, and message routing with the HiveMQ Cloud Broker.
    """
    def __init__(self, car_id: str, dispatch_queue: queue.Queue, control_queue: queue.Queue):
        self.car_id = car_id
        self.broker = config.MQTT_BROKER
        self.port = config.MQTT_PORT
        self.username = config.MQTT_USERNAME
        self.password = config.MQTT_PASSWORD

        self.topics = [
            (f"transport/commands/{self.car_id}/dispatch", 0),
            (f"transport/commands/{self.car_id}/control", 0)
        ]

        # Queues to pass incoming messages to the main state machine
        self.dispatch_queue = dispatch_queue
        self.control_queue = control_queue

        # Configure MQTT Client
        self.client = mqtt.Client()
        self.client.tls_set()
        self.client.username_pw_set(self.username, self.password)

        # Attach Callback functions
        self.client.on_connect = self.on_connect
        self.client.on_message = self.on_message
        self.client.on_disconnect = self.on_disconnect
        
        self.connected = False

    # ── MQTT Callbacks ────────────────────────────────────────

    def on_connect(self, client, userdata, flags, rc: int):
        if rc == 0:
            self.connected = True
            logger.info(f"[MQTT] Connected successfully to {self.broker}:{self.port}")
            for topic, qos in self.topics:
                self.client.subscribe(topic, qos)
                logger.info(f"[MQTT] Subscribed to topic: {topic}")
        else:
            self.connected = False
            logger.error(f"[MQTT] Connection failed, return code {rc}")

    def on_disconnect(self, client, userdata, rc: int):
        self.connected = False
        if rc != 0:
            logger.warning(f"[MQTT] Unexpected disconnection (code {rc}). Reconnecting...")

    def on_message(self, client, userdata, msg):
        try:
            topic = msg.topic
            payload = json.loads(msg.payload.decode("utf-8"))
            logger.info(f"[MQTT RX] Received on '{topic}': {payload}")

            if topic == f"transport/commands/{self.car_id}/dispatch":
                self.dispatch_queue.put(payload)
            elif topic == f"transport/commands/{self.car_id}/control":
                self.control_queue.put(payload)
            else:
                logger.warning(f"[MQTT RX] Unhandled topic: {topic}")
        except Exception as e:
            logger.error(f"[MQTT RX] Error parsing payload: {e}")

    # ── Client Lifecycle ──────────────────────────────────────

    def start(self):
        """Connects to the broker and runs the client network loop in a background thread."""
        logger.info(f"[MQTT] Connecting to broker {self.broker}...")
        try:
            self.client.connect(self.broker, self.port, 60)
            self.client.loop_start()
        except Exception as e:
            logger.error(f"[MQTT] Connection command failed: {e}")

    def stop(self):
        """Stops the client loop and disconnects from the broker."""
        logger.info("[MQTT] Stopping MQTT client connection...")
        try:
            self.client.loop_stop()
            self.client.disconnect()
            logger.info("[MQTT] Client stopped.")
        except Exception as e:
            logger.error(f"[MQTT] Error during stop: {e}")

    # ── Publishers ────────────────────────────────────────────

    def publish_arrival(self, room: str, arrived_request_ids: list[str]) -> bool:
        """Publishes the robot's arrival at a room to the cloud backend."""
        topic = f"transport/arrivals/{self.car_id}"
        payload = {
            "room": room,
            "arrived_request_ids": arrived_request_ids,
        }
        payload_str = json.dumps(payload)
        logger.info(f"[MQTT TX] Publishing arrival to '{topic}': {payload_str}")
        
        result = self.client.publish(topic, payload_str, qos=1)
        if result.rc == 0:  # SUCCESS
            logger.info(f"[MQTT TX] Arrival message published successfully (mid={result.mid})")
            return True
        else:
            logger.error(f"[MQTT TX] Failed to publish arrival — rc={result.rc}")
            return False

    def publish_ack(self, batch_id: str) -> bool:
        """Publishes batch receipt acknowledgement."""
        topic = f"transport/acks/{self.car_id}"
        payload_str = json.dumps({"status": "OK", "batch_id": batch_id})
        logger.info(f"[MQTT TX] Publishing ACK to '{topic}': {payload_str}")
        
        result = self.client.publish(topic, payload_str, qos=1)
        if result.rc == 0:
            logger.info("[MQTT TX] ACK published successfully")
            return True
        else:
            logger.error(f"[MQTT TX] Failed to publish ACK (rc={result.rc})")
            return False
        
    def publish_raw(self, topic: str, payload: dict) -> bool:
        """Publishes a custom dictionary payload to a specified topic."""
        try:
            payload_str = json.dumps(payload)
            logger.info(f"[MQTT TX] Publishing RAW to '{topic}': {payload_str}")
            result = self.client.publish(topic, payload_str, qos=1)
            
            if result.rc == 0:
                logger.info(f"[MQTT TX] RAW publish successful (mid={result.mid})")
                return True
            else:
                logger.error(f"[MQTT TX] RAW publish failed — rc={result.rc}")
                return False
        except Exception as e:
            logger.error(f"[MQTT TX] RAW publish error: {e}")
            return False