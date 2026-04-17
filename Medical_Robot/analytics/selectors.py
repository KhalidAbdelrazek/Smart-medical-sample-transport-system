"""
analytics/selectors.py

Database query layer for request analytics.
Handles filtering and aggregation of TransportRequest data.
"""
from datetime import date
from typing import Optional, List, Dict
from django.db.models import Q, Count, Case, When, Value, CharField
from django.db.models.functions import TruncDate, TruncMonth, TruncYear

from transport.models import TransportRequest


def get_requests_queryset(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    role: Optional[str] = None,
    user_id: Optional[str] = None,
    search: Optional[str] = None,
) -> 'QuerySet':
    """
    Get base queryset for TransportRequest with optional filters.
    
    Args:
        start_date: Filter requests created on or after this date
        end_date: Filter requests created on or before this date
        role: Filter by requested_by user role (DOCTOR, STORAGE_EMPLOYEE, ADMIN)
        user_id: Filter by specific user ID
        search: Search by user name or email (case-insensitive)
    
    Returns:
        QuerySet of filtered TransportRequest objects
    """
    queryset = TransportRequest.objects.all()
    
    # Filter by date range
    if start_date:
        queryset = queryset.filter(created_at__date__gte=start_date)
    if end_date:
        queryset = queryset.filter(created_at__date__lte=end_date)
    
    # Filter by user role
    if role:
        queryset = queryset.filter(requested_by__role=role)
    
    # Filter by specific user
    if user_id:
        queryset = queryset.filter(requested_by__id=user_id)
    
    # Search by user name or email (case-insensitive)
    if search:
        queryset = queryset.filter(
            Q(requested_by__full_name__icontains=search) |
            Q(requested_by__email__icontains=search)
        )
    
    return queryset


def get_request_summary(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    role: Optional[str] = None,
    user_id: Optional[str] = None,
    search: Optional[str] = None,
) -> Dict[str, int]:
    """
    Get aggregated request statistics for the given period and filters.
    
    Args:
        start_date: Start date for filtering
        end_date: End date for filtering
        role: Filter by user role
        user_id: Filter by specific user ID
        search: Search by user name or email
    
    Returns:
        Dictionary with keys: total_requests, succeeded, failed, cancelled, returned
    """
    queryset = get_requests_queryset(start_date, end_date, role, user_id, search)
    
    # Count by status
    total = queryset.count()
    succeeded = queryset.filter(status='DELIVERED').count()
    failed = queryset.filter(status='FAILED').count()
    cancelled = queryset.filter(status='CANCELLED').count()
    returned = queryset.filter(status='RETURNED').count()
    
    return {
        'total_requests': total,
        'succeeded': succeeded,
        'failed': failed,
        'cancelled': cancelled,
        'returned': returned,
    }


def get_request_timeseries(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    granularity: str = 'day',
    role: Optional[str] = None,
    user_id: Optional[str] = None,
    search: Optional[str] = None,
) -> List[Dict]:
    """
    Get time-series data for requests, grouped by granularity.
    
    Args:
        start_date: Start date for filtering
        end_date: End date for filtering
        granularity: 'day', 'month', or 'year'
        role: Filter by user role
        user_id: Filter by specific user ID
        search: Search by user name or email
    
    Returns:
        List of dictionaries with timeseries data
        Each dict has: period, total, succeeded, failed, cancelled, returned
    """
    queryset = get_requests_queryset(start_date, end_date, role, user_id, search)
    
    # Choose truncation function based on granularity
    if granularity == 'day':
        trunc_func = TruncDate
        date_format = '%Y-%m-%d'
    elif granularity == 'month':
        trunc_func = TruncMonth
        date_format = '%Y-%m'
    elif granularity == 'year':
        trunc_func = TruncYear
        date_format = '%Y'
    else:
        raise ValueError(f"Invalid granularity: {granularity}")
    
    # Annotate with truncated date
    queryset = queryset.annotate(period=trunc_func('created_at'))
    
    # Group and count by period and status
    grouped = queryset.values('period').annotate(
        total=Count('id'),
        succeeded=Count(Case(When(status='DELIVERED', then=1))),
        failed=Count(Case(When(status='FAILED', then=1))),
        cancelled=Count(Case(When(status='CANCELLED', then=1))),
        returned=Count(Case(When(status='RETURNED', then=1))),
    ).order_by('period')
    
    # Format results
    timeseries = []
    for row in grouped:
        period_value = row['period']
        if period_value:
            period_str = period_value.strftime(date_format)
        else:
            period_str = 'Unknown'
        
        timeseries.append({
            'period': period_str,
            'total': row['total'],
            'succeeded': row['succeeded'],
            'failed': row['failed'],
            'cancelled': row['cancelled'],
            'returned': row['returned'],
        })
    
    return timeseries
