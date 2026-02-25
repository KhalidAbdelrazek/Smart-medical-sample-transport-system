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

    # ------------------- TransportRequest -------------------
    path('transport-requests/', robot_views.TransportRequestListGeneric.as_view(), name='transport-request-list-generic'),
    path('transport-requests/<uuid:pk>/', robot_views.TransportRequestDetailGeneric.as_view(), name='transport-request-detail-generic'),

    # ------------------- TransportFulfillment -------------------
    path('transport-fulfillments/', robot_views.TransportFulfillmentListGeneric.as_view(), name='transport-fulfillment-list-generic'),
    path('transport-fulfillments/<uuid:pk>/', robot_views.TransportFulfillmentDetailGeneric.as_view(), name='transport-fulfillment-detail-generic'),

    # ------------------- VehicleDispatch -------------------
    path('vehicle-dispatches/', robot_views.VehicleDispatchListGeneric.as_view(), name='vehicle-dispatch-list-generic'),
    path('vehicle-dispatches/<uuid:pk>/', robot_views.VehicleDispatchDetailGeneric.as_view(), name='vehicle-dispatch-detail-generic'),
]
