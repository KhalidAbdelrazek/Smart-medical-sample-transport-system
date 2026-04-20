"""
analytics/serializers.py

Serializers for Swagger/OpenAPI documentation only.
The actual data comes directly from analytics_service aggregation dicts.
"""
from rest_framework import serializers


class DoctorDashboardSerializer(serializers.Serializer):
    """Response shape for DOCTOR role."""
    total_requests = serializers.IntegerField()
    successful_requests = serializers.IntegerField()
    failed_requests = serializers.IntegerField()
    cancelled_requests = serializers.IntegerField()
    pending_requests = serializers.IntegerField()
    success_rate = serializers.FloatField()
    period = serializers.CharField()
    role = serializers.CharField()


class StorageEmployeeDashboardSerializer(serializers.Serializer):
    """Response shape for STORAGE_EMPLOYEE role."""
    total_actions = serializers.IntegerField()
    car_dispatch = serializers.IntegerField()
    sample_added_to_car = serializers.IntegerField()
    sample_removed_from_car = serializers.IntegerField()
    transport_request_update = serializers.IntegerField()
    other = serializers.IntegerField()
    period = serializers.CharField()
    role = serializers.CharField()


class AdminDoctorsStatsSerializer(serializers.Serializer):
    total_requests = serializers.IntegerField()
    successful = serializers.IntegerField()
    failed = serializers.IntegerField()
    cancelled = serializers.IntegerField()
    pending = serializers.IntegerField()


class AdminStorageStatsSerializer(serializers.Serializer):
    total_actions = serializers.IntegerField()
    car_dispatch = serializers.IntegerField()
    sample_added = serializers.IntegerField()
    sample_removed = serializers.IntegerField()
    transport_updates = serializers.IntegerField()
    other = serializers.IntegerField()


class AdminDashboardSerializer(serializers.Serializer):
    """Response shape for ADMIN role."""
    period = serializers.CharField()
    role = serializers.CharField()
    doctors = AdminDoctorsStatsSerializer()
    storage = AdminStorageStatsSerializer()
