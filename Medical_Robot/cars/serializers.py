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
