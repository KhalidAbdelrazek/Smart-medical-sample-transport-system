# """
# URL configuration for clinic_management project.

# The `urlpatterns` list routes URLs to views. For more information please see:
#     https://docs.djangoproject.com/en/6.0/topics/http/urls/
# Examples:
# Function views
#     1. Add an import:  from my_app import views
#     2. Add a URL to urlpatterns:  path('', views.home, name='home')
# Class-based views
#     1. Add an import:  from other_app.views import Home
#     2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
# Including another URLconf
#     1. Import the include() function: from django.urls import include, path
#     2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
# """
from django.contrib import admin
from django.urls import path, include
from django.conf.urls import include
from healthcare import views
from robot import views  # app name is robot

urlpatterns = [
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