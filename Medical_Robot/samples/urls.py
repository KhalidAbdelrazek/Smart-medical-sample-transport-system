"""
samples/urls.py
"""
from django.urls import path
from .views import BloodSampleDetailView, RequestSampleView

urlpatterns = [
    path('request/', RequestSampleView.as_view(), name='sample-request'),
    path('<uuid:pk>/', BloodSampleDetailView.as_view(), name='sample-detail'),
]
