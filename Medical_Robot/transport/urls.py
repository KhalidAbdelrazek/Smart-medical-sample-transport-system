from django.urls import path
from .views import (
    TransportRequestListView,
    AddToCarView,
    DispatchCarView,
    DoctorTransportRequestListView,
    CancelTransportRequestView,
    RemoveFromCartView,
)

urlpatterns = [
    # GET /api/transport/requests/
    path('requests/', TransportRequestListView.as_view(), name='transport-requests'),
    
    # POST /api/transport/add-to-car/
    path('add-to-car/', AddToCarView.as_view(), name='add-to-car'),
    
    # POST /api/transport/dispatch-car/
    path('dispatch-car/', DispatchCarView.as_view(), name='dispatch-car'),

    # GET /api/transport/my-requests/
    path('my-requests/', DoctorTransportRequestListView.as_view(), name='my-requests'),

    # DELETE /api/transport/requests/{uuid}/cancel/
    path('requests/<uuid:request_id>/cancel/', CancelTransportRequestView.as_view(), name='cancel-request'),

    # DELETE /api/transport/requests/{uuid}/remove-from-cart/
    path('requests/<uuid:request_id>/remove-from-cart/', RemoveFromCartView.as_view(), name='remove-from-cart'),

]
