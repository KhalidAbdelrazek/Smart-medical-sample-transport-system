"""
analytics/urls.py

Single endpoint for the unified analytics dashboard.
"""
from django.urls import path
from analytics.views import DashboardView

app_name = 'analytics'

urlpatterns = [
    path('dashboard/', DashboardView.as_view(), name='analytics-dashboard'),
]
