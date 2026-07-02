"""
accounts/permissions.py

Custom DRF permission classes for role-based access control.
"""
from rest_framework.permissions import BasePermission


class IsDoctor(BasePermission):
    """Allow access only to users with the DOCTOR role."""
    message = "Only doctors can perform this action."

    def has_permission(self, request, view):
        return (
            request.user
            and request.user.is_authenticated
            and request.user.role == 'DOCTOR'
        )


class IsStorageEmployee(BasePermission):
    """Allow access only to users with the STORAGE_EMPLOYEE role."""
    message = "Only storage employees can perform this action."

    def has_permission(self, request, view):
        return (
            request.user
            and request.user.is_authenticated
            and request.user.role == 'STORAGE_EMPLOYEE'
        )


class IsAdminRole(BasePermission):
    """Allow access only to users with the ADMIN role."""
    message = "Only admins can perform this action."

    def has_permission(self, request, view):
        return (
            request.user
            and request.user.is_authenticated
            and request.user.role == 'ADMIN'
        )
