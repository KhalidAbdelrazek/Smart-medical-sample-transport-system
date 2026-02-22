from django.contrib import admin
from .models import Patient, Staff, SensorReading
# Register your models here.

admin.site.register(Patient)
admin.site.register(Staff)
admin.site.register(SensorReading)
