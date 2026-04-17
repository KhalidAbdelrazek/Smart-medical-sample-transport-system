"""
stats/urls.py

URL configuration for consolidated admin statistics endpoint.
Single route: /api/admin/stats/
"""
from django.urls import path

from stats.views import AdminStatsView

app_name = 'stats'

urlpatterns = [
    path('', AdminStatsView.as_view(), name='admin-stats'),
]
