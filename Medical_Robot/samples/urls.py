from django.urls import path
from .views import (
    BloodSampleDetailView,
    RequestSampleView,
    BloodSampleSearchView,
    CreateBloodSampleView,
)

urlpatterns = [
    # GET /api/samples/search/?q=
    path('search/', BloodSampleSearchView.as_view(), name='sample-search'),

    # POST /api/samples/create/
    path('create/', CreateBloodSampleView.as_view(), name='sample-create'),
    
    # POST /api/samples/request/
    path('request/', RequestSampleView.as_view(), name='sample-request'),
    
    # GET /api/samples/{sample_code}/
    path('<str:sample_code>/', BloodSampleDetailView.as_view(), name='sample-detail'),

]
