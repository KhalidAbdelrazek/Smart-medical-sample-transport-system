"""
analytics/views.py

API views for request analytics endpoints.
- GET /api/analytics/requests/ - User and admin analytics (with different filter capabilities)
- GET /api/analytics/storage-employees/logs/ - Storage employee log analytics
"""
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.exceptions import ValidationError

from drf_spectacular.utils import extend_schema

from accounts.permissions import IsAdminRole, IsStorageEmployee
from common.utils.response import unified_response
from analytics import services
from analytics.serializers import (
    RequestAnalyticsFilterSerializer,
    RequestAnalyticsResponseSerializer,
    StorageEmployeeLogsFilterSerializer,
    StorageEmployeeLogsResponseSerializer,
)


class RequestAnalyticsView(APIView):
    """
    GET /api/analytics/requests/
    
    User request analytics endpoint.
    - Doctors see only their own request analytics
    - Admins can filter by role or specific user
    """
    permission_classes = [IsAuthenticated]

    @extend_schema(
        tags=['Request Analytics'],
        summary='Get request analytics (user or admin)',
        description='Returns aggregated request statistics and time-series data. '
                    'Doctors see only their own data. Admins can filter by role or user.',
        parameters=[RequestAnalyticsFilterSerializer],
        responses=RequestAnalyticsResponseSerializer,
    )
    def get(self, request):
        """
        Handle GET request for analytics.
        
        Query Parameters:
            - granularity: 'day', 'month', 'year' (default: 'day')
            - start_date: ISO date (YYYY-MM-DD)
            - end_date: ISO date (YYYY-MM-DD)
            - role: 'DOCTOR', 'STORAGE_EMPLOYEE', 'ADMIN' (admin only)
            - user_id: UUID of specific user (admin only)
            - search: search by user name/email (admin only)
        """
        # Parse and validate filter parameters
        filter_serializer = RequestAnalyticsFilterSerializer(data=request.query_params)
        filter_serializer.is_valid(raise_exception=True)
        params = filter_serializer.validated_data

        # Extract filters
        start_date = params.get('start_date')
        end_date = params.get('end_date')
        granularity = params.get('granularity', 'day')
        role = params.get('role')
        user_id = params.get('user_id')
        search = params.get('search')

        # Validate date range
        if start_date and end_date and start_date > end_date:
            raise ValidationError("start_date must be less than or equal to end_date.")

        # Permission check: non-admin users can only see their own data
        if request.user.role != 'ADMIN':
            # Non-admin users cannot filter by role or user_id
            if role or user_id:
                return unified_response(
                    success=False,
                    message='You do not have permission to filter by role or user_id',
                    errors={'permission_denied': 'Only admins can use these filters'},
                    status=403,
                )
            # Non-admin users can only see their own data
            user_id = str(request.user.id)
        elif request.user.role == 'STORAGE_EMPLOYEE':
            user_id = str(request.user.id)
            search = None  # Employees cannot use search param
        else:
            return unified_response(
                success=False,
                message='You do not have permission for this analytics view',
                errors={'permission_denied': 'Forbidden'},
                status=403,
            )

        # Get analytics data
        data = services.get_request_analytics(
            start_date=start_date,
            end_date=end_date,
            granularity=granularity,
            role=role,
            user_id=user_id,
            search=search,
        )

        # Serialize response
        serializer = RequestAnalyticsResponseSerializer(data)
        
        return unified_response(
            success=True,
            message='Request analytics retrieved successfully',
            data=serializer.data,
        )


class StorageEmployeeLogsAnalyticsView(APIView):
    """
    GET /api/analytics/storage-employees/logs/
    Analytics for storage employee log actions (admin or own).
    """
    permission_classes = [IsAuthenticated]

    @extend_schema(
        tags=['Storage Employee Analytics'],
        summary='Get storage employee log analytics',
        description=(
            'Summary and timeseries for storage employee log actions. '
            'Admins can filter by employee, action, search; storage employees see only their own.'
        ),
        parameters=[StorageEmployeeLogsFilterSerializer],
        responses=StorageEmployeeLogsResponseSerializer,
    )
    def get(self, request):
        filter_serializer = StorageEmployeeLogsFilterSerializer(data=request.query_params)
        filter_serializer.is_valid(raise_exception=True)
        params = filter_serializer.validated_data
        start_date = params.get('start_date')
        end_date = params.get('end_date')
        granularity = params.get('granularity', 'day')
        action = params.get('action')
        employee_id = params.get('employee_id')
        search = params.get('search')

        # Permissions
        if request.user.role == 'ADMIN':
            # Admin can filter by anything
            pass
        elif request.user.role == 'STORAGE_EMPLOYEE':
            employee_id = str(request.user.id)
            search = None  # Employees cannot use search param
        else:
            return unified_response(
                success=False,
                message='You do not have permission for this analytics view',
                errors={'permission_denied': 'Forbidden'},
                status=403,
            )
        
        # Validate date range
        if start_date and end_date and start_date > end_date:
            return unified_response(
                success=False,
                message='start_date must be less than or equal to end_date.',
                errors={'invalid_date_range': 'start_date > end_date'},
                status=400,
            )

        data = services.get_storage_employee_logs_analytics(
            start_date=start_date,
            end_date=end_date,
            granularity=granularity,
            employee_id=employee_id,
            search=search,
            action=action,
        )
        serializer = StorageEmployeeLogsResponseSerializer(data)
        return unified_response(
            success=True,
            message="Storage employee logs retrieved successfully",
            data=serializer.data,
        )
