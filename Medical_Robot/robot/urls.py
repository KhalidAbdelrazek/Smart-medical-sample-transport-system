from django.urls import path, include
from . import views

urlpatterns = [
    # Employee URLs
    path('employees/', views.EmployeeListCreateView.as_view(), name='employee-list-create'),
    path('employees/<int:pk>/', views.EmployeeRetrieveUpdateDestroyView.as_view(), name='employee-retrieve-update-destroy'),
    
    # EmployeeStatistics URLs
    path('employee-statistics/', views.EmployeeStatisticsListView.as_view(), name='employee-statistics-list'),
    path('employee-statistics/<int:pk>/', views.EmployeeStatisticsDetailView.as_view(), name='employee-statistics-detail'),
    
    # Patient URLs
    path('patients/', views.PatientListCreateView.as_view(), name='patient-list-create'),
    path('patients/<int:pk>/', views.PatientRetrieveUpdateDestroyView.as_view(), name='patient-retrieve-update-destroy'),
    
    # Vehicle URLs
    path('vehicles/', views.VehicleListCreateView.as_view(), name='vehicle-list-create'),
    path('vehicles/<int:pk>/', views.VehicleRetrieveUpdateDestroyView.as_view(), name='vehicle-retrieve-update-destroy'),
    
    # Request URLs
    path('requests/', views.RequestListCreateView.as_view(), name='request-list-create'),
    path('requests/<int:pk>/', views.RequestRetrieveUpdateDestroyView.as_view(), name='request-retrieve-update-destroy'),
    
    # Response URLs
    path('responses/', views.ResponseListCreateView.as_view(), name='response-list-create'),
    path('responses/<int:pk>/', views.ResponseRetrieveUpdateDestroyView.as_view(), name='response-retrieve-update-destroy'),
    
    # Dispatch URLs
    path('dispatches/', views.DispatchListCreateView.as_view(), name='dispatch-list-create'),
    path('dispatches/<int:pk>/', views.DispatchRetrieveUpdateDestroyView.as_view(), name='dispatch-retrieve-update-destroy'),
]
