from django.core.management.base import BaseCommand
from accounts.models import User

TEST_USERS = [
    {
        'email': 'storage1@bioroute.com',
        'full_name': 'Storage Employee One',
        'role': 'STORAGE_EMPLOYEE',
        'department': 'Blood Storage Unit',
        'shift': 'MORNING',
        'employee_id': 'EMP-ST-001',
    },
    {
        'email': 'storage2@bioroute.com',
        'full_name': 'Storage Employee Two',
        'role': 'STORAGE_EMPLOYEE',
        'department': 'Blood Storage Unit',
        'shift': 'EVENING',
        'employee_id': 'EMP-ST-002',
    },
    {
        'email': 'doctor1@bioroute.com',
        'full_name': 'Doctor One',
        'role': 'DOCTOR',
        'department': 'Cardiology',
        'shift': '',
        'employee_id': 'EMP-DR-001',
    },
    {
        'email': 'doctor2@bioroute.com',
        'full_name': 'Doctor Two',
        'role': 'DOCTOR',
        'department': 'Oncology',
        'shift': '',
        'employee_id': 'EMP-DR-002',
    },
    {
        'email': 'admin@bioroute.com',
        'full_name': 'System Admin',
        'role': 'ADMIN',
        'department': 'IT Operations',
        'shift': '',
        'employee_id': 'EMP-AD-001',
    },
]

DEFAULT_PASSWORD = 'AaAa112233_'

class Command(BaseCommand):
    help = 'Create initial test users'

    def handle(self, *args, **kwargs):
        self.stdout.write('Creating test users...')
        for user_data in TEST_USERS:
            email = user_data['email']
            if User.objects.filter(email=email).exists():
                self.stdout.write(f'SKIP: {email} already exists')
                continue
            User.objects.create_user(
                email=email,
                password=DEFAULT_PASSWORD,
                full_name=user_data['full_name'],
                role=user_data['role'],
                department=user_data['department'],
                shift=user_data['shift'],
                employee_id=user_data['employee_id'],
                is_staff=(user_data['role'] == 'ADMIN'),
            )
            self.stdout.write(f'CREATED: {email} [{user_data["role"]}]')
        self.stdout.write('Done!')
