"""
stats/models.py

Statistics and analytics models:
- CarDispatch: Tracks car dispatch events and outcomes
- UserActivityLog: Immutable audit log for user actions
"""
import uuid
from django.conf import settings
from django.db import models


class CarDispatch(models.Model):
    """
    Represents a single car dispatch attempt.
    
    Tracks when a car was dispatched, how many requests it carried,
    and the outcome (success/cancelled/failed).
    """
    
    STATUS_CHOICES = [
        ('DISPATCHED', 'Dispatched'),    # Car was dispatched
        ('SUCCESS', 'Success'),          # Dispatch completed successfully
        ('CANCELLED', 'Cancelled'),      # Dispatch was cancelled
        ('FAILED', 'Failed'),            # Dispatch failed
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    car = models.ForeignKey(
        'cars.Car',
        on_delete=models.SET_NULL,
        null=True,
        related_name='dispatch_events',
        help_text="The car that was dispatched",
    )
    
    dispatched_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='car_dispatches',
        help_text="The StorageEmployee who initiated the dispatch",
    )
    
    status = models.CharField(max_length=15, choices=STATUS_CHOICES, default='DISPATCHED')
    
    request_count = models.PositiveIntegerField(
        default=0,
        help_text="Number of transport requests carried in this dispatch",
    )
    
    notes = models.TextField(
        blank=True,
        default='',
        help_text="Optional notes about this dispatch",
    )
    
    # Lifecycle timestamps
    started_at = models.DateTimeField(auto_now_add=True, help_text="When dispatch was initiated")
    completed_at = models.DateTimeField(null=True, blank=True, help_text="When dispatch completed successfully")
    cancelled_at = models.DateTimeField(null=True, blank=True, help_text="When dispatch was cancelled")
    failed_at = models.DateTimeField(null=True, blank=True, help_text="When dispatch failed")
    
    class Meta:
        verbose_name = 'Car Dispatch'
        verbose_name_plural = 'Car Dispatches'
        ordering = ['-started_at']
        indexes = [
            models.Index(fields=['started_at', 'status']),
            models.Index(fields=['car', 'started_at']),
        ]
    
    def __str__(self):
        return f"Dispatch {self.id} | Car: {self.car_id} | Status: {self.status}"


class UserActivityLog(models.Model):
    """
    Immutable audit log for user actions related to transport requests.
    
    Logs key events:
    - Request created, cancelled, completed, failed
    - Car dispatched, dispatch completed, failed, cancelled
    """
    
    ACTION_CHOICES = [
        ('REQUEST_CREATED', 'Request Created'),
        ('REQUEST_CANCELLED', 'Request Cancelled'),
        ('REQUEST_LOADED', 'Request Loaded'),
        ('REQUEST_DISPATCHED', 'Request Dispatched'),
        ('REQUEST_DELIVERED', 'Request Delivered'),
        ('REQUEST_RETURNED', 'Request Returned'),
        ('REQUEST_FAILED', 'Request Failed'),
        ('CAR_DISPATCHED', 'Car Dispatched'),
        ('CAR_DISPATCH_SUCCESS', 'Car Dispatch Success'),
        ('CAR_DISPATCH_CANCELLED', 'Car Dispatch Cancelled'),
        ('CAR_DISPATCH_FAILED', 'Car Dispatch Failed'),
    ]
    
    OUTCOME_CHOICES = [
        ('SUCCESS', 'Success'),
        ('CANCELLED', 'Cancelled'),
        ('FAILED', 'Failed'),
        ('PENDING', 'Pending'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='activity_logs',
        help_text="The user who performed the action",
    )
    
    transport_request = models.ForeignKey(
        'transport.TransportRequest',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='activity_logs',
        help_text="The transport request involved in this action",
    )
    
    car_dispatch = models.ForeignKey(
        CarDispatch,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='activity_logs',
        help_text="The car dispatch event (if applicable)",
    )
    
    action_type = models.CharField(max_length=30, choices=ACTION_CHOICES)
    
    outcome = models.CharField(max_length=15, choices=OUTCOME_CHOICES, default='PENDING')
    
    # Denormalized fields for faster filtering
    user_role = models.CharField(
        max_length=20,
        blank=True,
        default='',
        help_text="User role at time of action (DOCTOR, ADMIN, STORAGE_EMPLOYEE)",
    )
    
    car = models.ForeignKey(
        'cars.Car',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='+',  # No reverse relation
        help_text="Car involved in the action (denormalized)",
    )
    
    sample_code = models.CharField(
        max_length=100,
        blank=True,
        default='',
        help_text="Sample code (denormalized for fast lookup)",
    )
    
    notes = models.TextField(
        blank=True,
        default='',
        help_text="Additional context about this action",
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = 'User Activity Log'
        verbose_name_plural = 'User Activity Logs'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['created_at', 'action_type']),
            models.Index(fields=['user', 'created_at']),
            models.Index(fields=['action_type', 'outcome', 'created_at']),
            models.Index(fields=['car', 'created_at']),
        ]
    
    def __str__(self):
        return f"Activity {self.id} | User: {self.user_id} | Action: {self.action_type}"
