from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Employee, EmployeeStatistics


@receiver(post_save, sender=Employee)
def create_employee_statistics(sender, instance, created, **kwargs):
    
    if created:
        EmployeeStatistics.objects.create(employee=instance)