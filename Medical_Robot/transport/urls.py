from django.urls import path
from .views import (
    TransportRequestListView,
    AddToCarView,
    DispatchCarView,
    DoctorTransportRequestListView,
    CancelTransportRequestView,
    RemoveFromCartView,
    AllTransportRequestsView,
    CompleteTransportRequestView,
    FailTransportRequestView,
    DoctorReturnRequestView,
    RequestReturnView,
    ReturnRequestsView,
    ApproveReturnView,
    ReturnStatusView,
    ConfirmReturnView,
    ListPendingReturnsView,
    StartReturnCollectionView,
    ConfirmReturnedSamplesView,
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

    # POST /api/transport/requests/{uuid}/complete/
    path('requests/<uuid:request_id>/complete/', CompleteTransportRequestView.as_view(), name='complete-request'),

    # POST /api/transport/requests/{uuid}/fail/
    path('requests/<uuid:request_id>/fail/', FailTransportRequestView.as_view(), name='fail-request'),
    
    # POST /api/transport/return-request/ - Doctor requests sample return
    path('return-request/', DoctorReturnRequestView.as_view(), name='return-request'),

    # POST /api/transport/request-return/ - Doctor requests return for multiple samples
    path('request-return/', RequestReturnView.as_view(), name='request-return'),

    # GET /api/transport/return-requests/ - Storage views grouped return requests
    path('return-requests/', ReturnRequestsView.as_view(), name='return-requests'),

    # POST /api/transport/approve-return/ - Storage approves selected samples and dispatches
    path('approve-return/', ApproveReturnView.as_view(), name='approve-return'),

    # GET /api/transport/return-status/ - Doctor polls for arrived return batches
    path('return-status/', ReturnStatusView.as_view(), name='return-status'),

    # POST /api/transport/confirm-return/ - Doctor confirms handoff for arrived return batch
    path('confirm-return/', ConfirmReturnView.as_view(), name='confirm-return'),
    
    # GET /api/transport/pending-returns/ - Storage views pending returns
    path('pending-returns/', ListPendingReturnsView.as_view(), name='pending-returns'),
    
    # POST /api/transport/start-return-collection/ - Storage starts collection with selected samples
    path('start-return-collection/', StartReturnCollectionView.as_view(), name='start-return-collection'),

    # POST /api/transport/confirm-returned-samples/ - Storage confirms returned sample codes
    path('confirm-returned-samples/', ConfirmReturnedSamplesView.as_view(), name='confirm-returned-samples'),
]
