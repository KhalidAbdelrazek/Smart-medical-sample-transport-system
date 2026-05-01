"""
transport/mqtt_client.py

MQTT client module for robotic sample delivery integration.

Provides:
- publish_and_wait_for_ack: Synchronous publish + ACK wait for dispatch commands
- publish_proceed_command: Fire-and-forget proceed/stop commands to cars
- MqttSubscriber: Background listener for ACK and arrival topics
"""
import json
import logging
import signal
import ssl
import threading
import uuid

import paho.mqtt.client as mqtt
from django.conf import settings

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Topic helpers
# ---------------------------------------------------------------------------

def _dispatch_topic(car_id):
    return f"transport/commands/{car_id}/dispatch"


def _ack_topic(car_id):
    return f"transport/acks/{car_id}"


def _arrival_topic(car_id):
    return f"transport/arrivals/{car_id}"


def _control_topic(car_id):
    return f"transport/commands/{car_id}/control"


# ---------------------------------------------------------------------------
# Broker connection helpers
# ---------------------------------------------------------------------------

def _broker_host():
    return getattr(settings, "MQTT_BROKER_HOST", getattr(settings, "BROKER_URL", None))


def _broker_port():
    return int(getattr(settings, "MQTT_BROKER_PORT", getattr(settings, "BROKER_PORT", 1883)))


def _broker_username():
    return getattr(settings, "MQTT_BROKER_USERNAME", getattr(settings, "MQTT_USERNAME", ""))


def _broker_password():
    return getattr(settings, "MQTT_BROKER_PASSWORD", getattr(settings, "MQTT_PASSWORD", ""))


def _use_tls():
    return bool(getattr(settings, "MQTT_BROKER_USE_TLS", True))


def _ack_timeout():
    return int(getattr(settings, "MQTT_ACK_TIMEOUT_SECONDS", 300))


def _ack_retries():
    return int(getattr(settings, "MQTT_ACK_RETRY_COUNT", 1))


def _qos():
    return int(getattr(settings, "MQTT_DISPATCH_QOS", 1))


def _configure_client(client):
    """Apply broker credentials and TLS to a paho Client."""
    username = _broker_username()
    if username:
        client.username_pw_set(username, _broker_password())
    if _use_tls():
        client.tls_set(cert_reqs=ssl.CERT_REQUIRED, tls_version=ssl.PROTOCOL_TLS)


# ---------------------------------------------------------------------------
# Synchronous publish + ACK wait (used by dispatch_car)
# ---------------------------------------------------------------------------

