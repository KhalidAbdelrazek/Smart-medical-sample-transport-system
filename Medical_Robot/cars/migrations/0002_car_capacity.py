# Generated migration for adding car capacity field

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('cars', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='car',
            name='capacity',
            field=models.PositiveIntegerField(
                default=10,
                help_text='Maximum number of samples this car can carry (used for return batch picking)',
            ),
        ),
    ]
