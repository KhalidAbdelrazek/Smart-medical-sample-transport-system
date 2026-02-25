import uuid
from django.db import models
from django.utils import timezone
from datetime import date
from django.core.exceptions import ValidationError


BLOOD_TYPES = [
    ('A+', 'A+'), ('A-', 'A-'), ('B+', 'B+'), ('B-', 'B-'),
    ('AB+', 'AB+'), ('AB-', 'AB-'), ('O+', 'O+'), ('O-', 'O-'),
]


class Employee(models.Model):
    DEPARTMENT_CHOICES = [
        ('samples', 'Samples Department'),
        ('blood_bags', 'Blood Bags Department'),
    ]

    SHIFT_CHOICES = [
        ('morning', 'Morning'),
        ('evening', 'Evening'),
        ('night', 'Night'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False, help_text="Unique UUID for the employee.")
    employee_id = models.CharField(max_length=20, unique=True, help_text="Official hospital employee identification number.")
    name = models.CharField(max_length=100, help_text="Full name of the employee.")
    department = models.CharField(max_length=20, choices=DEPARTMENT_CHOICES, help_text="The department the employee works in.")
    shift = models.CharField(max_length=20, choices=SHIFT_CHOICES, help_text="The working shift of the employee.")
    birth_date = models.DateField(help_text="The employee's date of birth.")

    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(default=timezone.now)

    @property
    def age(self):
        today = date.today()
        return today.year - self.birth_date.year - (
            (today.month, today.day) < (self.birth_date.month, self.birth_date.day)
        )

    def __str__(self):
        return self.name


class EmployeeStatistics(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    employee = models.OneToOneField(Employee, on_delete=models.CASCADE)
    processed_samples = models.IntegerField(default=0, editable=False)
    processed_bags = models.IntegerField(default=0, editable=False)
    dispatched_cars = models.IntegerField(default=0, editable=False)

    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(default=timezone.now)

    def __str__(self):
        return f"Stats for {self.employee.name}"


class Patient(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False, help_text="Unique UUID for the patient.")
    name = models.CharField(max_length=100, help_text="Full name of the patient.")
    phone = models.CharField(max_length=15, help_text="Primary contact phone number.")
    email = models.EmailField(help_text="Patient's email address.")
    address = models.TextField(help_text="Full residential address.")
    birth_date = models.DateField(help_text="The patient's date of birth.")
    blood_type = models.CharField(max_length=5, choices=BLOOD_TYPES, help_text="The patient's blood type (e.g., A+, O-).")

    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(default=timezone.now)

    @property
    def age(self):
        today = date.today()
        return today.year - self.birth_date.year - (
            (today.month, today.day) < (self.birth_date.month, self.birth_date.day)
        )

    def __str__(self):
        return self.name


class Request(models.Model):
    REQUEST_TYPES = [
        ('sample', 'Blood Sample'),
        ('blood_bag', 'Blood Bag'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False, help_text="Unique UUID for the transport request.")
    request_type = models.CharField(max_length=20, choices=REQUEST_TYPES, help_text="Type of transport requested (e.g., blood sample, blood bag).")
    blood_type = models.CharField(max_length=5, choices=BLOOD_TYPES, help_text="Blood type corresponding to the request.")
    room_number = models.CharField(max_length=20, help_text="The room number where the items are located or need to be delivered.")
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, null=True, blank=True, help_text="The patient associated with this request.")
    created_by = models.ForeignKey(Employee, on_delete=models.CASCADE, help_text="The employee who initiated this request.")
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f"{self.request_type} - {self.blood_type}"


class Vehicle(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False, help_text="Unique UUID for the vehicle/robot.")
    name = models.CharField(max_length=100, help_text="Name or identifier of the vehicle.")
    capacity = models.IntegerField(default=5, help_text="Maximum number of requests the vehicle can handle at once.")
    current_load = models.IntegerField(default=0, help_text="The current number of active requests assigned to this vehicle.")

    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(default=timezone.now)

    @property
    def is_available(self):
        return self.current_load < self.capacity

    def __str__(self):
        return self.name


class Response(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False, help_text="Unique UUID for the response.")
    request = models.OneToOneField(Request, on_delete=models.CASCADE, help_text="The request this response is fulfilling.")
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, help_text="The transport vehicle assigned to fulfill the request.")
    handled_by = models.ForeignKey(Employee, on_delete=models.CASCADE, help_text="The employee responsible for handling this response.")
    status = models.CharField(
        max_length=20,
        choices=[('in_car', 'In Car'), ('dispatched', 'Dispatched'), ('completed', 'Completed')],
        default='in_car',
        help_text="Current fulfillment status of the request."
    )
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(default=timezone.now)

    def save(self, *args, **kwargs):
        is_new = self.pk is None

        if is_new:
            # لو العربية ممتلئة، اعرض رسالة ودية
            if self.vehicle.current_load >= self.vehicle.capacity:
                raise ValidationError("The vehicle is full! Cannot add a new Response.")

            # زود الحمولة
            self.vehicle.current_load += 1
            self.vehicle.save()

            # خلي الحالة in_car تلقائي
            self.status = 'in_car'

        super().save(*args, **kwargs)

    def mark_completed(self):
        if self.status != 'completed':
            self.status = 'completed'
            self.save()

            stats, _ = EmployeeStatistics.objects.get_or_create(employee=self.handled_by)
            if self.request.request_type == 'sample':
                stats.processed_samples += 1
            else:
                stats.processed_bags += 1
            stats.save()

    def __str__(self):
        return f"Response for {self.request}"


class Dispatch(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False, help_text="Unique UUID for the dispatch event.")
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, help_text="The vehicle being dispatched.")
    dispatched_by = models.ForeignKey(Employee, on_delete=models.CASCADE, help_text="The employee who orchestrated the dispatch.")
    dispatched_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(default=timezone.now)

    def save(self, *args, **kwargs):
        is_new = self.pk is None

        super().save(*args, **kwargs)  # احفظ أولاً علشان يكون عندنا ID للـ Dispatch

        if is_new:
            # كل الـ Responses اللي بالعربية لسة in_car
            responses_in_vehicle = Response.objects.filter(vehicle=self.vehicle, status='in_car')

            # حساب عدد العينات والأكياس
            samples_count = responses_in_vehicle.filter(request__request_type='sample').count()
            bags_count = responses_in_vehicle.filter(request__request_type='blood_bag').count()

            # تحديث إحصائيات الموظف اللي عمل Dispatch
            stats, _ = EmployeeStatistics.objects.get_or_create(employee=self.dispatched_by)
            stats.dispatched_cars += 1
            stats.processed_samples += samples_count
            stats.processed_bags += bags_count
            stats.save()

            # تحديث حالة كل الـ Responses في العربية
            responses_in_vehicle.update(status='dispatched')

            # تصفير الحمولة بعد الـ Dispatch
            self.vehicle.current_load = 0
            self.vehicle.save()

    def __str__(self):
        return f"Dispatch {self.id}"
