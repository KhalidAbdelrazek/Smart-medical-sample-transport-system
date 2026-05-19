"""
restrictions/urls.py
"""
from django.urls import path
from .views import (
    RestrictDoctorSamplesView,
    RestrictStorageSamplesView,
    RestrictTransportCarView,
    RestrictionStatusView,
)

urlpatterns = [
    path('restrict-doctor-samples/', RestrictDoctorSamplesView.as_view(), name='restrict_doctor_samples'),
    path('restrict-storage-samples/', RestrictStorageSamplesView.as_view(), name='restrict_storage_samples'),
    path('restrict-transport-car/', RestrictTransportCarView.as_view(), name='restrict_transport_car'),
    path('status/', RestrictionStatusView.as_view(), name='restriction_status'),
]
