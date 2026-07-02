"""
analytics/management/commands/seed_analytics_data.py

Management command to seed test data for the analytics dashboard.

Usage:
    python manage.py seed_analytics_data

Properties:
- Fully idempotent (safe to re-run — uses get_or_create for users)
- Creates dummy + "real" test users with role-specific data
- Distributes data across today, last week, current month, previous months
- Password for all seeded users: AaAa112233_

IMPORTANT: Analytics system works completely independently of this seed data.
           This command is purely for testing/demonstration purposes.
"""
import random
from datetime import date, timedelta, datetime, timezone

from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.db import transaction

from samples.models import BloodSample
from transport.models import TransportRequest
from analytics.models import StorageEmployeeLog

User = get_user_model()

PASSWORD = 'AaAa112233_'

SEED_USER_MARKER = '[SEED]'  # used in description to mark seed logs

# ---------------------------------------------------------------------------
# User definitions
# ---------------------------------------------------------------------------

DOCTORS = [
    {'email': 'doctor_dummy1@bioroute.com', 'full_name': 'Doctor Dummy 1', 'role': 'DOCTOR'},
    {'email': 'doctor_dummy2@bioroute.com', 'full_name': 'Doctor Dummy 2', 'role': 'DOCTOR'},
    {'email': 'doctor_dummy3@bioroute.com', 'full_name': 'Doctor Dummy 3', 'role': 'DOCTOR'},
    {'email': 'doctor3@bioroute.com',        'full_name': 'Doctor 3',         'role': 'DOCTOR'},
]

STORAGE_EMPLOYEES = [
    {'email': 'storage_dummy1@bioroute.com', 'full_name': 'Storage Dummy 1', 'role': 'STORAGE_EMPLOYEE'},
    {'email': 'storage_dummy2@bioroute.com', 'full_name': 'Storage Dummy 2', 'role': 'STORAGE_EMPLOYEE'},
    {'email': 'storage_dummy3@bioroute.com', 'full_name': 'Storage Dummy 3', 'role': 'STORAGE_EMPLOYEE'},
    {'email': 'storage3@bioroute.com',        'full_name': 'Storage 3',         'role': 'STORAGE_EMPLOYEE'},
]

ADMINS = [
    {'email': 'admin@bioroute.com', 'full_name': 'Admin', 'role': 'ADMIN'},
]

# ---------------------------------------------------------------------------
# Date distribution helpers
# ---------------------------------------------------------------------------

def _dates_for_period() -> list:
    """
    Return a list of dates spanning:
    - today
    - a few days in the last week
    - some earlier days in the current month
    - some days in the previous 2 months
    """
    today = date.today()
    dates = []

    # Today
    dates.append(today)

    # Last 7 days
    for delta in range(1, 7):
        dates.append(today - timedelta(days=delta))

    # Earlier in current month (days 1-15 if we're past day 15)
    if today.day > 15:
        for day in range(1, 15, 3):
            try:
                dates.append(today.replace(day=day))
            except ValueError:
                pass

    # Previous month
    first_of_this_month = today.replace(day=1)
    last_month_end = first_of_this_month - timedelta(days=1)
    for day in range(1, last_month_end.day, 5):
        try:
            dates.append(last_month_end.replace(day=day))
        except ValueError:
            pass

    # Two months ago
    first_of_last_month = last_month_end.replace(day=1)
    two_months_ago_end = first_of_last_month - timedelta(days=1)
    for day in range(1, two_months_ago_end.day, 7):
        try:
            dates.append(two_months_ago_end.replace(day=day))
        except ValueError:
            pass

    return list(set(dates))  # deduplicate


def _random_datetime_on(day: date) -> datetime:
    """Return a random datetime on the given date in UTC."""
    hour = random.randint(7, 18)
    minute = random.randint(0, 59)
    second = random.randint(0, 59)
    return datetime(day.year, day.month, day.day, hour, minute, second, tzinfo=timezone.utc)


# ---------------------------------------------------------------------------
# Main command
# ---------------------------------------------------------------------------

