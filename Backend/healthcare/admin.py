from django.contrib import admin
from .models import SensorReading
# Register your models here.

@admin.register(SensorReading)
class SensorReadingAdmin(admin.ModelAdmin):
    list_display = ('id', 'cart', 'state', 'time')
    readonly_fields = ('id', 'time')
