"""
Management command to periodically poll for cars that have returned to storage.

Usage:
    python manage.py poll_returned_cars
    python manage.py poll_returned_cars --interval 10  # Check every 10 seconds
    python manage.py poll_returned_cars --verbose     # Show detailed logs

This command:
1. Polls the database periodically for cars with arrived_at_storage set
2. Logs returned cars awaiting confirmation
3. Can be run in a separate process or integrated with a task queue
4. Useful for development/monitoring or as a fallback to WebSocket notifications
"""
import logging
import time
from django.core.management.base import BaseCommand, CommandError
from transport.services import get_returned_cars, get_returned_cars_count

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = 'Poll for cars that have returned to storage and log them'

    def add_arguments(self, parser):
        parser.add_argument(
            '--interval',
            type=int,
            default=5,
            help='Polling interval in seconds (default: 5)',
        )
        parser.add_argument(
            '--once',
            action='store_true',
            help='Run once and exit (no continuous polling)',
        )
        parser.add_argument(
            '--verbose',
            action='store_true',
            help='Show detailed information for each returned car',
        )

    def handle(self, *args, **options):
        interval = options['interval']
        once = options['once']
        verbose = options['verbose']

        if interval < 1:
            raise CommandError('Interval must be at least 1 second')

        self.stdout.write(self.style.SUCCESS('🚗 Starting returned cars polling...'))
        if not once:
            self.stdout.write(f'   Polling every {interval} second(s). Press Ctrl+C to stop.')
        self.stdout.write('')

        try:
            while True:
                self._poll_once(verbose=verbose)

                if once:
                    break

                time.sleep(interval)

        except KeyboardInterrupt:
            self.stdout.write(self.style.WARNING('\n⏹️  Polling stopped by user.'))
        except Exception as e:
            logger.exception('Error during polling')
            raise CommandError(f'Polling error: {str(e)}')

    def _poll_once(self, verbose=False):
        """Perform a single polling cycle."""
        try:
            count = get_returned_cars_count()

            if count > 0:
                msg = f'✅ Found {count} car(s) awaiting storage confirmation'
                self.stdout.write(self.style.SUCCESS(msg))
                logger.info(msg)

                if verbose:
                    returned_cars = get_returned_cars()
                    for car in returned_cars:
                        self.stdout.write(
                            f'   • Car {car.car_number} (ID: {car.id}) - '
                            f'Status: {car.status} - '
                            f'Arrived: {car.arrived_at_storage}'
                        )
                        logger.info(
                            f'Returned car: car_number={car.car_number} '
                            f'car_id={car.id} status={car.status} '
                            f'arrived_at_storage={car.arrived_at_storage}'
                        )
            else:
                msg = '✓ No returned cars awaiting confirmation'
                self.stdout.write(self.style.HTTP_INFO(msg))
                logger.debug(msg)

        except Exception as e:
            msg = f'❌ Polling error: {str(e)}'
            self.stdout.write(self.style.ERROR(msg))
            logger.error(msg, exc_info=True)
