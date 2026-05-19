"""
transport/return_services.py

Services for return requests (doctor -> storage reverse flow).
"""
import uuid

from django.db import transaction
from django.utils import timezone
from rest_framework.exceptions import NotFound, ValidationError

from analytics.services import log_storage_employee_action
from cars.models import Car
from restrictions.services import check_storage_samples_restriction
from samples.models import BloodSample
from transport.services import dispatch_car

from .models import TransportRequest

RETURN_TERMINAL_STATUSES = {
    "RETURN_CONFIRMED",
    "RETURNED",
    "CANCELLED",
    "FAILED",
}

RETURN_ACTIVE_STATUSES = {
    "RETURN_REQUESTED",
    "LOADED_FOR_RETURN",
    "DISPATCHED",
    "ARRIVED_AT_DOCTOR",
    # Legacy return statuses still considered active for duplicate protection.
    "PENDING",
    "LOADED",
}


def _validate_return_sample(sample, doctor):
    if sample.status != "WITH_DOCTOR" or sample.is_in_storage:
        raise ValidationError(
            f"Sample {sample.id} is not currently with the doctor and cannot be returned."
        )

    delivered_request_exists = TransportRequest.objects.filter(
        sample=sample,
        requested_by=doctor,
        request_type="DELIVERY",
        status="DELIVERED",
    ).exists()
    if not delivered_request_exists:
        raise ValidationError(
            f"Sample {sample.id} was not delivered to the authenticated doctor."
        )

    duplicate_return_exists = TransportRequest.objects.filter(
        sample=sample,
        request_type="RETURN",
        status__in=RETURN_ACTIVE_STATUSES,
    ).exists()
    if duplicate_return_exists:
        raise ValidationError(
            f"Sample {sample.id} already has an active return request."
        )


def _set_car_idle_if_ready(car_ids):
    if not car_ids:
        return

    for car_id in car_ids:
        car = Car.objects.select_for_update().get(id=car_id)
        has_active_requests = TransportRequest.objects.filter(
            assigned_car=car,
            status__in=["LOADED", "LOADED_FOR_RETURN", "DISPATCHED"],
        ).exists()
        if not has_active_requests:
            car.status = "IDLE"
            car.save(update_fields=["status"])


def _select_idle_car(required_capacity):
    car = (
        Car.objects.select_for_update()
        .filter(status="IDLE", capacity__gte=required_capacity)
        .order_by("id")
        .first()
    )
    if not car:
        raise ValidationError(
            "No idle car with sufficient capacity is currently available."
        )
    return car


def request_return_batch(sample_ids, doctor):
    if not sample_ids:
        raise ValidationError("At least one sample ID is required.")

    # ── Doctor must have an active delivery arrival (car at room) ──
    has_delivery_at_room = TransportRequest.objects.filter(
        requested_by=doctor,
        request_type="DELIVERY",
        status="ARRIVED_AT_DOCTOR_DELIVERY",
    ).exists()
    if not has_delivery_at_room:
        raise ValidationError(
            "You can only return samples when a delivery car is at your room. "
            "Please wait for a delivery to arrive first."
        )

    sample_ids = list(dict.fromkeys(str(sample_id) for sample_id in sample_ids))

    with transaction.atomic():
        samples = list(
            BloodSample.objects.select_for_update().filter(id__in=sample_ids)
        )
        found_ids = {str(sample.id) for sample in samples}
        missing = [sample_id for sample_id in sample_ids if sample_id not in found_ids]
        if missing:
            raise ValidationError(f"Sample not found: {missing[0]}")

        for sample in samples:
            _validate_return_sample(sample, doctor)

        batch_id = uuid.uuid4()
        return_requests = [
            TransportRequest(
                sample=sample,
                requested_by=doctor,
                room_number=TransportRequest.objects.filter(
                    sample=sample,
                    request_type="DELIVERY",
                    requested_by=doctor,
                    status="DELIVERED",
                )
                .order_by("-created_at")
                .values_list("room_number", flat=True)
                .first()
                or "",
                status="RETURN_REQUESTED",
                request_type="RETURN",
                batch_id=batch_id,
            )
            for sample in samples
        ]
        TransportRequest.objects.bulk_create(return_requests)

    return batch_id, list(
        TransportRequest.objects.filter(batch_id=batch_id).select_related(
            "sample", "requested_by", "assigned_car"
        )
    )


