"""
transport/views.py

API views for storage employee transport operations.

Endpoints:
    GET  /api/transport/requests/      — List all PENDING requests (Storage Employee)
    POST /api/transport/add-to-car/    — Add a sample to a car (Storage Employee)
    POST /api/transport/dispatch-car/  — Dispatch a car (Storage Employee)
"""
from drf_spectacular.utils import extend_schema, OpenApiExample
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

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
    Returns all PENDING transport requests (samples waiting to be loaded).
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
        return Response(serializer.data, status=status.HTTP_200_OK)


class AddToCarView(APIView):
    """
    POST /api/transport/add-to-car/
    Storage employee manually assigns a sample to a car (for loading).
    """
    permission_classes = [IsAuthenticated, IsStorageEmployee]

    @extend_schema(
        tags=['Transport'],
        summary='Add Sample to Car',
        description='Assign a requested sample to a car. Car status changes to LOADING.',
        request=AddToCarSerializer,
        responses={200: TransportRequestSerializer},
        examples=[
            OpenApiExample('Add To Car', value={
                'sample_id': 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
                'car_id': 1,
            }, request_only=True),
        ],
    )
    def post(self, request):
        serializer = AddToCarSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        transport_request = add_sample_to_car(
            sample_id=serializer.validated_data['sample_id'],
            car_id=serializer.validated_data['car_id'],
        )

        response_data = TransportRequestSerializer(transport_request).data
        return Response(response_data, status=status.HTTP_200_OK)


class DispatchCarView(APIView):
    """
    POST /api/transport/dispatch-car/
    Dispatches a car. All loaded samples are marked as OUT_FOR_DELIVERY.
    Returns an error if the car is empty.
    """
    permission_classes = [IsAuthenticated, IsStorageEmployee]

    @extend_schema(
        tags=['Transport'],
        summary='Dispatch Car',
        description=(
            'Dispatch a car carrying samples. '
            'All loaded samples become OUT_FOR_DELIVERY. '
            'Car becomes DISPATCHED. Returns error if car is empty.'
        ),
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
        return Response(
            {
                'message': f'Car dispatched successfully with {len(dispatched_requests)} sample(s).',
                'dispatched_requests': response_data,
            },
            status=status.HTTP_200_OK,
        )
