"""
restrictions/services.py

Two layers of service functions:

  CHECK LAYER  — called from samples/services.py and transport/services.py
                 before any transaction executes.  Raises PermissionDenied
                 (HTTP 403) if the user is restricted.

  APPLY LAYER  — called from restrictions/views.py to mutate the database
                 when an admin activates or lifts a restriction.
"""
from django.db import transaction, models
from django.db.models import Value, BooleanField, Exists, OuterRef, F
from rest_framework.exceptions import PermissionDenied

from .models import SystemRestriction, RestrictedUser


# ─────────────────────────────────────────────────────────────────
# Internal helper
# ─────────────────────────────────────────────────────────────────

def _get_restriction(restriction_type: str) -> SystemRestriction:
    """
    Return the SystemRestriction row for the given type.
    If it doesn't exist, create it with a default mode of ALL_UNRESTRICT.
    """
    restriction, _ = SystemRestriction.objects.get_or_create(
        restriction_type=restriction_type,
        defaults={'mode': 'ALL_UNRESTRICT'}
    )
    return restriction


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

    if restriction.mode == 'ALL_UNRESTRICT':
        return  # ✅ No restriction active

    if restriction.mode == 'GLOBAL_RESTRICT':
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

    if restriction.mode == 'ALL_UNRESTRICT':
        return  # ✅

    if restriction.mode == 'GLOBAL_RESTRICT':
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


def check_transport_robot_restriction() -> None:
    """
    Guard for the 'Dispatch Robot' operation.
    Always binary (NONE or GLOBAL) — no per-user variant.
    """
    restriction = _get_restriction('TRANSPORT_ROBOT')

    if restriction.mode == 'GLOBAL_RESTRICT':
        reason_text = restriction.reason or "A system-wide emergency restriction is active."
        raise PermissionDenied(
            f"Robot dispatch is currently disabled. Reason: {reason_text}"
        )


# ─────────────────────────────────────────────────────────────────
# APPLY LAYER — called by the restriction views
# ─────────────────────────────────────────────────────────────────

