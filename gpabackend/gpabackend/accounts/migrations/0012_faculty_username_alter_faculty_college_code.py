# Generated by Django 5.1.5 on 2025-04-02 16:23

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0011_faculty'),
    ]

    operations = [
        migrations.AddField(
            model_name='faculty',
            name='username',
            field=models.CharField(default='default_username', max_length=150, unique=True),
        ),
        migrations.AlterField(
            model_name='faculty',
            name='college_code',
            field=models.CharField(default='default_college_code', max_length=20),
        ),
    ]
