"""
transport/serializers.py

Serializers for TransportRequest and storage employee actions.
"""
from rest_framework import serializers
from .models import TransportRequest
from samples.serializers import BloodSampleSerializer
from cars.serializers import CarSerializer


class TransportRequestSerializer(serializers.ModelSerializer):
    """Full serializer for transport requests (used in list and detail responses)."""
    sample = BloodSampleSerializer(read_only=True)
    assigned_car = CarSerializer(read_only=True)
    requested_by_name = serializers.CharField(source='requested_by.full_name', read_only=True)

    class Meta:
        model = TransportRequest
        fields = [
            'id', 'request_type', 'sample', 'requested_by_name',
            'room_number', 'assigned_car', 'status', 'created_at',
        ]


class AddToCarSerializer(serializers.Serializer):
    """Body for adding a sample to a car."""
    sample_code = serializers.CharField()
    car_id = serializers.IntegerField()


class DispatchCarSerializer(serializers.Serializer):
    """Body for dispatching a car."""
    car_id = serializers.IntegerField()


class RemoveFromCartSerializer(serializers.Serializer):
    """Body for removing a sample from a car."""

    # No input parameters needed - request_id comes from URL path
    pass


class DoctorReturnRequestSerializer(serializers.Serializer):
    """Body for doctor requesting sample return."""
    sample_code = serializers.CharField()


class StartReturnCollectionSerializer(serializers.Serializer):
    """Body for storage employee starting return collection."""
    car_id = serializers.IntegerField()
    selected_request_ids = serializers.ListField(
        child=serializers.CharField(),
        help_text="List of TransportRequest IDs to collect"
    )


class AllTransportRequestsSerializer(serializers.ModelSerializer):
    """Detailed serializer showing all request information."""

    sample_id = serializers.CharField(source="sample.id", read_only=True)
    sample_code = serializers.CharField(source="sample.sample_code", read_only=True)
    patient_name = serializers.CharField(source="sample.patient_name", read_only=True)
    blood_type = serializers.CharField(source="sample.blood_type", read_only=True)
    sample_status = serializers.CharField(source="sample.status", read_only=True)

    requested_by_id = serializers.CharField(source="requested_by.id", read_only=True)
    requested_by_name = serializers.CharField(
        source="requested_by.full_name", read_only=True
    )
    requested_by_email = serializers.CharField(
        source="requested_by.email", read_only=True
    )

    car_id = serializers.IntegerField(
        source="assigned_car.id", read_only=True, allow_null=True
    )
    car_number = serializers.CharField(
        source="assigned_car.car_number", read_only=True, allow_null=True
    )
    car_status = serializers.CharField(
        source="assigned_car.status", read_only=True, allow_null=True
    )

    class Meta:
        model = TransportRequest
        fields = [
            "id",
            "request_type",
            "status",
            "room_number",
            "created_at",
            # Sample Details
            "sample_id",
            "sample_code",
            "patient_name",
            "blood_type",
            "sample_status",
            # Doctor Details
            "requested_by_id",
            "requested_by_name",
            "requested_by_email",
            # Car Details
            "car_id",
            "car_number",
            "car_status",
        ]
