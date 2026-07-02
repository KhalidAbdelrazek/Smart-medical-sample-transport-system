"""
cars/views.py

Views for car management endpoints.
"""
from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.exceptions import NotFound
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView

from accounts.permissions import IsStorageEmployee
from common.utils.response import unified_response, format_error_message
from .serializers import CarDetailsSerializer
from .services import get_car_details


class CarDetailsView(APIView):
    """
    GET /api/cars/{car_id}/details/
    Retrieve car details including occupancy and sample codes.
    Storage employees only.
    """
    permission_classes = [IsAuthenticated, IsStorageEmployee]

    @extend_schema(
        tags=['Cars'],
        summary='Get Car Details with Occupancy',
        description='Returns car details including total capacity, used capacity, remaining capacity, and sample codes currently in the car.',
        responses={200: CarDetailsSerializer},
    )
    def get(self, request, car_id):
        try:
            car_details = get_car_details(car_id)
            serializer = CarDetailsSerializer(car_details)
            return unified_response(
                success=True,
                message="Car details retrieved successfully",
                data=serializer.data,
                status=status.HTTP_200_OK,
            )
        except NotFound as e:
            return unified_response(
                success=False,
                message=format_error_message(e),
                status=status.HTTP_404_NOT_FOUND,
            )
