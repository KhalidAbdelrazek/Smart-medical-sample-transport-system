from django.core.management.base import BaseCommand
from django.utils import timezone

class Command(BaseCommand):
    help = 'Reset monthly activity statistics (simulated/log)'

    def handle(self, *args, **options):
        now = timezone.now()
        self.stdout.write(self.style.SUCCESS(
            f'Statistics for {now.strftime("%B %Y")} are ready for fresh counting. '
            '(Dynamic filtering automatically resets counters on the 1st of each month.)'
        ))
