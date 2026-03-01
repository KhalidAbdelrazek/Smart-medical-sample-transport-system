"""
cars/models.py

Car model for the automated blood sample transport vehicles.
"""
from django.db import models


class Car(models.Model):
    """
    Represents a transport car (robot cart) in the system.
    Status lifecycle: IDLE → LOADING → DISPATCHED → IDLE (after delivery)
    """

    STATUS_CHOICES = [
        ('IDLE', 'Idle'),
        ('LOADING', 'Loading'),
        ('DISPATCHED', 'Dispatched'),
    ]

    car_number = models.CharField(max_length=50, unique=True, help_text="Unique car identifier, e.g. CAR-01")
    status = models.CharField(max_length=15, choices=STATUS_CHOICES, default='IDLE')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Car'
        verbose_name_plural = 'Cars'
        ordering = ['car_number']

    def __str__(self):
        return f"Car {self.car_number} [{self.status}]"
