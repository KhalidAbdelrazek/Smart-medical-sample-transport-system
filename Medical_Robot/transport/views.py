from drf_spectacular.utils import extend_schema, OpenApiExample, OpenApiParameter
from rest_framework import status
from rest_framework.exceptions import NotFound, ValidationError
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from common.utils.response import unified_response

from accounts.permissions import IsStorageEmployee, IsDoctor
from .serializers import (
    TransportRequestSerializer,
    AddToCarSerializer,
    DispatchCarSerializer,
    AllTransportRequestsSerializer,
    DoctorReturnRequestSerializer,
    StartReturnCollectionSerializer,
)
from .services import (
    add_sample_to_car, 
    dispatch_car, 
    cancel_transport_request, 
    remove_sample_from_cart,
    complete_transport_request,
    fail_transport_request
)
from .return_services import (
    request_sample_return,
    list_pending_returns,
    start_return_collection,
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
        tags=['Transport'],
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
        tags=['Transport'],
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
        tags=['Transport'],
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
                message=str(e),
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
        tags=["Transport"],
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
                success=False, message=str(e), status=status.HTTP_400_BAD_REQUEST
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
        tags=["Transport"],
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


class CompleteTransportRequestView(APIView):
    """
    POST /api/transport/requests/{request_id}/complete/
    Mark a dispatched request as SUCCESSFUL/EXECUTED.
    """

    permission_classes = [IsAuthenticated, IsStorageEmployee]

    @extend_schema(
        tags=["Transport"],
        summary="Complete Transport Request",
        description="Mark a dispatched transport request as successful/executed.",
        responses={200: TransportRequestSerializer},
    )
    def post(self, request, request_id):
        try:
            transport_request = complete_transport_request(
                request_id=request_id,
                actor=request.user,
            )
            return unified_response(
                success=True,
                message="Transport request marked as completed",
                data=TransportRequestSerializer(transport_request).data,
                status=status.HTTP_200_OK,
            )
        except (NotFound, ValidationError) as e:
            return unified_response(
                success=False, message=str(e), status=status.HTTP_400_BAD_REQUEST
            )


class FailTransportRequestView(APIView):
    """
    POST /api/transport/requests/{request_id}/fail/
    Mark a request as FAILED.
    """

    permission_classes = [IsAuthenticated, IsStorageEmployee]

    @extend_schema(
        tags=["Transport"],
        summary="Fail Transport Request",
        description="Mark a transport request as failed.",
        responses={200: TransportRequestSerializer},
    )
    def post(self, request, request_id):
        try:
            transport_request = fail_transport_request(
                request_id=request_id,
                actor=request.user,
            )
            return unified_response(
                success=True,
                message="Transport request marked as failed",
                data=TransportRequestSerializer(transport_request).data,
                status=status.HTTP_200_OK,
            )
        except (NotFound, ValidationError) as e:
            return unified_response(
                success=False, message=str(e), status=status.HTTP_400_BAD_REQUEST
            )


class DoctorReturnRequestView(APIView):
    """
    POST /api/transport/return-request/
    Doctor requests return of a sample they've finished examining.
    """
    permission_classes = [IsAuthenticated, IsDoctor]

    @extend_schema(
        tags=['Transport - Return'],
        summary='Request Sample Return',
        description='Doctor marks a sample as finished and requests its return to storage.',
        request=DoctorReturnRequestSerializer,
        responses={201: TransportRequestSerializer},
        examples=[
            OpenApiExample(
                'Return Request',
                value={'sample_code': 'PT-0001'},
                request_only=True,
            ),
        ],
    )
    def post(self, request):
        serializer = DoctorReturnRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            return_request = request_sample_return(
                sample_code=serializer.validated_data['sample_code'],
                doctor=request.user,
            )
            response_data = TransportRequestSerializer(return_request).data
            return unified_response(
                success=True,
                message="Sample return request created successfully",
                data=response_data,
                status=status.HTTP_201_CREATED,
            )
        except NotFound as e:
            return unified_response(
                success=False,
                message=str(e),
                status=status.HTTP_404_NOT_FOUND,
            )
        except ValidationError as e:
            return unified_response(
                success=False,
                message=str(e),
                status=status.HTTP_400_BAD_REQUEST,
            )


class ListPendingReturnsView(APIView):
    """
    GET /api/transport/pending-returns/?car_id={id}
    Storage employee views pending return requests for picking/selection.
    Optionally shows capacity context for a specific car.
    """
    permission_classes = [IsAuthenticated, IsStorageEmployee]

    @extend_schema(
        tags=['Transport - Return'],
        summary='List Pending Return Requests',
        description='Returns all pending return requests grouped by room. Shows car capacity if car_id provided.',
        parameters=[
            OpenApiParameter(
                name='car_id',
                description='Optional car ID to show capacity context',
                required=False,
                type=int,
            ),
        ],
        responses={200: TransportRequestSerializer(many=True)},
    )
    def get(self, request):
        car_id = request.query_params.get('car_id')
        
        try:
            queryset, car = list_pending_returns(car_id=car_id)
            serializer = TransportRequestSerializer(queryset, many=True)
            pending_count = queryset.count()
            
            response_data = {'requests': serializer.data}
            if car:
                response_data['car_info'] = {
                    'id': car.id,
                    'car_number': car.car_number,
                    'capacity': car.capacity,
                    'remaining_capacity': car.capacity,
                    'pending_requests_count': pending_count,
                    'max_selectable_now': min(car.capacity, pending_count),
                    'overflow_count': max(pending_count - car.capacity, 0),
                    'status': car.status,
                }
            
            return unified_response(
                success=True,
                message=f"Found {pending_count} pending return request(s)",
                data=response_data,
                status=status.HTTP_200_OK,
            )
        except NotFound as e:
            return unified_response(
                success=False,
                message=str(e),
                status=status.HTTP_404_NOT_FOUND,
            )


class StartReturnCollectionView(APIView):
    """
    POST /api/transport/start-return-collection/
    Storage employee manually starts a return collection run with selected samples.
    """
    permission_classes = [IsAuthenticated, IsStorageEmployee]

    @extend_schema(
        tags=['Transport - Return'],
        summary='Start Return Collection Run',
        description='Dispatch a car to collect selected return samples. Guards: car must be IDLE, no outbound deliveries pending, selections within capacity.',
        request=StartReturnCollectionSerializer,
        responses={200: TransportRequestSerializer(many=True)},
        examples=[
            OpenApiExample(
                'Start Collection',
                value={
                    'car_id': 1,
                    'selected_request_ids': ['uuid-1', 'uuid-2'],
                },
                request_only=True,
            ),
        ],
    )
    def post(self, request):
        serializer = StartReturnCollectionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            dispatched_requests, car = start_return_collection(
                car_id=serializer.validated_data['car_id'],
                selected_request_ids=serializer.validated_data['selected_request_ids'],
                actor=request.user,
            )
            response_data = TransportRequestSerializer(dispatched_requests, many=True).data
            return unified_response(
                success=True,
                message=f"Return collection started with {len(dispatched_requests)} sample(s)",
                data={'selected_requests': response_data},
                status=status.HTTP_200_OK,
            )
        except NotFound as e:
            return unified_response(
                success=False,
                message=str(e),
                status=status.HTTP_404_NOT_FOUND,
            )
        except ValidationError as e:
            return unified_response(
                success=False,
                message=str(e),
                status=status.HTTP_400_BAD_REQUEST,
            )
