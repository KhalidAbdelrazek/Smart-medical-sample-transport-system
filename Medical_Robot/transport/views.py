from drf_spectacular.utils import extend_schema, OpenApiExample
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from common.utils.response import unified_response

from accounts.permissions import IsStorageEmployee
from .serializers import (
    TransportRequestSerializer,
    AddToCarSerializer,
    DispatchCarSerializer,
)
from .services import add_sample_to_car, dispatch_car
from .models import TransportRequest


class TransportRequestListView(APIView):
    """
    GET /api/transport/requests/
    Returns all PENDING transport requests.
    Accessible by Storage Employees only.
    """
    permission_classes = [IsAuthenticated, IsStorageEmployee]

    @extend_schema(
        tags=['Transport'],
        summary='List Pending Transport Requests',
        description='Returns all PENDING sample transport requests for the storage dashboard.',
        responses={200: TransportRequestSerializer(many=True)},
    )
    def get(self, request):
        requests = TransportRequest.objects.filter(
            status='PENDING'
        ).select_related('sample', 'requested_by', 'assigned_car')
        serializer = TransportRequestSerializer(requests, many=True)
        return unified_response(
            success=True,
            message="Pending transport requests fetched successfully",
            data=serializer.data,
            status=status.HTTP_200_OK
        )


class AddToCarView(APIView):
    """
    POST /api/transport/add-to-car/
    Storage employee manually assigns a sample to a car using sample_code.
    """
    permission_classes = [IsAuthenticated, IsStorageEmployee]

    @extend_schema(
        tags=['Transport'],
        summary='Add Sample to Car',
        description='Assign a requested sample to a car via sample_code.',
        request=AddToCarSerializer,
        responses={200: TransportRequestSerializer},
        examples=[
            OpenApiExample('Add To Car', value={
                'sample_code': 'PT-0001',
                'car_id': 1,
            }, request_only=True),
        ],
    )
    def post(self, request):
        serializer = AddToCarSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        transport_request = add_sample_to_car(
            sample_code=serializer.validated_data['sample_code'],
            car_id=serializer.validated_data['car_id'],
        )

        response_data = TransportRequestSerializer(transport_request).data
        return unified_response(
            success=True,
            message="Sample added to car successfully",
            data=response_data,
            status=status.HTTP_200_OK
        )


class DispatchCarView(APIView):
    """
    POST /api/transport/dispatch-car/
    Dispatches a car.
    """
    permission_classes = [IsAuthenticated, IsStorageEmployee]

    @extend_schema(
        tags=['Transport'],
        summary='Dispatch Car',
        description='Dispatch a car carrying samples.',
        request=DispatchCarSerializer,
        responses={200: TransportRequestSerializer(many=True)},
        examples=[
            OpenApiExample('Dispatch Car', value={'car_id': 1}, request_only=True),
        ],
    )
    def post(self, request):
        serializer = DispatchCarSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        dispatched_requests = dispatch_car(
            car_id=serializer.validated_data['car_id'],
        )

        response_data = TransportRequestSerializer(dispatched_requests, many=True).data
        return unified_response(
            success=True,
            message=f"Car dispatched successfully with {len(dispatched_requests)} sample(s).",
            data={'dispatched_requests': response_data},
            status=status.HTTP_200_OK
        )
