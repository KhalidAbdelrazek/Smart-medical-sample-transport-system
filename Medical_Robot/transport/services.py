from django.db import transaction
from django.utils import timezone
from rest_framework.exceptions import NotFound, ValidationError

from samples.models import BloodSample
from cars.models import Car
from .models import TransportRequest

from django.core.exceptions import PermissionDenied


def add_sample_to_car(sample_code, car_id, actor=None):
    """
    Storage employee adds a blood sample to a car.

    Rules:
    - Sample must exist and have status REQUESTED
    - Car must exist and not be DISPATCHED
    - Creates/updates the TransportRequest to LOADED
    - Sets car status to LOADING
    """
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

    return transport_request


def dispatch_car(car_id, actor=None):
    """
    Storage employee dispatches a car, sending all loaded samples for delivery.

    Rules:
    - Car must exist
    - Car must have at least one LOADED transport request
    - All LOADED samples are set to OUT_FOR_DELIVERY and is_in_storage=False
    - All LOADED transport requests are set to DISPATCHED and dispatched_at is set
    - Car status is set to DISPATCHED
    """
    try:
        car = Car.objects.get(id=car_id)
    except Car.DoesNotExist:
        raise NotFound(f"No car found with ID: {car_id}")

    # Get all LOADED transport requests for this car
    loaded_requests = TransportRequest.objects.filter(
        assigned_car=car,
        status='LOADED',
    ).select_related('sample')

    if not loaded_requests.exists():
        raise ValidationError(
            "Cannot dispatch an empty car. Please add at least one sample before dispatching."
        )

    with transaction.atomic():
        dispatched_requests = []

        for transport_request in loaded_requests:
            # Update the blood sample
            sample = transport_request.sample
            sample.status = 'OUT_FOR_DELIVERY'
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

    return dispatched_requests, car_dispatch


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

    if transport_request.status != "LOADED":
        raise ValidationError(
            f"Cannot remove a sample that is {transport_request.status}. "
            "You can only remove samples from carts that have not yet been dispatched."
        )

    with transaction.atomic():
        # Revert the blood sample's status back to REQUESTED
        sample = transport_request.sample
        sample.status = "REQUESTED"
        sample.save()

        # Revert the transport request back to PENDING
        car = transport_request.assigned_car
        transport_request.assigned_car = None
        transport_request.status = "PENDING"
        transport_request.loaded_at = None  # Clear the loaded timestamp
        transport_request.save()

        # Revert car status to IDLE if no other LOADED requests exist for this car
        other_loaded_requests = TransportRequest.objects.filter(
            assigned_car=car,
            status="LOADED",
        ).exists()

        if not other_loaded_requests:
            car.status = "IDLE"
            car.save()
        
        # Log activity

    return transport_request


def complete_transport_request(request_id, actor=None):
    """
    Mark a transport request as successful/delivered.
    Transition: DISPATCHED -> DELIVERED
    Car becomes IDLE if all its requests are completed.
    """
    try:
        transport_request = TransportRequest.objects.get(id=request_id)
    except TransportRequest.DoesNotExist:
        raise NotFound(f"No transport request found with ID: {request_id}")

    if transport_request.status != "DISPATCHED":
        raise ValidationError(
            f"Only dispatched requests can be completed. Current status: {transport_request.status}"
        )

    with transaction.atomic():
        # Set to DELIVERED
        transport_request.status = "DELIVERED"
        transport_request.completed_at = timezone.now()
        transport_request.save()

        # Update blood sample status
        sample = transport_request.sample
        sample.status = "IN_STORAGE"
        sample.is_in_storage = True
        sample.save()

        # Check if car should be IDLE
        car = transport_request.assigned_car
        if car:
            other_active = (
                TransportRequest.objects.filter(assigned_car=car)
                .exclude(status__in=["DELIVERED", "RETURNED", "FAILED", "CANCELLED", "PENDING"])
                .exclude(id=request_id)
                .exists()
            )
            if not other_active:
                car.status = "IDLE"
                car.save()
        
        # Log activity

    return transport_request


def fail_transport_request(request_id, actor=None):
    """
    Mark a transport request as failed.
    """
    try:
        transport_request = TransportRequest.objects.get(id=request_id)
    except TransportRequest.DoesNotExist:
        raise NotFound(f"No transport request found with ID: {request_id}")

    with transaction.atomic():
        transport_request.status = "FAILED"
        transport_request.failed_at = timezone.now()
        transport_request.status_note = "Delivery failed"
        transport_request.save()

        # Revert blood sample status to IN_STORAGE so it can be requested again
        sample = transport_request.sample
        sample.status = "IN_STORAGE"
        sample.is_in_storage = True
        sample.save()

        # Idle car if needed
        car = transport_request.assigned_car
        if car:
            car.status = "IDLE"
            car.save()
        
        # Log activity

    return transport_request
