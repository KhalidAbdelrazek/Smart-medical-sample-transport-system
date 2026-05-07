import logging
import json
import queue
import datetime
import paho.mqtt.client as mqtt

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - [%(levelname)s] - %(message)s'
)


class MQTTController:
    def __init__(self, car_id: str, dispatch_queue: queue.Queue, control_queue: queue.Queue):
        self.car_id = car_id

        self.broker   = "81758f399b5b46b9875ac5e5f1e3ef1e.s1.eu.hivemq.cloud"
        self.port     = 8883
        self.username = "hivemq.webclient.1764285829577"
        self.password = "bNtHo2#E,9>w18<CcOfF"

        self.topics = [
            (f"transport/commands/{self.car_id}/dispatch", 1),
            (f"transport/commands/{self.car_id}/control",  1),
        ]

        self.dispatch_queue = dispatch_queue
        self.control_queue  = control_queue

        self.client = mqtt.Client()
        self.client.tls_set()
        self.client.username_pw_set(self.username, self.password)

        self.client.on_connect    = self.on_connect
        self.client.on_message    = self.on_message
        self.client.on_disconnect = self.on_disconnect

        self.connected = False

    # =========================
    # Callbacks
    # =========================
    def on_connect(self, client, userdata, flags, rc):
        if rc == 0:
            self.connected = True
            logging.info(f"[MQTT] Connected to broker {self.broker}:{self.port}")
            for topic, qos in self.topics:
                self.client.subscribe(topic, qos)
                logging.info(f"[MQTT] Subscribed → {topic} (QoS {qos})")
        else:
            self.connected = False
            logging.error(f"[MQTT] Connection refused — rc={rc}")

    def on_disconnect(self, client, userdata, rc):
        self.connected = False
        if rc != 0:
            logging.warning(f"[MQTT] Unexpected disconnect (rc={rc})")

    def on_message(self, client, userdata, msg):
        try:
            topic   = msg.topic
            payload = json.loads(msg.payload.decode("utf-8"))
            logging.info(f"[MQTT] ← {topic}: {payload}")

            if topic == f"transport/commands/{self.car_id}/dispatch":
                self.dispatch_queue.put(payload)

            elif topic == f"transport/commands/{self.car_id}/control":
                self.control_queue.put(payload)

            else:
                logging.warning(f"[MQTT] Unknown topic: {topic}")

        except Exception as e:
            logging.error(f"[MQTT] Message handling error: {e}")

    # =========================
    # Lifecycle
    # =========================
    def start(self):
        logging.info(f"[MQTT] Connecting to {self.broker}:{self.port} ...")
        try:
            self.client.connect(self.broker, self.port, keepalive=60)
            self.client.loop_start()
        except Exception as e:
            logging.error(f"[MQTT] Initial connect failed: {e}")

    def stop(self):
        logging.info("[MQTT] Shutting down...")
        self.client.loop_stop()
        self.client.disconnect()

    # =========================
    # Publishers
    # =========================
    def publish_ack(self, batch_id: str) -> bool:
        """
        Sends acknowledgement that the car accepted the dispatch.
        Topic : transport/acks/{car_id}
        Payload:
          {
            "batch_id": "...",
            "status": "OK",
            "message": "Accepted"
          }
        """
        topic = f"transport/acks/{self.car_id}"
        payload = json.dumps({
            "batch_id": batch_id,
            "status":   "OK",
            "message":  "Accepted"
        })
        logging.info(f"[MQTT] → ACK  {topic}: {payload}")
        result = self.client.publish(topic, payload, qos=1)
        if result.rc == mqtt.MQTT_ERR_SUCCESS:
            logging.info("[MQTT] ACK queued OK")
            return True
        logging.error(f"[MQTT] ACK publish failed rc={result.rc}")
        return False

    def publish_arrival(
        self,
        room: str,
        arrived_request_ids: list,
        sample_ids: list
    ) -> bool:
        """
        Notifies the backend that the car arrived at a room.
        Topic : transport/arrivals/{car_id}
        Payload:
          {
            "car_id": 1,
            "room": "101",
            "arrived_request_ids": [...],
            "timestamp": "2026-05-02T12:34:56Z",
            "samples": [...]
          }
        """
        topic = f"transport/arrivals/{self.car_id}"
        payload = json.dumps({
            "car_id":               int(self.car_id),
            "room":                 str(room),
            "arrived_request_ids":  arrived_request_ids,
            "timestamp":            datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
            "samples":              sample_ids,
        })
        logging.info(f"[MQTT] → ARRIVAL  {topic}: {payload}")
        result = self.client.publish(topic, payload, qos=1)
        if result.rc == mqtt.MQTT_ERR_SUCCESS:
            logging.info("[MQTT] Arrival queued OK")
            return True
        logging.error(f"[MQTT] Arrival publish failed rc={result.rc}")
        return False