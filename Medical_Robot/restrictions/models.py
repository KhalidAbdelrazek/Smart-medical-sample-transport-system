"""
restrictions/models.py

Two models power the entire Restrictions System:
  - SystemRestriction : one row per restriction type (DOCTOR_SAMPLES,
                        STORAGE_SAMPLES, TRANSPORT_CAR).  Holds the
                        current mode (NONE / GLOBAL / PARTIAL).
  - RestrictedUser    : per-user block records, only meaningful when
                        the parent SystemRestriction.mode == 'PARTIAL'.
"""
import uuid
from django.db import models


class SystemRestriction(models.Model):
    """
    Global on/off switch for each restriction category.

    Exactly three rows exist (seeded by data migration):
        - DOCTOR_SAMPLES
        - STORAGE_SAMPLES
        - TRANSPORT_CAR

    mode choices:
        NONE    → no restriction active
        GLOBAL  → every user in the affected role is blocked
        PARTIAL → only users listed in RestrictedUser are blocked
    """

    RESTRICTION_TYPE_CHOICES = [
        ('DOCTOR_SAMPLES',  'Doctor Sample Requests'),
        ('STORAGE_SAMPLES', 'Storage Sample Loading'),
        ('TRANSPORT_CAR',   'Car Dispatch'),
    ]

    RESTRICTION_MODE_CHOICES = [
        ('NONE',    'Not Restricted'),
        ('GLOBAL',  'Globally Restricted'),
        ('PARTIAL', 'Partially Restricted (specific users)'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    restriction_type = models.CharField(
        max_length=30,
        choices=RESTRICTION_TYPE_CHOICES,
        unique=True,
    )

    mode = models.CharField(
        max_length=10,
        choices=RESTRICTION_MODE_CHOICES,
        default='NONE',
    )

    reason = models.TextField(
        blank=True,
        default='',
        help_text="Admin note explaining why the restriction is active.",
    )

    updated_at = models.DateTimeField(auto_now=True)

    updated_by = models.ForeignKey(
        'accounts.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='restriction_changes',
        help_text="The admin who last changed this restriction.",
    )

    class Meta:
        verbose_name = 'System Restriction'
        verbose_name_plural = 'System Restrictions'

    def __str__(self):
        return f"{self.get_restriction_type_display()} → {self.mode}"


class RestrictedUser(models.Model):
    """
    Stores individual user blocks under a PARTIAL restriction.
    Only enforced when the parent SystemRestriction.mode == 'PARTIAL'.

    The table is cleared and rebuilt atomically on every
    restrict_doctor_samples / restrict_storage_samples API call.
    """

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    restriction = models.ForeignKey(
        SystemRestriction,
        on_delete=models.CASCADE,
        related_name='restricted_users',
    )

    user = models.ForeignKey(
        'accounts.User',
        on_delete=models.CASCADE,
        related_name='active_restrictions',
    )

    restricted_at = models.DateTimeField(auto_now_add=True)

    restricted_by = models.ForeignKey(
        'accounts.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='restrictions_issued',
    )

    class Meta:
        verbose_name = 'Restricted User'
        verbose_name_plural = 'Restricted Users'
        unique_together = [('restriction', 'user')]
        indexes = [
            models.Index(fields=['restriction', 'user']),
        ]

    def __str__(self):
        return f"{self.user} blocked from {self.restriction.restriction_type}"