def _apply_restriction(restriction_type: str, mode: str,
                       user_ids: list, reason: str, admin) -> dict:
    """
    Atomically update a SystemRestriction row.

    Modes:
      ALL_UNRESTRICT    -> Lift all restrictions
      GLOBAL_RESTRICT   -> Block everyone
      PARTIAL_RESTRICT  -> Block specific users (requires user_ids)
      PARTIAL_UNRESTRICT -> Unblock specific user (requires target_user_id)
    """
    from accounts.models import User
    from rest_framework.exceptions import ValidationError

    role_map = {
        'DOCTOR_SAMPLES': 'DOCTOR',
        'STORAGE_SAMPLES': 'STORAGE_EMPLOYEE'
    }
    required_role = role_map.get(restriction_type)

    with transaction.atomic():
        restriction, _ = SystemRestriction.objects.select_for_update().get_or_create(
            restriction_type=restriction_type,
            defaults={'mode': 'ALL_UNRESTRICT'}
        )

        if restriction_type == 'TRANSPORT_ROBOT' and mode in ['PARTIAL_RESTRICT', 'PARTIAL_UNRESTRICT']:
            raise ValidationError("Partial restrictions are not supported for the Transport Robot.")

        if mode == 'PARTIAL_UNRESTRICT':
            if restriction.mode == 'GLOBAL_RESTRICT':
                # Transition: block ALL users except those in user_ids
                restriction.mode = 'PARTIAL_RESTRICT'
                role_map = {
                    'DOCTOR_SAMPLES': 'DOCTOR',
                    'STORAGE_SAMPLES': 'STORAGE_EMPLOYEE'
                }
                role = role_map.get(restriction_type)
                
                if role:
                    others = User.objects.filter(role=role, is_active=True).exclude(id__in=user_ids)
                    RestrictedUser.objects.filter(restriction=restriction).delete()
                    RestrictedUser.objects.bulk_create([
                        RestrictedUser(restriction=restriction, user=u, restricted_by=admin)
                        for u in others
                    ])
            else:
                # Remove specific users from the restricted list
                RestrictedUser.objects.filter(restriction=restriction, user_id__in=user_ids).delete()
            
            # Automatic Reset: If empty, switch to ALL_UNRESTRICT
            remaining = RestrictedUser.objects.filter(restriction=restriction).count()
            if remaining == 0:
                restriction.mode = 'ALL_UNRESTRICT'
            
            if reason:
                restriction.reason = reason
        else:
            # Standard modes
            restriction.mode   = mode
            restriction.reason = reason
            
            if mode != 'PARTIAL_RESTRICT':
                RestrictedUser.objects.filter(restriction=restriction).delete()

        restriction.updated_by = admin
        restriction.save()

        # Rebuild list if setting PARTIAL_RESTRICT
        if mode == 'PARTIAL_RESTRICT':
            if user_ids:
                users = User.objects.filter(id__in=user_ids)
                
                # Validation: Check roles
                if required_role:
                    invalid_users = users.exclude(role=required_role)
                    if invalid_users.exists():
                        raise ValidationError(
                            "Invalid User ID: User role does not match the restriction category."
                        )

                existing_user_ids = set(RestrictedUser.objects.filter(
                    restriction=restriction, user_id__in=user_ids
                ).values_list('user_id', flat=True))
                
                new_users = [u for u in users if u.id not in existing_user_ids]
                
                if new_users:
                    RestrictedUser.objects.bulk_create([
                        RestrictedUser(restriction=restriction, user=u, restricted_by=admin)
                        for u in new_users
                    ])

        blocked_count = RestrictedUser.objects.filter(restriction=restriction).count()

    restriction.refresh_from_db()
    return {
        'restriction_type': restriction_type,
        'mode':             restriction.mode,
        'restricted_count': blocked_count,
        'reason':           restriction.reason,
        'updated_at':       restriction.updated_at,
    }


def apply_doctor_samples_restriction(restriction_type: str,
                                     user_ids: list,
                                     reason: str,
                                     admin) -> dict:
    """
    Apply (or lift) the DOCTOR_SAMPLES restriction.
    """
    return _apply_restriction('DOCTOR_SAMPLES', restriction_type,
                              user_ids, reason, admin)


def apply_storage_samples_restriction(restriction_type: str,
                                      user_ids: list,
                                      reason: str,
                                      admin) -> dict:
    """
    Apply (or lift) the STORAGE_SAMPLES restriction.
    """
    return _apply_restriction('STORAGE_SAMPLES', restriction_type,
                              user_ids, reason, admin)


def apply_transport_robot_restriction(enabled: bool,
                                      reason: str,
                                      admin) -> dict:
    """
    Enable or disable the TRANSPORT_ROBOT (dispatch) restriction.

    Args:
        enabled: True  → GLOBAL restriction (no robot may be dispatched)
                 False → NONE   (restriction lifted)
        reason:  Admin note
        admin:   The requesting admin User instance
    """
    mode = 'GLOBAL_RESTRICT' if enabled else 'ALL_UNRESTRICT'
    return _apply_restriction('TRANSPORT_ROBOT', mode, [], reason, admin)


