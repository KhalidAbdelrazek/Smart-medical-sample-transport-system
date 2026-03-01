"""
samples/serializers.py

Serializers for BloodSample and the sample request action.
"""
from rest_framework import serializers
from .models import BloodSample


class BloodSampleSerializer(serializers.ModelSerializer):
    """Serialize full blood sample data."""

    class Meta:
        model = BloodSample
        fields = [
            'id', 'patient_name', 'patient_id',
            'blood_type', 'status', 'is_in_storage',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'status', 'is_in_storage', 'created_at', 'updated_at']


class SampleRequestSerializer(serializers.Serializer):
    """
    Used by Doctors when requesting a sample.
    The doctor sends: sample_id and room_number.
    """
    sample_id = serializers.UUIDField()
    room_number = serializers.CharField(max_length=50)
