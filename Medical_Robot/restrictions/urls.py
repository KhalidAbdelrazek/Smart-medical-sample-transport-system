"""
restrictions/urls.py
"""
from django.urls import path
from .views import (
    RestrictDoctorSamplesView,
    RestrictStorageSamplesView,
    RestrictTransportRobotView,
    RestrictionStatusView,
)

urlpatterns = [
    path('restrict-doctor-samples/', RestrictDoctorSamplesView.as_view(), name='restrict_doctor_samples'),
    path('restrict-storage-samples/', RestrictStorageSamplesView.as_view(), name='restrict_storage_samples'),
    path('restrict-transport-robot/', RestrictTransportRobotView.as_view(), name='restrict_transport_robot'),
    path('status/', RestrictionStatusView.as_view(), name='restriction_status'),
]
