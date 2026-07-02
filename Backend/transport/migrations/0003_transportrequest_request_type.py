# Generated migration for adding request_type and updating STATUS_CHOICES

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('transport', '0002_transportrequest_cancelled_at_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='transportrequest',
            name='request_type',
            field=models.CharField(
                choices=[('DELIVERY', 'Delivery'), ('RETURN', 'Return')],
                default='DELIVERY',
                help_text='Direction of transport: DELIVERY (storage->doctor) or RETURN (doctor->storage)',
                max_length=10,
            ),
        ),
        migrations.AlterField(
            model_name='transportrequest',
            name='status',
            field=models.CharField(
                choices=[
                    ('PENDING', 'Pending'),
                    ('LOADED', 'Loaded'),
                    ('DISPATCHED', 'Dispatched'),
                    ('DELIVERED', 'Delivered'),
                    ('RETURNED', 'Returned'),
                    ('CANCELLED', 'Cancelled'),
                    ('FAILED', 'Failed'),
                    ('SUCCESSFUL', 'Successful'),
                    ('EXECUTED', 'Executed'),
                ],
                default='PENDING',
                max_length=15,
            ),
        ),
        migrations.AddIndex(
            model_name='transportrequest',
            index=models.Index(fields=['request_type', 'status'], name='transport_t_request_93a2b8_idx'),
        ),
    ]
