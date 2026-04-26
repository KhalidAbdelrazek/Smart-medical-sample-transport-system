"""
samples/models.py

BloodSample model for blood sample storage and transport tracking.
"""
import uuid
from django.db import models


class BloodSample(models.Model):
    """
    Represents a blood sample stored in the hospital storage unit.
    Tracks the sample through its lifecycle: storage -> requested -> dispatched.
    """

    BLOOD_TYPE_CHOICES = [
        ('A+', 'A+'), ('A-', 'A-'),
        ('B+', 'B+'), ('B-', 'B-'),
        ('AB+', 'AB+'), ('AB-', 'AB-'),
        ('O+', 'O+'), ('O-', 'O-'),
    ]

    STATUS_CHOICES = [
        ('IN_STORAGE', 'In Storage'),       # Sample is in storage, not assigned to anyone
        ('REQUESTED', 'Requested'),         # Doctor has requested delivery to their room
        ('OUT_FOR_DELIVERY', 'Out For Delivery'),  # Sample is being transported for delivery
        ('WITH_DOCTOR', 'With Doctor'),     # Sample has been delivered to doctor (not in storage yet)
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    patient_name = models.CharField(max_length=200)
    sample_code = models.CharField(
        max_length=20, 
        db_index=True, 
        null=True,
        blank=True,
        editable=False,
        help_text="Human-readable code, e.g., PT-0001"
    )
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
        return f"{self.sample_code} | {self.patient_name} | {self.blood_type}"

    def save(self, *args, **kwargs):
        if not self.sample_code:
            # Generate sequential sample code: PT-0001, PT-0002, etc.
            last_sample = BloodSample.objects.order_by('-created_at').first()
            if last_sample and last_sample.sample_code:
                try:
                    # Extract number from code like 'PT-0005'
                    last_number = int(last_sample.sample_code.split('-')[1])
                    new_number = last_number + 1
                except (IndexError, ValueError):
                    new_number = 1
            else:
                new_number = 1
            
            self.sample_code = f"PT-{new_number:04d}"
        
        super().save(*args, **kwargs)
