import json
import ssl
import paho.mqtt.client as mqtt
from django.core.management.base import BaseCommand
from django.conf import settings


class Command(BaseCommand):
    help = 'Starts the MQTT Listener (subscriber to all topics)'

    def handle(self, *args, **options):
        # Broker configuration (reuse the same keys as mqtt_dispatch)
        broker_host = getattr(settings, "MQTT_BROKER_HOST", getattr(settings, "BROKER_URL", None))
        broker_port = int(getattr(settings, "MQTT_BROKER_PORT", getattr(settings, "BROKER_PORT", 1883)))
        username = getattr(settings, "MQTT_BROKER_USERNAME", getattr(settings, "MQTT_USERNAME", ""))
        password = getattr(settings, "MQTT_BROKER_PASSWORD", getattr(settings, "MQTT_PASSWORD", ""))
        use_tls = bool(getattr(settings, "MQTT_BROKER_USE_TLS", True))
        qos = int(getattr(settings, "MQTT_DISPATCH_QOS", 1))

        if not broker_host:
            self.stdout.write(self.style.ERROR("MQTT listener skipped: broker host is not configured."))
            return

        # 2. Define what happens when we connect
        def on_connect(client, userdata, flags, rc):
            if rc == 0:
                self.stdout.write(self.style.SUCCESS(f"Connected to MQTT broker {broker_host}:{broker_port} (subscribing to all topics)"))
                # subscribe to all topics
                client.subscribe("#", qos=qos)
            else:
                self.stdout.write(self.style.ERROR(f"Connection failed with code {rc}"))

        def on_subscribe(client, userdata, mid, granted_qos):
            self.stdout.write(f"Subscribed (mid={mid}) granted_qos={granted_qos}")

        # 3. Define what happens when a message arrives
        def on_message(client, userdata, msg):
            try:
                payload = msg.payload.decode('utf-8', errors='replace')
            except Exception:
                payload = str(msg.payload)

            # Print topic and raw payload
            self.stdout.write(f"Received on topic '{msg.topic}': {payload}")

            # Try to parse JSON and pretty-print
            try:
                parsed = json.loads(payload)
                pretty = json.dumps(parsed, indent=2, sort_keys=True, ensure_ascii=False)
                self.stdout.write("Parsed JSON payload:\n" + pretty)
            except json.JSONDecodeError:
                self.stdout.write("Payload is not valid JSON (raw printed above)")

        # 4. Setup the Client
        client = mqtt.Client()
        client.on_connect = on_connect
        client.on_message = on_message
        client.on_subscribe = on_subscribe

        if username:
            client.username_pw_set(username, password)

        if use_tls:
            client.tls_set(cert_reqs=ssl.CERT_REQUIRED, tls_version=ssl.PROTOCOL_TLS)

        # 5. Connect and Loop Forever
        self.stdout.write(f"Connecting to broker {broker_host}:{broker_port} ...")
        try:
            client.connect(broker_host, broker_port, keepalive=60)
            client.loop_forever()  # This blocks the script and runs callbacks
        except KeyboardInterrupt:
            self.stdout.write(self.style.SUCCESS('Stopped by user. Disconnecting...'))
            try:
                client.disconnect()
            except Exception:
                pass
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"MQTT listener error: {e}"))
            try:
                client.disconnect()
            except Exception:
                pass
