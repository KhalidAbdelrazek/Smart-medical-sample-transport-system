import logging
import uuid

from django.db import transaction
from django.utils import timezone
from rest_framework.exceptions import NotFound, ValidationError

from samples.models import BloodSample
from cars.models import Car
from .models import TransportRequest
from analytics.services import log_storage_employee_action

from django.core.exceptions import PermissionDenied
from restrictions.services import (
    check_storage_samples_restriction,
    check_transport_car_restriction,
)


logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Grouped-by-room payload builder
# ---------------------------------------------------------------------------

def build_grouped_dispatch_payload(car, loaded_requests):
    """
    Build the dispatch payload grouped by destination room.

    Returns dict:
    {
        "car_id": int,
        "batch_id": "uuid...",
        "grouped_by_room": {
            "Room A": [{"request_id": "...", "sample_id": "...", "doctor_id": "..."}],
            "Room B": [...],
        }
    }
    """
    batch_id = str(uuid.uuid4())
    grouped = {}

    for transport_request in loaded_requests:
        room = transport_request.room_number
        if room not in grouped:
            grouped[room] = []
        grouped[room].append({
            "request_id": str(transport_request.id),
            "sample_id": str(transport_request.sample_id),
            "doctor_id": str(transport_request.requested_by_id) if transport_request.requested_by_id else None,
        })

    return {
        "car_id": car.id,
        "batch_id": batch_id,
        "grouped_by_room": grouped,
    }


# ---------------------------------------------------------------------------
# Legacy payload builder (kept for backward compatibility with existing code)
# ---------------------------------------------------------------------------

def _build_legacy_dispatch_payload(car, dispatched_requests):
    """Build the legacy payload format used by healthcare.mqtt_dispatch."""
    from healthcare.mqtt_dispatch import build_dispatch_payload
    return build_dispatch_payload(car=car, dispatched_requests=dispatched_requests)


# ---------------------------------------------------------------------------
# Core transport services
# ---------------------------------------------------------------------------

def add_sample_to_car(sample_code, car_id, actor=None):
    """
    Storage employee adds a blood sample to a car.

    Rules:
    - Sample must exist and have status REQUESTED
    - Car must exist and not be DISPATCHED
    - Creates/updates the TransportRequest to LOADED
    - Sets car status to LOADING
    """
    # ── RESTRICTION CHECK ──────────────────────────────
    if actor:
        check_storage_samples_restriction(actor)
    # ──────────────────────────────────────────────────

    try:
        sample = BloodSample.objects.get(sample_code=sample_code)
    except BloodSample.DoesNotExist:
        raise NotFound(f"No blood sample found with code: {sample_code}")

    if sample.status != 'REQUESTED':
        raise ValidationError(
            f"Sample must have status REQUESTED to be added to a car. Current status: {sample.status}"
        )

    try:
        car = Car.objects.get(id=car_id)
    except Car.DoesNotExist:
        raise NotFound(f"No car found with ID: {car_id}")

    if car.status == 'DISPATCHED':
        raise ValidationError("Cannot add samples to a car that has already been dispatched.")

    with transaction.atomic():
        # Update the pending transport request for this sample
        transport_request = TransportRequest.objects.filter(
            sample=sample,
            status='PENDING',
        ).order_by('-created_at').first()

        if not transport_request:
            raise ValidationError("No pending transport request found for this sample.")

        transport_request.assigned_car = car
        transport_request.status = 'LOADED'
        transport_request.loaded_at = timezone.now()
        transport_request.save()

        # Update car status to LOADING
        car.status = 'LOADING'
        car.save()
        
        # Log activity
        if actor:
            log_storage_employee_action(
                employee=actor,
                action='SAMPLE_ADDED_TO_CAR',
                description=f"Added sample {sample.sample_code} to car {car.car_number}",
                transport_request=transport_request,
                car=car,
            )

    return transport_request


