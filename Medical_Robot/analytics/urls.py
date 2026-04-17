"""
analytics/urls.py

URL configuration for request analytics endpoints.
"""
from django.urls import path

from analytics.views import RequestAnalyticsView, StorageEmployeeLogsAnalyticsView

app_name = 'analytics'

urlpatterns = [
    path('requests/', RequestAnalyticsView.as_view(), name='request-analytics'),
    path('storage-employees/logs/', StorageEmployeeLogsAnalyticsView.as_view(), name='storage-employee-logs-analytics'),
]
