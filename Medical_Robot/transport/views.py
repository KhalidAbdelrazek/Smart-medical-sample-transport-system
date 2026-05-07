from drf_spectacular.utils import extend_schema, OpenApiExample, OpenApiParameter
from rest_framework import status
from rest_framework.exceptions import NotFound, ValidationError
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from common.utils.response import unified_response, format_error_message

from accounts.permissions import IsStorageEmployee, IsDoctor
from .serializers import (
    TransportRequestSerializer,
    AddToCarSerializer,
    DispatchCarSerializer,
    AllTransportRequestsSerializer,
    DoctorReturnRequestSerializer,
    RequestReturnSerializer,
    ConfirmReturnSerializer,
    StartReturnCollectionSerializer,
    ConfirmReturnedSamplesSerializer,
    CarReturnConfirmSerializer,
    ReturnedCarSerializer,
    RejectDeliverySerializer,
)
from .services import (
    add_sample_to_car, 
    dispatch_car, 
    cancel_transport_request, 
    remove_sample_from_cart,
    confirm_delivery,
    reject_delivery,
    confirm_return_handoff,
    confirm_car_returned,
    get_returned_cars,
    get_returned_cars_count,
)
from .return_services import (
    request_return_batch,
    request_return_by_codes,
    get_grouped_return_requests,
    get_doctor_return_arrivals,
    confirm_return_batch,
    list_pending_returns,
    start_return_collection,
    confirm_returned_samples,
)
from .models import TransportRequest
from django.core.exceptions import PermissionDenied