def dispatch_car(car_id, actor=None):
    """
    Storage employee dispatches a car, sending all loaded samples for delivery.

    ACK-gated flow:
    1. Build grouped-by-room dispatch payload
    2. Publish to MQTT and wait for device ACK
    3. Only on "OK" ACK: mark requests DISPATCHED, samples OUT_FOR_DELIVERY, car DISPATCHED
    4. On timeout/error: leave everything unchanged and raise ValidationError

    Rules:
    - Car must exist
    - Car must have at least one LOADED transport request
    """
    # ── RESTRICTION CHECK ──────────────────────────────
    check_transport_car_restriction()
    # ──────────────────────────────────────────────────

    try:
        car = Car.objects.get(id=car_id)
    except Car.DoesNotExist:
        raise NotFound(f"No car found with ID: {car_id}")

    # Get all loaded transport requests for this car (legacy + return flow)
    loaded_requests = list(
        TransportRequest.objects.filter(
            assigned_car=car,
            status__in=['LOADED', 'LOADED_FOR_RETURN'],
        ).select_related('sample', 'requested_by')
    )

    if not loaded_requests:
        raise ValidationError(
            "Cannot dispatch an empty car. Please add at least one sample before dispatching."
        )

    # ── STEP 1: Build grouped payload ──────────────────
    payload = build_grouped_dispatch_payload(car, loaded_requests)

    # ── STEP 2: Publish and wait for ACK ───────────────
    from .mqtt_client import publish_and_wait_for_ack

    ack_success, ack_error = publish_and_wait_for_ack(car_id=car.id, payload=payload)

    if not ack_success:
        logger.error(
            "Dispatch ACK failed for car_id=%s: %s. Leaving requests unchanged.",
            car.id, ack_error,
        )
        raise ValidationError(
            f"Dispatch failed: device did not acknowledge. {ack_error}"
        )

    # ── STEP 3: ACK received — commit the dispatch ─────
    with transaction.atomic():
        dispatched_requests = []

        for transport_request in loaded_requests:
            # Update the blood sample
            sample = transport_request.sample
            if transport_request.request_type == 'DELIVERY':
                sample.status = 'OUT_FOR_DELIVERY'
                sample.is_in_storage = False
            else:
                # Return flow: sample remains with doctor until handoff is confirmed.
                sample.status = 'WITH_DOCTOR'
                sample.is_in_storage = False
            sample.save()

            # Update the transport request with timestamp
            transport_request.status = 'DISPATCHED'
            transport_request.dispatched_at = timezone.now()
            transport_request.save()

            dispatched_requests.append(transport_request)

        # Update car status
        car.status = 'DISPATCHED'
        car.save()
        
        # Log activity
        if actor:
            log_storage_employee_action(
                employee=actor,
                action='CAR_DISPATCH',
                description=f"Dispatched car {car.car_number} with {len(dispatched_requests)} sample(s)",
                car=car,
            )

    return dispatched_requests, car


def cancel_transport_request(request_id, doctor):
    """
    Cancel a pending transport request.

    Rules:
    - TransportRequest must exist.
    - User attempting to cancel must be the 'requested_by' doctor.
    - Status must be 'PENDING'.
    - Marks request as CANCELLED (does not delete) and reverts BloodSample status to 'IN_STORAGE'.
    """

    try:
        transport_request = TransportRequest.objects.get(id=request_id)
    except TransportRequest.DoesNotExist:
        raise NotFound(f"No transport request found with ID: {request_id}")

    if transport_request.requested_by != doctor:
        raise PermissionDenied("You do not have permission to cancel this request.")

    if transport_request.status != 'PENDING':
        raise ValidationError(
            f"Cannot cancel a request that is already {transport_request.status}."
        )

    with transaction.atomic():
        # Mark as CANCELLED instead of deleting
        transport_request.status = 'CANCELLED'
        transport_request.cancelled_at = timezone.now()
        transport_request.status_note = 'Cancelled by doctor'
        transport_request.save()
        
        # Revert the blood sample's status back to in storage
        sample = transport_request.sample
        sample.status = 'IN_STORAGE'
        sample.save()
        
        # Log activity

    return True, transport_request


def remove_sample_from_cart(request_id, actor=None):
    """
    Storage employee removes a loaded sample from a car before dispatch.

    Rules:
    - TransportRequest must exist
    - Status must be 'LOADED' (not PENDING or DISPATCHED)
    - Reverts TransportRequest.status back to 'PENDING'
    - Reverts BloodSample.status back to 'REQUESTED'
    - Reverts Car.status back to 'IDLE' if no other LOADED requests exist for this car
    """
    try:
        transport_request = TransportRequest.objects.get(id=request_id)
    except TransportRequest.DoesNotExist:
        raise NotFound(f"No transport request found with ID: {request_id}")

    if transport_request.status not in ("LOADED", "LOADED_FOR_RETURN"):
        raise ValidationError(
            f"Cannot remove a sample that is {transport_request.status}. "
            "You can only remove samples from carts that have not yet been dispatched."
        )

    with transaction.atomic():
        # Revert the blood sample to the expected pre-loaded state.
        sample = transport_request.sample
        if transport_request.request_type == 'RETURN':
            sample.status = "WITH_DOCTOR"
            sample.is_in_storage = False
        else:
            sample.status = "REQUESTED"
            sample.is_in_storage = True
        sample.save()

        # Revert the transport request back to the correct pre-loaded state.
        car = transport_request.assigned_car
        transport_request.assigned_car = None
        transport_request.status = (
            "APPROVED_BY_STORAGE" if transport_request.request_type == "RETURN" else "PENDING"
        )
        transport_request.loaded_at = None  # Clear the loaded timestamp
        transport_request.save()

        # Revert car status to IDLE if no other loaded requests exist for this car.
        other_loaded_requests = TransportRequest.objects.filter(
            assigned_car=car,
            status__in=["LOADED", "LOADED_FOR_RETURN"],
        ).exists()

        if not other_loaded_requests:
            car.status = "IDLE"
            car.save()
        
        # Log activity
        if actor:
            log_storage_employee_action(
                employee=actor,
                action='SAMPLE_REMOVED_FROM_CAR',
                description=f"Removed sample {sample.sample_code} from car {car.car_number}",
                transport_request=transport_request,
                car=car,
            )

    return transport_request


