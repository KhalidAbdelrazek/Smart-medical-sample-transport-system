"""
stats/views.py

Admin-only statistics API views.
All endpoints require IsAuthenticated + IsAdminRole permission.
"""
from datetime import date, datetime
from typing import Optional

from rest_framework import status
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.exceptions import ValidationError, PermissionDenied

from drf_spectacular.utils import extend_schema, OpenApiParameter, OpenApiTypes

from accounts.permissions import IsAdminRole
from common.utils.response import unified_response
from stats import services
from stats.serializers import (
    OverviewStatsSerializer,
    UserActivityStatsSerializer,
    TopUserSerializer,
    CarUtilizationSerializer,
    TimeseriesPointSerializer,
    StatsFilterSerializer,
)


@extend_schema(
    tags=['Admin Statistics'],
    summary='Get system overview statistics',
    description='Returns aggregated metrics for requests, dispatches, active users, and cars.',
    parameters=[
        OpenApiParameter('start_date', OpenApiTypes.DATE, OpenApiParameter.QUERY, description='Start date (YYYY-MM-DD)'),
        OpenApiParameter('end_date', OpenApiTypes.DATE, OpenApiParameter.QUERY, description='End date (YYYY-MM-DD)'),
    ],
    responses=OverviewStatsSerializer,
)
class AdminOverviewView(APIView):
    """
    GET /api/admin/stats/overview/
    
    System summary endpoint with optional date range filtering.
    Requires admin role.
    """
    permission_classes = [IsAuthenticated, IsAdminRole]
    
    def get(self, request):
        start_date = self._parse_date(request.query_params.get('start_date'))
        end_date = self._parse_date(request.query_params.get('end_date'))
        
        self._validate_date_range(start_date, end_date)
        
        data = services.get_overview_stats(start_date, end_date)
        
        return unified_response(
            success=True,
            message='Overview statistics retrieved successfully',
            data=data,
        )
    
    def _parse_date(self, date_str: Optional[str]) -> Optional[date]:
        """Parse date string safely."""
        if not date_str:
            return None
        try:
            return datetime.strptime(date_str, '%Y-%m-%d').date()
        except ValueError:
            raise ValidationError(f"Invalid date format: {date_str}. Expected YYYY-MM-DD.")
    
    def _validate_date_range(self, start_date: Optional[date], end_date: Optional[date]):
        """Validate that start_date <= end_date."""
        if start_date and end_date and start_date > end_date:
            raise ValidationError("start_date must be less than or equal to end_date.")


@extend_schema(
    tags=['Admin Statistics'],
    summary='Get user activity statistics',
    description='Returns per-user request activity with pagination support.',
    parameters=[
        OpenApiParameter('start_date', OpenApiTypes.DATE, OpenApiParameter.QUERY),
        OpenApiParameter('end_date', OpenApiTypes.DATE, OpenApiParameter.QUERY),
        OpenApiParameter('granularity', OpenApiTypes.STR, OpenApiParameter.QUERY, enum=['day', 'week', 'month']),
        OpenApiParameter('role', OpenApiTypes.STR, OpenApiParameter.QUERY, enum=['DOCTOR', 'ADMIN', 'STORAGE_EMPLOYEE']),
    ],
    responses=UserActivityStatsSerializer(many=True),
)
class AdminUserActivityView(APIView):
    """
    GET /api/admin/stats/users/activity/
    
    Per-user activity statistics with pagination.
    Requires admin role.
    """
    permission_classes = [IsAuthenticated, IsAdminRole]
    
    def get(self, request):
        start_date = self._parse_date(request.query_params.get('start_date'))
        end_date = self._parse_date(request.query_params.get('end_date'))
        granularity = request.query_params.get('granularity', 'day')
        role = request.query_params.get('role')
        
        self._validate_date_range(start_date, end_date)
        self._validate_granularity(granularity)
        self._validate_role(role)
        
        queryset = services.get_user_activity_stats(start_date, end_date, role, granularity)
        
        # Apply pagination manually since this is a custom queryset
        # page = self.paginate_queryset(queryset)
        # if page is not None:
        #     return self.get_paginated_response(page)
        
        return unified_response(
            success=True,
            message='User activity statistics retrieved successfully',
            data=list(queryset),
        )
    
    def _parse_date(self, date_str: Optional[str]) -> Optional[date]:
        if not date_str:
            return None
        try:
            return datetime.strptime(date_str, '%Y-%m-%d').date()
        except ValueError:
            raise ValidationError(f"Invalid date format: {date_str}. Expected YYYY-MM-DD.")
    
    def _validate_date_range(self, start_date: Optional[date], end_date: Optional[date]):
        if start_date and end_date and start_date > end_date:
            raise ValidationError("start_date must be less than or equal to end_date.")
    
    def _validate_granularity(self, granularity: str):
        if granularity not in ['day', 'week', 'month']:
            raise ValidationError(f"Invalid granularity: {granularity}. Must be day, week, or month.")
    
    def _validate_role(self, role: Optional[str]):
        if role and role not in ['DOCTOR', 'ADMIN', 'STORAGE_EMPLOYEE']:
            raise ValidationError(f"Invalid role: {role}. Must be DOCTOR, ADMIN, or STORAGE_EMPLOYEE.")