def get_grouped_return_requests():
    queryset = (
        TransportRequest.objects.filter(
            request_type="RETURN",
            status__in=[
                "RETURN_REQUESTED",
                "LOADED_FOR_RETURN",
                "DISPATCHED",
                "ARRIVED_AT_DOCTOR",
            ],
        )
        .select_related("sample", "requested_by")
        .order_by("created_at")
    )

    grouped = {}
    for transport_request in queryset:
        batch_key = str(transport_request.batch_id or transport_request.id)
        bucket = grouped.get(batch_key)
        if not bucket:
            bucket = {
                "batch_id": batch_key,
                "doctor": {
                    "id": str(transport_request.requested_by_id)
                    if transport_request.requested_by_id
                    else None,
                    "name": (
                        transport_request.requested_by.full_name
                        if transport_request.requested_by
                        else None
                    ),
                },
                "room": transport_request.room_number,
                "samples": [],
            }
            grouped[batch_key] = bucket

        bucket["samples"].append(
            {
                "request_id": str(transport_request.id),
                "sample_id": str(transport_request.sample_id),
                "sample_name": transport_request.sample.patient_name,
                "status": transport_request.status,
            }
        )

    return list(grouped.values())


# approve_return_batch() has been removed — storage approval step is no longer needed.
# Returns are now picked up at the doctor's room during delivery (see Edit 4).


def get_doctor_return_arrivals(doctor):
    return (
        TransportRequest.objects.filter(
            requested_by=doctor,
            request_type="RETURN",
            status="ARRIVED_AT_DOCTOR",
        )
        .select_related("sample")
        .order_by("created_at")
    )


def confirm_return_batch(batch_id, doctor, actor=None):
    with transaction.atomic():
        batch_requests = list(
            TransportRequest.objects.select_for_update()
            .select_related("sample", "assigned_car")
            .filter(
                batch_id=batch_id,
                requested_by=doctor,
                request_type="RETURN",
            )
            .order_by("created_at")
        )
        if not batch_requests:
            raise NotFound(f"No return requests found for batch: {batch_id}")

        arrived_requests = [
            transport_request
            for transport_request in batch_requests
            if transport_request.status == "ARRIVED_AT_DOCTOR"
        ]
        if not arrived_requests:
            if all(
                transport_request.status in {"RETURNED", "RETURN_CONFIRMED"}
                for transport_request in batch_requests
            ):
                return batch_requests
            raise ValidationError("No arrived return samples are pending confirmation.")

        now = timezone.now()
        affected_car_ids = set()
        for transport_request in arrived_requests:
            sample = transport_request.sample
            sample.status = "IN_STORAGE"
            sample.is_in_storage = True
            sample.save(update_fields=["status", "is_in_storage", "updated_at"])

            transport_request.status = "RETURNED"
            transport_request.completed_at = now
            transport_request.save(update_fields=["status", "completed_at"])

            if transport_request.assigned_car_id:
                affected_car_ids.add(transport_request.assigned_car_id)

            if actor:
                log_storage_employee_action(
                    employee=actor,
                    action="TRANSPORT_REQUEST_UPDATE",
                    description=(
                        f"Doctor confirmed return handoff for sample "
                        f"{sample.sample_code} in batch {batch_id}"
                    ),
                    transport_request=transport_request,
                    car=transport_request.assigned_car,
                )

        _set_car_idle_if_ready(affected_car_ids)

    return list(
        TransportRequest.objects.filter(
            batch_id=batch_id,
            requested_by=doctor,
            request_type="RETURN",
        )
        .select_related("sample", "assigned_car")
        .order_by("created_at")
    )


# ---------------------------------------------------------------------------
# Legacy return flow wrappers (kept for backwards compatibility)
# ---------------------------------------------------------------------------

def request_sample_return(sample_code, doctor):
    try:
        sample = BloodSample.objects.get(sample_code=sample_code)
    except BloodSample.DoesNotExist as exc:
        raise NotFound(f"No blood sample found with code: {sample_code}") from exc

    _batch_id, requests = request_return_batch(sample_ids=[sample.id], doctor=doctor)
    return requests[0]


def list_pending_returns(car_id=None):
    queryset = (
        TransportRequest.objects.filter(
            request_type="RETURN",
            status__in=["PENDING", "RETURN_REQUESTED"],
        )
        .select_related("sample", "requested_by")
        .order_by("room_number", "created_at")
    )

    car = None
    if car_id:
        try:
            car = Car.objects.get(id=car_id)
        except Car.DoesNotExist as exc:
            raise NotFound(f"Car not found: {car_id}") from exc

    return queryset, car


