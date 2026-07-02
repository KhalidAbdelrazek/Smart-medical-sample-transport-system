"""
cars/serializers.py
"""
from rest_framework import serializers
from .models import Car


class CarSerializer(serializers.ModelSerializer):
    class Meta:
        model = Car
        fields = ['id', 'car_number', 'status', 'created_at']
        read_only_fields = ['id', 'status', 'created_at']


class CarDetailsSerializer(serializers.Serializer):
    """Serializer for car details including occupancy and sample codes."""
    car_id = serializers.IntegerField(read_only=True)
    car_number = serializers.CharField(read_only=True)
    status = serializers.CharField(read_only=True)
    capacity = serializers.IntegerField(read_only=True)
    used_capacity = serializers.IntegerField(read_only=True)
    remaining_capacity = serializers.IntegerField(read_only=True)
    sample_codes = serializers.ListField(
        child=serializers.CharField(),
        read_only=True,
        help_text="List of sample codes currently in this car"
    )
