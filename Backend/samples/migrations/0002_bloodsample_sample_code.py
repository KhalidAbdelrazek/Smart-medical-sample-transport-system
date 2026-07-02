from django.db import migrations, models

class Migration(migrations.Migration):

    dependencies = [
        ('samples', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='bloodsample',
            name='sample_code',
            field=models.CharField(blank=True, db_index=True, editable=False, help_text='Human-readable code, e.g., PT-0001', max_length=20, null=True),
        ),
    ]
