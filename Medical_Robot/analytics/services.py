"""
analytics/services.py

Business logic layer for request analytics.
Orchestrates selectors and normalizes data for API responses.
"""
from datetime import date
from typing import Optional, Dict

from analytics import selectors


def get_request_analytics(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    granularity: str = 'day',
    role: Optional[str] = None,
    user_id: Optional[str] = None,
    search: Optional[str] = None,
) -> Dict:
    """
    Get complete request analytics for the given filters and granularity.
    
    This is the main entry point for analytics data retrieval.
    Returns aggregated summary and time-series data.
    
    Args:
        start_date: Filter requests created on or after this date
        end_date: Filter requests created on or before this date
        granularity: Aggregation granularity ('day', 'month', 'year')
        role: Filter by user role (DOCTOR, STORAGE_EMPLOYEE, ADMIN)
        user_id: Filter by specific user ID (UUID string)
        search: Search by user name or email (case-insensitive)
    
    Returns:
        {
            'summary': {
                'total_requests': int,
                'succeeded': int,
                'failed': int,
                'cancelled': int,
                'returned': int,
            },
            'timeseries': [
                {
                    'period': str,
                    'total': int,
                    'succeeded': int,
                    'failed': int,
                    'cancelled': int,
                    'returned': int,
                },
                ...
            ]
        }
    """
    # Validate granularity
    if granularity not in ['day', 'month', 'year']:
        raise ValueError(f"Invalid granularity: {granularity}. Must be 'day', 'month', or 'year'.")
    
    # Get summary statistics
    summary = selectors.get_request_summary(start_date, end_date, role, user_id, search)
    
    # Get time-series data
    timeseries = selectors.get_request_timeseries(start_date, end_date, granularity, role, user_id, search)
    
    return {
        'summary': summary,
        'timeseries': timeseries,
    }

def get_storage_employee_logs_analytics(
    start_date=None,
    end_date=None,
    granularity='day',
    employee_id=None,
    search=None,
    action=None,
):
    """
    Get complete storage employee log analytics for the given filters.
    Returns summary and timeseries dicts.
    """
    if granularity not in ['day', 'month', 'year']:
        raise ValueError(f"Invalid granularity: {granularity}.")
    from analytics import selectors
    summary = selectors.get_storage_employee_logs_summary(start_date, end_date, employee_id, search, action)
    timeseries = selectors.get_storage_employee_logs_timeseries(start_date, end_date, granularity, employee_id, search, action)
    return { 'summary': summary, 'timeseries': timeseries }
