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
    
    # Request URLs
    path('requests/', views.RequestListGeneric.as_view(), name='request-list'),
    path('requests/<uuid:pk>/', views.RequestDetailGeneric.as_view(), name='request-detail'),
    
    # Response URLs
    path('responses/', views.ResponseListGeneric.as_view(), name='response-list'),
    path('responses/<uuid:pk>/', views.ResponseDetailGeneric.as_view(), name='response-detail'),
    
    # Dispatch URLs
    path('dispatches/', views.DispatchListGeneric.as_view(), name='dispatch-list'),
    path('dispatches/<uuid:pk>/', views.DispatchDetailGeneric.as_view(), name='dispatch-detail'),
]