def publish_and_wait_for_ack(car_id, payload, timeout=None, retries=None):
    """
    Publish a dispatch command and block until an ACK is received from the device.

    The ACK must contain a matching batch_id to prevent stale ACKs from being
    accepted.  Publishing is deferred until the ACK-topic subscription is
    confirmed to avoid missing fast responses.

    Returns:
        (success: bool, error_message: str | None)
    """
    broker_host = _broker_host()
    if not broker_host:
        return False, "MQTT broker host is not configured"

    if timeout is None:
        timeout = _ack_timeout()
    if retries is None:
        retries = _ack_retries()

    dispatch_tp = _dispatch_topic(car_id)
    ack_tp = _ack_topic(car_id)
    qos = _qos()

    expected_batch_id = payload.get("batch_id")

    # Shared state for the ACK callback
    ack_event = threading.Event()
    subscribed_event = threading.Event()
    ack_result = {"status": None, "message": None}

    def on_connect(client, userdata, flags, reason_code, properties=None):
        logger.info(
            "ACK-wait client connected to broker. rc=%s subscribing to %s",
            reason_code, ack_tp,
        )
        client.subscribe(ack_tp, qos=qos)

    def on_subscribe(client, userdata, mid, reason_codes, properties=None):
        logger.info("ACK-wait subscription confirmed. mid=%s", mid)
        subscribed_event.set()

    def on_message(client, userdata, msg):
        try:
            data = json.loads(msg.payload.decode("utf-8"))
        except Exception:
            logger.exception("Failed to parse ACK message on %s", msg.topic)
            # Don't set event — wait for a valid ACK
            return

        # ── Fix #1: validate batch_id to reject stale ACKs ──
        ack_batch_id = data.get("batch_id")
        if expected_batch_id and ack_batch_id != expected_batch_id:
            logger.warning(
                "Ignoring stale ACK: expected batch_id=%s, got batch_id=%s",
                expected_batch_id, ack_batch_id,
            )
            return

        ack_result["status"] = data.get("status", "ERROR")
        ack_result["message"] = data.get("message", "")
        logger.info("ACK received on %s: %s", msg.topic, data)
        ack_event.set()

    client = mqtt.Client(
        callback_api_version=mqtt.CallbackAPIVersion.VERSION2,
        client_id=f"dispatch-ack-{car_id}-{uuid.uuid4().hex[:8]}",
    )
    _configure_client(client)
    client.on_connect = on_connect
    client.on_subscribe = on_subscribe
    client.on_message = on_message

    loop_started = False
    try:
        client.connect(broker_host, _broker_port(), keepalive=60)
        client.loop_start()
        loop_started = True

        # ── Fix #2: wait until subscription is active before publishing ──
        if not subscribed_event.wait(timeout=timeout):
            return False, "Timed out waiting for ACK-topic subscription"

        attempts = 1 + retries  # initial attempt + retries
        for attempt in range(1, attempts + 1):
            # Publish dispatch command
            payload_json = json.dumps(payload)
            msg_info = client.publish(dispatch_tp, payload_json, qos=qos)

            if msg_info.rc != mqtt.MQTT_ERR_SUCCESS:
                logger.error(
                    "MQTT publish failed. rc=%s topic=%s attempt=%d/%d",
                    msg_info.rc, dispatch_tp, attempt, attempts,
                )
                continue

            # Wait for the publish to be delivered to broker
            try:
                msg_info.wait_for_publish(timeout=timeout)
            except ValueError:
                # Already published
                pass

            if not msg_info.is_published():
                logger.error(
                    "MQTT publish delivery timed out. topic=%s attempt=%d/%d",
                    dispatch_tp, attempt, attempts,
                )
                continue

            logger.info(
                "Dispatch published to %s, waiting for ACK (timeout=%ds, attempt=%d/%d)",
                dispatch_tp, timeout, attempt, attempts,
            )

            # Wait for ACK
            ack_received = ack_event.wait(timeout=timeout)

            if ack_received:
                if ack_result["status"] == "OK":
                    return True, None
                else:
                    error_msg = (
                        f"Device returned error ACK: {ack_result['message']}"
                    )
                    logger.error(
                        "Error ACK from device. car_id=%s message=%s",
                        car_id, ack_result["message"],
                    )
                    return False, error_msg

            logger.warning(
                "ACK timeout for car_id=%s (attempt %d/%d, timeout=%ds)",
                car_id, attempt, attempts, timeout,
            )
            ack_event.clear()

        return False, f"No ACK received from device after {attempts} attempt(s) (timeout={timeout}s each)"

    except Exception as exc:
        logger.exception("MQTT publish_and_wait_for_ack failed. car_id=%s", car_id)
        return False, f"MQTT connection/publish error: {exc}"
    finally:
        if loop_started:
            client.loop_stop()
        try:
            client.disconnect()
        except Exception:
            logger.debug("Failed to disconnect ACK-wait client cleanly. car_id=%s", car_id)


# ---------------------------------------------------------------------------
# Fire-and-forget publish (proceed / stop commands)
# ---------------------------------------------------------------------------

def publish_proceed_command(car_id, room):
    """Publish a 'proceed' control command so the car moves to the next room."""
    _publish_control(car_id, command="proceed", room=room)


def publish_stop_command(car_id, reason=""):
    """Publish a 'stop' control command."""
    _publish_control(car_id, command="stop", reason=reason)


def _publish_control(car_id, **kwargs):
    """Internal: publish a control message to the car."""
    broker_host = _broker_host()
    if not broker_host:
        logger.error("Cannot publish control command: MQTT broker host not configured")
        return

    topic = _control_topic(car_id)
    payload = {"car_id": car_id, **kwargs}
    qos = _qos()
    timeout = _ack_timeout()

    client = mqtt.Client(
        callback_api_version=mqtt.CallbackAPIVersion.VERSION2,
        client_id=f"control-{car_id}-{uuid.uuid4().hex[:8]}",
    )
    _configure_client(client)
    loop_started = False

    try:
        client.connect(broker_host, _broker_port(), keepalive=60)
        client.loop_start()
        loop_started = True

        msg_info = client.publish(topic, json.dumps(payload), qos=qos)
        try:
            msg_info.wait_for_publish(timeout=timeout)
        except ValueError:
            pass

        if msg_info.is_published():
            logger.info("Control command published. topic=%s payload=%s", topic, payload)
        else:
            logger.error("Control command publish timed out. topic=%s", topic)
    except Exception:
        logger.exception("Control command publish failed. topic=%s car_id=%s", topic, car_id)
    finally:
        if loop_started:
            client.loop_stop()
        try:
            client.disconnect()
        except Exception:
            pass


