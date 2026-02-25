import uuid
from django.db import models
from django.utils import timezone
from datetime import timedelta
# Create your models here.

  
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