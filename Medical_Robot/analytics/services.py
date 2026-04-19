"""
analytics/services.py

Business logic layer for request analytics.
Orchestrates selectors and normalizes data for API responses.
Also handles storage employee action logging.
"""
from datetime import date
from typing import Optional, Dict

from analytics import selectors
from analytics.models import StorageEmployeeLog


def log_storage_employee_action(
    employee,
    action,
    description='',
    transport_request=None,
    car=None,
):
    """
    Log a storage employee action to the StorageEmployeeLog model.
    
    Args:
        employee: User object (must be a storage employee)
        action: One of StorageEmployeeLog.ACTION_CHOICES
                - 'CAR_DISPATCH'
                - 'SAMPLE_ADDED_TO_CAR'
                - 'SAMPLE_REMOVED_FROM_CAR'
                - 'TRANSPORT_REQUEST_UPDATE'
                - 'CAR_STATUS_UPDATE'
                - 'OTHER'
        description: String describing the action details
        transport_request: Optional TransportRequest object related to this action
        car: Optional Car object related to this action
    
    Returns:
        StorageEmployeeLog: The created log entry
    
    Raises:
        ValueError: If employee is None or action is invalid
    """
    if employee is None:
        raise ValueError("employee cannot be None")
    
    valid_actions = [choice[0] for choice in StorageEmployeeLog.ACTION_CHOICES]
    if action not in valid_actions:
        raise ValueError(f"Invalid action: {action}. Must be one of {valid_actions}")
    
    log_entry = StorageEmployeeLog.objects.create(
        employee=employee,
        action=action,
        description=description,
        transport_request=transport_request,
        car=car,
    )
    
    return log_entry


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
