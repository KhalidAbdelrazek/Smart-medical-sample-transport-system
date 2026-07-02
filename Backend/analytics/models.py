from django.db import models
from django.conf import settings
import uuid

class StorageEmployeeLog(models.Model):
    ACTION_CHOICES = [
        ('CAR_DISPATCH', 'Car Dispatch'),
        ('SAMPLE_REMOVED_FROM_CAR', 'Sample Removed From Car'),
        ('SAMPLE_ADDED_TO_CAR', 'Sample Added To Car'),
        ('CAR_STATUS_UPDATE', 'Car Status Update'),
        ('TRANSPORT_REQUEST_UPDATE', 'Transport Request Update'),
        ('OTHER', 'Other'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    employee = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='storage_logs',
        help_text='The storage employee (user) who did the action.'
    )
    action = models.CharField(max_length=50, choices=ACTION_CHOICES)
    description = models.TextField(blank=True, default='')
    transport_request = models.ForeignKey(
        'transport.TransportRequest',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='storage_employee_logs',
        help_text='The related request, if applicable.'
    )
    car = models.ForeignKey(
        'cars.Car',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='storage_employee_logs',
        help_text='The related car, if applicable.'
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['employee', 'created_at']),
            models.Index(fields=['action', 'created_at']),
            models.Index(fields=['created_at']),
        ]

    def __str__(self):
        return f"{self.employee.full_name} | {self.action} | {self.created_at}"