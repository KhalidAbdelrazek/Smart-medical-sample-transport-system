# Generated migration for updating BloodSample status choices

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('samples', '0003_remove_bloodsample_patient_id'),
    ]

    operations = [
        migrations.AlterField(
            model_name='bloodsample',
            name='status',
            field=models.CharField(
                choices=[
                    ('IN_STORAGE', 'In Storage'),
                    ('REQUESTED', 'Requested'),
                    ('OUT_FOR_DELIVERY', 'Out For Delivery'),
                    ('WITH_DOCTOR', 'With Doctor'),
                ],
                default='IN_STORAGE',
                max_length=20,
            ),
        ),
    ]
