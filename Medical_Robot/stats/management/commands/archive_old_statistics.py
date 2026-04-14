"""
Management command to archive old statistics data.

Usage:
    python manage.py archive_old_statistics --before=2025-01-01
    python manage.py archive_old_statistics --before=2025-01-01 --model=UserActivityLog
    python manage.py archive_old_statistics --before=2025-01-01 --dry-run
"""
import json
from datetime import date

from django.core.management.base import BaseCommand, CommandError
from django.utils import timezone

from stats.models import CarDispatch, UserActivityLog
from transport.models import TransportRequest


class Command(BaseCommand):
    help = 'Archive old statistics data before a specified date'

    def add_arguments(self, parser):
        parser.add_argument(
            '--before',
            type=str,
            required=True,
            help='Archive records created before this date (YYYY-MM-DD)',
        )
        parser.add_argument(
            '--model',
            type=str,
            choices=['CarDispatch', 'UserActivityLog', 'TransportRequest', 'all'],
            default='all',
            help='Which model to archive (default: all)',
        )
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Show what would be archived without actually deleting',
        )
        parser.add_argument(
            '--output',
            type=str,
            help='Output file path for archived data (JSON format)',
        )

    def handle(self, *args, **options):
        before_date = self._parse_date(options['before'])
        model = options['model']
        dry_run = options['dry_run']
        output_file = options['output']

        self.stdout.write(
            self.style.WARNING(
                f"Starting archive process for records before {before_date}"
            )
        )

        if dry_run:
            self.stdout.write(self.style.WARNING("DRY RUN - No records will be deleted"))

        archived_data = {
            'archived_at': timezone.now().isoformat(),
            'before_date': str(before_date),
            'CarDispatch': [],
            'UserActivityLog': [],
            'TransportRequest': [],
        }

        # Archive CarDispatch
        if model in ['CarDispatch', 'all']:
            count = self._archive_model(
                CarDispatch,
                before_date,
                'started_at',
                archived_data['CarDispatch'],
                dry_run,
            )

        # Archive UserActivityLog
        if model in ['UserActivityLog', 'all']:
            count = self._archive_model(
                UserActivityLog,
                before_date,
                'created_at',
                archived_data['UserActivityLog'],
                dry_run,
            )

        # Archive old terminal TransportRequests
        if model in ['TransportRequest', 'all']:
            count = self._archive_terminal_requests(
                before_date,
                archived_data['TransportRequest'],
                dry_run,
            )

        # Write to output file if specified
        if output_file:
            with open(output_file, 'w') as f:
                json.dump(archived_data, f, indent=2, default=str)
            self.stdout.write(self.style.SUCCESS(f"Archive data written to {output_file}"))

        self.stdout.write(self.style.SUCCESS("Archive process completed"))

    def _parse_date(self, date_str: str) -> date:
        """Parse date string."""
        try:
            return date.fromisoformat(date_str)
        except ValueError:
            raise CommandError(f"Invalid date format: {date_str}. Expected YYYY-MM-DD")

    def _archive_model(self, model_class, before_date, date_field, archive_list, dry_run):
        """Archive records from a model before a specified date."""
        filter_kwargs = {f'{date_field}__date__lt': before_date}
        queryset = model_class.objects.filter(**filter_kwargs)
        count = queryset.count()

        if count == 0:
            self.stdout.write(f"No {model_class.__name__} records to archive")
            return 0

        self.stdout.write(f"Found {count} {model_class.__name__} records to archive")

        # Collect data for archiving
        for obj in queryset[:1000]:  # Limit to avoid memory issues
            archive_list.append({
                'id': str(obj.id),
                'created_at': str(getattr(obj, date_field, obj.created_at)),
            })

        if not dry_run:
            # Delete in chunks to avoid memory issues
            queryset.delete()
            self.stdout.write(
                self.style.SUCCESS(f"Archived {count} {model_class.__name__} records")
            )
        else:
            self.stdout.write(
                self.style.WARNING(f"Would archive {count} {model_class.__name__} records")
            )

        return count

    def _archive_terminal_requests(self, before_date, archive_list, dry_run):
        """Archive only terminal state transport requests (DELIVERED, RETURNED, CANCELLED, FAILED)."""
        terminal_statuses = ['DELIVERED', 'RETURNED', 'CANCELLED', 'FAILED']
        queryset = TransportRequest.objects.filter(
            created_at__date__lt=before_date,
            status__in=terminal_statuses,
        )
        count = queryset.count()

        if count == 0:
            self.stdout.write("No terminal TransportRequest records to archive")
            return 0

        self.stdout.write(f"Found {count} terminal TransportRequest records to archive")

        # Collect data for archiving
        for obj in queryset[:1000]:
            archive_list.append({
                'id': str(obj.id),
                'status': obj.status,
                'created_at': str(obj.created_at),
                'sample_id': str(obj.sample_id),
            })

        if not dry_run:
            queryset.delete()
            self.stdout.write(
                self.style.SUCCESS(f"Archived {count} terminal TransportRequest records")
            )
        else:
            self.stdout.write(
                self.style.WARNING(f"Would archive {count} terminal TransportRequest records")
            )

        return count
