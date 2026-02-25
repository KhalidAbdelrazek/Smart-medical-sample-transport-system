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

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    employee_id = models.CharField(max_length=20, unique=True)
    name = models.CharField(max_length=100)
    department = models.CharField(max_length=20, choices=DEPARTMENT_CHOICES)
    shift = models.CharField(max_length=20, choices=SHIFT_CHOICES)
    birth_date = models.DateField()

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
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100)
    phone = models.CharField(max_length=15)
    email = models.EmailField()
    address = models.TextField()
    birth_date = models.DateField()
    blood_type = models.CharField(max_length=5, choices=BLOOD_TYPES)

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

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    request_type = models.CharField(max_length=20, choices=REQUEST_TYPES)
    blood_type = models.CharField(max_length=5, choices=BLOOD_TYPES)
    room_number = models.CharField(max_length=20)
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, null=True, blank=True)
    created_by = models.ForeignKey(Employee, on_delete=models.CASCADE)
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f"{self.request_type} - {self.blood_type}"


class Vehicle(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100)
    capacity = models.IntegerField(default=5)
    current_load = models.IntegerField(default=0)

    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(default=timezone.now)

    @property
    def is_available(self):
        return self.current_load < self.capacity

    def __str__(self):
        return self.name


class Response(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    request = models.OneToOneField(Request, on_delete=models.CASCADE)
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE)
    handled_by = models.ForeignKey(Employee, on_delete=models.CASCADE)
    status = models.CharField(
        max_length=20,
        choices=[('in_car', 'In Car'), ('dispatched', 'Dispatched'), ('completed', 'Completed')],
        default='in_car'
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
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE)
    dispatched_by = models.ForeignKey(Employee, on_delete=models.CASCADE)
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
