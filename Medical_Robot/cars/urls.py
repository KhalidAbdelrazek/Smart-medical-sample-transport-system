"""
cars/urls.py

URL routing for cars endpoints.
"""
from django.urls import path
from .views import CarDetailsView

urlpatterns = [
    # GET /api/cars/{car_id}/details/
    path('<int:car_id>/details/', CarDetailsView.as_view(), name='car-details'),
]
