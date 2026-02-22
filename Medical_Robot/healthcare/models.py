import uuid
from django.db import models
from django.utils import timezone
from datetime import timedelta
# Create your models here.

class Patient(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100)
    age = models.IntegerField()
    gender = models.CharField(max_length=10)
    description = models.TextField(max_length=500, null=True, blank=True)
    phone = models.CharField(max_length=15)
    email = models.EmailField()
    password = models.CharField(max_length=100)
    city = models.CharField(max_length=50)
    address = models.CharField(max_length=100)
    zip_code = models.CharField(max_length=10)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return self.name


class Staff(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100)
    age = models.IntegerField()
    gender = models.CharField(max_length=10)
    role = models.CharField(max_length=50)
    phone = models.CharField(max_length=15)
    city = models.CharField(max_length=50)
    address = models.CharField(max_length=100)
    zip_code = models.CharField(max_length=10)
    email = models.EmailField()
    password = models.CharField(max_length=100)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return self.name

  
class SensorReading(models.Model):
    STATE_CHOICES = [
        ('ON', 'On'),
        ('OFF', 'Off'),
    ]
        
    cart = models.CharField(max_length=50, blank=True, null=True)
    
    position = models.CharField(max_length=10, blank=True, null=True)
    
    load = models.CharField(max_length=10, blank=True, null=True)

    state = models.CharField(max_length=10, choices=STATE_CHOICES, default='OFF')

    time = models.DateTimeField(auto_now_add=True)
        
    # cutoff_date = timezone.now() - timedelta(hours=1)
    # deleted_count, _ = SensorReading.objects.filter(
    #     time__lt=cutoff_date
    # ).delete()
    
    # if deleted_count > 0:
    #     print(f"Cleaned up {deleted_count} old readings")
        
    def __str__(self):
        return f"{self.cart}: {self.state}"       