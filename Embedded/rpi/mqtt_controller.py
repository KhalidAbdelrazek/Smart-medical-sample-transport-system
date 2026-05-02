import logging
import threading
import json
import time

try:
    import RPi.GPIO as GPIO
except ImportError:
    logging.error("[ERROR] RPi.GPIO not found. Using Mock.")
    from unittest.mock import MagicMock
    GPIO = MagicMock()

import paho.mqtt.client as mqtt
from uart_controller import UARTCarController
from functons import get_rooms, get_request_ids_for_room, filter_sensors, decide_movement


# =========================
# Logging Setup
# =========================
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - [%(levelname)s] - %(message)s'
)


# =========================
# Line Follower Controller
# =========================
class LineFollowerController:
    def __init__(self, uart_controller: UARTCarController, sensor_left_pin=17, sensor_right_pin=27):
        self.uart = uart_controller
        self.sensor_left_pin = sensor_left_pin
        self.sensor_right_pin = sensor_right_pin
        self.loop_delay = 0.1
        self.running = False
        self._setup_gpio()

    def _setup_gpio(self):
        logging.info("[INIT] Setting up GPIO for Line Follower...")
        GPIO.setwarnings(False)
        GPIO.setmode(GPIO.BCM)
        GPIO.setup(self.sensor_left_pin, GPIO.IN)
        GPIO.setup(self.sensor_right_pin, GPIO.IN)
        logging.info(f"[INIT] GPIO initialized successfully (LEFT={self.sensor_left_pin}, RIGHT={self.sensor_right_pin})")

    def _read_sensors(self):
        left_val = GPIO.input(self.sensor_left_pin)
        right_val = GPIO.input(self.sensor_right_pin)
        return left_val, right_val

    def run_until_arrival(self):
        """
        Runs the line follower loop until the STOP condition (Arrival) is met.
        """
        logging.info("[ROBOT] Starting Autonomous Line Follower Loop...")
        self.running = True
        
        last_cmd = None
        filter_samples_count = 3
        
        while self.running:
            left_samples = []
            right_samples = []
            
            for _ in range(filter_samples_count):
                l, r = self._read_sensors()
                left_samples.append(l)
                right_samples.append(r)
                time.sleep(0.01)
                
            left, right = filter_sensors(left_samples, right_samples)
            
            if left is None or right is None:
                logging.debug("[DEBUG] Invalid sensor read (instability). Skipping loop.")
                time.sleep(self.loop_delay)
                continue
                
            action, cmd = decide_movement(left, right)
            
            if cmd != last_cmd:
                logging.debug(f"[STATE] >>> STATE CHANGED from {repr(last_cmd)} to {repr(cmd)} <<<")
                
            success = self.uart.send_command(cmd)
            
            if success:
                response = self.uart.read_uart_response()
                if response:
                    logging.debug(f"[UART RX] Received: {response}")
                last_cmd = cmd
            else:
                logging.error(f"[ERROR] FAILED to send: {repr(cmd)}")
                
            if action == "STOP":
                logging.info("[ROBOT] STOP condition met! Arrived at destination.")
                self.running = False
                break
                
            time.sleep(self.loop_delay)


# =========================
# MQTT Controller
# =========================
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
        self.client.tls_set()
        self.client.username_pw_set(self.username, self.password)

        # Callbacks
        self.client.on_connect = self.on_connect
        self.client.on_message = self.on_message
        self.client.on_disconnect = self.on_disconnect
        
        # Internal line follower
        self.line_follower = LineFollowerController(self.car)

    # =========================
    # MQTT Callbacks
    # =========================
    def on_connect(self, client, userdata, flags, rc):
        if rc == 0:
            logging.info(f"[MQTT] Connected to {self.broker}:{self.port}")
            for topic, qos in self.topics:
                self.client.subscribe(topic, qos)
                logging.info(f"[MQTT] Subscribed to: {topic}")
        else:
            logging.error(f"[MQTT] Failed to connect, return code {rc}")

    def on_disconnect(self, client, userdata, rc):
        if rc != 0:
            logging.warning(f"[MQTT] Unexpected disconnection (code {rc}). Reconnecting...")

    def on_message(self, client, userdata, msg):
        try:
            topic = msg.topic
            payload = json.loads(msg.payload.decode("utf-8"))

            logging.info(f"[MQTT] {topic}: {payload}")

            if topic == f"transport/commands/{self.car_id}/dispatch":
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
            logging.info(f"[MQTT] Queued successfully (mid={result.mid})")
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

    # =========================
    # Robot Logic
    # =========================
    def handle_dispatch(self, payload: dict):
        self.car.state = "DISPATCH"

        rooms, batch_id = get_rooms(payload)

        logging.info(f"[ROBOT] Batch ID: {batch_id}")
        logging.info(f"[ROBOT] Rooms: {rooms}")

        # Acknowledge dispatch to backend immediately
        self.publish_ack(batch_id)

        for room in rooms:
            logging.info(f"[ROBOT] Moving to room {room}")
            
            # Start Line Follower
            self.line_follower.run_until_arrival()
            
            # Arrived at room
            request_ids = get_request_ids_for_room(payload, room)
            self.publish_arrival(room, request_ids)
            
            # Brief pause before next room (or next state)
            time.sleep(2)

        logging.info("[ROBOT] Dispatch complete, returning to idle state")

        self.car.state = "SLEEP"