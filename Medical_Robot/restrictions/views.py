"""
restrictions/views.py

API views for the Restrictions System.
Includes endpoints for admins to set restrictions and a public status endpoint.
"""
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework import status
from drf_spectacular.utils import extend_schema, OpenApiExample, OpenApiParameter

from accounts.permissions import IsAdminRole
from common.utils.response import unified_response
from .serializers import (
    RestrictDoctorSamplesSerializer,
    RestrictStorageSamplesSerializer,
    RestrictTransportCarSerializer,
)
from .services import (
    apply_doctor_samples_restriction,
    apply_storage_samples_restriction,
    apply_transport_car_restriction,
    get_all_restriction_statuses,
    get_users_restriction_status,
)


class RestrictDoctorSamplesView(APIView):
    """
    POST /api/restrictions/restrict-doctor-samples/
    Set global, partial, or no restriction on doctor sample requests.
    Accessible by Admin only.
    """
    permission_classes = [IsAuthenticated, IsAdminRole]

    @extend_schema(
        tags=['Restrictions'],
        summary='Restrict Doctor Samples',
        description='Set a global or partial restriction on the "Request Sample" process for doctors.',
        request=RestrictDoctorSamplesSerializer,
        responses={200: OpenApiExample('Success Response', value={
            "success": True,
            "message": "Doctor samples restriction updated successfully.",
            "data": {
                "restriction_type": "DOCTOR_SAMPLES",
                "mode": "PARTIAL",
                "restricted_count": 2,
                "reason": "Emergency maintenance",
                "updated_at": "2026-04-23T20:00:00Z"
            }
        })},
    )
    def post(self, request):
        serializer = RestrictDoctorSamplesSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        result = apply_doctor_samples_restriction(
            restriction_type=serializer.validated_data['restriction_type'],
            user_ids=serializer.validated_data.get('user_ids', []),
            reason=serializer.validated_data.get('reason', ''),
            admin=request.user,
        )

        return unified_response(
            success=True,
            message="Doctor samples restriction updated successfully.",
            data=result,
            status=status.HTTP_200_OK
        )


class RestrictStorageSamplesView(APIView):
    """
    POST /api/restrictions/restrict-storage-samples/
    Set global, partial, or no restriction on storage sample loading.
    Accessible by Admin only.
    """
    permission_classes = [IsAuthenticated, IsAdminRole]

    @extend_schema(
        tags=['Restrictions'],
        summary='Restrict Storage Samples',
        description='Set a global or partial restriction on the sample loading process for warehouse employees.',
        request=RestrictStorageSamplesSerializer,
        responses={200: OpenApiExample('Success Response', value={
            "success": True,
            "message": "Storage samples restriction updated successfully.",
            "data": {
                "restriction_type": "STORAGE_SAMPLES",
                "mode": "GLOBAL",
                "restricted_count": 0,
                "reason": "Storage area cleaning",
                "updated_at": "2026-04-23T20:05:00Z"
            }
        })},
    )
    def post(self, request):
        serializer = RestrictStorageSamplesSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        result = apply_storage_samples_restriction(
            restriction_type=serializer.validated_data['restriction_type'],
            user_ids=serializer.validated_data.get('user_ids', []),
            reason=serializer.validated_data.get('reason', ''),
            admin=request.user,
        )

        return unified_response(
            success=True,
            message="Storage samples restriction updated successfully.",
            data=result,
            status=status.HTTP_200_OK
        )


class RestrictTransportCarView(APIView):
    """
    POST /api/restrictions/restrict-transport-car/
    Enable or disable a global restriction on car dispatch.
    Accessible by Admin only.
    """
    permission_classes = [IsAuthenticated, IsAdminRole]

    @extend_schema(
        tags=['Restrictions'],
        summary='Restrict Transport Car Dispatch',
        description='Set a global restriction on the "Dispatch" process to prevent any car from leaving.',
        request=RestrictTransportCarSerializer,
        responses={200: OpenApiExample('Success Response', value={
            "success": True,
            "message": "Transport car dispatch restriction updated.",
            "data": {
                "restriction_type": "TRANSPORT_CAR",
                "mode": "GLOBAL",
                "restricted_count": 0,
                "reason": "Inclement weather",
                "updated_at": "2026-04-23T20:10:00Z"
            }
        })},
    )
    def post(self, request):
        serializer = RestrictTransportCarSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        result = apply_transport_car_restriction(
            enabled=serializer.validated_data['status'],
            reason=serializer.validated_data.get('reason', ''),
            admin=request.user,
        )

        status_msg = "enabled" if serializer.validated_data['status'] else "lifted"
        return unified_response(
            success=True,
            message=f"Transport car dispatch restriction {status_msg}.",
            data=result,
            status=status.HTTP_200_OK
        )


class RestrictionStatusView(APIView):
    """
    GET /api/restrictions/status/
    Get the current status of all restrictions.
    Used for real-time synchronization on client devices.
    """
    permission_classes = [IsAuthenticated]

    @extend_schema(
        tags=['Restrictions'],
        summary='Get Restrictions Status',
        description=(
            'Returns current system restrictions for the requested categories. '
            'The "query" parameter is mandatory and can be a comma-separated list '
            'or multiple "query" parameters (e.g., ?query=doctor,storage,car).'
        ),
        parameters=[
            OpenApiParameter(
                name='query',
                type=str,
                location=OpenApiParameter.QUERY,
                description='Categories to fetch (doctor, storage, car)',
                required=True,
                enum=['doctor', 'storage', 'car']
            ),
        ],
        responses={200: OpenApiExample('Status Response', value={
            "success": True,
            "message": "Current system restrictions fetched successfully.",
            "data": {
                "doctor_samples": [
                    {"id": "...", "name": "Dr. Smith", "is_restricted": False},
                    {"id": "...", "name": "Dr. Doe", "is_restricted": True}
                ],
                "storage_samples": [
                    {"id": "...", "name": "Emp A", "is_restricted": False}
                ],
                "transport_car": {"mode": "ALL_UNRESTRICT", "is_restricted": False}
            }
        })},
    )
    def get(self, request):
        # Extract query parameters (handles ?query=a,b and ?query=a&query=b)
        query_raw = request.query_params.get('query', '')
        if not query_raw:
            return unified_response(
                success=False,
                message='The query list cannot be empty. Please select at least one category (doctor, storage, or car).',
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Split by comma and flatten multiple 'query' keys if they exist
        query_list = []
        for q in request.query_params.getlist('query'):
            query_list.extend([item.strip().lower() for item in q.split(',') if item.strip()])
        
        # Remove duplicates
        query_list = list(set(query_list))
        
        # Validate that at least one valid category is present
        valid_categories = {'doctor', 'storage', 'car'}
        if not any(cat in valid_categories for cat in query_list):
            return unified_response(
                success=False,
                message='The query list cannot be empty. Please select at least one category (doctor, storage, or car).',
                status=status.HTTP_400_BAD_REQUEST
            )

        data = get_all_restriction_statuses(query_list)
        
        return unified_response(
            success=True,
            message="Current system restrictions fetched successfully.",
            data=data,
            status=status.HTTP_200_OK
        )
