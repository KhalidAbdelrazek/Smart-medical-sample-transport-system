"""
Management command to run the MQTT subscriber for transport events.

Listens for device ACK and arrival messages on MQTT topics and updates
the database accordingly.

Usage:
    python manage.py run_mqtt_subscriber

The subscriber connects to the MQTT broker configured in settings.py
and subscribes to:
    - transport/acks/+     (device acknowledgements)
    - transport/arrivals/+ (car arrival events)
"""
import signal
import logging

from django.core.management.base import BaseCommand


logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = "Start the MQTT subscriber for transport ACK and arrival events"

    def handle(self, *args, **options):
        from transport.mqtt_client import MqttSubscriber

        subscriber = MqttSubscriber()

        # Graceful shutdown on SIGINT / SIGTERM
        def _shutdown(signum, frame):
            self.stdout.write(self.style.WARNING(
                f"\nReceived signal {signum}, shutting down MQTT subscriber…"
            ))
            subscriber.stop()

        signal.signal(signal.SIGINT, _shutdown)
        signal.signal(signal.SIGTERM, _shutdown)

        self.stdout.write(self.style.SUCCESS(
            "Starting MQTT subscriber for transport events…\n"
            "Press Ctrl+C to stop.\n"
        ))

        try:
            subscriber.start()
        except KeyboardInterrupt:
            self.stdout.write(self.style.WARNING("\nKeyboard interrupt received."))
        except Exception as exc:
            self.stderr.write(self.style.ERROR(f"MQTT subscriber error: {exc}"))
            logger.exception("MQTT subscriber crashed")
            raise

        self.stdout.write(self.style.SUCCESS("MQTT subscriber stopped."))