def complete_transport_request(request_id, actor=None):
    """
    Mark a transport request as completed.
    
    Transitions:
    - DELIVERY (DISPATCHED -> DELIVERED): sample moves to WITH_DOCTOR (stays with doctor, not in storage)
    - DELIVERY (ARRIVED_AT_DOCTOR_DELIVERY -> DELIVERED): same as above (after arrival event)
    - RETURN (DISPATCHED -> RETURNED): sample returns to IN_STORAGE
    
    Car becomes IDLE if all its requests are completed.
    """
    try:
        transport_request = TransportRequest.objects.get(id=request_id)
    except TransportRequest.DoesNotExist:
        raise NotFound(f"No transport request found with ID: {request_id}")

    if transport_request.status not in ("DISPATCHED", "ARRIVED_AT_DOCTOR_DELIVERY"):
        raise ValidationError(
            f"Only dispatched or arrived requests can be completed. Current status: {transport_request.status}"
        )

    with transaction.atomic():
        sample = transport_request.sample
        
        # Branch by request type
        if transport_request.request_type == 'DELIVERY':
            # Delivery completion: sample stays with doctor
            transport_request.status = "DELIVERED"
            sample.status = "WITH_DOCTOR"
            sample.is_in_storage = False
            description = f"Completed delivery of sample {sample.sample_code} to room {transport_request.room_number}"
        else:  # RETURN
            # Return completion signal in existing mechanism means "robot arrived at doctor".
            transport_request.status = "ARRIVED_AT_DOCTOR"
            sample.status = "WITH_DOCTOR"
            sample.is_in_storage = False
            description = (
                f"Return robot arrived for sample {sample.sample_code} at room "
                f"{transport_request.room_number}; awaiting doctor confirmation"
            )
        
        transport_request.completed_at = timezone.now()
        transport_request.save()
        sample.save()

        # Check if car should be IDLE
        car = transport_request.assigned_car
        if car:
            other_active = (
                TransportRequest.objects.filter(assigned_car=car)
                .exclude(
                    status__in=[
                        "DELIVERED",
                        "RETURNED",
                        "FAILED",
                        "CANCELLED",
                        "PENDING",
                        "RETURN_REQUESTED",
                        "APPROVED_BY_STORAGE",
                        "ARRIVED_AT_DOCTOR",
                        "RETURN_CONFIRMED",
                        "ARRIVED_AT_DOCTOR_DELIVERY",
                    ]
                )
                .exclude(id=request_id)
                .exists()
            )
            if not other_active:
                car.status = "IDLE"
                car.save()
        
        # Log activity
        if actor:
            log_storage_employee_action(
                employee=actor,
                action='TRANSPORT_REQUEST_UPDATE',
                description=description,
                transport_request=transport_request,
                car=car,
            )

    return transport_request

def fail_transport_request(request_id, actor=None):
    """
    Mark a transport request as failed.
    
    For DELIVERY: sample reverts to IN_STORAGE for retry
    For RETURN: sample reverts to WITH_DOCTOR so doctor can retry return
    """
    try:
        transport_request = TransportRequest.objects.get(id=request_id)
    except TransportRequest.DoesNotExist:
        raise NotFound(f"No transport request found with ID: {request_id}")

    with transaction.atomic():
        transport_request.status = "FAILED"
        transport_request.failed_at = timezone.now()
        transport_request.status_note = "Transport failed"
        transport_request.save()

        sample = transport_request.sample
        
        # Branch by request type to revert sample to appropriate status
        if transport_request.request_type == 'DELIVERY':
            # Delivery failed: sample back to storage for retry
            sample.status = "IN_STORAGE"
            sample.is_in_storage = True
        else:  # RETURN
            # Return failed: sample stays with doctor for retry
            sample.status = "WITH_DOCTOR"
            sample.is_in_storage = False
        
        sample.save()

        # Idle car
        car = transport_request.assigned_car
        if car:
            car.status = "IDLE"
            car.save()
        
        # Log activity
        if actor:
            log_storage_employee_action(
                employee=actor,
                action='TRANSPORT_REQUEST_UPDATE',
                description=f"Failed {transport_request.request_type.lower()} of sample {sample.sample_code}. Reason: {transport_request.status_note}",
                transport_request=transport_request,
                car=car,
            )

    return transport_request


