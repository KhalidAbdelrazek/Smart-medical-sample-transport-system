"""
restrictions/migrations/0002_seed_system_restrictions.py

Seeds exactly three rows — one per restriction type — all starting as NONE.
Uses get_or_create so re-running is safe.
"""
from django.db import migrations


def seed_restrictions(apps, schema_editor):
    SystemRestriction = apps.get_model('restrictions', 'SystemRestriction')
    for rtype in ['DOCTOR_SAMPLES', 'STORAGE_SAMPLES', 'TRANSPORT_CAR']:
        SystemRestriction.objects.get_or_create(
            restriction_type=rtype,
            defaults={'mode': 'NONE', 'reason': ''},
        )


def reverse_seed(apps, schema_editor):
    # Leave rows in place on reverse — safe, non-destructive.
    pass


class Migration(migrations.Migration):

    dependencies = [
        ('restrictions', '0001_initial'),
    ]

    operations = [
        migrations.RunPython(seed_restrictions, reverse_seed),
    ]
