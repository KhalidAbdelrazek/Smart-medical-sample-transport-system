"""
stats/urls.py

URL configuration for statistics admin endpoints.
All routes are under /api/admin/stats/
"""
from django.urls import path

from stats.views import (
    AdminOverviewView,
    AdminUserActivityView,
    AdminTopUsersView,
    AdminRequestsTimeseriesView,
    AdminCarUtilizationView,
)

app_name = 'stats'

urlpatterns = [
    # System overview
    path('overview/', AdminOverviewView.as_view(), name='admin-stats-overview'),
    
    # User activity endpoints
    path('users/activity/', AdminUserActivityView.as_view(), name='admin-user-activity'),
    path('users/top/', AdminTopUsersView.as_view(), name='admin-top-users'),
    
    # Timeseries
    path('requests/timeseries/', AdminRequestsTimeseriesView.as_view(), name='admin-requests-timeseries'),
    
    # Car utilization
    path('cars/utilization/', AdminCarUtilizationView.as_view(), name='admin-car-utilization'),
]
