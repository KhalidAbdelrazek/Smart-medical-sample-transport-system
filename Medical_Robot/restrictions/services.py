"""
restrictions/services.py

Two layers of service functions:

  CHECK LAYER  — called from samples/services.py and transport/services.py
                 before any transaction executes.  Raises PermissionDenied
                 (HTTP 403) if the user is restricted.

  APPLY LAYER  — called from restrictions/views.py to mutate the database
                 when an admin activates or lifts a restriction.
"""
from django.db import transaction
from rest_framework.exceptions import PermissionDenied

from .models import SystemRestriction, RestrictedUser


# ─────────────────────────────────────────────────────────────────
# Internal helper
# ─────────────────────────────────────────────────────────────────

def _get_restriction(restriction_type: str) -> SystemRestriction:
    """
    Return the SystemRestriction row for the given type.
    Safe because the seed migration always guarantees these rows exist.
    """
    try:
        return SystemRestriction.objects.get(restriction_type=restriction_type)
    except SystemRestriction.DoesNotExist:
        # Fallback: if seed migration hasn't run yet, treat as unrestricted.
        return SystemRestriction(restriction_type=restriction_type, mode='NONE')


# ─────────────────────────────────────────────────────────────────
# CHECK LAYER — import these into other services
# ─────────────────────────────────────────────────────────────────

def check_doctor_samples_restriction(doctor) -> None:
    """
    Guard for the 'Request Sample' operation.

    Decision tree:
      mode == NONE    → allow (return silently)
      mode == GLOBAL  → deny all doctors
      mode == PARTIAL → deny only if doctor.id is in RestrictedUser
    """
    restriction = _get_restriction('DOCTOR_SAMPLES')

    if restriction.mode == 'NONE':
        return  # ✅ No restriction active

    if restriction.mode == 'GLOBAL':
        reason_text = restriction.reason or "A system-wide emergency restriction is active."
        raise PermissionDenied(
            f"Sample requests are currently disabled for all doctors. Reason: {reason_text}"
        )

    # PARTIAL — check individual block
    if RestrictedUser.objects.filter(restriction=restriction, user=doctor).exists():
        raise PermissionDenied(
            "Your account has been restricted from requesting samples. "
            "Please contact the system administrator."
        )


def check_storage_samples_restriction(employee) -> None:
    """
    Guard for the 'Add Sample to Car' (load) operation.

    Decision tree:
      mode == NONE    → allow
      mode == GLOBAL  → deny all storage employees
      mode == PARTIAL → deny only if employee.id is in RestrictedUser
    """
    restriction = _get_restriction('STORAGE_SAMPLES')

    if restriction.mode == 'NONE':
        return  # ✅

    if restriction.mode == 'GLOBAL':
        reason_text = restriction.reason or "A system-wide emergency restriction is active."
        raise PermissionDenied(
            f"Sample loading is currently disabled for all storage employees. Reason: {reason_text}"
        )

    # PARTIAL
    if RestrictedUser.objects.filter(restriction=restriction, user=employee).exists():
        raise PermissionDenied(
            "Your account has been restricted from loading samples into cars. "
            "Please contact the system administrator."
        )


def check_transport_car_restriction() -> None:
    """
    Guard for the 'Dispatch Car' operation.
    Always binary (NONE or GLOBAL) — no per-user variant.
    """
    restriction = _get_restriction('TRANSPORT_CAR')

    if restriction.mode == 'GLOBAL':
        reason_text = restriction.reason or "A system-wide emergency restriction is active."
        raise PermissionDenied(
            f"Car dispatch is currently disabled. Reason: {reason_text}"
        )


# ─────────────────────────────────────────────────────────────────
# APPLY LAYER — called by the restriction views
# ─────────────────────────────────────────────────────────────────