class Command(BaseCommand):
    help = (
        'Seed test data for analytics dashboard. '
        'Creates dummy and real test users and distributes synthetic data '
        'across multiple time periods. Safe to re-run (idempotent).'
    )

    def handle(self, *args, **options):
        self.stdout.write(self.style.MIGRATE_HEADING('=== Seeding Analytics Data ==='))

        with transaction.atomic():
            doctors = self._seed_users(DOCTORS)
            storage_employees = self._seed_users(STORAGE_EMPLOYEES)
            self._seed_users(ADMINS)

            dates = _dates_for_period()
            self.stdout.write(f'  Distributing data across {len(dates)} dates...')

            transport_requests_created = self._seed_transport_requests(doctors, dates)
            logs_created = self._seed_storage_employee_logs(storage_employees, dates)

        self.stdout.write(self.style.SUCCESS(
            f'\n✔ Done! Created {transport_requests_created} TransportRequests '
            f'and {logs_created} StorageEmployeeLogs.'
        ))

    # -------------------------------------------------------------------------

    def _seed_users(self, user_defs: list) -> list:
        """Create or retrieve all users in user_defs. Returns list of User objects."""
        users = []
        for defn in user_defs:
            user, created = User.objects.get_or_create(
                email=defn['email'],
                defaults={
                    'full_name': defn['full_name'],
                    'role': defn['role'],
                    'is_active': True,
                    'is_staff': defn['role'] == 'ADMIN',
                    'is_superuser': defn['role'] == 'ADMIN',
                }
            )
            if created:
                user.set_password(PASSWORD)
                user.save()
                self.stdout.write(f'  [CREATED] {defn["role"]}: {defn["email"]}')
            else:
                self.stdout.write(f'  [EXISTS]  {defn["role"]}: {defn["email"]}')
            users.append(user)
        return users

    def _seed_transport_requests(self, doctors: list, dates: list) -> int:
        """
        Create TransportRequest records for each doctor across the date distribution.
        Skips dates where the doctor already has >= 3 seeded requests (idempotency approximation).
        """
        statuses = ['PENDING', 'DELIVERED', 'FAILED', 'CANCELLED', 'DELIVERED', 'DELIVERED']
        total_created = 0

        for doctor in doctors:
            for day in dates:
                # Idempotency: check if doctor already has requests on this day
                existing_count = TransportRequest.objects.filter(
                    requested_by=doctor,
                    created_at__date=day,
                ).count()
                if existing_count >= 2:
                    continue  # already seeded this day

                # Create 1-3 requests per doctor per date
                num_requests = random.randint(1, 3)
                for _ in range(num_requests):
                    sample = self._get_or_create_sample()
                    status = random.choice(statuses)
                    req = TransportRequest(
                        sample=sample,
                        requested_by=doctor,
                        room_number=f'Room-{random.randint(100, 499)}',
                        status=status,
                    )
                    req.save()

                    # Override created_at to distribute across dates
                    TransportRequest.objects.filter(pk=req.pk).update(
                        created_at=_random_datetime_on(day)
                    )
                    total_created += 1

        return total_created

    def _seed_storage_employee_logs(self, employees: list, dates: list) -> int:
        """
        Create StorageEmployeeLog records for each employee across date distribution.
        """
        actions = [
            'CAR_DISPATCH',
            'SAMPLE_ADDED_TO_CAR',
            'SAMPLE_REMOVED_FROM_CAR',
            'TRANSPORT_REQUEST_UPDATE',
            'OTHER',
            'CAR_STATUS_UPDATE',
        ]
        total_created = 0

        for employee in employees:
            for day in dates:
                # Idempotency: skip if already has 2+ seed logs on this day
                existing_count = StorageEmployeeLog.objects.filter(
                    employee=employee,
                    created_at__date=day,
                    description__startswith=SEED_USER_MARKER,
                ).count()
                if existing_count >= 2:
                    continue

                num_logs = random.randint(1, 4)
                for _ in range(num_logs):
                    action = random.choice(actions)
                    log = StorageEmployeeLog(
                        employee=employee,
                        action=action,
                        description=f'{SEED_USER_MARKER} Seeded log entry for {day}',
                    )
                    log.save()

                    # Override created_at
                    StorageEmployeeLog.objects.filter(pk=log.pk).update(
                        created_at=_random_datetime_on(day)
                    )
                    total_created += 1

        return total_created

    def _get_or_create_sample(self) -> BloodSample:
        """Get or create a reusable BloodSample for seeding transport requests."""
        blood_types = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
        patient_names = [
            'Seed Patient Alpha', 'Seed Patient Beta', 'Seed Patient Gamma',
            'Seed Patient Delta', 'Seed Patient Epsilon',
        ]
        # Reuse an existing seed sample to avoid bloat
        existing = BloodSample.objects.filter(
            patient_name__startswith='Seed Patient'
        ).first()
        if existing:
            return existing

        return BloodSample.objects.create(
            patient_name=random.choice(patient_names),
            blood_type=random.choice(blood_types),
            status='IN_STORAGE',
            is_in_storage=True,
        )