@extend_schema(
    tags=['Admin Statistics'],
    summary='Get top users by request count',
    description='Returns top N users ranked by request count.',
    parameters=[
        OpenApiParameter('start_date', OpenApiTypes.DATE, OpenApiParameter.QUERY),
        OpenApiParameter('end_date', OpenApiTypes.DATE, OpenApiParameter.QUERY),
        OpenApiParameter('role', OpenApiTypes.STR, OpenApiParameter.QUERY, enum=['DOCTOR', 'ADMIN', 'STORAGE_EMPLOYEE']),
        OpenApiParameter('limit', OpenApiTypes.INT, OpenApiParameter.QUERY, description='Number of top users to return'),
    ],
    responses=TopUserSerializer(many=True),
)
class AdminTopUsersView(APIView):
    """
    GET /api/admin/stats/users/top/
    
    Top users by request count.
    Requires admin role.
    """
    permission_classes = [IsAuthenticated, IsAdminRole]
    
    def get(self, request):
        start_date = self._parse_date(request.query_params.get('start_date'))
        end_date = self._parse_date(request.query_params.get('end_date'))
        role = request.query_params.get('role')
        limit = int(request.query_params.get('limit', 10))
        
        self._validate_date_range(start_date, end_date)
        self._validate_role(role)
        
        users = services.get_top_users(start_date, end_date, role, limit)
        
        return unified_response(
            success=True,
            message='Top users retrieved successfully',
            data=list(users),
        )
    
    def _parse_date(self, date_str: Optional[str]) -> Optional[date]:
        if not date_str:
            return None
        try:
            return datetime.strptime(date_str, '%Y-%m-%d').date()
        except ValueError:
            raise ValidationError(f"Invalid date format: {date_str}. Expected YYYY-MM-DD.")
    
    def _validate_date_range(self, start_date: Optional[date], end_date: Optional[date]):
        if start_date and end_date and start_date > end_date:
            raise ValidationError("start_date must be less than or equal to end_date.")
    
    def _validate_role(self, role: Optional[str]):
        if role and role not in ['DOCTOR', 'ADMIN', 'STORAGE_EMPLOYEE']:
            raise ValidationError(f"Invalid role: {role}. Must be DOCTOR, ADMIN, or STORAGE_EMPLOYEE.")


