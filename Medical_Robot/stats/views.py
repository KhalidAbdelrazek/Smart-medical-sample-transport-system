"""
stats/views.py

Admin-only consolidated statistics API view.
Single endpoint: GET /api/admin/stats/
"""
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.exceptions import ValidationError

from drf_spectacular.utils import extend_schema

from accounts.permissions import IsAdminRole
from common.utils.response import unified_response
from stats import services
from stats.serializers import (
    StatsFilterSerializer,
    UnifiedAdminStatsResponseSerializer,
)



class AdminStatsView(APIView):
    """
    GET /api/admin/stats/

    Consolidated admin statistics endpoint.
    Returns: overview, requests_timeseries, user_activity (paginated), top_users, car_utilization.
    Requires admin role.
    """
    permission_classes = [IsAuthenticated, IsAdminRole]


    @extend_schema(
        tags=['Admin Statistics'],
        summary='Get consolidated admin statistics',
        description='Returns overview, timeseries, user activity (paginated), top users, and car utilization in one response.',
        parameters=[StatsFilterSerializer],
        responses=UnifiedAdminStatsResponseSerializer,
    )
    
    
    def get(self, request):
        filter_serializer = StatsFilterSerializer(data=request.query_params)
        filter_serializer.is_valid(raise_exception=True)
        params = filter_serializer.validated_data

        start_date = params.get('start_date')
        end_date = params.get('end_date')
        granularity = params.get('granularity', 'day')
        role = params.get('role')
        car_id = params.get('car_id')
        top = params.get('top', 10)
        page = params.get('page', 1)
        page_size = params.get('page_size', 20)

        if start_date and end_date and start_date > end_date:
            raise ValidationError("start_date must be less than or equal to end_date.")

        data = services.get_admin_stats(
            start_date=start_date,
            end_date=end_date,
            granularity=granularity,
            role=role,
            car_id=car_id,
            top=top,
            page=page,
            page_size=page_size,
        )

        return unified_response(
            success=True,
            message='Admin statistics retrieved successfully',
            data=data,
        )
