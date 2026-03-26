"""
transport/admin.py
"""
from django.contrib import admin
from .models import TransportRequest


@admin.register(TransportRequest)
class TransportRequestAdmin(admin.ModelAdmin):
    list_display = ('id', 'sample', 'requested_by', 'room_number', 'assigned_car', 'status', 'created_at')
    list_filter = ('status',)
    search_fields = ('room_number',)
    raw_id_fields = ('sample', 'requested_by', 'assigned_car')
