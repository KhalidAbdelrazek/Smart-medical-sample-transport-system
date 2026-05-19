"""
analytics/services/analytics_service.py

Real-time, database-driven analytics aggregation service.

Rules:
- ALL data comes from live ORM queries.
- NO caching, NO hardcoded values, NO dummy-vs-real separation.
- Reflects every database change immediately.
"""
from django.db.models import Count, Case, When, IntegerField, Q
from transport.models import TransportRequest
from analytics.models import StorageEmployeeLog
from analytics.utils.date_filters import get_date_range, period_label


def _apply_date_filter(queryset, date_field: str, start, end):
    """Apply optional start/end date filter to a queryset."""
    if start:
        queryset = queryset.filter(**{f'{date_field}__date__gte': start})
    if end:
        queryset = queryset.filter(**{f'{date_field}__date__lte': end})
    return queryset


# ---------------------------------------------------------------------------
# DOCTOR DASHBOARD
# ---------------------------------------------------------------------------

def get_doctor_dashboard(user, period: str = 'month') -> dict:
    """
    Returns aggregated TransportRequest stats for the logged-in doctor.

    - Filters strictly by request.requested_by == user
    - Aggregates in a single ORM query using Count + Case/When
    - Instantly reflects any new/updated request
    """
    start, end = get_date_range(period)

    qs = TransportRequest.objects.filter(requested_by=user)
    qs = _apply_date_filter(qs, 'created_at', start, end)

    aggregated = qs.aggregate(
        total_requests=Count('id'),
        successful_requests=Count(Case(When(status='DELIVERED', then=1), output_field=IntegerField())),
        failed_requests=Count(Case(When(status='FAILED', then=1), output_field=IntegerField())),
        cancelled_requests=Count(Case(When(status='CANCELLED', then=1), output_field=IntegerField())),
        pending_requests=Count(Case(When(status='PENDING', then=1), output_field=IntegerField())),
    )

    total = aggregated['total_requests']
    successful = aggregated['successful_requests']

    # Avoid division by zero
    success_rate = round((successful / total) * 100, 2) if total > 0 else 0.0

    return {
        'total_requests': total,
        'successful_requests': successful,
        'failed_requests': aggregated['failed_requests'],
        'cancelled_requests': aggregated['cancelled_requests'],
        'pending_requests': aggregated['pending_requests'],
        'success_rate': success_rate,
        'period': period_label(period),
        'role': 'DOCTOR',
    }


# ---------------------------------------------------------------------------
# STORAGE EMPLOYEE DASHBOARD
# ---------------------------------------------------------------------------

def get_storage_employee_dashboard(user, period: str = 'month') -> dict:
    """
    Returns aggregated StorageEmployeeLog stats for the logged-in storage employee.

    - Filters strictly by log.employee == user
    - Counts each action type via Case/When in a single query
    - Instantly reflects any newly created log entry
    """
    start, end = get_date_range(period)

    qs = StorageEmployeeLog.objects.filter(employee=user)
    qs = _apply_date_filter(qs, 'created_at', start, end)

    aggregated = qs.aggregate(
        total_actions=Count('id'),
        car_dispatch=Count(Case(When(action='CAR_DISPATCH', then=1), output_field=IntegerField())),
        sample_added_to_car=Count(Case(When(action='SAMPLE_ADDED_TO_CAR', then=1), output_field=IntegerField())),
        sample_removed_from_car=Count(Case(When(action='SAMPLE_REMOVED_FROM_CAR', then=1), output_field=IntegerField())),
        transport_request_update=Count(Case(When(action='TRANSPORT_REQUEST_UPDATE', then=1), output_field=IntegerField())),
        other=Count(Case(
            When(action='OTHER', then=1),
            When(action='CAR_STATUS_UPDATE', then=1),
            output_field=IntegerField()
        )),
    )

    return {
        'total_actions': aggregated['total_actions'],
        'car_dispatch': aggregated['car_dispatch'],
        'sample_added_to_car': aggregated['sample_added_to_car'],
        'sample_removed_from_car': aggregated['sample_removed_from_car'],
        'transport_request_update': aggregated['transport_request_update'],
        'other': aggregated['other'],
        'period': period_label(period),
        'role': 'STORAGE_EMPLOYEE',
    }


# ---------------------------------------------------------------------------
# ADMIN DASHBOARD
# ---------------------------------------------------------------------------

def get_admin_dashboard(period: str = 'month') -> dict:
    """
    Returns system-wide aggregated stats for admin.

    - Aggregates ALL TransportRequest records (all doctors)
    - Aggregates ALL StorageEmployeeLog records (all storage employees)
    - Groups and counts via pure ORM — no hardcoded offsets
    - Instantly reflects every record in the database
    """
    start, end = get_date_range(period)

    # --- Doctors / Transport Requests ---
    tr_qs = TransportRequest.objects.all()
    tr_qs = _apply_date_filter(tr_qs, 'created_at', start, end)

    tr_agg = tr_qs.aggregate(
        total_requests=Count('id'),
        successful=Count(Case(When(status='DELIVERED', then=1), output_field=IntegerField())),
        failed=Count(Case(When(status='FAILED', then=1), output_field=IntegerField())),
        cancelled=Count(Case(When(status='CANCELLED', then=1), output_field=IntegerField())),
        pending=Count(Case(When(status='PENDING', then=1), output_field=IntegerField())),
    )

    # --- Storage / Employee Logs ---
    log_qs = StorageEmployeeLog.objects.all()
    log_qs = _apply_date_filter(log_qs, 'created_at', start, end)

    log_agg = log_qs.aggregate(
        total_actions=Count('id'),
        car_dispatch=Count(Case(When(action='CAR_DISPATCH', then=1), output_field=IntegerField())),
        sample_added=Count(Case(When(action='SAMPLE_ADDED_TO_CAR', then=1), output_field=IntegerField())),
        sample_removed=Count(Case(When(action='SAMPLE_REMOVED_FROM_CAR', then=1), output_field=IntegerField())),
        transport_updates=Count(Case(When(action='TRANSPORT_REQUEST_UPDATE', then=1), output_field=IntegerField())),
        other=Count(Case(
            When(action='OTHER', then=1),
            When(action='CAR_STATUS_UPDATE', then=1),
            output_field=IntegerField()
        )),
    )

    return {
        'period': period_label(period),
        'role': 'ADMIN',
        'doctors': {
            'total_requests': tr_agg['total_requests'],
            'successful': tr_agg['successful'],
            'failed': tr_agg['failed'],
            'cancelled': tr_agg['cancelled'],
            'pending': tr_agg['pending'],
        },
        'storage': {
            'total_actions': log_agg['total_actions'],
            'car_dispatch': log_agg['car_dispatch'],
            'sample_added': log_agg['sample_added'],
            'sample_removed': log_agg['sample_removed'],
            'transport_updates': log_agg['transport_updates'],
            'other': log_agg['other'],
        },
    }
