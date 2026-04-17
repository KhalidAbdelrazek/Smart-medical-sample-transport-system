"""
stats/selectors.py

Query/repository layer for statistics aggregation.
Uses Django ORM aggregation with Trunc functions for timeseries.
"""
from datetime import date, datetime
from typing import Optional

from django.db import models
from django.db.models import (
    Count, Q, F, Value, Case, When, IntegerField, FloatField
)
from django.db.models.functions import TruncDay, TruncWeek, TruncMonth, Coalesce
from django.utils import timezone

from transport.models import TransportRequest
from stats.models import CarDispatch, UserActivityLog
from accounts.models import User


def get_trunc_function(granularity: str):
    """Returns the appropriate Trunc function based on granularity."""
    trunc_map = {
        'day': TruncDay,
        'week': TruncWeek,
        'month': TruncMonth,
    }
    return trunc_map.get(granularity, TruncDay)


def get_request_stats(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
) -> dict:
    """
    Get aggregated request statistics for a date range.
    
    Returns:
        dict with keys: total, delivered, returned, cancelled, failed
    """
    queryset = TransportRequest.objects.all()
    
    if start_date:
        queryset = queryset.filter(created_at__date__gte=start_date)
    if end_date:
        queryset = queryset.filter(created_at__date__lte=end_date)
    
    stats = queryset.aggregate(
        total=Count('id'),
        delivered=Count('id', filter=Q(status='DELIVERED')),
        returned=Count('id', filter=Q(status='RETURNED')),
        cancelled=Count('id', filter=Q(status='CANCELLED')),
        failed=Count('id', filter=Q(status='FAILED')),
    )
    
    return stats


def get_dispatch_stats(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
) -> dict:
    """
    Get aggregated car dispatch statistics for a date range.
    
    Returns:
        dict with keys: total, success, cancelled, failed
    """
    queryset = CarDispatch.objects.all()
    
    if start_date:
        queryset = queryset.filter(started_at__date__gte=start_date)
    if end_date:
        queryset = queryset.filter(started_at__date__lte=end_date)
    
    stats = queryset.aggregate(
        total=Count('id'),
        success=Count('id', filter=Q(status='SUCCESS')),
        cancelled=Count('id', filter=Q(status='CANCELLED')),
        failed=Count('id', filter=Q(status='FAILED')),
    )
    
    return stats


def get_active_users_count(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
) -> int:
    """Get count of unique users with activity in the period."""
    queryset = UserActivityLog.objects.values('user').distinct()
    
    if start_date:
        queryset = queryset.filter(created_at__date__gte=start_date)
    if end_date:
        queryset = queryset.filter(created_at__date__lte=end_date)
    
    return queryset.count()


def get_active_cars_count(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
) -> int:
    """Get count of unique cars with activity in the period."""
    queryset = CarDispatch.objects.values('car').distinct()
    
    if start_date:
        queryset = queryset.filter(started_at__date__gte=start_date)
    if end_date:
        queryset = queryset.filter(started_at__date__lte=end_date)
    
    return queryset.count()


def get_user_activity(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    role: Optional[str] = None,
    granularity: str = 'day',
) -> models.QuerySet:
    """
    Get per-user daily/weekly/monthly request statistics from UserActivityLog.

    Returns queryset with fields:
        - date (truncated)
        - user_id, name, role
        - request_count, success_count, cancelled_count, failed_count
    """
    trunc_func = get_trunc_function(granularity)
    queryset = UserActivityLog.objects.filter(
        user__isnull=False,
        transport_request__isnull=False,
    )
    if start_date:
        queryset = queryset.filter(created_at__date__gte=start_date)
    if end_date:
        queryset = queryset.filter(created_at__date__lte=end_date)
    if role:
        queryset = queryset.filter(user__role=role)

    return queryset.annotate(
        date=trunc_func('created_at')
    ).values(
        'date',
        'user',
        'user__full_name',
        'user__role',
    ).annotate(
        user_id=F('user'),
        name=Coalesce(F('user__full_name'), Value('')),
        role=Coalesce(F('user__role'), Value('')),
        request_count=Count('transport_request', distinct=True),
        success_count=Count(
            'transport_request',
            filter=Q(outcome='SUCCESS'),
            distinct=True
        ),
        cancelled_count=Count(
            'transport_request',
            filter=Q(outcome='CANCELLED'),
            distinct=True
        ),
        failed_count=Count(
            'transport_request',
            filter=Q(outcome='FAILED'),
            distinct=True
        ),
    ).values(
        'date', 'user_id', 'name', 'role',
        'request_count', 'success_count', 'cancelled_count', 'failed_count'
    ).order_by('-date', 'role', '-request_count', 'name')