# ---------------------------------------------------------------------------
# Arrival event handling (called by MQTT subscriber)
# ---------------------------------------------------------------------------

def handle_arrival_event(car_id, room, arrived_request_ids, timestamp=None):
    """
    Process an arrival event from the Raspberry Pi device.

    When the car arrives at a room, mark matching TransportRequest rows
    as ARRIVED_AT_DOCTOR_DELIVERY (for delivery) or ARRIVED_AT_DOCTOR (for return).

    Idempotent: skips requests already in an arrived or later state.

    Args:
        car_id: The car that arrived
        room: The room the car arrived at
        arrived_request_ids: List of TransportRequest UUIDs that arrived
        timestamp: Optional ISO timestamp from device
    """
    # Validate car exists
    try:
        car = Car.objects.get(id=car_id)
    except Car.DoesNotExist:
        logger.error("Arrival event for unknown car_id=%s", car_id)
        raise ValidationError(f"Unknown car_id: {car_id}")

    arrival_time = timezone.now()
    if timestamp:
        try:
            from django.utils.dateparse import parse_datetime
            parsed = parse_datetime(timestamp)
            if parsed:
                arrival_time = parsed
        except Exception:
            pass  # Use server time as fallback

    updated_count = 0

    with transaction.atomic():
        requests = list(
            TransportRequest.objects.select_for_update()
            .select_related('sample')
            .filter(
                id__in=arrived_request_ids,
                assigned_car=car,
                room_number=room,  # Fix #3: enforce room match
            )
        )

        # Warn about request_ids that didn't match (wrong car OR wrong room)
        found_ids = {str(r.id) for r in requests}
        for req_id in arrived_request_ids:
            if str(req_id) not in found_ids:
                logger.warning(
                    "Arrival event references request_id=%s that does not match "
                    "car_id=%s and room=%s",
                    req_id, car_id, room,
                )

        for transport_request in requests:
            # Idempotent: skip if already arrived or in a terminal state
            if transport_request.status in (
                "ARRIVED_AT_DOCTOR_DELIVERY",
                "ARRIVED_AT_DOCTOR",
                "DELIVERED",
                "RETURNED",
                "RETURN_CONFIRMED",
                "FAILED",
                "CANCELLED",
            ):
                logger.info(
                    "Skipping arrival for request %s — already in status %s",
                    transport_request.id, transport_request.status,
                )
                continue

            # Only DISPATCHED requests can transition to arrived
            if transport_request.status != "DISPATCHED":
                logger.warning(
                    "Cannot mark request %s as arrived — current status %s",
                    transport_request.id, transport_request.status,
                )
                continue

            if transport_request.request_type == "DELIVERY":
                transport_request.status = "ARRIVED_AT_DOCTOR_DELIVERY"
            else:
                transport_request.status = "ARRIVED_AT_DOCTOR"

            transport_request.arrived_at = arrival_time
            transport_request.save(update_fields=["status", "arrived_at"])
            updated_count += 1

            logger.info(
                "Request %s marked as %s (car_id=%s, room=%s)",
                transport_request.id, transport_request.status, car_id, room,
            )

    logger.info(
        "Arrival event processed. car_id=%s room=%s updated=%d/%d",
        car_id, room, updated_count, len(arrived_request_ids),
    )
    return updated_count


# ---------------------------------------------------------------------------
# Doctor confirm / reject delivery
# ---------------------------------------------------------------------------

def _should_proceed_from_room(car, room):
    """
    Check whether the car should proceed from a room.
    Returns True if no requests with status ARRIVED_AT_DOCTOR_DELIVERY
    remain for the given (car, room).
    """
    waiting = TransportRequest.objects.filter(
        assigned_car=car,
        room_number=room,
        status="ARRIVED_AT_DOCTOR_DELIVERY",
    ).exists()
    return not waiting


