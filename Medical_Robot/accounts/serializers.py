"""
accounts/serializers.py

Serializers for authentication and user profile.
"""
from django.contrib.auth import authenticate
from rest_framework import serializers
from .models import User


class LoginSerializer(serializers.Serializer):
    """Used by both Doctor and Storage Employee for login."""
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)


class AdminLoginSerializer(serializers.Serializer):
    """Used exclusively by Admin for login."""
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)


class ProfileSerializer(serializers.ModelSerializer):
    """
    Returns user profile in the format expected by the Flutter app.
    Fields: id, name, role, department, shift, employee_id
    """
    name = serializers.CharField(source='full_name')

    class Meta:
        model = User
        fields = ['id', 'name', 'role', 'department', 'shift', 'employee_id']
