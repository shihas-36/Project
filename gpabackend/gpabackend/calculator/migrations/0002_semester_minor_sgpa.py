# Generated by Django 5.1.5 on 2025-03-18 15:11

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('calculator', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='semester',
            name='minor_sgpa',
            field=models.FloatField(blank=True, null=True),
        ),
    ]
