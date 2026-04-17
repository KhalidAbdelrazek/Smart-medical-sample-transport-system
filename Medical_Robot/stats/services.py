"""
stats/services.py

Business logic layer for statistics APIs.
Composes selectors and normalizes data for API responses.
"""
from datetime import date, datetime
from typing import Optional

from django.db import transaction
from django.utils import timezone

from accounts.models import User
from stats import selectors
from stats.models import CarDispatch, UserActivityLog


def get_admin_stats(
    start_date=None,
    end_date=None,
    granularity='day',
    role=None,
    car_id=None,
    top=10,
    page=1,
    page_size=20,
) -> dict:
    """
    Orchestrate all admin stats into a single response.

    Returns:
        {
            'overview': {...},
            'requests_timeseries': [...],
            'user_activity': [...],
            'user_activity_pagination': {'page': int, 'page_size': int, 'total_count': int},
            'top_users': {'ADMIN': [...], 'DOCTOR': [...], 'STORAGE_EMPLOYEE': [...]},
            'car_utilization': [...],
        }
    """
    overview = get_overview_stats(start_date, end_date)
    requests_timeseries = get_requests_timeseries(start_date, end_date, granularity)
    car_utilization = get_car_utilization(start_date, end_date, car_id, granularity)

    # User activity with pagination
    full_user_activity = selectors.get_user_activity(start_date, end_date, role, granularity)
    total_count = full_user_activity.count()
    start_idx = (page - 1) * page_size
    end_idx = start_idx + page_size
    user_activity = list(full_user_activity[start_idx:end_idx])

    top_users = get_top_users(start_date, end_date, role, top)

    return {
        'overview': overview,
        'requests_timeseries': list(requests_timeseries),
        'user_activity': user_activity,
        'user_activity_pagination': {
            'page': page,
            'page_size': page_size,
            'total_count': total_count,
        },
        'top_users': top_users,
        'car_utilization': list(car_utilization),
    }


def get_overview_stats(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
) -> dict:
    """
    Get system overview statistics.
    
    Returns:
        {
            'requests': {total, delivered, returned, cancelled, failed},
            'dispatches': {total, success, cancelled, failed},
            'active_users_count': int,
            'active_cars_count': int,
        }
    """
    request_stats = selectors.get_request_stats(start_date, end_date)
    dispatch_stats = selectors.get_dispatch_stats(start_date, end_date)
    active_users = selectors.get_active_users_count(start_date, end_date)
    active_cars = selectors.get_active_cars_count(start_date, end_date)
    
    return {
        'requests': request_stats,
        'dispatches': dispatch_stats,
        'active_users_count': active_users,
        'active_cars_count': active_cars,
    }


def get_user_activity_stats(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    role: Optional[str] = None,
    granularity: str = 'day',
):
    """
    Get per-user activity statistics with pagination.
    Returns queryset from selector.
    """
    return selectors.get_user_activity(start_date, end_date, role, granularity)


def get_top_users(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    role: Optional[str] = None,
    limit: int = 10,
):
    """
    Get top users by request count grouped by role.
    """
    all_roles = [role_value for role_value, _ in User.ROLE_CHOICES]
    selected_roles = [role] if role else all_roles
    top_users_by_role = {role_value: [] for role_value in all_roles}

    for role_value in selected_roles:
        top_users_by_role[role_value] = list(
            selectors.get_top_users(
                start_date=start_date,
                end_date=end_date,
                role=role_value,
                limit=limit,
            )
        )

    return top_users_by_role


def get_requests_timeseries(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    granularity: str = 'day',
):
    """
    Get system-wide request timeseries data.
    """
    return selectors.get_requests_timeseries(start_date, end_date, granularity)


def get_car_utilization(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    car_id=None,
    granularity: str = 'day',
):
    """
    Get per-car utilization metrics.
    """
    return selectors.get_car_utilization(start_date, end_date, car_id, granularity)


@transaction.atomic
def log_user_activity(
    user,
    action_type: str,
    outcome: str = 'PENDING',
    transport_request=None,
    car_dispatch=None,
    car=None,
    sample_code: str = '',
    notes: str = '',
) -> UserActivityLog:
    """
    Create an immutable user activity log entry.
    
    This should be called from transport services to track lifecycle events.
    """
    user_role = getattr(user, 'role', '') if user else ''
    
    activity_log = UserActivityLog.objects.create(
        user=user,
        action_type=action_type,
        outcome=outcome,
        transport_request=transport_request,
        car_dispatch=car_dispatch,
        user_role=user_role,
        car=car,
        sample_code=sample_code,
        notes=notes,
    )
    
    return activity_log


@transaction.atomic
def create_car_dispatch(
    car,
    dispatched_by,
    request_count: int = 0,
    notes: str = '',
) -> CarDispatch:
    """
    Create a new car dispatch record.
    Also logs the activity.
    """
    dispatch = CarDispatch.objects.create(
        car=car,
        dispatched_by=dispatched_by,
        request_count=request_count,
        notes=notes,
        status='DISPATCHED',
    )
    
    log_user_activity(
        user=dispatched_by,
        action_type='CAR_DISPATCHED',
        outcome='PENDING',
        car_dispatch=dispatch,
        car=car,
        notes=f"Car dispatched with {request_count} requests",
    )
    
    return dispatch


@transaction.atomic
def complete_car_dispatch(dispatch: CarDispatch) -> CarDispatch:
    """Mark a car dispatch as successful."""
    dispatch.status = 'SUCCESS'
    dispatch.completed_at = timezone.now()
    dispatch.save()
    
    log_user_activity(
        user=dispatch.dispatched_by,
        action_type='CAR_DISPATCH_SUCCESS',
        outcome='SUCCESS',
        car_dispatch=dispatch,
        car=dispatch.car,
        notes="Car dispatch completed successfully",
    )
    
    return dispatch


@transaction.atomic
def cancel_car_dispatch(dispatch: CarDispatch, notes: str = '') -> CarDispatch:
    """Cancel a car dispatch."""
    dispatch.status = 'CANCELLED'
    dispatch.cancelled_at = timezone.now()
    if notes:
        dispatch.notes = f"{dispatch.notes}\nCancelled: {notes}" if dispatch.notes else f"Cancelled: {notes}"
    dispatch.save()
    
    log_user_activity(
        user=dispatch.dispatched_by,
        action_type='CAR_DISPATCH_CANCELLED',
        outcome='CANCELLED',
        car_dispatch=dispatch,
        car=dispatch.car,
        notes=notes or "Car dispatch cancelled",
    )
    
    return dispatch


@transaction.atomic
def fail_car_dispatch(dispatch: CarDispatch, notes: str = '') -> CarDispatch:
    """Mark a car dispatch as failed."""
    dispatch.status = 'FAILED'
    dispatch.failed_at = timezone.now()
    if notes:
        dispatch.notes = f"{dispatch.notes}\nFailed: {notes}" if dispatch.notes else f"Failed: {notes}"
    dispatch.save()
    
    log_user_activity(
        user=dispatch.dispatched_by,
        action_type='CAR_DISPATCH_FAILED',
        outcome='FAILED',
        car_dispatch=dispatch,
        car=dispatch.car,
        notes=notes or "Car dispatch failed",
    )
    
    return dispatch