def get_top_users(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    role: Optional[str] = None,
    limit: int = 10,
) -> models.QuerySet:
    """
    Get top users by request count from UserActivityLog.

    Returns queryset with fields:
        - user_id, name, role
        - request_count, success_count, cancelled_count, failed_count
    """
    queryset = UserActivityLog.objects.filter(
        user__isnull=False,
        transport_request__isnull=False,
    )
    if start_date:
        queryset = queryset.filter(created_at__date__gte=start_date)
    if end_date:
        queryset = queryset.filter(created_at__date__lte=end_date)
    if role:
        queryset = queryset.filter(user__role=role)

    return queryset.values(
        'user',
        'user__full_name',
        'user__role',
    ).annotate(
        user_id=F('user'),
        name=Coalesce(F('user__full_name'), Value('')),
        role=Coalesce(F('user__role'), Value('')),
        request_count=Count('transport_request', distinct=True),
        success_count=Count(
            'transport_request',
            filter=Q(outcome='SUCCESS'),
            distinct=True
        ),
        cancelled_count=Count(
            'transport_request',
            filter=Q(outcome='CANCELLED'),
            distinct=True
        ),
        failed_count=Count(
            'transport_request',
            filter=Q(outcome='FAILED'),
            distinct=True
        ),
    ).values(
        'user_id', 'name', 'role',
        'request_count', 'success_count', 'cancelled_count', 'failed_count'
    ).order_by('-request_count', 'name')[:limit]


def get_requests_timeseries(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    granularity: str = 'day',
) -> models.QuerySet:
    """
    Get total system requests over time (timeseries).
    
    Returns queryset with fields:
        - date (truncated)
        - count
    """
    trunc_func = get_trunc_function(granularity)
    
    queryset = TransportRequest.objects.annotate(
        date=trunc_func('created_at')
    ).values('date').annotate(
        count=Count('id')
    ).order_by('date')
    
    if start_date:
        queryset = queryset.filter(created_at__date__gte=start_date)
    if end_date:
        queryset = queryset.filter(created_at__date__lte=end_date)
    
    return queryset


def get_car_utilization(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    car_id=None,
    granularity: str = 'day',
) -> models.QuerySet:
    """
    Get per-car dispatch and outcome metrics.
    
    Returns queryset with fields:
        - car_id, car_number
        - total_dispatches, success_dispatches, failed_dispatches, cancelled_dispatches
        - utilization_rate (percentage)
    """
    trunc_func = get_trunc_function(granularity)
    
    queryset = CarDispatch.objects.annotate(
        date=trunc_func('started_at'),
        car_number=F('car__car_number')
    ).values(
        'car_id', 'car_number'
    ).annotate(
        total_dispatches=Count('id'),
        success_dispatches=Count('id', filter=Q(status='SUCCESS')),
        failed_dispatches=Count('id', filter=Q(status='FAILED')),
        cancelled_dispatches=Count('id', filter=Q(status='CANCELLED')),
    ).annotate(
        utilization_rate=Case(
            When(total_dispatches=0, then=Value(0.0)),
            default=Value(100.0) * F('success_dispatches') / F('total_dispatches'),
            output_field=FloatField()
        )
    ).order_by('-total_dispatches')
    
    if start_date:
        queryset = queryset.filter(started_at__date__gte=start_date)
    if end_date:
        queryset = queryset.filter(started_at__date__lte=end_date)
    if car_id:
        queryset = queryset.filter(car_id=car_id)
    
    return queryset
