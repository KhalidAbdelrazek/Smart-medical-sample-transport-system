"""
accounts/selectors.py

Database query layer for user-related queries.
Handles filtering and pagination of User data.
"""
from typing import Optional, List, Dict
from django.db.models import Q

from accounts.models import User


def get_users_queryset(
    role: Optional[str] = None,
    search: Optional[str] = None,
) -> 'QuerySet':
    """
    Get base queryset for User with optional filters.
    
    Args:
        role: Filter by user role (DOCTOR, STORAGE_EMPLOYEE, ADMIN)
        search: Search by full_name or email (case-insensitive)
    
    Returns:
        QuerySet of filtered User objects
    """
    queryset = User.objects.all()
    
    # Filter by role
    if role:
        queryset = queryset.filter(role=role)
    
    # Search by name or email (case-insensitive)
    if search:
        queryset = queryset.filter(
            Q(full_name__icontains=search) |
            Q(email__icontains=search)
        )
    
    return queryset.order_by('-created_at')


def get_users_list(
    role: Optional[str] = None,
    search: Optional[str] = None,
    page: int = 1,
    page_size: int = 20,
) -> Dict:
    """
    Get paginated list of users with filters.
    
    Args:
        role: Filter by user role
        search: Search by name or email
        page: Page number (1-indexed)
        page_size: Number of users per page
    
    Returns:
        {
            'users': [user1, user2, ...],
            'total_count': int,
            'page': int,
            'page_size': int,
        }
    """
    queryset = get_users_queryset(role, search)
    
    # Get total count
    total_count = queryset.count()
    
    # Apply pagination
    start_idx = (page - 1) * page_size
    end_idx = start_idx + page_size
    users = list(queryset[start_idx:end_idx])
    
    return {
        'users': users,
        'total_count': total_count,
        'page': page,
        'page_size': page_size,
    }
