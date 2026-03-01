"""
transport/urls.py
"""
from django.urls import path
from .views import TransportRequestListView, AddToCarView, DispatchCarView

urlpatterns = [
    path('requests/', TransportRequestListView.as_view(), name='transport-requests'),
    path('add-to-car/', AddToCarView.as_view(), name='transport-add-to-car'),
    path('dispatch-car/', DispatchCarView.as_view(), name='transport-dispatch-car'),
]
