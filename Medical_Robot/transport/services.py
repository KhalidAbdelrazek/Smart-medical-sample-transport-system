from django.db import transaction
from rest_framework.exceptions import NotFound, ValidationError

from samples.models import BloodSample
from cars.models import Car
from .models import TransportRequest


def add_sample_to_car(sample_code, car_id):
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
        transport_request.save()

        # Update car status to LOADING
        car.status = 'LOADING'
        car.save()

    return transport_request


def dispatch_car(car_id):
    """
    Storage employee dispatches a car, sending all loaded samples for delivery.

    Rules:
    - Car must exist
    - Car must have at least one LOADED transport request
    - All LOADED samples are set to OUT_FOR_DELIVERY and is_in_storage=False
    - All LOADED transport requests are set to DISPATCHED
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

            # Update the transport request
            transport_request.status = 'DISPATCHED'
            transport_request.save()

            dispatched_requests.append(transport_request)

        # Update car status
        car.status = 'DISPATCHED'
        car.save()

    return dispatched_requests
