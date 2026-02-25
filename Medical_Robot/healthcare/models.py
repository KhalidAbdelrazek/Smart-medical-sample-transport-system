import uuid
from django.db import models
from django.utils import timezone
from datetime import timedelta
# Create your models here.

class Patient(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False, help_text="Unique UUID for the patient.")
    name = models.CharField(max_length=100, help_text="The patient's full name.")
    age = models.IntegerField(help_text="The patient's age in years.")
    gender = models.CharField(max_length=10, help_text="The patient's gender (e.g., Male, Female).")
    description = models.TextField(max_length=500, null=True, blank=True, help_text="Additional medical details or notes about the patient.")
    phone = models.CharField(max_length=15, help_text="Primary contact number for the patient.")
    email = models.EmailField(help_text="Patient's email address.")
    password = models.CharField(max_length=100, help_text="Hashed password for patient login.")
    city = models.CharField(max_length=50, help_text="City of residence.")
    address = models.CharField(max_length=100, help_text="Full street address.")
    zip_code = models.CharField(max_length=10, help_text="Postal zip code.")
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return self.name


class Staff(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False, help_text="Unique UUID for the staff member.")
    name = models.CharField(max_length=100, help_text="The full name of the staff member.")
    age = models.IntegerField(help_text="The staff member's age in years.")
    gender = models.CharField(max_length=10, help_text="The staff member's gender.")
    role = models.CharField(max_length=50, help_text="The medical or administrative role of the staff member.")
    phone = models.CharField(max_length=15, help_text="Primary contact number.")
    city = models.CharField(max_length=50, help_text="City of residence.")
    address = models.CharField(max_length=100, help_text="Full street address.")
    zip_code = models.CharField(max_length=10, help_text="Postal zip code.")
    email = models.EmailField(help_text="Staff member's email address.")
    password = models.CharField(max_length=100, help_text="Hashed password for staff login.")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return self.name

  
class SensorReading(models.Model):
    # STATE_CHOICES = [
    #     ('C', 'C')
    # ]
        
    cart = models.CharField(max_length=50, blank=True, null=True, help_text="Identifier for the robot cart.")
    
    position = models.CharField(max_length=10, blank=True, null=True, help_text="Current physical position of the cart.")
    
    load = models.CharField(max_length=10, blank=True, null=True, help_text="Current load status or weight.")

    state = models.CharField(max_length=10, help_text="The current operational state of the cart (e.g., 'C' for complete/call).")

    time = models.DateTimeField(auto_now_add=True)

    # if state != 'C':
    #     print("The cart is not in the correct position")
    # else:
    #     print("The cart is in the correct position")

    # cutoff_date = timezone.now() - timedelta(hours=1)
    # deleted_count, _ = SensorReading.objects.filter(
    #     time__lt=cutoff_date
    # ).delete()
    
    # if deleted_count > 0:
    #     print(f"Cleaned up {deleted_count} old readings")
        
    def __str__(self):
        return f"{self.cart}: {self.state}"       