"""
transport/admin.py
"""
from django.contrib import admin
from .models import TransportRequest


@admin.register(TransportRequest)
class TransportRequestAdmin(admin.ModelAdmin):
    list_display = ('id', 'sample', 'requested_by', 'room_number', 'request_type', 'batch_id', 'status', 'assigned_car', 'created_at')
    list_filter = ('request_type', 'status')
    search_fields = ('room_number', 'batch_id')
    raw_id_fields = ('sample', 'requested_by', 'assigned_car')
