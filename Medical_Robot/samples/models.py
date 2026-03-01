"""
samples/models.py

BloodSample model for blood sample storage and transport tracking.
"""
import uuid
from django.db import models


class BloodSample(models.Model):
    """
    Represents a blood sample stored in the hospital storage unit.
    Tracks the sample through its lifecycle: storage → requested → dispatched.
    """

    BLOOD_TYPE_CHOICES = [
        ('A+', 'A+'), ('A-', 'A-'),
        ('B+', 'B+'), ('B-', 'B-'),
        ('AB+', 'AB+'), ('AB-', 'AB-'),
        ('O+', 'O+'), ('O-', 'O-'),
    ]

    STATUS_CHOICES = [
        ('IN_STORAGE', 'In Storage'),
        ('REQUESTED', 'Requested'),
        ('OUT_FOR_DELIVERY', 'Out For Delivery'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    patient_name = models.CharField(max_length=200)
    patient_id = models.CharField(max_length=100, help_text="Hospital patient ID number")
    blood_type = models.CharField(max_length=5, choices=BLOOD_TYPE_CHOICES)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='IN_STORAGE')
    is_in_storage = models.BooleanField(
        default=True,
        help_text="True = sample is physically in storage; False = out for delivery"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Blood Sample'
        verbose_name_plural = 'Blood Samples'
        ordering = ['-created_at']

    def __str__(self):
        return f"Sample {self.id} | {self.patient_name} | {self.blood_type} | {self.status}"
