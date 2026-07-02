"""
restrictions/migrations/0001_initial.py
"""
from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion
import uuid


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='SystemRestriction',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('restriction_type', models.CharField(
                    choices=[
                        ('DOCTOR_SAMPLES',  'Doctor Sample Requests'),
                        ('STORAGE_SAMPLES', 'Storage Sample Loading'),
                        ('TRANSPORT_CAR',   'Car Dispatch'),
                    ],
                    max_length=30,
                    unique=True,
                )),
                ('mode', models.CharField(
                    choices=[
                        ('NONE',    'Not Restricted'),
                        ('GLOBAL',  'Globally Restricted'),
                        ('PARTIAL', 'Partially Restricted (specific users)'),
                    ],
                    default='NONE',
                    max_length=10,
                )),
                ('reason', models.TextField(blank=True, default='', help_text='Admin note explaining why the restriction is active.')),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('updated_by', models.ForeignKey(
                    blank=True,
                    null=True,
                    on_delete=django.db.models.deletion.SET_NULL,
                    related_name='restriction_changes',
                    to=settings.AUTH_USER_MODEL,
                    help_text='The admin who last changed this restriction.',
                )),
            ],
            options={
                'verbose_name': 'System Restriction',
                'verbose_name_plural': 'System Restrictions',
            },
        ),
        migrations.CreateModel(
            name='RestrictedUser',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('restricted_at', models.DateTimeField(auto_now_add=True)),
                ('restriction', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='restricted_users',
                    to='restrictions.systemrestriction',
                )),
                ('user', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='active_restrictions',
                    to=settings.AUTH_USER_MODEL,
                )),
                ('restricted_by', models.ForeignKey(
                    blank=True,
                    null=True,
                    on_delete=django.db.models.deletion.SET_NULL,
                    related_name='restrictions_issued',
                    to=settings.AUTH_USER_MODEL,
                )),
            ],
            options={
                'verbose_name': 'Restricted User',
                'verbose_name_plural': 'Restricted Users',
            },
        ),
        migrations.AddIndex(
            model_name='restricteduser',
            index=models.Index(fields=['restriction', 'user'], name='restrictions_rest_user_idx'),
        ),
        migrations.AlterUniqueTogether(
            name='restricteduser',
            unique_together={('restriction', 'user')},
        ),
    ]
