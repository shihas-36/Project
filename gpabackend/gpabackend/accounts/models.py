from django.contrib.auth.models import AbstractUser,BaseUserManager
from django.db import models

class CustomUserManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('The Email must be set')
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save()
        return user

    def create_superuser(self, email, password, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        return self.create_user(email, password, **extra_fields)


class CustomUser(AbstractUser):
    email = models.EmailField(unique=True)
    KTUID = models.CharField(max_length=20, unique=True, null=True, blank=True)  # Added KTUID field
    semester = models.CharField(max_length=20, blank=True, null=True)
    option = models.CharField(max_length=100, blank=True, null=True)
    is_honors = models.BooleanField(default=False)
    is_minor = models.BooleanField(default=False)  # New field
    is_let = models.BooleanField(default=False)  # New field
    degree = models.CharField(max_length=10, blank=True, null=True)  # Add this line
    targeted_cgpa = models.FloatField(null=True, blank=True)  # Add this line
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username', 'KTUID', 'semester']
    objects = CustomUserManager()  # Add this line

    groups = models.ManyToManyField(
        'auth.Group',
        related_name='accounts_user_set',  # Added related_name
        blank=True,
        help_text='The groups this user belongs to. A user will get all permissions granted to each of their groups.',
        verbose_name='groups',
    )
    user_permissions = models.ManyToManyField(
        'auth.Permission',
        related_name='accounts_user_permissions',  # Added related_name
        blank=True,
        help_text='Specific permissions for this user.',
        verbose_name='user permissions',
    )
    def __str__(self):
        return self.email