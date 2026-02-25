from django.urls import path
from . import views

urlpatterns = [
    # Employee URLs
    path('employees/', views.EmployeeListGeneric.as_view(), name='employee-list'),
    path('employees/<uuid:pk>/', views.EmployeeDetailGeneric.as_view(), name='employee-detail'),
    
    # EmployeeStatistics URLs
    path('employee-statistics/', views.EmployeeStatisticsListGeneric.as_view(), name='employee-statistics-list'),
    path('employee-statistics/<uuid:pk>/', views.EmployeeStatisticsDetailGeneric.as_view(), name='employee-statistics-detail'),
    
    # Patient URLs
    path('patients/', views.PatientListGeneric.as_view(), name='patient-list'),
    path('patients/<uuid:pk>/', views.PatientDetailGeneric.as_view(), name='patient-detail'),
    
    # Vehicle URLs
    path('vehicles/', views.VehicleListGeneric.as_view(), name='vehicle-list'),
    path('vehicles/<uuid:pk>/', views.VehicleDetailGeneric.as_view(), name='vehicle-detail'),
    
    # TransportRequest URLs
    path('transport-requests/', views.TransportRequestListGeneric.as_view(), name='transport-request-list'),
    path('transport-requests/<uuid:pk>/', views.TransportRequestDetailGeneric.as_view(), name='transport-request-detail'),
    
    # TransportFulfillment URLs
    path('transport-fulfillments/', views.TransportFulfillmentListGeneric.as_view(), name='transport-fulfillment-list'),
    path('transport-fulfillments/<uuid:pk>/', views.TransportFulfillmentDetailGeneric.as_view(), name='transport-fulfillment-detail'),
    
    # VehicleDispatch URLs
    path('vehicle-dispatches/', views.VehicleDispatchListGeneric.as_view(), name='vehicle-dispatch-list'),
    path('vehicle-dispatches/<uuid:pk>/', views.VehicleDispatchDetailGeneric.as_view(), name='vehicle-dispatch-detail'),
]
