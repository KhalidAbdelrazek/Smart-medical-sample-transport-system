"""
stats/serializers.py

DTOs and serializers for statistics API endpoints.
"""
from rest_framework import serializers


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
    date = serializers.DateTimeField(help_text="Activity date (truncated)")
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


class TopUsersByRoleSerializer(serializers.Serializer):
    """Top users grouped by user role."""
    ADMIN = TopUserSerializer(many=True)
    DOCTOR = TopUserSerializer(many=True)
    STORAGE_EMPLOYEE = TopUserSerializer(many=True)


class CarUtilizationSerializer(serializers.Serializer):
    """Per-car utilization statistics."""
    car_id = serializers.UUIDField(help_text="Car ID")
    car_number = serializers.CharField(help_text="Car identifier/number")
    total_dispatches = serializers.IntegerField(help_text="Total dispatch events")
    success_dispatches = serializers.IntegerField(help_text="Successful dispatches")
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
    car_id = serializers.IntegerField(required=False, allow_null=True, help_text="Filter by car ID")
    top = serializers.IntegerField(required=False, default=10, min_value=1, max_value=100, help_text="Limit for top-N queries")
    page = serializers.IntegerField(required=False, default=1, min_value=1, help_text="Page number for user activity")
    page_size = serializers.IntegerField(required=False, default=20, min_value=1, max_value=100, help_text="Page size for user activity")


class UserActivityPaginationSerializer(serializers.Serializer):
    """Pagination metadata for user activity."""
    page = serializers.IntegerField()
    page_size = serializers.IntegerField()
    total_count = serializers.IntegerField()


class UnifiedAdminStatsResponseSerializer(serializers.Serializer):
    """Unified response serializer for the consolidated admin stats endpoint."""
    overview = OverviewStatsSerializer()
    requests_timeseries = TimeseriesPointSerializer(many=True)
    user_activity = UserActivityStatsSerializer(many=True)
    user_activity_pagination = UserActivityPaginationSerializer()
    top_users = TopUsersByRoleSerializer()
    car_utilization = CarUtilizationSerializer(many=True)
