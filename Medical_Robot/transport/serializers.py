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
            'id', 'sample', 'requested_by_name',
            'room_number', 'assigned_car', 'status', 'created_at',
        ]


class AddToCarSerializer(serializers.Serializer):
    """Body for adding a sample to a car."""
    sample_code = serializers.CharField()
    car_id = serializers.IntegerField()


class DispatchCarSerializer(serializers.Serializer):
    """Body for dispatching a car."""
    car_id = serializers.IntegerField()
