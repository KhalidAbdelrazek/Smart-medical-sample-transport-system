from rest_framework import serializers
from .models import BloodSample


class BloodSampleSerializer(serializers.ModelSerializer):
    """Serialize full blood sample data."""

    class Meta:
        model = BloodSample
        fields = [
            'id', 'sample_code', 'patient_name', 'patient_id',
            'blood_type', 'status', 'is_in_storage',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'status', 'is_in_storage', 'created_at', 'updated_at']


class SamplePreviewSerializer(serializers.ModelSerializer):
    """Lightweight serializer for search results."""

    class Meta:
        model = BloodSample
        fields = ['id', 'sample_code', 'patient_name', 'status', 'is_in_storage']
        read_only_fields = ['id', 'sample_code', 'patient_name', 'status', 'is_in_storage']


class SampleRequestSerializer(serializers.Serializer):
    """
    Used by Doctors when requesting a sample.
    The doctor sends: sample_code and room_number.
    """
    sample_code = serializers.CharField()
    room_number = serializers.CharField(max_length=50)
