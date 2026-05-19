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
        fields = ['id', 'name', 'email', 'role', 'department', 'shift', 'employee_id']
        read_only_fields = ['id', 'role', 'employee_id']


class UserListSerializer(serializers.ModelSerializer):
    """
    Serializer for listing users in admin users endpoint.
    Displays essential user info for admin dashboard.
    """
    class Meta:
        model = User
        fields = ['id', 'full_name', 'email', 'role', 'department', 'employee_id']
        read_only_fields = fields


class UserListPaginationSerializer(serializers.Serializer):
    """Pagination metadata for user list."""
    page = serializers.IntegerField(help_text="Current page number")
    page_size = serializers.IntegerField(help_text="Items per page")
    total_count = serializers.IntegerField(help_text="Total number of users")


class AdminUsersListResponseSerializer(serializers.Serializer):
    """Response serializer for admin users list endpoint."""
    users = UserListSerializer(many=True, help_text="List of users")
    pagination = UserListPaginationSerializer(help_text="Pagination metadata")


class AdminUsersListFilterSerializer(serializers.Serializer):
    """Filter parameters for admin users list endpoint."""
    role = serializers.ChoiceField(
        choices=['DOCTOR', 'STORAGE_EMPLOYEE', 'ADMIN'],
        required=False,
        allow_null=True,
        help_text="Filter by user role"
    )
    search = serializers.CharField(
        required=False,
        allow_blank=True,
        help_text="Search by user name or email (case-insensitive)"
    )
    page = serializers.IntegerField(
        required=False,
        default=1,
        min_value=1,
        help_text="Page number for pagination"
    )
    page_size = serializers.IntegerField(
        required=False,
        default=20,
        min_value=1,
        max_value=100,
        help_text="Number of users per page"
    )
