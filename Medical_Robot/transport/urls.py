from django.urls import path
from .views import (
    TransportRequestListView,
    AddToCarView,
    DispatchCarView,
    DoctorTransportRequestListView,
    CancelTransportRequestView,
    RemoveFromCartView,
    AllTransportRequestsView,
    # RequestReturnView,
    # ReturnRequestsView,
    ReturnStatusView,
    DeliveryArrivalsView,
    ConfirmDeliveryView,
    RejectDeliveryView,
    ConfirmReturnHandoffView,
    ConfirmCarReturnView,
    ReturnedCarsView,
    ReturnedCarsCountView,
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

    # GET /api/transport/filtered-requests/
    path('filtered-requests/', AllTransportRequestsView.as_view(), name='filtered-transport-requests'),

    # POST /api/transport/request-return/ - Doctor requests return for multiple samples
    # path('request-return/', RequestReturnView.as_view(), name='request-return'),

    # GET /api/transport/return-requests/ - Storage views grouped return requests
    # path('return-requests/', ReturnRequestsView.as_view(), name='return-requests'),

    # GET /api/transport/return-status/ - Doctor polls for arrived return batches
    path('return-status/', ReturnStatusView.as_view(), name='return-status'),
    
    # GET /api/transport/arrivals/ - Doctor polls for delivery arrivals
    path('arrivals/', DeliveryArrivalsView.as_view(), name='delivery-arrivals'),

    # POST /api/transport/requests/{uuid}/confirm-delivery/ - Doctor confirms delivery
    path('requests/<uuid:request_id>/confirm-delivery/', ConfirmDeliveryView.as_view(), name='confirm-delivery'),

    # POST /api/transport/requests/{uuid}/reject-delivery/ - Doctor rejects delivery
    path('requests/<uuid:request_id>/reject-delivery/', RejectDeliveryView.as_view(), name='reject-delivery'),

    # POST /api/transport/confirm-return-handoff/ - Doctor confirms they gave the return samples to the car
    path('confirm-return-handoff/', ConfirmReturnHandoffView.as_view(), name='confirm-return-handoff'),
    
    # GET /api/transport/returned-cars/ - Storage polls for cars that arrived at storage
    path('returned-cars/', ReturnedCarsView.as_view(), name='returned-cars'),
    
    # GET /api/transport/returned-cars/count/ - Quick poll for returned cars count
    # path('returned-cars/count/', ReturnedCarsCountView.as_view(), name='returned-cars-count'),
    
    # POST /api/transport/confirm-car-return/ - Storage confirms car return to storage
    path('confirm-car-return/', ConfirmCarReturnView.as_view(), name='confirm-car-return'),
    
]