def start_return_collection(car_id, selected_request_ids, actor=None):
    if actor:
        check_storage_samples_restriction(actor)

    if not selected_request_ids:
        raise ValidationError("At least one return request must be selected.")

    selected_request_ids = list(dict.fromkeys(str(req_id) for req_id in selected_request_ids))

    with transaction.atomic():
        try:
            car = Car.objects.select_for_update().get(id=car_id)
        except Car.DoesNotExist as exc:
            raise NotFound(f"Car not found: {car_id}") from exc

        if car.status != "IDLE":
            raise ValidationError(
                f"Car must be IDLE to start collection. Current status: {car.status}"
            )

        selected_requests = list(
            TransportRequest.objects.select_for_update()
            .select_related("sample")
            .filter(id__in=selected_request_ids)
        )
        found_ids = {str(transport_request.id) for transport_request in selected_requests}
        missing = [request_id for request_id in selected_request_ids if request_id not in found_ids]
        if missing:
            raise ValidationError(f"Request not found: {missing[0]}")

        for transport_request in selected_requests:
            if transport_request.request_type != "RETURN":
                raise ValidationError(f"Request {transport_request.id} is not a RETURN request.")
            if transport_request.status not in {
                "PENDING",
                "RETURN_REQUESTED",
            }:
                raise ValidationError(
                    f"Request {transport_request.id} cannot be collected from status "
                    f"{transport_request.status}."
                )

        if len(selected_requests) > car.capacity:
            raise ValidationError(
                f"Selected {len(selected_requests)} requests exceeds car capacity ({car.capacity})."
            )

        now = timezone.now()
        for transport_request in selected_requests:
            transport_request.status = "LOADED_FOR_RETURN"
            transport_request.assigned_car = car
            transport_request.loaded_at = now
            transport_request.save(update_fields=["status", "assigned_car", "loaded_at"])

        car.status = "LOADING"
        car.save(update_fields=["status"])

    return dispatch_car(car_id=car.id, actor=actor)


def confirm_returned_samples(sample_codes, actor=None):
    if not sample_codes:
        raise ValidationError("At least one sample code must be provided.")

    sample_codes = list(
        dict.fromkeys(str(sample_code).strip() for sample_code in sample_codes if str(sample_code).strip())
    )
    if not sample_codes:
        raise ValidationError("At least one valid sample code must be provided.")

    with transaction.atomic():
        samples = list(
            BloodSample.objects.select_for_update().filter(sample_code__in=sample_codes)
        )
        found_codes = {sample.sample_code for sample in samples}
        missing = [sample_code for sample_code in sample_codes if sample_code not in found_codes]
        if missing:
            raise ValidationError(f"Sample not found: {missing[0]}")

        requests = list(
            TransportRequest.objects.select_for_update()
            .select_related("sample", "assigned_car")
            .filter(
                sample__sample_code__in=sample_codes,
                request_type="RETURN",
                status__in=["DISPATCHED", "ARRIVED_AT_DOCTOR", "LOADED_FOR_RETURN"],
            )
            .order_by("created_at")
        )
        by_code = {transport_request.sample.sample_code: transport_request for transport_request in requests}
        missing_requests = [
            sample_code for sample_code in sample_codes if sample_code not in by_code
        ]
        if missing_requests:
            raise ValidationError(
                f"Sample {missing_requests[0]} has no dispatched/arrived/loaded RETURN request."
            )

        now = timezone.now()
        affected_car_ids = set()
        updated_requests = []
        for sample_code in sample_codes:
            transport_request = by_code[sample_code]
            sample = transport_request.sample

            sample.status = "IN_STORAGE"
            sample.is_in_storage = True
            sample.save(update_fields=["status", "is_in_storage", "updated_at"])

            transport_request.status = "RETURNED"
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
                        f"Confirmed returned sample {sample.sample_code}; moved to IN_STORAGE"
                    ),
                    transport_request=transport_request,
                    car=transport_request.assigned_car,
                )

        _set_car_idle_if_ready(affected_car_ids)

    return updated_requests


def request_return_by_codes(sample_codes, doctor):
    """Accept return requests using human-readable sample codes.

    Resolves codes like 'PT-0001' to BloodSample objects and delegates
    to request_return_batch().
    """
    if not sample_codes:
        raise ValidationError("At least one sample code is required.")

    sample_codes = list(
        dict.fromkeys(
            str(code).strip() for code in sample_codes if str(code).strip()
        )
    )
    if not sample_codes:
        raise ValidationError("At least one valid sample code is required.")

    samples = list(BloodSample.objects.filter(sample_code__in=sample_codes))
    found_codes = {s.sample_code for s in samples}
    missing = [c for c in sample_codes if c not in found_codes]
    if missing:
        raise NotFound(f"Sample not found: {missing[0]}")

    return request_return_batch(
        sample_ids=[s.id for s in samples],
        doctor=doctor,
    )
