"""
accounts/services.py

Business logic for authentication.
Separated from views to keep code clean and easy to maintain.
"""
from django.contrib.auth import authenticate as django_authenticate
from rest_framework.exceptions import AuthenticationFailed, PermissionDenied
from rest_framework_simplejwt.tokens import RefreshToken

from .models import User


def get_tokens_for_user(user):
    """Generate JWT access and refresh tokens for a given user."""
    refresh = RefreshToken.for_user(user)
    return {
        'refresh': str(refresh),
        'access': str(refresh.access_token),
    }


def authenticate_staff(email, password):
    """
    Authenticate a Doctor or Storage Employee.
    Returns JWT tokens on success.
    Raises AuthenticationFailed or PermissionDenied on failure.
    """
    user = django_authenticate(username=email, password=password)
    if user is None:
        raise AuthenticationFailed("Invalid email or password.")
    if user.role not in ('DOCTOR', 'STORAGE_EMPLOYEE'):
        raise PermissionDenied("This login is for Doctors and Storage Employees only.")
    return get_tokens_for_user(user)


def authenticate_admin(email, password):
    """
    Authenticate an Admin user.
    Returns JWT tokens on success.
    Raises AuthenticationFailed or PermissionDenied on failure.
    """
    user = django_authenticate(username=email, password=password)
    if user is None:
        raise AuthenticationFailed("Invalid email or password.")
    if user.role != 'ADMIN':
        raise PermissionDenied("This login is for Admins only.")
    return get_tokens_for_user(user)