class TransportRequestListView(APIView):
    """
    GET /api/transport/requests/
    Returns all PENDING and LOADED transport requests.
    Accessible by Storage Employees only.
    """
    permission_classes = [IsAuthenticated, IsStorageEmployee]

    @extend_schema(
        tags=['Transport - Delivery - For Storage'],
        summary='List Pending and Loaded Transport Requests',
        description='Returns all PENDING and LOADED sample transport requests for the storage dashboard.',
        responses={200: TransportRequestSerializer(many=True)},
    )
    def get(self, request):
        requests = TransportRequest.objects.filter(
            status__in=['PENDING', 'LOADED']
        ).select_related('sample', 'requested_by', 'assigned_car')
        serializer = TransportRequestSerializer(requests, many=True)
        return unified_response(
            success=True,
            message="Pending and loaded transport requests fetched successfully",
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
        tags=['Transport - Delivery - For Storage'],
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
            actor=request.user,
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
        tags=['Transport - Delivery - For Storage'],
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

        dispatched_requests, _car_dispatch = dispatch_car(
            car_id=serializer.validated_data['car_id'],
            actor=request.user,
        )

        response_data = TransportRequestSerializer(dispatched_requests, many=True).data
        return unified_response(
            success=True,
            message=f"Car dispatched successfully with {len(dispatched_requests)} sample(s).",
            data={'dispatched_requests': response_data},
            status=status.HTTP_200_OK
        )


class DoctorTransportRequestListView(APIView):
    """
    GET /api/transport/my-requests/
    Returns all transport requests made by the current doctor.
    Accessible by Doctors only.
    """
    permission_classes = [IsAuthenticated, IsDoctor]

    @extend_schema(
        tags=['Transport - Delivery - For Doctor'],
        summary='List My Requests',
        description='Returns all sample transport requests created by the authenticated doctor.',
        responses={200: TransportRequestSerializer(many=True)},
    )
    def get(self, request):
        requests = TransportRequest.objects.filter(
            requested_by=request.user
        ).select_related('sample', 'assigned_car').order_by('-created_at')
        
        serializer = TransportRequestSerializer(requests, many=True)
        return unified_response(
            success=True,
            message="Your transport requests fetched successfully",
            data=serializer.data,
            status=status.HTTP_200_OK
        )


class CancelTransportRequestView(APIView):
    """
    DELETE /api/transport/requests/{request_id}/cancel/
    Allows a doctor to cancel their pending transport request.
    """
    permission_classes = [IsAuthenticated, IsDoctor]

    @extend_schema(
        tags=['Transport - Delivery - For Doctor'],
        summary='Cancel Transport Request',
        description='Allows a doctor to cancel a transport request they made, provided it is still PENDING.',
        responses={
            200: OpenApiExample(
                'Success', 
                value={'success': True, 'message': 'Transport request cancelled successfully', 'data': None}
            )
        },
    )
    def delete(self, request, request_id):

        try:
            cancel_transport_request(request_id=request_id, doctor=request.user)
            return unified_response(
                success=True,
                message="Transport request cancelled successfully",
                status=status.HTTP_200_OK
            )
        except PermissionDenied as e:
            return unified_response(
                success=False,
                message=format_error_message(e),
                status=status.HTTP_403_FORBIDDEN
            )


class RemoveFromCartView(APIView):
    """
    DELETE /api/transport/requests/{request_id}/remove-from-cart/
    Storage employee removes an accidentally added sample from a car.
    Only works for LOADED requests that haven't been dispatched yet.
    """

    permission_classes = [IsAuthenticated, IsStorageEmployee]

    @extend_schema(
        tags=["Transport - Delivery - For Storage"],
        summary="Remove Sample from Cart",
        description="Remove a loaded sample from a car before dispatch. Storage employees only.",
        responses={
            200: OpenApiExample(
                "Success",
                value={
                    "success": True,
                    "message": "Sample removed from cart successfully",
                    "data": {},
                },
            )
        },
    )
    def delete(self, request, request_id):
        try:
            transport_request = remove_sample_from_cart(
                request_id=request_id,
                actor=request.user,
            )
            response_data = TransportRequestSerializer(transport_request).data
            return unified_response(
                success=True,
                message="Sample removed from cart successfully",
                data=response_data,
                status=status.HTTP_200_OK,
            )
        except (NotFound, ValidationError) as e:
            return unified_response(
                success=False, message=format_error_message(e), status=status.HTTP_400_BAD_REQUEST
            )


class AllTransportRequestsView(APIView):
    """
    GET /api/transport/all-requests/
    Returns all transport requests with complete details.
    Allows filtering by status via query parameter.
    Accessible by Storage Employees and Admins only.
    """

    permission_classes = [IsAuthenticated, IsStorageEmployee]

    @extend_schema(
        tags=["Transport - Delivery - For Storage"],
        summary="List Transport Requests Filtered according to its status",
        description="Returns transport requests with full details. Can be filtered by status (PENDING, LOADED, DISPATCHED).",
        responses={200: AllTransportRequestsSerializer(many=True)},
        parameters=[
            OpenApiParameter(
                name="status",
                description="Filter by status",
                required=False,
                type=str,
                enum=["PENDING", "LOADED", "DISPATCHED"],
            )
        ],
    )
    def get(self, request):
        status_filter = request.query_params.get("status")

        queryset = TransportRequest.objects.all().select_related(
            "sample", "requested_by", "assigned_car"
        )

        if status_filter:
            if status_filter not in dict(TransportRequest.STATUS_CHOICES):
                return unified_response(
                    success=False,
                    message=f"Invalid status: {status_filter}. Must be one of: {', '.join(dict(TransportRequest.STATUS_CHOICES).keys())}",
                    status=status.HTTP_400_BAD_REQUEST,
                )
            queryset = queryset.filter(status=status_filter)

        requests = queryset.order_by("-created_at")
        serializer = AllTransportRequestsSerializer(requests, many=True)

        return unified_response(
            success=True,
            message=f"Transport requests fetched successfully. Total: {len(serializer.data)}",
            data=serializer.data,
            status=status.HTTP_200_OK,
        )








class RequestReturnView(APIView):
    """
    POST /api/transport/request-return/
    Doctor requests returns for one or many samples using sample UUIDs.
    """
    permission_classes = [IsAuthenticated, IsDoctor]

    @extend_schema(
        tags=['Transport - Return - For Doctor'],
        summary='Request Return (Batch)',
        description='Create one RETURN transport request per sample using a shared batch_id.',
        request=RequestReturnSerializer,
        responses={201: TransportRequestSerializer(many=True)},
    )
    def post(self, request):
        serializer = RequestReturnSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            sample_ids = serializer.validated_data.get('sample_ids', [])
            sample_codes = serializer.validated_data.get('sample_codes', [])

            if sample_codes:
                batch_id, return_requests = request_return_by_codes(
                    sample_codes=sample_codes,
                    doctor=request.user,
                )
            else:
                batch_id, return_requests = request_return_batch(
                    sample_ids=sample_ids,
                    doctor=request.user,
                )
            return unified_response(
                success=True,
                message=f"Created return batch with {len(return_requests)} sample(s)",
                data={
                    'batch_id': str(batch_id),
                    'requests': TransportRequestSerializer(return_requests, many=True).data,
                },
                status=status.HTTP_201_CREATED,
            )
        except (NotFound, ValidationError) as e:
            return unified_response(
                success=False,
                message=format_error_message(e),
                status=status.HTTP_400_BAD_REQUEST,
            )


class ReturnRequestsView(APIView):
    """
    GET /api/transport/return-requests/
    Storage views grouped return requests by batch.
    """
    permission_classes = [IsAuthenticated, IsStorageEmployee]

    @extend_schema(
        tags=['Transport - Return - For Storage'],
        summary='List Return Requests',
        description='Returns return requests grouped by batch_id.',
    )
    def get(self, request):
        grouped = get_grouped_return_requests()
        return unified_response(
            success=True,
            message=f"Found {len(grouped)} return batch(es)",
            data=grouped,
            status=status.HTTP_200_OK,
        )


# ApproveReturnView has been removed — storage approval step is no longer needed.
# Returns are now picked up at the doctor's room during delivery (see Edit 4).



class ReturnStatusView(APIView):
    """
    GET /api/transport/return-status/
    Doctor polls return statuses to show blocking arrival popup.
    """
    permission_classes = [IsAuthenticated, IsDoctor]

    @extend_schema(
        tags=['Transport - Return - For Doctor'],
        summary='Get Return Arrival Status',
        description='Returns doctor return requests that reached ARRIVED_AT_DOCTOR.',
    )
    def get(self, request):
        arrivals = get_doctor_return_arrivals(doctor=request.user)
        response_rows = [
            {
                "request_id": str(transport_request.id),
                "batch_id": (
                    str(transport_request.batch_id)
                    if transport_request.batch_id
                    else None
                ),
                "sample_id": str(transport_request.sample_id),
                "sample_name": transport_request.sample.patient_name,
                "status": transport_request.status,
            }
            for transport_request in arrivals
        ]
        return unified_response(
            success=True,
            message=f"Found {len(response_rows)} return arrival update(s)",
            data=response_rows,
            status=status.HTTP_200_OK,
        )







class DeliveryArrivalsView(APIView):
    """
    GET /api/transport/arrivals/
    Doctor polls for delivery arrivals — samples that have physically arrived
    at their room and are waiting for confirmation.

    Also includes a return_offer flag + returnable samples list when the car
    is at the doctor's room and the doctor has samples eligible for return.
    """
    permission_classes = [IsAuthenticated, IsDoctor]

    @extend_schema(
        tags=['Transport - Delivery - For Doctor'],
        summary='Poll Delivery Arrivals',
        description=(
            'Returns samples with status ARRIVED_AT_DOCTOR_DELIVERY for the '
            'authenticated doctor. Includes return_offer when the doctor has '
            'returnable samples and a car is at the room.'
        ),
    )
    def get(self, request):
        from samples.models import BloodSample

        arrivals = (
            TransportRequest.objects.filter(
                requested_by=request.user,
                request_type='DELIVERY',
                status='ARRIVED_AT_DOCTOR_DELIVERY',
            )
            .select_related('sample')
            .order_by('arrived_at')
        )
        response_rows = [
            {
                "request_id": str(tr.id),
                "sample_id": str(tr.sample_id),
                "sample_name": tr.sample.patient_name,
                "sample_code": tr.sample.sample_code,
                "status": tr.status,
                "room": tr.room_number,
            }
            for tr in arrivals
        ]

        # ── Return offer: show returnable samples when car is at room ──
        return_offer = False
        returnable_samples = []
        if arrivals.exists():
            with_doctor_samples = (
                BloodSample.objects.filter(
                    status="WITH_DOCTOR",
                    is_in_storage=False,
                    transport_requests__requested_by=request.user,
                    transport_requests__request_type="DELIVERY",
                    transport_requests__status="DELIVERED",
                )
                .distinct()
            )
            if with_doctor_samples.exists():
                return_offer = True
                returnable_samples = [
                    {
                        "sample_id": str(s.id),
                        "sample_code": s.sample_code,
                        "patient_name": s.patient_name,
                    }
                    for s in with_doctor_samples
                ]

        return unified_response(
            success=True,
            message=f"Found {len(response_rows)} delivery arrival(s)",
            data={
                "arrivals": response_rows,
                "return_offer": return_offer,
                "returnable_samples": returnable_samples,
            },
            status=status.HTTP_200_OK,
        )


class ConfirmDeliveryView(APIView):
    """
    POST /api/transport/requests/{request_id}/confirm-delivery/
    Doctor confirms receipt of a delivered sample.
    
    NOTE: The car will NOT proceed immediately after confirmation.
    The car waits for the doctor to either:
    1. Confirm return handoff via /confirm-return-handoff/ (car then proceeds)
    2. Or the system determines no returns are needed (car then proceeds)
    """
    permission_classes = [IsAuthenticated, IsDoctor]

    @extend_schema(
        tags=['Transport - Delivery - For Doctor'],
        summary='Confirm Delivery',
        description='Doctor confirms a sample that has arrived at their room. Car will proceed after return confirmation or if no returns available.',
        responses={200: TransportRequestSerializer},
    )
    def post(self, request, request_id):
        try:
            transport_request = confirm_delivery(
                request_id=request_id,
                doctor=request.user,
            )
            return unified_response(
                success=True,
                message="Delivery confirmed successfully",
                data=TransportRequestSerializer(transport_request).data,
                status=status.HTTP_200_OK,
            )
        except PermissionDenied as e:
            return unified_response(
                success=False,
                message=format_error_message(e),
                status=status.HTTP_403_FORBIDDEN,
            )
        except (NotFound, ValidationError) as e:
            return unified_response(
                success=False,
                message=format_error_message(e),
                status=status.HTTP_400_BAD_REQUEST,
            )


class RejectDeliveryView(APIView):
    """
    POST /api/transport/requests/{request_id}/reject-delivery/
    Doctor rejects a delivered sample (e.g. wrong sample, damaged).
    """
    permission_classes = [IsAuthenticated, IsDoctor]

    @extend_schema(
        tags=['Transport - Delivery - For Doctor'],
        summary='Reject Delivery',
        description='Doctor rejects a sample. Marks request as FAILED and may trigger car to proceed.',
        request=RejectDeliverySerializer,
        responses={200: TransportRequestSerializer},
    )
    def post(self, request, request_id):
        serializer = RejectDeliverySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            transport_request = reject_delivery(
                request_id=request_id,
                doctor=request.user,
                reason=serializer.validated_data.get('reason', ''),
            )
            return unified_response(
                success=True,
                message="Delivery rejected",
                data=TransportRequestSerializer(transport_request).data,
                status=status.HTTP_200_OK,
            )
        except PermissionDenied as e:
            return unified_response(
                success=False,
                message=format_error_message(e),
                status=status.HTTP_403_FORBIDDEN,
            )
        except (NotFound, ValidationError) as e:
            return unified_response(
                success=False,
                message=format_error_message(e),
                status=status.HTTP_400_BAD_REQUEST,
            )


class ConfirmReturnHandoffView(APIView):
    """
    POST /api/transport/confirm-return-handoff/
    Doctor confirms they handed return samples to the car at their room.
    
    This is the CRITICAL step that triggers car progression:
    - Marks return samples as LOADED_FOR_RETURN
    - Triggers proceed check and command to next room or storage
    - If no returns available, still triggers proceed
    """
    permission_classes = [IsAuthenticated, IsDoctor]

    @extend_schema(
        tags=['Transport - Return - For Doctor'],
        summary='Confirm Return Handoff (Triggers Car Proceed)',
        description=(
            'Doctor confirms they gave the return samples to the car. '
            'This endpoint triggers the car to proceed to the next room or storage. '
            'If no return samples are available, car still proceeds immediately. '
            'This is the critical step after delivery confirmation.'
        ),
    )
    def post(self, request):
        try:
            loaded_count = confirm_return_handoff(doctor=request.user)
            if loaded_count == 0:
                message = "No samples to return. Car is proceeding."
            else:
                message = f"Confirmed handoff of {loaded_count} sample(s) to the car"
            return unified_response(
                success=True,
                message=message,
                data={"loaded_count": loaded_count},
                status=status.HTTP_200_OK,
            )
        except ValidationError as e:
            return unified_response(
                success=False,
                message=format_error_message(e),
                status=status.HTTP_400_BAD_REQUEST,
            )


class ConfirmCarReturnView(APIView):
    """
    POST /api/transport/confirm-car-return/
    Storage employee confirms a car has returned to the storage area.
    """
    permission_classes = [IsAuthenticated, IsStorageEmployee]

    @extend_schema(
        tags=['Transport - Return - For Storage'],
        summary='Confirm Car Return',
        description='Marks the specified car as IDLE, indicating it is back in storage.',
        request=CarReturnConfirmSerializer,
        responses={200: OpenApiExample(
            'Success',
            value={'success': True, 'message': 'Car return confirmed successfully', 'data': {'car': {'id': 1, 'car_number': 'C1', 'status': 'IDLE'}}}
        )},
    )
    def post(self, request):
        serializer = CarReturnConfirmSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        car_id = serializer.validated_data['car_id']
        car = confirm_car_returned(car_id, actor=request.user)
        return unified_response(
            success=True,
            message="Car return confirmed successfully",
            data={
                "car": {
                    "id": car.id,
                    "car_number": car.car_number,
                    "status": car.status,
                }
            },
            status=status.HTTP_200_OK,
        )


class ReturnedCarsView(APIView):
    """
    GET /api/transport/returned-cars/
    Storage employee polls for cars that have arrived back at storage.
    Returns a list of cars awaiting confirmation of return.
    """
    permission_classes = [IsAuthenticated, IsStorageEmployee]

    @extend_schema(
        tags=['Transport - Return - For Storage'],
        summary='List Returned Cars',
        description='Returns cars that have arrived back at storage and are awaiting confirmation.',
        responses={200: ReturnedCarSerializer(many=True)},
    )
    def get(self, request):
        returned_cars = get_returned_cars()
        serializer = ReturnedCarSerializer(returned_cars, many=True)
        
        # Transform data to include car_id alias for clarity
        returned_cars_data = []
        for car_data in serializer.data:
            car_data['car_id'] = car_data.get('id')  # Add car_id alias
            returned_cars_data.append(car_data)
        
        return unified_response(
            success=True,
            message=f"Found {len(returned_cars_data)} returned car(s) awaiting confirmation",
            data={
                "returned_cars": returned_cars_data,
            },
            status=status.HTTP_200_OK,
        )


class ReturnedCarsCountView(APIView):
    """
    GET /api/transport/returned-cars/count/
    Quick polling endpoint to check if any cars are waiting for return confirmation.
    Useful for storage UI to show a notification badge or trigger full data fetch.
    """
    permission_classes = [IsAuthenticated, IsStorageEmployee]

    @extend_schema(
        tags=['Transport - Return - For Storage'],
        summary='Check Returned Cars Count',
        description='Returns the count of cars waiting for return confirmation. Lightweight endpoint for polling.',
        responses={200: OpenApiExample(
            'Success',
            value={'success': True, 'message': 'Returned cars count', 'data': {'count': 2, 'has_returned_cars': True}}
        )},
    )
    def get(self, request):
        count = get_returned_cars_count()
        return unified_response(
            success=True,
            message="Returned cars count retrieved",
            data={
                "count": count,
                "has_returned_cars": count > 0,
            },
            status=status.HTTP_200_OK,
        )

