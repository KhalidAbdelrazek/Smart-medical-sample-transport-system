import json
import logging
import ssl

import paho.mqtt.client as mqtt
from django.conf import settings
from django.utils import timezone


logger = logging.getLogger(__name__)


def build_dispatch_payload(car, dispatched_requests):
    """
    Build dispatch payload grouped by room number.
    
    Format:
    {
      "data": [
        {
          "samples": ["PT-001", "PT-003"],
          "roomNumber": 2001
        },
        ...
      ]
    }
    """
    room_samples = {}

    for transport_request in dispatched_requests:
        sample = transport_request.sample
        room_number = transport_request.room_number
        
        if room_number not in room_samples:
            room_samples[room_number] = []
        
        room_samples[room_number].append(sample.sample_code)

    data = [
        {
            "samples": sample_codes,
            "roomNumber": room_number,
        }
        for room_number, sample_codes in sorted(room_samples.items())
    ]

    return {
        "data": data,
    }


def publish_dispatch_event(payload):
    broker_host = getattr(settings, "MQTT_BROKER_HOST", getattr(settings, "BROKER_URL", None))
    broker_port = int(getattr(settings, "MQTT_BROKER_PORT", getattr(settings, "BROKER_PORT", 1883)))
    username = getattr(settings, "MQTT_BROKER_USERNAME", getattr(settings, "MQTT_USERNAME", ""))
    password = getattr(settings, "MQTT_BROKER_PASSWORD", getattr(settings, "MQTT_PASSWORD", ""))
    topic = getattr(settings, "TOPIC", "carts/1/command")
    qos = int(getattr(settings, "MQTT_DISPATCH_QOS", 1))
    timeout_seconds = int(getattr(settings, "MQTT_DISPATCH_TIMEOUT_SECONDS", 300))
    use_tls = bool(getattr(settings, "MQTT_BROKER_USE_TLS", True))

    if not broker_host:
        logger.error(
            "MQTT dispatch skipped: broker host is not configured. car_id=%s",
            payload.get("car_id"),
        )
        return False

    client = mqtt.Client()
    loop_started = False

    if username:
        client.username_pw_set(username, password)

    if use_tls:
        client.tls_set(cert_reqs=ssl.CERT_REQUIRED, tls_version=ssl.PROTOCOL_TLS)

    try:
        client.connect(broker_host, broker_port, keepalive=60)
        client.loop_start()
        loop_started = True

        payload_json = json.dumps(payload)
        message_info = client.publish(topic, payload_json, qos=qos)

        if message_info.rc != mqtt.MQTT_ERR_SUCCESS:
            logger.error(
                "MQTT publish returned non-success code. rc=%s topic=%s car_id=%s",
                message_info.rc,
                topic,
                payload.get("car_id"),
            )
            return False

        message_info.wait_for_publish(timeout=timeout_seconds)
        if not message_info.is_published():
            logger.error(
                "MQTT message delivery timed out. topic=%s car_id=%s timeout_seconds=%s",
                topic,
                payload.get("car_id"),
                timeout_seconds,
            )
            return False

        return True
    except Exception:
        logger.exception(
            "MQTT dispatch publish failed. topic=%s car_id=%s sample_count=%s",
            topic,
            payload.get("car_id"),
            len(payload.get("samples", [])),
        )
        return False
    finally:
        if loop_started:
            client.loop_stop()
        try:
            client.disconnect()
        except Exception:
            logger.exception(
                "Failed to disconnect MQTT client cleanly. car_id=%s",
                payload.get("car_id"),
            )
