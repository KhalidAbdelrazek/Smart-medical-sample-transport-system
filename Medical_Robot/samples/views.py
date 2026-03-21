from accounts.permissions import IsStorageEmployee
from django.db.models import Q
from drf_spectacular.utils import extend_schema, OpenApiExample, OpenApiParameter
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView

from accounts.permissions import IsDoctor
from common.utils.response import unified_response
from .models import BloodSample
from .serializers import (
    BloodSampleSerializer,
    SampleRequestSerializer,
    SamplePreviewSerializer,
    CreateBloodSampleSerializer,
    BulkSampleRequestSerializer,
)
from .services import get_sample_by_code, request_sample
import re
from transport.serializers import TransportRequestSerializer


class BloodSampleSearchView(APIView):
    """
    GET /api/samples/search/?q=
    Search for samples by code, patient name, or patient ID.
    Returns a list of matching samples.
    """

    permission_classes = [IsAuthenticated, IsDoctor]

    @extend_schema(
        tags=["Samples"],
        summary="Search Blood Samples",
        description="Search for samples using code (e.g. PT-0001), patient name, or patient ID.",
        parameters=[
            OpenApiParameter(
                name="q", description="Search query", required=True, type=str
            )
        ],
        responses={200: BloodSampleSerializer(many=True)},
    )
    def get(self, request):
        query = request.query_params.get("q", "")
        if not query:
            return unified_response(
                success=False,
                message="Search query 'q' is required",
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Search by sample_code, patient_name, or patient_id
        samples = BloodSample.objects.filter(
            Q(sample_code__icontains=query)
            | Q(patient_name__icontains=query)
        )

        serializer = BloodSampleSerializer(samples, many=True)
        return unified_response(
            success=True,
            message=f"Found {samples.count()} samples",
            data=serializer.data,
            status=status.HTTP_200_OK,
        )


class BloodSampleDetailView(APIView):
    """
    GET /api/samples/{sample_code}/
    If matches PT-XXXX -> Returns full details of the sample.
    Otherwise -> Performs smart search and returns preview list.
    """

    permission_classes = [IsAuthenticated, IsDoctor]

    @extend_schema(
        tags=["Samples"],
        summary="Get Sample Detail or Search",
        description=(
            "Smart endpoint with dual behavior:\n"
            "1. If 'sample_code' matches PT-XXXX format (e.g., PT-0001) -> Returns full object.\n"
            "2. Otherwise -> Performs smart case-insensitive search (name, code, id) and returns preview list."
        ),
        parameters=[
            OpenApiParameter(
                name="sample_code",
                location=OpenApiParameter.PATH,
                description="Sample code or search query",
                required=True,
                type=str,
            )
        ],
        responses={
            200: BloodSampleSerializer,
            404: OpenApiExample(
                "Not Found",
                value={
                    "success": False,
                    "message": "No blood sample found...",
                    "data": None,
                },
            ),
        },
        examples=[
            OpenApiExample("Exact Match", value="PT-0001"),
            OpenApiExample("Smart Search (Name)", value="khalid"),
            OpenApiExample("Smart Search (Partial)", value="pt"),
        ],
    )
    def get(self, request, sample_code):
        # 1. Clean input
        value = sample_code.strip()

        # 2. Check for exact PT-XXXX pattern
        is_exact_code = re.match(r"^PT-\d{4}$", value, re.IGNORECASE)

        if is_exact_code:
            # Case 1: Exact PT match
            try:
                sample = BloodSample.objects.get(sample_code__iexact=value)
                serializer = BloodSampleSerializer(sample)
                return unified_response(
                    success=True,
                    message="Sample details fetched successfully",
                    data=serializer.data,
                    status=status.HTTP_200_OK,
                )
            except BloodSample.DoesNotExist:
                return unified_response(
                    success=False,
                    message=f"No blood sample found with code: {value}",
                    status=status.HTTP_404_NOT_FOUND,
                )
        else:
            # Case 2: Smart Search
            from django.db.models import Case, When, Value, IntegerField

            samples = (
                BloodSample.objects.filter(
                    Q(sample_code__icontains=value)
                    | Q(patient_name__icontains=value)
                )
                .annotate(
                    priority=Case(
                        When(status="IN_STORAGE", then=Value(1)),
                        When(status="REQUESTED", then=Value(2)),
                        When(status="OUT_FOR_DELIVERY", then=Value(3)),
                        default=Value(4),
                        output_field=IntegerField(),
                    )
                )
                .order_by("priority")[:10]
            )

            serializer = SamplePreviewSerializer(samples, many=True)
            return unified_response(
                success=True,
                message="Search results fetched",
                data=serializer.data,
                status=status.HTTP_200_OK,
            )


class RequestSampleView(APIView):
    """
    POST /api/samples/request/
    Doctor requests a blood sample using sample_code.
    """

    permission_classes = [IsAuthenticated, IsDoctor]

    @extend_schema(
        tags=["Samples"],
        summary="Request a Blood Sample",
        description="Doctor sends sample_code and room_number.",
        request=SampleRequestSerializer,
        responses={201: TransportRequestSerializer},
        examples=[
            OpenApiExample(
                "Sample Request",
                value={
                    "sample_code": "PT-0001",
                    "room_number": "305",
                },
                request_only=True,
            ),
        ],
    )
    def post(self, request):
        serializer = SampleRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        transport_request = request_sample(
            sample_code=serializer.validated_data["sample_code"],
            room_number=serializer.validated_data["room_number"],
            doctor=request.user,
        )

        response_data = TransportRequestSerializer(transport_request).data
        return unified_response(
            success=True,
            message="Sample transport requested successfully",
            data=response_data,
            status=status.HTTP_201_CREATED,
        )


class BulkRequestSampleView(APIView):
    """
    POST /api/samples/request-bulk/
    Doctor requests multiple blood samples for the same room in a single API call.
    """

    permission_classes = [IsAuthenticated, IsDoctor]

    @extend_schema(
        tags=["Samples"],
        summary="Request Multiple Blood Samples",
        description="Doctor sends multiple sample codes for delivery to the same room.",
        request=BulkSampleRequestSerializer,
        responses={201: TransportRequestSerializer(many=True)},
        examples=[
            OpenApiExample(
                "Bulk Sample Request",
                value={
                    "sample_codes": ["PT-0001", "PT-0002", "PT-0003"],
                    "room_number": "305",
                },
                request_only=True,
            ),
        ],
    )
    def post(self, request):
        serializer = BulkSampleRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        sample_codes = serializer.validated_data["sample_codes"]
        room_number = serializer.validated_data["room_number"]

        # Track results
        successful_requests = []
        failed_requests = []

        for sample_code in sample_codes:
            try:
                transport_request = request_sample(
                    sample_code=sample_code,
                    room_number=room_number,
                    doctor=request.user,
                )
                response_data = TransportRequestSerializer(transport_request).data
                successful_requests.append(response_data)
            except BloodSample.DoesNotExist:
                failed_requests.append(
                    {
                        "sample_code": sample_code,
                        "error": f"Sample {sample_code} not found",
                    }
                )
            except Exception as e:
                failed_requests.append({"sample_code": sample_code, "error": str(e)})

        # Determine response status
        if not successful_requests:
            # All failed
            return unified_response(
                success=False,
                message=f"Failed to request {len(failed_requests)} samples",
                data={
                    "successful": successful_requests,
                    "failed": failed_requests,
                    "summary": {
                        "total": len(sample_codes),
                        "success": len(successful_requests),
                        "failed": len(failed_requests),
                    },
                },
                status=status.HTTP_400_BAD_REQUEST,
            )
        else:
            # Partial or full success
            http_status = (
                status.HTTP_201_CREATED
                if not failed_requests
                else status.HTTP_207_MULTI_STATUS
            )
            return unified_response(
                success=True,
                message=f"Requested {len(successful_requests)} samples. {len(failed_requests)} failed.",
                data={
                    "successful": successful_requests,
                    "failed": failed_requests,
                    "summary": {
                        "total": len(sample_codes),
                        "success": len(successful_requests),
                        "failed": len(failed_requests),
                    },
                },
                status=http_status,
            )


class CreateBloodSampleView(APIView):
    """
    POST /api/samples/create/
    Create a new blood sample record in the database.
    """

    permission_classes = [IsAuthenticated, IsStorageEmployee]

    @extend_schema(
        tags=["Samples"],
        summary="Create New Blood Sample",
        description="Add a new blood sample to storage with patient details.",
        request=CreateBloodSampleSerializer,
        responses={201: BloodSampleSerializer},
        examples=[
            OpenApiExample(
                "Valid Sample",
                value={
                    "patient_name": "John Doe",
                    "blood_type": "O+",
                },
                request_only=True,
            ),
        ],
    )
    def post(self, request):
        serializer = CreateBloodSampleSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        # Create the sample
        sample = BloodSample.objects.create(
            patient_name=serializer.validated_data["patient_name"],
            blood_type=serializer.validated_data["blood_type"],
            status="IN_STORAGE",
            is_in_storage=True,
        )

        response_data = BloodSampleSerializer(sample).data
        return unified_response(
            success=True,
            message=f"Blood sample created successfully with code: {sample.sample_code}",
            data=response_data,
            status=status.HTTP_201_CREATED,
        )
