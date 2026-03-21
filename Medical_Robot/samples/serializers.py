from rest_framework import serializers
from .models import BloodSample
import re


class BloodSampleSerializer(serializers.ModelSerializer):
    """Serialize full blood sample data."""

    class Meta:
        model = BloodSample
        fields = [
            "id",
            "sample_code",
            "patient_name",
            "patient_id",
            "blood_type",
            "status",
            "is_in_storage",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "status", "is_in_storage", "created_at", "updated_at"]


class SamplePreviewSerializer(serializers.ModelSerializer):
    """Lightweight serializer for search results."""

    class Meta:
        model = BloodSample
        fields = ["id", "sample_code", "patient_name", "status", "is_in_storage"]
        read_only_fields = [
            "id",
            "sample_code",
            "patient_name",
            "status",
            "is_in_storage",
        ]


class SampleRequestSerializer(serializers.Serializer):
    """
    Used by Doctors when requesting a sample.
    The doctor sends: sample_code and room_number.
    """

    sample_code = serializers.CharField()
    room_number = serializers.CharField(max_length=50)


class CreateBloodSampleSerializer(serializers.ModelSerializer):
    """Serializer for creating new blood samples."""

    class Meta:
        model = BloodSample
        fields = ["patient_name", "patient_id", "blood_type"]

    def validate_patient_id(self, value):
        """
        Validate that patient_id follows PT-XXXX format (where X are digits).
        Example: PT-0001, PT-1234, etc.
        """
        pattern = r"^PT-\d{4}$"

        if not re.match(pattern, value, re.IGNORECASE):
            raise serializers.ValidationError(
                f"Patient ID must follow the format PT-XXXX (e.g., PT-0001), got: {value}"
            )

        value = value.upper()  # Normalize to uppercase

        # Optional: Add validation to ensure patient_id is unique
        if BloodSample.objects.filter(patient_id=value).exists():
            raise serializers.ValidationError(
                f"A blood sample for patient {value} already exists."
            )

        return value
