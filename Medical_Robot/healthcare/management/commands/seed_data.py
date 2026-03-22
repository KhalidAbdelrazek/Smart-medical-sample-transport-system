import random
import uuid
from datetime import date, timedelta
from django.core.management.base import BaseCommand
from django.utils import timezone
from healthcare.models import Patient as HCPatient, Staff, SensorReading
from robot.models import Employee, Patient as RobotPatient, Request, Vehicle, Response, Dispatch, BLOOD_TYPES

class Command(BaseCommand):
    help = 'Seeds the database with dummy data for testing'

    def handle(self, *args, **kwargs):
        self.stdout.write('Cleaning up old data...')
        # Optional: Clear tables to avoid duplicates (Use with caution)
        # HCPatient.objects.all().delete()
        # Staff.objects.all().delete()
        # SensorReading.objects.all().delete()
        # Employee.objects.all().delete()
        # RobotPatient.objects.all().delete()
        # Vehicle.objects.all().delete()
        # Request.objects.all().delete()
        # Response.objects.all().delete()
        # Dispatch.objects.all().delete()

        self.stdout.write('Seeding data...')
        suffix = uuid.uuid4().hex[:6]

        # 1. Healthcare Staff
        staff_members = []
        for i in range(7):
            s = Staff.objects.create(
                name=f'Staff Member {i+1} {suffix}',
                age=25 + i,
                gender='Male' if i % 2 == 0 else 'Female',
                role='Doctor' if i % 3 == 0 else 'Nurse',
                phone=f'0100000000{i}',
                city='Cairo',
                address=f'Address {i+1}',
                zip_code=f'1234{i}',
                email=f'staff{i+1}_{suffix}@example.com',
                password='password123'
            )
            staff_members.append(s)
        self.stdout.write(self.style.SUCCESS(f'Created {len(staff_members)} staff members'))

        # 2. Healthcare Patients
        hc_patients = []
        for i in range(10):
            p = HCPatient.objects.create(
                name=f'HC Patient {i+1} {suffix}',
                age=20 + i,
                gender='Male' if i % 2 == 0 else 'Female',
                description=f'Description for patient {i+1}',
                phone=f'0110000000{i}',
                email=f'hcpient{i+1}_{suffix}@example.com',
                password='password123',
                city='Giza',
                address=f'Address {i+1}',
                zip_code=f'5432{i}'
            )
            hc_patients.append(p)
        self.stdout.write(self.style.SUCCESS(f'Created {len(hc_patients)} healthcare patients'))

        # 3. Sensor Readings
        for i in range(15):
            SensorReading.objects.create(
                cart=f'Cart {random.randint(1, 5)} {suffix}',
                position=f'Pos {random.randint(1, 10)}',
                load=str(random.randint(1, 80)),
                state='C' if i % 2 == 0 else 'W'
            )
        self.stdout.write(self.style.SUCCESS('Created 15 sensor readings'))

        # 4. Robot Employees
        employees = []
        for i in range(6):
            e = Employee.objects.create(
                employee_id=f'E{suffix}{i+1}',
                name=f'Employee {i+1} {suffix}',
                department='samples' if i % 2 == 0 else 'blood_bags',
                shift='morning' if i % 3 == 0 else ('evening' if i % 3 == 1 else 'night'),
                birth_date=date(1990, 1, 1) + timedelta(days=i*365)
            )
            employees.append(e)
        self.stdout.write(self.style.SUCCESS(f'Created {len(employees)} robot employees'))

        # 5. Robot Patients
        robot_patients = []
        for i in range(8):
            p = RobotPatient.objects.create(
                name=f'Robot Patient {i+1} {suffix}',
                phone=f'0120000000{i}',
                email=f'rbpatient{i+1}_{suffix}@example.com',
                address=f'Robo City St {i+1}',
                birth_date=date(1980, 5, 20) + timedelta(days=i*500),
                blood_type=random.choice(BLOOD_TYPES)[0]
            )
            robot_patients.append(p)
        self.stdout.write(self.style.SUCCESS(f'Created {len(robot_patients)} robot patients'))

        # 6. Vehicles
        vehicles = []
        for i in range(5):
            v = Vehicle.objects.create(
                name=f'Vehicle {i+1} {suffix}',
                capacity=random.randint(5, 10)
            )
            vehicles.append(v)
        self.stdout.write(self.style.SUCCESS(f'Created {len(vehicles)} vehicles'))

        # 7. Requests
        requests = []
        for i in range(12):
            r = Request.objects.create(
                request_type='sample' if i % 2 == 0 else 'blood_bag',
                blood_type=random.choice(BLOOD_TYPES)[0],
                room_number=f'Room {100+i}',
                patient=random.choice(robot_patients),
                created_by=random.choice(employees)
            )
            requests.append(r)
        self.stdout.write(self.style.SUCCESS(f'Created {len(requests)} requests'))

        # 8. Responses
        responses = []
        for r in requests[:8]: # Create responses for some requests
            # Select a vehicle that is not full
            available_vehicles = [v for v in vehicles if v.current_load < v.capacity]
            if not available_vehicles:
                break
                
            resp = Response.objects.create(
                request=r,
                vehicle=random.choice(available_vehicles),
                handled_by=random.choice(employees),
                status='in_car'
            )
            responses.append(resp)
        self.stdout.write(self.style.SUCCESS(f'Created {len(responses)} responses'))

        # 9. Dispatches
        for i in range(3):
            # Refresh vehicles to get updated current_load
            all_vehicles = Vehicle.objects.all()
            loaded_vehicles = [v for v in all_vehicles if v.current_load > 0]
            if not loaded_vehicles:
                break
            
            v = random.choice(loaded_vehicles)
            Dispatch.objects.create(
                vehicle=v,
                dispatched_by=random.choice(employees)
            )
        self.stdout.write(self.style.SUCCESS('Created dispatches'))

        self.stdout.write(self.style.SUCCESS('Database seeding completed!'))
