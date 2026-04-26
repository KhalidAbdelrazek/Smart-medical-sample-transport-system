"""
transport/models.py

TransportRequest model - links BloodSample, Doctor, and Car together.
"""
import uuid
from django.conf import settings
from django.db import models


class TransportRequest(models.Model):
    """
    Represents a Doctor's request to transport a blood sample to their room or return it.

    Request Types:
        DELIVERY - outbound: sample is picked from storage and delivered to doctor
        RETURN   - inbound: sample is picked from doctor and returned to storage

    Lifecycle (DELIVERY):
        Doctor requests sample -> PENDING
        Storage employee adds to car -> LOADED
        Car dispatched -> DISPATCHED
        Doctor receives -> DELIVERED (sample now with doctor, not in storage)

    Lifecycle (RETURN):
        Doctor finishes exam, requests return -> PENDING
        Storage employee selects for collection -> LOADED
        Car dispatched -> DISPATCHED
        Car collects from doctor -> RETURNED (sample back in storage)
    """

    REQUEST_TYPE_CHOICES = [
        ('DELIVERY', 'Delivery'),  # Outbound: storage -> doctor
        ('RETURN', 'Return'),      # Inbound: doctor -> storage
    ]

    STATUS_CHOICES = [
        ('PENDING', 'Pending'),       # Waiting for next action (load/select)
        ('LOADED', 'Loaded'),          # Sample is loaded into a car
        ('DISPATCHED', 'Dispatched'),  # Car has been dispatched
        ('DELIVERED', 'Delivered'),    # DELIVERY: successfully delivered to doctor
        ('RETURNED', 'Returned'),      # RETURN: successfully returned to storage
        ('CANCELLED', 'Cancelled'),    # Request was cancelled
        ('FAILED', 'Failed'),          # Transport failed
        ('SUCCESSFUL', 'Successful'),  # Legacy: Delivery completed successfully
        ('EXECUTED', 'Executed'),      # Legacy: Request has been executed/processed
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    request_type = models.CharField(
        max_length=10,
        choices=REQUEST_TYPE_CHOICES,
        default='DELIVERY',
        help_text="Direction of transport: DELIVERY (storage->doctor) or RETURN (doctor->storage)"
    )

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
    
    # Lifecycle timestamps for analytics
    loaded_at = models.DateTimeField(null=True, blank=True, help_text="When sample was loaded into a car")
    dispatched_at = models.DateTimeField(null=True, blank=True, help_text="When car carrying this sample was dispatched")
    completed_at = models.DateTimeField(null=True, blank=True, help_text="When delivery was completed")
    cancelled_at = models.DateTimeField(null=True, blank=True, help_text="When request was cancelled")
    failed_at = models.DateTimeField(null=True, blank=True, help_text="When delivery failed")
    
    status_note = models.TextField(
        blank=True,
        default='',
        help_text="Optional note explaining status change (e.g., cancellation reason, failure reason)"
    )

    class Meta:
        verbose_name = 'Transport Request'
        verbose_name_plural = 'Transport Requests'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['created_at', 'status']),
            models.Index(fields=['request_type', 'status']),
            models.Index(fields=['requested_by', 'created_at']),
            models.Index(fields=['assigned_car', 'created_at']),
        ]

    def __str__(self):
        return (
            f"Request {self.id} | Sample: {self.sample_id} | "
            f"Room: {self.room_number} | Status: {self.status}"
        )
