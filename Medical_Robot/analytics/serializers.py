"""
analytics/serializers.py

Serializers for request analytics API endpoints.
"""
from rest_framework import serializers


class StorageEmployeeLogsFilterSerializer(serializers.Serializer):
    start_date = serializers.DateField(required=False, help_text="Start date (YYYY-MM-DD)")
    end_date = serializers.DateField(required=False, help_text="End date (YYYY-MM-DD)")
    granularity = serializers.ChoiceField(choices=["day", "month", "year"], required=False, default="day", help_text="Aggregation granularity for timeseries")
    action = serializers.ChoiceField(
        choices=[
            ('CAR_DISPATCH', 'Car Dispatch'),
            ('SAMPLE_REMOVED_FROM_CAR', 'Sample Removed From Car'),
            ('SAMPLE_ADDED_TO_CAR', 'Sample Added To Car'),
            ('CAR_STATUS_UPDATE', 'Car Status Update'),
            ('TRANSPORT_REQUEST_UPDATE', 'Transport Request Update'),
            ('OTHER', 'Other'),
        ],
        required=False,
        allow_null=True,
        help_text="Filter by action type (optional)"
    )
    employee_id = serializers.UUIDField(required=False, allow_null=True, help_text="Filter by storage employee ID (admin only)")
    search = serializers.CharField(required=False, allow_blank=True, help_text="Search by user name or email (admin only)")


class StorageEmployeeLogsSummarySerializer(serializers.Serializer):
    total_actions = serializers.IntegerField()
    car_dispatch = serializers.IntegerField()
    sample_removed_from_car = serializers.IntegerField()
    sample_added_to_car = serializers.IntegerField()
    car_status_update = serializers.IntegerField()
    transport_request_update = serializers.IntegerField()
    other = serializers.IntegerField()


class StorageEmployeeLogsTimeseriesSerializer(serializers.Serializer):
    period = serializers.CharField(help_text="Period label (YYYY-MM-DD, YYYY-MM, YYYY)")
    total = serializers.IntegerField()
    car_dispatch = serializers.IntegerField()
    sample_removed_from_car = serializers.IntegerField()
    sample_added_to_car = serializers.IntegerField()
    car_status_update = serializers.IntegerField()
    transport_request_update = serializers.IntegerField()
    other = serializers.IntegerField()


class StorageEmployeeLogsResponseSerializer(serializers.Serializer):
    summary = StorageEmployeeLogsSummarySerializer()
    timeseries = StorageEmployeeLogsTimeseriesSerializer(many=True)

class RequestAnalyticsFilterSerializer(serializers.Serializer):
    """Filter parameters for request analytics endpoints."""
    start_date = serializers.DateField(
        required=False,
        help_text="Start date (inclusive, ISO format: YYYY-MM-DD)"
    )
    end_date = serializers.DateField(
        required=False,
        help_text="End date (inclusive, ISO format: YYYY-MM-DD)"
    )
    granularity = serializers.ChoiceField(
        choices=['day', 'month', 'year'],
        required=False,
        default='day',
        help_text="Aggregation granularity for timeseries"
    )
    role = serializers.ChoiceField(
        choices=['DOCTOR', 'STORAGE_EMPLOYEE', 'ADMIN'],
        required=False,
        allow_null=True,
        help_text="Filter by user role (admin only)"
    )
    user_id = serializers.UUIDField(
        required=False,
        allow_null=True,
        help_text="Filter by specific user ID (admin only)"
    )
    search = serializers.CharField(
        required=False,
        allow_blank=True,
        help_text="Search by user name or email (case-insensitive, admin only)"
    )


class RequestSummarySerializer(serializers.Serializer):
    """Aggregated request statistics summary."""
    total_requests = serializers.IntegerField(
        help_text="Total number of requests in the period"
    )
    succeeded = serializers.IntegerField(
        help_text="Number of delivered requests"
    )
    failed = serializers.IntegerField(
        help_text="Number of failed requests"
    )
    cancelled = serializers.IntegerField(
        help_text="Number of cancelled requests"
    )
    returned = serializers.IntegerField(
        help_text="Number of returned requests"
    )


class TimeseriesPointSerializer(serializers.Serializer):
    """Single point in a timeseries with all status categories."""
    period = serializers.CharField(
        help_text="Period label (YYYY-MM-DD for day, YYYY-MM for month, YYYY for year)"
    )
    total = serializers.IntegerField(
        help_text="Total requests in this period"
    )
    succeeded = serializers.IntegerField(
        help_text="Delivered requests in this period"
    )
    failed = serializers.IntegerField(
        help_text="Failed requests in this period"
    )
    cancelled = serializers.IntegerField(
        help_text="Cancelled requests in this period"
    )
    returned = serializers.IntegerField(
        help_text="Returned requests in this period"
    )


class RequestAnalyticsResponseSerializer(serializers.Serializer):
    """Response serializer for request analytics endpoints."""
    summary = RequestSummarySerializer(
        help_text="Aggregated statistics for the entire period"
    )
    timeseries = TimeseriesPointSerializer(
        many=True,
        help_text="Time-series breakdown of requests by period"
    )
