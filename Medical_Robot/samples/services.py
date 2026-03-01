"""
samples/services.py

Business logic for blood sample operations.
Separated from views for clean architecture and easy maintenance.
"""
from rest_framework.exceptions import NotFound, ValidationError


def get_sample_by_id(sample_id):
    """
    Fetch a BloodSample by its UUID.
    Raises NotFound if the sample doesn't exist.
    """
    from .models import BloodSample
    try:
        return BloodSample.objects.get(id=sample_id)
    except BloodSample.DoesNotExist:
        raise NotFound(f"No blood sample found with ID: {sample_id}")


def request_sample(sample_id, room_number, doctor):
    """
    Doctor requests a blood sample to be delivered to a room.

    Rules:
    - Sample must be in storage (is_in_storage=True)
    - Sample status must NOT be OUT_FOR_DELIVERY
    - Creates a TransportRequest with status=PENDING
    - Updates sample status to REQUESTED

    Returns the created TransportRequest.
    """
    from .models import BloodSample
    from transport.models import TransportRequest

    try:
        sample = BloodSample.objects.get(id=sample_id)
    except BloodSample.DoesNotExist:
        raise NotFound(f"No blood sample found with ID: {sample_id}")

    # Business rule: sample must be physically in storage
    if not sample.is_in_storage or sample.status == 'OUT_FOR_DELIVERY':
        raise ValidationError(
            "Sample is currently out of storage. Please try again later."
        )

    # Business rule: don't create duplicate pending requests for same sample
    if sample.status == 'REQUESTED':
        raise ValidationError(
            "This sample has already been requested. "
            "Please wait for it to be processed."
        )

    # Update sample status
    sample.status = 'REQUESTED'
    sample.save()

    # Create transport request
    transport_request = TransportRequest.objects.create(
        sample=sample,
        requested_by=doctor,
        room_number=room_number,
        status='PENDING',
    )

    return transport_request
