from django.urls import path
from .views import (
    BloodSampleDetailView,
    RequestSampleView,
    BloodSampleSearchView,
    CreateBloodSampleView,
    BulkRequestSampleView,
)

urlpatterns = [
    # GET /api/samples/search/?q=
    path('search/', BloodSampleSearchView.as_view(), name='sample-search'),

    # POST /api/samples/create/
    path('create/', CreateBloodSampleView.as_view(), name='sample-create'),
    
    # POST /api/samples/request/
    path('request/', RequestSampleView.as_view(), name='sample-request'),

    # POST /api/samples/request-bulk/
    path('request-bulk/', BulkRequestSampleView.as_view(), name='sample-request-bulk'),
    
    # GET /api/samples/{sample_code}/
    path('<str:sample_code>/', BloodSampleDetailView.as_view(), name='sample-detail'),

]
