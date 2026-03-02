"""
transport/models.py

TransportRequest model - links BloodSample, Doctor, and Car together.
"""
import uuid
from django.conf import settings
from django.db import models


class TransportRequest(models.Model):
    """
    Represents a Doctor's request to transport a blood sample to their room.

    Lifecycle:
        Doctor requests sample -> PENDING
        Storage employee adds to car -> LOADED
        Car dispatched -> DISPATCHED
    """

    STATUS_CHOICES = [
        ('PENDING', 'Pending'),       # Doctor requested, waiting for storage action
        ('LOADED', 'Loaded'),          # Sample is loaded into a car
        ('DISPATCHED', 'Dispatched'),  # Car has been dispatched for delivery
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    sample = models.ForeignKey(
        'samples.BloodSample',
        on_delete=models.CASCADE,
        related_name='transport_requests',
    )

    requested_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='transport_requests',
        help_text="The Doctor who made this request",
    )

    room_number = models.CharField(
        max_length=50,
        help_text="Room number where the sample should be delivered"
    )

    assigned_car = models.ForeignKey(
        'cars.Car',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='transport_requests',
        help_text="The car assigned to carry this sample",
    )

    status = models.CharField(max_length=15, choices=STATUS_CHOICES, default='PENDING')

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Transport Request'
        verbose_name_plural = 'Transport Requests'
        ordering = ['-created_at']

    def __str__(self):
        return (
            f"Request {self.id} | Sample: {self.sample_id} | "
            f"Room: {self.room_number} | Status: {self.status}"
        )
