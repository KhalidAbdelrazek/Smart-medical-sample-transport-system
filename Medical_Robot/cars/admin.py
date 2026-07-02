"""
cars/admin.py
"""
from django.contrib import admin
from .models import Car


@admin.register(Car)
class CarAdmin(admin.ModelAdmin):
    list_display = ('id', 'car_number', 'status', 'capacity', 'created_at')
    list_filter = ('status',)
    search_fields = ('car_number',)