def get_all_restriction_statuses(categories: list = None) -> dict:
    """
    Return a detailed summary of requested restriction rows.
    Now includes a full list of users for each category (Doctor/Storage).
    """
    if not categories:
        return {}

    from accounts.models import User
    from django.db.models import Case, When, Subquery, DateTimeField

    rows = SystemRestriction.objects.all().prefetch_related('restricted_users__user')
    status_map = {r.restriction_type: r for r in rows}

    def _get_category_data(rtype, role):
        row = status_map.get(rtype)
        if not row:
            return {'mode': 'ALL_UNRESTRICT', 'reason': '', 'updated_at': None, 'users': []}
        
        mode = row.mode
        
        # Base queryset for users in this role
        users_qs = User.objects.filter(role=role, is_active=True).order_by('full_name')

        if mode == 'GLOBAL_RESTRICT':
            users_qs = users_qs.annotate(
                _is_res=Value(True, output_field=BooleanField()),
                _upd_at=Value(row.updated_at, output_field=DateTimeField())
            )
        elif mode == 'ALL_UNRESTRICT':
            users_qs = users_qs.annotate(
                _is_res=Value(False, output_field=BooleanField()),
                _upd_at=Value(row.updated_at, output_field=DateTimeField())
            )
        else:  # PARTIAL_RESTRICT
            restricted_subquery = RestrictedUser.objects.filter(
                restriction=row,
                user=OuterRef('pk')
            )
            users_qs = users_qs.annotate(
                _is_res=Exists(restricted_subquery),
                _res_at=Subquery(restricted_subquery.values('restricted_at')[:1])
            ).annotate(
                _upd_at=Case(
                    When(_is_res=True, then=F('_res_at')),
                    default=Value(row.updated_at),
                    output_field=DateTimeField()
                )
            )

        users_list = [
            {
                'id': u.id,
                'name': u.full_name,
                'is_restricted': u._is_res,
                'updated_at': u._upd_at
            }
            for u in users_qs
        ]

        return {
            'mode': mode,
            'reason': row.reason,
            'updated_at': row.updated_at,
            'users': users_list
        }

    response_data = {}
    
    if 'doctor' in categories:
        response_data['doctor_samples'] = _get_category_data('DOCTOR_SAMPLES', 'DOCTOR')
    
    if 'storage' in categories:
        response_data['storage_samples'] = _get_category_data('STORAGE_SAMPLES', 'STORAGE_EMPLOYEE')
        
    if 'robot' in categories:
        row = status_map.get('TRANSPORT_ROBOT')
        if row:
            response_data['transport_robot'] = {
                'mode': row.mode,
                'is_restricted': row.mode == 'GLOBAL_RESTRICT',
                'updated_at': row.updated_at,
                'reason': row.reason
            }
            response_data['robot_restriction'] = row.mode
        else:
            response_data['transport_robot'] = {
                'mode': 'ALL_UNRESTRICT',
                'is_restricted': False,
                'updated_at': None,
                'reason': ''
            }
            response_data['robot_restriction'] = 'ALL_UNRESTRICT'

    return response_data


def get_users_restriction_status(category: str):
    """
    Return a list of users (id, name, is_restricted) for a given category.
    Used by GET /api/restrictions/status/?type=...
    
    Logic:
      - GLOBAL  → all is_restricted: True
      - PARTIAL → only those in RestrictedUser are True
      - NONE    → all is_restricted: False
    """
    from accounts.models import User

    if category == 'doctor':
        role = 'DOCTOR'
        restriction_type = 'DOCTOR_SAMPLES'
    elif category == 'storage':
        role = 'STORAGE_EMPLOYEE'
        restriction_type = 'STORAGE_SAMPLES'
    else:
        return []

    restriction = _get_restriction(restriction_type)
    mode = restriction.mode

    queryset = User.objects.filter(role=role, is_active=True)

    if mode == 'GLOBAL_RESTRICT':
        queryset = queryset.annotate(
            _res=Value(True, output_field=BooleanField())
        )
    elif mode == 'ALL_UNRESTRICT':
        queryset = queryset.annotate(
            _res=Value(False, output_field=BooleanField())
        )
    else:  # PARTIAL
        # Exists subquery for performance
        restricted_subquery = RestrictedUser.objects.filter(
            restriction=restriction,
            user=OuterRef('pk')
        )
        queryset = queryset.annotate(
            _res=Exists(restricted_subquery)
        )

    # Alphabetical sorting and field mapping
    return queryset.order_by('full_name').values(
        'id',
        name=F('full_name'),
        is_restricted=F('_res')
    )
