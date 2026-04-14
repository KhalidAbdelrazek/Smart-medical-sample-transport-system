"""
stats/serializers.py

DTOs and serializers for statistics API endpoints.
"""
from rest_framework import serializers
from drf_spectacular.utils import extend_schema_field
from drf_spectacular.types import OpenApiTypes


class OverviewStatsSerializer(serializers.Serializer):
    """System overview statistics."""
    requests = serializers.DictField(
        help_text="Request statistics: {total, delivered, returned, cancelled, failed}"
    )
    dispatches = serializers.DictField(
        help_text="Dispatch statistics: {total, success, cancelled, failed}"
    )
    active_users_count = serializers.IntegerField(
        help_text="Number of unique users with activity in the period"
    )
    active_cars_count = serializers.IntegerField(
        help_text="Number of unique cars with activity in the period"
    )


class UserActivityStatsSerializer(serializers.Serializer):
    """Per-user activity statistics."""
    user_id = serializers.UUIDField(help_text="User ID")
    name = serializers.CharField(help_text="User full name")
    role = serializers.CharField(help_text="User role (DOCTOR, ADMIN, STORAGE_EMPLOYEE)")
    request_count = serializers.IntegerField(help_text="Total requests by this user")
    success_count = serializers.IntegerField(help_text="Delivered + Returned requests")
    cancelled_count = serializers.IntegerField(help_text="Cancelled requests")
    failed_count = serializers.IntegerField(help_text="Failed requests")


class TopUserSerializer(serializers.Serializer):
    """Top users by request count."""
    user_id = serializers.UUIDField(help_text="User ID")
    name = serializers.CharField(help_text="User full name")
    role = serializers.CharField(help_text="User role")
    request_count = serializers.IntegerField(help_text="Total request count")
    success_count = serializers.IntegerField(help_text="Successful outcomes count")
    cancelled_count = serializers.IntegerField(help_text="Cancelled count")
    failed_count = serializers.IntegerField(help_text="Failed count")


class CarUtilizationSerializer(serializers.Serializer):
    """Per-car utilization statistics."""
    car_id = serializers.UUIDField(help_text="Car ID")
    car_number = serializers.CharField(help_text="Car identifier/number")
    total_dispatches = serializers.IntegerField(help_text="Total dispatch events")
    success_dispatches = serializers.IntegerField(help_text="Successful dispatchs")
    failed_dispatches = serializers.IntegerField(help_text="Failed dispatches")
    cancelled_dispatches = serializers.IntegerField(help_text="Cancelled dispatches")
    utilization_rate = serializers.FloatField(
        help_text="Percentage of successful dispatches (0-100)"
    )


class TimeseriesPointSerializer(serializers.Serializer):
    """Single point in a timeseries."""
    date = serializers.DateField(help_text="Date for this data point")
    count = serializers.IntegerField(help_text="Count for this date")


class StatsFilterSerializer(serializers.Serializer):
    """Shared filter parameters for statistics endpoints."""
    start_date = serializers.DateField(required=False, help_text="Start date (inclusive)")
    end_date = serializers.DateField(required=False, help_text="End date (inclusive)")
    granularity = serializers.ChoiceField(
        choices=['day', 'week', 'month'],
        required=False,
        default='day',
        help_text="Aggregation granularity for timeseries"
    )
    role = serializers.ChoiceField(
        choices=['DOCTOR', 'ADMIN', 'STORAGE_EMPLOYEE'],
        required=False,
        allow_null=True,
        help_text="Filter by user role"
    )
    car_id = serializers.UUIDField(required=False, allow_null=True, help_text="Filter by car ID")
    limit = serializers.IntegerField(required=False, default=10, min_value=1, max_value=100, help_text="Limit for top-N queries")
