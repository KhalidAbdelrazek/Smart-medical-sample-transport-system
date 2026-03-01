"""
samples/admin.py
"""
from django.contrib import admin
from .models import BloodSample


@admin.register(BloodSample)
class BloodSampleAdmin(admin.ModelAdmin):
    list_display = ('id', 'patient_name', 'patient_id', 'blood_type', 'status', 'is_in_storage', 'created_at')
    list_filter = ('status', 'blood_type', 'is_in_storage')
    search_fields = ('patient_name', 'patient_id')
    readonly_fields = ('id', 'created_at', 'updated_at')
