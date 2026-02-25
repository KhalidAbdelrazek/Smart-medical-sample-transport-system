from django.contrib import admin
from django.urls import path, include
from django.conf.urls import include
from healthcare import views
from robot import views  # app name is robot

from drf_spectacular.views import (
    SpectacularAPIView, 
    SpectacularRedocView, 
    SpectacularSwaggerView
)

urlpatterns = [

    # 1. The raw schema file (YAML/JSON) - Frontend can use this to auto-generate code!
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),

    # 2. Swagger UI (Interactive interface for testing endpoints)
    path('api/docs/swagger/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),

    # 3. Redoc (Clean, linear documentation layout)
    path('api/docs/redoc/', SpectacularRedocView.as_view(url_name='schema'), name='redoc'),
    
    path('robot/', include('robot.urls')), # السطر ده بيربط مشروعك بملف الـ api
    path('', include('healthcare.urls')),
    path('admin/', admin.site.urls),

    # ------------------- Employee -------------------
    path('employees/', views.EmployeeListCreateView.as_view(), name='employee-list-create'),
    path('employees/<int:pk>/', views.EmployeeRetrieveUpdateDestroyView.as_view(), name='employee-detail'),

    # ------------------- EmployeeStatistics -------------------
    path('stats/', views.EmployeeStatisticsListView.as_view(), name='stats-list'),
    path('stats/<int:pk>/', views.EmployeeStatisticsDetailView.as_view(), name='stats-detail'),

    # ------------------- Patient -------------------
    path('patients/', views.PatientListCreateView.as_view(), name='patient-list-create'),
    path('patients/<int:pk>/', views.PatientRetrieveUpdateDestroyView.as_view(), name='patient-detail'),

    # ------------------- Vehicle -------------------
    path('vehicles/', views.VehicleListCreateView.as_view(), name='vehicle-list-create'),
    path('vehicles/<int:pk>/', views.VehicleRetrieveUpdateDestroyView.as_view(), name='vehicle-detail'),

    # ------------------- Request -------------------
    path('requests/', views.RequestListCreateView.as_view(), name='request-list-create'),
    path('requests/<int:pk>/', views.RequestRetrieveUpdateDestroyView.as_view(), name='request-detail'),

    # ------------------- Response -------------------
    path('responses/', views.ResponseListCreateView.as_view(), name='response-list-create'),
    path('responses/<int:pk>/', views.ResponseRetrieveUpdateDestroyView.as_view(), name='response-detail'),

    # ------------------- Dispatch -------------------
    path('dispatches/', views.DispatchListCreateView.as_view(), name='dispatch-list-create'),
    path('dispatches/<int:pk>/', views.DispatchRetrieveUpdateDestroyView.as_view(), name='dispatch-detail'),
]