from django.urls import path
from .views import (
    BloodSampleDetailView,
    RequestSampleView,
    BloodSampleSearchView,
)

urlpatterns = [
    # GET /api/samples/search/?q=
    path('search/', BloodSampleSearchView.as_view(), name='sample-search'),
    
    # POST /api/samples/request/
    path('request/', RequestSampleView.as_view(), name='sample-request'),
    
    # GET /api/samples/{sample_code}/
    path('<str:sample_code>/', BloodSampleDetailView.as_view(), name='sample-detail'),
]
