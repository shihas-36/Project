# Generated by Django 5.1.5 on 2025-02-10 14:11

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0003_alter_customuser_managers'),
        ('auth', '0012_alter_user_first_name_max_length'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='customuser',
            name='KTUID',
        ),
        migrations.RemoveField(
            model_name='customuser',
            name='is_honors',
        ),
        migrations.RemoveField(
            model_name='customuser',
            name='option',
        ),
        migrations.AlterField(
            model_name='customuser',
            name='groups',
            field=models.ManyToManyField(blank=True, help_text='The groups this user belongs to. A user will get all permissions granted to each of their groups.', related_name='accounts_user_set', to='auth.group', verbose_name='groups'),
        ),
        migrations.AlterField(
            model_name='customuser',
            name='semester',
            field=models.CharField(blank=True, max_length=20, null=True),
        ),
        migrations.AlterField(
            model_name='customuser',
            name='user_permissions',
            field=models.ManyToManyField(blank=True, help_text='Specific permissions for this user.', related_name='accounts_user_permissions', to='auth.permission', verbose_name='user permissions'),
        ),
    ]
