from rest_framework.exceptions import NotFound, ValidationError


def get_sample_by_code(sample_code):
    """
    Fetch a BloodSample by its human-readable code.
    Raises NotFound if the sample doesn't exist.
    """
    from .models import BloodSample
    try:
        return BloodSample.objects.get(sample_code=sample_code)
    except BloodSample.DoesNotExist:
        raise NotFound(f"No blood sample found with code: {sample_code}")


def request_sample(sample_code, room_number, doctor):
    """
    Doctor requests a blood sample to be delivered to a room.

    Rules:
    - Sample must be in storage (is_in_storage=True)
    - Sample status must NOT be OUT_FOR_DELIVERY
    - Creates a TransportRequest with status=PENDING
    - Updates sample status to REQUESTED
    """
    from .models import BloodSample
    from transport.models import TransportRequest

    sample = get_sample_by_code(sample_code)

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
