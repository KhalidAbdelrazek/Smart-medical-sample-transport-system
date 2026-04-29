"""
transport/return_services.py

Services for handling return requests (samples returned by doctors).
"""
import logging
from django.db import transaction
from django.utils import timezone
from rest_framework.exceptions import NotFound, ValidationError

from samples.models import BloodSample
from cars.models import Car
from healthcare.mqtt_dispatch import build_dispatch_payload, publish_dispatch_event
from .models import TransportRequest
from analytics.services import log_storage_employee_action
from restrictions.services import check_transport_robot_restriction

logger = logging.getLogger(__name__)


def request_sample_return(sample_code, doctor):
    """
    Doctor requests to return a sample they've finished examining.
    
    Rules:
    - Sample must be WITH_DOCTOR (currently in doctor's possession)
    - Sample must belong to a DELIVERED transport request (doctor received it)
    - Cannot create duplicate pending RETURN request for same sample
    - Creates a TransportRequest with status=PENDING, request_type=RETURN
    """
    try:
        sample = BloodSample.objects.get(sample_code=sample_code)
    except BloodSample.DoesNotExist:
        raise NotFound(f"No blood sample found with code: {sample_code}")
    
    if sample.status != 'WITH_DOCTOR':
        raise ValidationError(
            f"Sample must be WITH_DOCTOR to request return. Current status: {sample.status}"
        )
    
    # Verify this is the doctor who received it
    delivered_request = TransportRequest.objects.filter(
        sample=sample,
        requested_by=doctor,
        request_type='DELIVERY',
        status='DELIVERED'
    ).first()
    
    if not delivered_request:
        raise ValidationError(
            "You have not received this sample or it was not successfully delivered to you."
        )
    
    # Check for duplicate pending RETURN request
    existing_return = TransportRequest.objects.filter(
        sample=sample,
        request_type='RETURN',
        status__in=['PENDING', 'LOADED', 'DISPATCHED']
    ).exists()
    
    if existing_return:
        raise ValidationError(
            "A return request for this sample is already queued. Please wait for collection."
        )
    
    # Create the return request using the same room
    return_request = TransportRequest.objects.create(
        sample=sample,
        requested_by=doctor,
        room_number=delivered_request.room_number,  # Reuse delivery room
        status='PENDING',
        request_type='RETURN',
    )
    
    return return_request


def list_pending_returns(car_id=None):
    """
    List all pending RETURN requests (awaiting selection for collection).
    
    Returns queryset grouped by request for storage employee picking.
    Optionally filter by car to show capacity context.
    """
    queryset = TransportRequest.objects.filter(
        request_type='RETURN',
        status='PENDING'
    ).select_related('sample', 'requested_by').order_by('room_number', 'created_at')
    
    car = None
    if car_id:
        try:
            car = Car.objects.get(id=car_id)
        except Car.DoesNotExist:
            raise NotFound(f"Car not found: {car_id}")
    
    return queryset, car


def start_return_collection(car_id, selected_request_ids, actor=None):
    """
    Storage employee manually starts a return collection run.
    
    Rules:
    - Selected car must be IDLE
    - No outbound requests should be PENDING/LOADED/DISPATCHED (gating check)
    - Selected request IDs must all be pending RETURN requests
    - Selected count cannot exceed car capacity
    - Assigns selected requests to car, transitions to LOADED/DISPATCHED, publishes MQTT
    
    Args:
        car_id: ID of the car to use
        selected_request_ids: List of TransportRequest UUIDs to collect
        actor: Storage employee making the request
    
    Returns:
        (dispatched_requests, car)
    """
    # ── RESTRICTION CHECK ──────────────────────────────
    check_transport_robot_restriction()
    # ──────────────────────────────────────────────────
    
    if not selected_request_ids:
        raise ValidationError("At least one return request must be selected.")

    unique_request_ids = list(dict.fromkeys(str(req_id) for req_id in selected_request_ids))

    with transaction.atomic():
        try:
            car = Car.objects.select_for_update().get(id=car_id)
        except Car.DoesNotExist:
            raise NotFound(f"Car not found: {car_id}")

        # Guard: car must be IDLE
        if car.status != 'IDLE':
            raise ValidationError(
                f"Car must be IDLE to start collection. Current status: {car.status}"
            )

        # Guard: no outstanding outbound delivery requests
        pending_deliveries = TransportRequest.objects.filter(
            request_type='DELIVERY',
            status__in=['PENDING', 'LOADED', 'DISPATCHED']
        ).count()

        if pending_deliveries > 0:
            raise ValidationError(
                f"Cannot start return collection: {pending_deliveries} outbound delivery request(s) still pending. "
                "Complete all deliveries first."
            )

        selected_requests = list(
            TransportRequest.objects.select_for_update()
            .select_related('sample')
            .filter(id__in=unique_request_ids)
        )

        found_request_ids = {str(req.id) for req in selected_requests}
        missing_ids = [req_id for req_id in unique_request_ids if req_id not in found_request_ids]
        if missing_ids:
            raise ValidationError(f"Request not found: {missing_ids[0]}")

        for req in selected_requests:
            if req.request_type != 'RETURN' or req.status != 'PENDING':
                raise ValidationError(
                    f"Request {req.id} must be a pending RETURN request. "
                    f"Current: type={req.request_type}, status={req.status}"
                )

        # Guard: capacity check
        if len(selected_requests) > car.capacity:
            raise ValidationError(
                f"Selected {len(selected_requests)} returns exceed car capacity ({car.capacity}). "
                f"Please select no more than {car.capacity} samples."
            )

        now = timezone.now()
        dispatched_requests = []
        for transport_request in selected_requests:
            sample = transport_request.sample
            sample.status = 'OUT_FOR_DELIVERY'
            sample.is_in_storage = False
            sample.save(update_fields=['status', 'is_in_storage', 'updated_at'])

            transport_request.assigned_car = car
            transport_request.status = 'DISPATCHED'
            transport_request.loaded_at = now
            transport_request.dispatched_at = now
            transport_request.save(update_fields=['assigned_car', 'status', 'loaded_at', 'dispatched_at'])
            dispatched_requests.append(transport_request)

        car.status = 'DISPATCHED'
        car.save(update_fields=['status'])

        if actor:
            log_storage_employee_action(
                employee=actor,
                action='CAR_DISPATCH',
                description=f"Dispatched return collection car {car.car_number} with {len(dispatched_requests)} sample(s)",
                car=car,
            )

    try:
        payload = build_dispatch_payload(car=car, dispatched_requests=dispatched_requests)
        published = publish_dispatch_event(payload)
        if not published:
            logger.error(
                "Return collection MQTT publish failed but dispatch completed. car_id=%s sample_count=%s",
                car.id,
                len(dispatched_requests),
            )
    except Exception:
        logger.exception(
            "Unexpected MQTT return-dispatch integration error. car_id=%s sample_count=%s",
            car.id,
            len(dispatched_requests),
        )

    return dispatched_requests, car


