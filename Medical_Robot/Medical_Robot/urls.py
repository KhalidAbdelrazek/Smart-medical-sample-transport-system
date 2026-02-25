from django.contrib import admin
from django.urls import path, include
from robot import views as robot_views
from healthcare import views as healthcare_views

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
    path('employees/', robot_views.EmployeeListGeneric.as_view(), name='employee-list-generic'),
    path('employees/<uuid:pk>/', robot_views.EmployeeDetailGeneric.as_view(), name='employee-detail-generic'),

    # ------------------- EmployeeStatistics -------------------
    path('stats/', robot_views.EmployeeStatisticsListGeneric.as_view(), name='stats-list-generic'),
    path('stats/<uuid:pk>/', robot_views.EmployeeStatisticsDetailGeneric.as_view(), name='stats-detail-generic'),

    # ------------------- Patient -------------------
    path('patients/', robot_views.PatientListGeneric.as_view(), name='patient-list-generic'),
    path('patients/<uuid:pk>/', robot_views.PatientDetailGeneric.as_view(), name='patient-detail-generic'),

    # ------------------- Vehicle -------------------
    path('vehicles/', robot_views.VehicleListGeneric.as_view(), name='vehicle-list-generic'),
    path('vehicles/<uuid:pk>/', robot_views.VehicleDetailGeneric.as_view(), name='vehicle-detail-generic'),

    # ------------------- Request -------------------
    path('requests/', robot_views.RequestListGeneric.as_view(), name='request-list-generic'),
    path('requests/<uuid:pk>/', robot_views.RequestDetailGeneric.as_view(), name='request-detail-generic'),

    # ------------------- Response -------------------
    path('responses/', robot_views.ResponseListGeneric.as_view(), name='response-list-generic'),
    path('responses/<uuid:pk>/', robot_views.ResponseDetailGeneric.as_view(), name='response-detail-generic'),

    # ------------------- Dispatch -------------------
    path('dispatches/', robot_views.DispatchListGeneric.as_view(), name='dispatch-list-generic'),
    path('dispatches/<uuid:pk>/', robot_views.DispatchDetailGeneric.as_view(), name='dispatch-detail-generic'),
]
