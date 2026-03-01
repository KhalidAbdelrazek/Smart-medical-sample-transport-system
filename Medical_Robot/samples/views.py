"""
samples/views.py

API views for blood sample operations.

Endpoints:
    GET  /api/samples/{id}/     — Get sample details (Doctor)
    POST /api/samples/request/  — Request a sample for delivery (Doctor)
"""
from drf_spectacular.utils import extend_schema, OpenApiExample
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.permissions import IsDoctor
from .serializers import BloodSampleSerializer, SampleRequestSerializer
from .services import get_sample_by_id, request_sample
from transport.serializers import TransportRequestSerializer


class BloodSampleDetailView(APIView):
    """
    GET /api/samples/{id}/
    Returns details of a specific blood sample by UUID.
    Accessible only by Doctors.
    """
    permission_classes = [IsAuthenticated, IsDoctor]

    @extend_schema(
        tags=['Samples'],
        summary='Get Blood Sample by ID',
        description='Retrieve blood sample details using its UUID. Doctor only.',
        responses={200: BloodSampleSerializer},
    )
    def get(self, request, pk):
        sample = get_sample_by_id(pk)
        serializer = BloodSampleSerializer(sample)
        return Response(serializer.data, status=status.HTTP_200_OK)


class RequestSampleView(APIView):
    """
    POST /api/samples/request/
    Doctor requests a blood sample to be delivered to a room.
    """
    permission_classes = [IsAuthenticated, IsDoctor]

    @extend_schema(
        tags=['Samples'],
        summary='Request a Blood Sample',
        description=(
            'Doctor sends sample_id and room_number. '
            'If the sample is in storage, a transport request is created. '
            'Returns an error if the sample is out for delivery.'
        ),
        request=SampleRequestSerializer,
        responses={201: TransportRequestSerializer},
        examples=[
            OpenApiExample('Sample Request', value={
                'sample_id': 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
                'room_number': '305',
            }, request_only=True),
        ],
    )
    def post(self, request):
        serializer = SampleRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        transport_request = request_sample(
            sample_id=serializer.validated_data['sample_id'],
            room_number=serializer.validated_data['room_number'],
            doctor=request.user,
        )

        response_data = TransportRequestSerializer(transport_request).data
        return Response(response_data, status=status.HTTP_201_CREATED)