def confirm_delivery(request_id, doctor):
    """
    Doctor confirms receipt of a delivered sample.

    Transitions: ARRIVED_AT_DOCTOR_DELIVERY -> DELIVERED
    After confirming, if no other doctors in the room are waiting,
    publishes a 'proceed' command to the car.

    Fix #4: the proceed-check is inside the same atomic block with
    select_for_update to prevent duplicate proceed commands.
    """
    try:
        transport_request = TransportRequest.objects.select_related(
            'sample', 'assigned_car'
        ).get(id=request_id)
    except TransportRequest.DoesNotExist:
        raise NotFound(f"No transport request found with ID: {request_id}")

    if transport_request.requested_by_id != doctor.id:
        raise PermissionDenied("You do not have permission to confirm this delivery.")

    if transport_request.status != "ARRIVED_AT_DOCTOR_DELIVERY":
        raise ValidationError(
            f"Only arrived deliveries can be confirmed. Current status: {transport_request.status}"
        )

    car = transport_request.assigned_car
    room = transport_request.room_number
    should_proceed = False

    with transaction.atomic():
        # Re-fetch with row lock to prevent concurrent proceed races
        transport_request = (
            TransportRequest.objects.select_for_update()
            .select_related('sample')
            .get(id=request_id)
        )
        if transport_request.status != "ARRIVED_AT_DOCTOR_DELIVERY":
            # Another concurrent call already handled this request
            return transport_request

        sample = transport_request.sample
        transport_request.status = "DELIVERED"
        transport_request.completed_at = timezone.now()
        sample.status = "WITH_DOCTOR"
        sample.is_in_storage = False
        transport_request.save(update_fields=["status", "completed_at"])
        sample.save(update_fields=["status", "is_in_storage", "updated_at"])

        # Check proceed while still holding the row locks
        should_proceed = car is not None and _should_proceed_from_room(car, room)

    logger.info(
        "Delivery confirmed. request_id=%s sample=%s room=%s",
        request_id, sample.sample_code, room,
    )

    if should_proceed:
        try:
            from .mqtt_client import publish_proceed_command
            publish_proceed_command(car_id=car.id, room=room)
            logger.info("Proceed command sent for car_id=%s room=%s", car.id, room)
        except Exception:
            logger.exception(
                "Failed to send proceed command. car_id=%s room=%s", car.id, room,
            )

    return transport_request


def reject_delivery(request_id, doctor, reason=""):
    """
    Doctor rejects a delivered sample.

    Transitions: ARRIVED_AT_DOCTOR_DELIVERY -> FAILED
    Uses fail_transport_request to mark the request as failed.
    After rejecting, if no other doctors in the room are waiting,
    publishes a 'proceed' command to the car.

    Fix #4: the proceed-check is inside the same atomic block with
    select_for_update to prevent duplicate proceed commands.
    """
    try:
        transport_request = TransportRequest.objects.select_related(
            'sample', 'assigned_car'
        ).get(id=request_id)
    except TransportRequest.DoesNotExist:
        raise NotFound(f"No transport request found with ID: {request_id}")

    if transport_request.requested_by_id != doctor.id:
        raise PermissionDenied("You do not have permission to reject this delivery.")

    if transport_request.status != "ARRIVED_AT_DOCTOR_DELIVERY":
        raise ValidationError(
            f"Only arrived deliveries can be rejected. Current status: {transport_request.status}"
        )

    car = transport_request.assigned_car
    room = transport_request.room_number
    should_proceed = False

    with transaction.atomic():
        # Re-fetch with row lock to prevent concurrent proceed races
        transport_request = (
            TransportRequest.objects.select_for_update()
            .select_related('sample')
            .get(id=request_id)
        )
        if transport_request.status != "ARRIVED_AT_DOCTOR_DELIVERY":
            return transport_request

        transport_request.status = "FAILED"
        transport_request.failed_at = timezone.now()
        transport_request.status_note = reason or "Rejected by doctor"
        transport_request.save(update_fields=["status", "failed_at", "status_note"])

        sample = transport_request.sample
        sample.status = "IN_STORAGE"
        sample.is_in_storage = True
        sample.save(update_fields=["status", "is_in_storage", "updated_at"])

        # Check proceed while still holding the row locks
        should_proceed = car is not None and _should_proceed_from_room(car, room)

    logger.info(
        "Delivery rejected. request_id=%s sample=%s room=%s reason=%s",
        request_id, sample.sample_code, room, reason,
    )

    if should_proceed:
        try:
            from .mqtt_client import publish_proceed_command
            publish_proceed_command(car_id=car.id, room=room)
            logger.info("Proceed command sent for car_id=%s room=%s", car.id, room)
        except Exception:
            logger.exception(
                "Failed to send proceed command. car_id=%s room=%s", car.id, room,
            )

    return transport_request
