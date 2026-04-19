"""
analytics/services.py

Public service API for the analytics app.

- log_storage_employee_action() → used by other apps (cars, transport) to record employee actions
- Analytics aggregation is handled in analytics/services/analytics_service.py
"""
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
        action: One of StorageEmployeeLog.ACTION_CHOICES:
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

    return StorageEmployeeLog.objects.create(
        employee=employee,
        action=action,
        description=description,
        transport_request=transport_request,
        car=car,
    )