def confirm_returned_samples(sample_codes, actor=None):
    """
    Confirm a batch of physically returned samples by sample code.

    Rules:
    - Every sample code must exist.
    - Every sample must have a DISPATCHED RETURN request.
    - Sample transitions to IN_STORAGE / is_in_storage=True.
    - Request is marked DELIVERED (terminal), not RETURNED.
    - Assigned car is set to IDLE if it has no other active requests.
    """
    if not sample_codes:
        raise ValidationError("At least one sample code must be provided.")

    normalized_codes = [str(code).strip() for code in sample_codes if str(code).strip()]
    unique_codes = list(dict.fromkeys(normalized_codes))
    if not unique_codes:
        raise ValidationError("At least one valid sample code must be provided.")

    with transaction.atomic():
        samples = list(
            BloodSample.objects.select_for_update().filter(sample_code__in=unique_codes)
        )
        found_sample_codes = {sample.sample_code for sample in samples}
        missing_sample_codes = [code for code in unique_codes if code not in found_sample_codes]
        if missing_sample_codes:
            raise ValidationError(f"Sample not found: {missing_sample_codes[0]}")

        dispatched_returns = list(
            TransportRequest.objects.select_for_update()
            .select_related("sample", "assigned_car")
            .filter(
                sample__sample_code__in=unique_codes,
                request_type="RETURN",
                status="DISPATCHED",
            )
            .order_by("created_at")
        )

        request_by_sample_code = {}
        for transport_request in dispatched_returns:
            request_by_sample_code[transport_request.sample.sample_code] = transport_request

        missing_dispatched_requests = [
            code for code in unique_codes if code not in request_by_sample_code
        ]
        if missing_dispatched_requests:
            raise ValidationError(
                f"Sample {missing_dispatched_requests[0]} has no dispatched RETURN request."
            )

        now = timezone.now()
        affected_car_ids = set()
        updated_requests = []

        for sample_code in unique_codes:
            transport_request = request_by_sample_code[sample_code]
            sample = transport_request.sample

            sample.status = "IN_STORAGE"
            sample.is_in_storage = True
            sample.save(update_fields=["status", "is_in_storage", "updated_at"])

            transport_request.status = "DELIVERED"
            transport_request.completed_at = now
            transport_request.save(update_fields=["status", "completed_at"])

            if transport_request.assigned_car_id:
                affected_car_ids.add(transport_request.assigned_car_id)

            updated_requests.append(transport_request)

            if actor:
                log_storage_employee_action(
                    employee=actor,
                    action="TRANSPORT_REQUEST_UPDATE",
                    description=(
                        f"Confirmed return for sample {sample.sample_code}; "
                        "sample moved to IN_STORAGE"
                    ),
                    transport_request=transport_request,
                    car=transport_request.assigned_car,
                )

        for car_id in affected_car_ids:
            car = Car.objects.select_for_update().get(id=car_id)
            has_other_active_requests = (
                TransportRequest.objects.filter(assigned_car=car)
                .exclude(status__in=["DELIVERED", "RETURNED", "FAILED", "CANCELLED", "PENDING"])
                .exists()
            )
            if not has_other_active_requests:
                car.status = "IDLE"
                car.save(update_fields=["status"])

    return updated_requests
