"""
Data migration: move any APPROVED_BY_STORAGE rows to RETURN_REQUESTED.

This is needed because Edit 1 removes the storage-approval step entirely.
Existing rows with that status would be orphaned without this cleanup.
"""
from django.db import migrations


def forward(apps, schema_editor):
    TransportRequest = apps.get_model("transport", "TransportRequest")
    updated = TransportRequest.objects.filter(
        status="APPROVED_BY_STORAGE",
    ).update(status="RETURN_REQUESTED")
    if updated:
        print(f"\n  Migrated {updated} APPROVED_BY_STORAGE → RETURN_REQUESTED")


def reverse(apps, schema_editor):
    # No reliable way to reverse; leave as RETURN_REQUESTED.
    pass


class Migration(migrations.Migration):

    dependencies = [
        ("transport", "0006_add_arrived_at_doctor_delivery_status"),
    ]

    operations = [
        migrations.RunPython(forward, reverse, elidable=True),
    ]
