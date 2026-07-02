import json
import ssl
import paho.mqtt.client as mqtt
from django.core.management.base import BaseCommand
from django.conf import settings
from django.utils import timezone
from datetime import timedelta
from healthcare.models import SensorReading

# 1. Configuration (Move these to settings.py in production)

class Command(BaseCommand):
    help = 'Starts the MQTT Listener'

    def handle(self, *args, **options):
        # 2. Define what happens when we connect
        def on_connect(client, userdata, flags, rc):
            if rc == 0:
                self.stdout.write(self.style.SUCCESS('Successfully connected to HiveMQ!'))
                client.subscribe(settings.TOPIC)
            else:
                self.stdout.write(self.style.ERROR(f'Connection failed with code {rc}'))

        # 3. Define what happens when a message arrives
        def on_message(client, userdata, msg):
            try:
                # Payload comes as bytes, decode to string
                payload = msg.payload.decode('utf-8')
                data = json.loads(payload)
                
                # Save to Django Database
                reading = SensorReading.objects.create(
                    cart=data.get('cart'),
                    position=data.get('position'),
                    load=data.get('load'),
                    state=data.get('state'),
                    time=data.get('time')
                )
                print(f"Saved: {reading}")
                
                # Automatically delete readings older than 1 hour
                cutoff_date = timezone.now() - timedelta(hours=1)
                deleted_count, _ = SensorReading.objects.filter(
                    time__lt=cutoff_date
                ).delete()
                
                if deleted_count > 0:
                    print(f"Cleaned up {deleted_count} old readings")
                
            except json.JSONDecodeError:
                print("Error: Message was not valid JSON")
            except Exception as e:
                print(f"Error saving to DB: {e}")

        # 4. Setup the Client
        client = mqtt.Client()
        client.on_connect = on_connect
        client.on_message = on_message

        # 5. Security (Crucial for HiveMQ Cloud)
        client.username_pw_set(settings.MQTT_USERNAME, settings.MQTT_PASSWORD)
        client.tls_set(cert_reqs=ssl.CERT_REQUIRED, tls_version=ssl.PROTOCOL_TLS)

        # 6. Connect and Loop Forever
        self.stdout.write('Connecting to broker...')
        try:
            client.connect(settings.BROKER_URL, settings.BROKER_PORT, 60)
            client.loop_forever() # This blocks the script and runs forever
        except KeyboardInterrupt:
            self.stdout.write(self.style.SUCCESS('Stopped.'))
            client.disconnect()
            
            