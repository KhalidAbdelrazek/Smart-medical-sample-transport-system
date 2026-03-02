from django.urls import path
from .views import (
    TransportRequestListView,
    AddToCarView,
    DispatchCarView,
)

urlpatterns = [
    # GET /api/transport/requests/
    path('requests/', TransportRequestListView.as_view(), name='transport-requests'),
    
    # POST /api/transport/add-to-car/
    path('add-to-car/', AddToCarView.as_view(), name='add-to-car'),
    
    # POST /api/transport/dispatch-car/
    path('dispatch-car/', DispatchCarView.as_view(), name='dispatch-car'),
]
