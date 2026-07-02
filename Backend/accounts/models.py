"""
accounts/models.py

Custom User model for BioRoute Smart Medical Transport System.
Roles: ADMIN, DOCTOR, STORAGE_EMPLOYEE
"""
import uuid
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models


class UserManager(BaseUserManager):
    """Custom manager for User model using email as the unique identifier."""

    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError("Email is required")
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('role', 'ADMIN')
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        return self.create_user(email, password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    """
    Custom user model.
    - Doctors and Storage Employees log in via /api/auth/login/
    - Admins log in via /api/auth/admin/login/
    """

    ROLE_CHOICES = [
        ('ADMIN', 'Admin'),
        ('DOCTOR', 'Doctor'),
        ('STORAGE_EMPLOYEE', 'Storage Employee'),
    ]

    SHIFT_CHOICES = [
        ('MORNING', 'Morning'),
        ('EVENING', 'Evening'),
        ('NIGHT', 'Night'),
        ('', 'N/A'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    full_name = models.CharField(max_length=150)
    email = models.EmailField(unique=True)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='DOCTOR')
    department = models.CharField(max_length=100, blank=True, default='')
    shift = models.CharField(max_length=10, choices=SHIFT_CHOICES, blank=True, default='')
    # Auto-generated employee ID for display purposes
    employee_id = models.CharField(max_length=50, blank=True, default='')
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)  # Required for Django admin access
    created_at = models.DateTimeField(auto_now_add=True)

    objects = UserManager()

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['full_name']

    class Meta:
        verbose_name = 'User'
        verbose_name_plural = 'Users'
        ordering = ['created_at']

    def __str__(self):
        return f"{self.full_name} ({self.role})"