# ---------------------------------------------------------------------------
# Background MQTT subscriber (used by management command)
# ---------------------------------------------------------------------------

class MqttSubscriber:
    """
    Long-running MQTT subscriber that listens for device ACK and arrival
    messages and dispatches them to service functions.
    """

    def __init__(self):
        self._client = mqtt.Client(
            callback_api_version=mqtt.CallbackAPIVersion.VERSION2,
            client_id=f"transport-subscriber-{uuid.uuid4().hex[:8]}",
        )
        _configure_client(self._client)
        self._client.on_connect = self._on_connect
        self._client.on_message = self._on_message
        self._client.on_disconnect = self._on_disconnect
        self._running = False

    def _on_connect(self, client, userdata, flags, reason_code, properties=None):
        logger.info("MQTT subscriber connected. rc=%s", reason_code)
        # Subscribe to wildcard topics for all cars
        client.subscribe("transport/acks/+", qos=_qos())
        client.subscribe("transport/arrivals/+", qos=_qos())
        logger.info("Subscribed to transport/acks/+ and transport/arrivals/+")

    def _on_disconnect(self, client, userdata, flags, reason_code, properties=None):
        logger.warning("MQTT subscriber disconnected. rc=%s", reason_code)

    def _on_message(self, client, userdata, msg):
        topic = msg.topic
        try:
            payload = json.loads(msg.payload.decode("utf-8"))
        except Exception:
            logger.exception("Failed to parse MQTT message on %s", topic)
            return

        logger.info("MQTT message received. topic=%s payload=%s", topic, payload)

        # Extract car_id from topic (last segment)
        parts = topic.split("/")
        if len(parts) < 3:
            logger.error("Unexpected topic format: %s", topic)
            return

        try:
            car_id = int(parts[-1])
        except (ValueError, IndexError):
            logger.error("Cannot extract car_id from topic: %s", topic)
            return

        if topic.startswith("transport/arrivals/"):
            self._handle_arrival(car_id, payload)
        elif topic.startswith("transport/acks/"):
            # ACKs for dispatch are handled synchronously by publish_and_wait_for_ack.
            # This handler logs background ACKs (e.g., late or duplicate ACKs).
            logger.info(
                "Background ACK received for car_id=%s status=%s",
                car_id, payload.get("status"),
            )

    def _handle_arrival(self, car_id, payload):
        """Process an arrival event from the device."""
        # Import here to avoid circular imports at module load time
        from transport.services import handle_arrival_event

        room = payload.get("room")
        arrived_request_ids = payload.get("arrived_request_ids", [])
        timestamp = payload.get("timestamp")

        if not room or not arrived_request_ids:
            logger.error(
                "Invalid arrival payload for car_id=%s: missing room or arrived_request_ids. payload=%s",
                car_id, payload,
            )
            return

        try:
            handle_arrival_event(
                car_id=car_id,
                room=room,
                arrived_request_ids=arrived_request_ids,
                timestamp=timestamp,
            )
        except Exception:
            logger.exception(
                "Failed to handle arrival event. car_id=%s room=%s",
                car_id, room,
            )

    def start(self):
        """Connect and run the MQTT loop forever. Blocks until stop() is called."""
        broker_host = _broker_host()
        if not broker_host:
            logger.error("Cannot start MQTT subscriber: broker host not configured")
            return

        self._running = True
        logger.info(
            "Starting MQTT subscriber. broker=%s:%s",
            broker_host, _broker_port(),
        )
        self._client.connect(broker_host, _broker_port(), keepalive=60)
        self._client.loop_forever()

    def stop(self):
        """Gracefully stop the subscriber."""
        logger.info("Stopping MQTT subscriber…")
        self._running = False
        self._client.disconnect()
