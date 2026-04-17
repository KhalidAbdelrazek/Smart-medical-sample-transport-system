"""
analytics/urls.py

URL configuration for request analytics endpoints.
"""
from django.urls import path

from analytics.views import RequestAnalyticsView

app_name = 'analytics'

urlpatterns = [
    path('requests/', RequestAnalyticsView.as_view(), name='request-analytics'),
]
