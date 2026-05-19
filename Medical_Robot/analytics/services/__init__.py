"""
analytics/services/__init__.py

Re-exports log_storage_employee_action so that existing callers that use:
    from analytics.services import log_storage_employee_action
continue to work after the analytics/services/ package was created.
"""
# Import from the parent-level services.py module.
# We cannot do `from analytics.services import ...` (circular),
# so we import the model directly.
from analytics.models import StorageEmployeeLog


def log_storage_employee_action(
    employee,
    action,
    description='',
    transport_request=None,
    car=None,
):
    """
    Log a storage employee action.

    This is the canonical entry point kept here for backward compatibility.
    The implementation is duplicated from analytics/services.py to avoid
    circular imports inside the services package.
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