def _apply_restriction(restriction_type: str, mode: str,
                       user_ids: list, reason: str, admin) -> dict:
    """
    Atomically update a SystemRestriction row and rebuild its
    RestrictedUser set.

    Steps:
      1. Update mode + reason + updated_by on the SystemRestriction row.
      2. Delete all existing RestrictedUser rows for this restriction.
      3. If mode == PARTIAL, bulk-create new RestrictedUser rows from user_ids.

    Returns a summary dict suitable for the API response.
    """
    from accounts.models import User  # local import to avoid circular deps

    with transaction.atomic():
        restriction = SystemRestriction.objects.select_for_update().get(
            restriction_type=restriction_type
        )
        restriction.mode       = mode
        restriction.reason     = reason
        restriction.updated_by = admin
        restriction.save()

        # Always wipe and rebuild the user list
        RestrictedUser.objects.filter(restriction=restriction).delete()

        blocked_count = 0
        if mode == 'PARTIAL' and user_ids:
            users = User.objects.filter(id__in=user_ids)
            RestrictedUser.objects.bulk_create([
                RestrictedUser(
                    restriction=restriction,
                    user=u,
                    restricted_by=admin,
                )
                for u in users
            ])
            blocked_count = users.count()

    # Refresh to get the auto_now updated_at value
    restriction.refresh_from_db()

    return {
        'restriction_type': restriction_type,
        'mode':             mode,
        'restricted_count': blocked_count,
        'reason':           reason,
        'updated_at':       restriction.updated_at,
    }


def apply_doctor_samples_restriction(restriction_type: str,
                                     user_ids: list,
                                     reason: str,
                                     admin) -> dict:
    """
    Apply (or lift) the DOCTOR_SAMPLES restriction.

    Args:
        restriction_type: 'NONE' | 'GLOBAL' | 'PARTIAL'
        user_ids:         List of doctor UUIDs (required when PARTIAL)
        reason:           Admin note
        admin:            The requesting admin User instance
    """
    return _apply_restriction('DOCTOR_SAMPLES', restriction_type,
                              user_ids, reason, admin)


def apply_storage_samples_restriction(restriction_type: str,
                                      user_ids: list,
                                      reason: str,
                                      admin) -> dict:
    """
    Apply (or lift) the STORAGE_SAMPLES restriction.

    Args:
        restriction_type: 'NONE' | 'GLOBAL' | 'PARTIAL'
        user_ids:         List of storage-employee UUIDs (required when PARTIAL)
        reason:           Admin note
        admin:            The requesting admin User instance
    """
    return _apply_restriction('STORAGE_SAMPLES', restriction_type,
                              user_ids, reason, admin)


def apply_transport_car_restriction(enabled: bool,
                                    reason: str,
                                    admin) -> dict:
    """
    Enable or disable the TRANSPORT_CAR (dispatch) restriction.

    Args:
        enabled: True  → GLOBAL restriction (no car may be dispatched)
                 False → NONE   (restriction lifted)
        reason:  Admin note
        admin:   The requesting admin User instance
    """
    mode = 'GLOBAL' if enabled else 'NONE'
    return _apply_restriction('TRANSPORT_CAR', mode, [], reason, admin)


def get_all_restriction_statuses() -> dict:
    """
    Return a lightweight summary of all three restriction rows.
    Used by the GET /api/restrictions/status/ polling endpoint.
    Includes names of restricted users when mode is PARTIAL.
    """
    rows = SystemRestriction.objects.all().prefetch_related('restricted_users__user')
    status_map = {r.restriction_type: r for r in rows}

    def _entry(rtype):
        row = status_map.get(rtype)
        if not row:
            return {'mode': 'NONE', 'reason': '', 'updated_at': None, 'restricted_users': []}
        
        data = {
            'mode':       row.mode,
            'reason':     row.reason,
            'updated_at': row.updated_at,
            'restricted_users': []
        }

        if row.mode == 'PARTIAL':
            # Collect ID and full_name of each restricted user
            data['restricted_users'] = [
                {
                    'id': ru.user.id,
                    'full_name': ru.user.full_name,
                    'employee_id': ru.user.employee_id
                }
                for ru in row.restricted_users.all()
            ]

        return data

    return {
        'doctor_samples':  _entry('DOCTOR_SAMPLES'),
        'storage_samples': _entry('STORAGE_SAMPLES'),
        'transport_car':   _entry('TRANSPORT_CAR'),
    }