@extend_schema(
    tags=['Admin Statistics'],
    summary='Get request timeseries data',
    description='Returns total system requests over time with configurable granularity.',
    parameters=[
        OpenApiParameter('start_date', OpenApiTypes.DATE, OpenApiParameter.QUERY),
        OpenApiParameter('end_date', OpenApiTypes.DATE, OpenApiParameter.QUERY),
        OpenApiParameter('granularity', OpenApiTypes.STR, OpenApiParameter.QUERY, enum=['day', 'week', 'month']),
    ],
    responses=TimeseriesPointSerializer(many=True),
)
class AdminRequestsTimeseriesView(APIView):
    """
    GET /api/admin/stats/requests/timeseries/
    
    System-wide request timeseries.
    Requires admin role.
    """
    permission_classes = [IsAuthenticated, IsAdminRole]
    
    def get(self, request):
        start_date = self._parse_date(request.query_params.get('start_date'))
        end_date = self._parse_date(request.query_params.get('end_date'))
        granularity = request.query_params.get('granularity', 'day')
        
        self._validate_date_range(start_date, end_date)
        self._validate_granularity(granularity)
        
        timeseries = services.get_requests_timeseries(start_date, end_date, granularity)
        
        return unified_response(
            success=True,
            message='Request timeseries retrieved successfully',
            data=list(timeseries),
        )
    
    def _parse_date(self, date_str: Optional[str]) -> Optional[date]:
        if not date_str:
            return None
        try:
            return datetime.strptime(date_str, '%Y-%m-%d').date()
        except ValueError:
            raise ValidationError(f"Invalid date format: {date_str}. Expected YYYY-MM-DD.")
    
    def _validate_date_range(self, start_date: Optional[date], end_date: Optional[date]):
        if start_date and end_date and start_date > end_date:
            raise ValidationError("start_date must be less than or equal to end_date.")
    
    def _validate_granularity(self, granularity: str):
        if granularity not in ['day', 'week', 'month']:
            raise ValidationError(f"Invalid granularity: {granularity}. Must be day, week, or month.")


@extend_schema(
    tags=['Admin Statistics'],
    summary='Get car utilization statistics',
    description='Returns per-car dispatch metrics and utilization rates.',
    parameters=[
        OpenApiParameter('start_date', OpenApiTypes.DATE, OpenApiParameter.QUERY),
        OpenApiParameter('end_date', OpenApiTypes.DATE, OpenApiParameter.QUERY),
        OpenApiParameter('granularity', OpenApiTypes.STR, OpenApiParameter.QUERY, enum=['day', 'week', 'month']),
        OpenApiParameter('car_id', OpenApiTypes.UUID, OpenApiParameter.QUERY, description='Filter by specific car ID'),
    ],
    responses=CarUtilizationSerializer(many=True),
)
class AdminCarUtilizationView(APIView):
    """
    GET /api/admin/stats/cars/utilization/
    
    Per-car utilization metrics.
    Requires admin role.
    """
    permission_classes = [IsAuthenticated, IsAdminRole]
    
    def get(self, request):
        start_date = self._parse_date(request.query_params.get('start_date'))
        end_date = self._parse_date(request.query_params.get('end_date'))
        granularity = request.query_params.get('granularity', 'day')
        car_id = request.query_params.get('car_id')
        
        self._validate_date_range(start_date, end_date)
        self._validate_granularity(granularity)
        
        utilization = services.get_car_utilization(start_date, end_date, car_id, granularity)
        
        return unified_response(
            success=True,
            message='Car utilization retrieved successfully',
            data=list(utilization),
        )
    
    def _parse_date(self, date_str: Optional[str]) -> Optional[date]:
        if not date_str:
            return None
        try:
            return datetime.strptime(date_str, '%Y-%m-%d').date()
        except ValueError:
            raise ValidationError(f"Invalid date format: {date_str}. Expected YYYY-MM-DD.")
    
    def _validate_date_range(self, start_date: Optional[date], end_date: Optional[date]):
        if start_date and end_date and start_date > end_date:
            raise ValidationError("start_date must be less than or equal to end_date.")
    
    def _validate_granularity(self, granularity: str):
        if granularity not in ['day', 'week', 'month']:
            raise ValidationError(f"Invalid granularity: {granularity}. Must be day, week, or month.")
