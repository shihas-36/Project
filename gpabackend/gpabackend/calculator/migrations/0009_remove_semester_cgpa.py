# Generated by Django 5.1.5 on 2025-03-27 10:04

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('calculator', '0008_semester_earn_credits_semester_minor_credits_and_more'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='semester',
            name='cgpa',
        ),
    ]
