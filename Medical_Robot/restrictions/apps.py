"""
restrictions/apps.py
"""
from django.apps import AppConfig


class RestrictionsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'restrictions'
    verbose_name = 'Admin Restrictions'
