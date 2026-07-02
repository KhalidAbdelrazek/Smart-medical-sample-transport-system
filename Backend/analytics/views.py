"""
analytics/views.py

Single unified dashboard endpoint for all roles.
GET /api/analytics/dashboard/

Role is determined from the JWT access token.
Dispatches to the appropriate aggregation function in analytics_service.
"""
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from drf_spectacular.utils import extend_schema, OpenApiParameter, inline_serializer
from rest_framework import serializers

from common.utils.response import unified_response
from analytics.services.analytics_service import (
    get_doctor_dashboard,
    get_storage_employee_dashboard,
    get_admin_dashboard,
)


class DashboardView(APIView):
    """
    GET /api/analytics/dashboard/

    Unified real-time analytics dashboard.

    Role-based response (determined from JWT token):
    - DOCTOR         → own request statistics for the period
    - STORAGE_EMPLOYEE → own log action statistics for the period
    - ADMIN          → system-wide aggregated stats for all doctors and storage employees

    Query parameters:
        period  (str)  week | month (default) | year | all_time
    """
    permission_classes = [IsAuthenticated]

    @extend_schema(
        tags=['Analytics'],
        summary='Unified analytics dashboard',
        description=(
            'Returns real-time aggregated statistics based on the caller\'s role.\n\n'
            '- **DOCTOR**: own TransportRequest counts for the period\n'
            '- **STORAGE_EMPLOYEE**: own StorageEmployeeLog action counts for the period\n'
            '- **ADMIN**: system-wide aggregation across all doctors and storage employees\n\n'
            'All data is queried live from the database — no caching, no precomputed values.'
        ),
        parameters=[
            OpenApiParameter(
                name='period',
                type=str,
                enum=['week', 'month', 'year', 'all_time'],
                default='month',
                description='Time period to aggregate over (default: current month)',
            )
        ],
    )
    def get(self, request):
        period = request.query_params.get('period', 'month')

        # Validate period
        valid_periods = {'week', 'month', 'year', 'all_time'}
        if period not in valid_periods:
            return unified_response(
                success=False,
                message=f'Invalid period. Must be one of: {", ".join(sorted(valid_periods))}',
                errors={'invalid_period': period},
                status=400,
            )

        role = request.user.role

        if role == 'DOCTOR':
            data = get_doctor_dashboard(user=request.user, period=period)

        elif role == 'STORAGE_EMPLOYEE':
            data = get_storage_employee_dashboard(user=request.user, period=period)

        elif role == 'ADMIN':
            data = get_admin_dashboard(period=period)

        else:
            return unified_response(
                success=False,
                message='Your account role is not supported for dashboard analytics.',
                errors={'unsupported_role': role},
                status=403,
            )

        return unified_response(
            success=True,
            message='Dashboard analytics retrieved successfully',
            data=data,
        )
