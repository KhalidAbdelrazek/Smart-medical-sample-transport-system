"""
accounts/services.py

Business logic for authentication and user management.
Separated from views to keep code clean and easy to maintain.
"""
from django.contrib.auth import authenticate as django_authenticate
from rest_framework.exceptions import AuthenticationFailed, PermissionDenied
from rest_framework_simplejwt.tokens import RefreshToken
from typing import Optional

from .models import User
from accounts import selectors


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


def get_admin_users_list(
    role: Optional[str] = None,
    search: Optional[str] = None,
    page: int = 1,
    page_size: int = 20,
) -> dict:
    """
    Get paginated list of users for admin dashboard.
    Supports filtering by role and searching by name/email.
    
    Args:
        role: Filter by user role (DOCTOR, STORAGE_EMPLOYEE, ADMIN)
        search: Search by full_name or email (case-insensitive)
        page: Page number (1-indexed)
        page_size: Number of users per page
    
    Returns:
        {
            'users': [serialized users...],
            'pagination': {
                'page': int,
                'page_size': int,
                'total_count': int,
            }
        }
    """
    result = selectors.get_users_list(role, search, page, page_size)
    
    return {
        'users': result['users'],
        'pagination': {
            'page': result['page'],
            'page_size': result['page_size'],
            'total_count': result['total_count'],
        }
    }
