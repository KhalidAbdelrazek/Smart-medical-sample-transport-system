from django.urls import path, include
from . import views
from rest_framework.routers import DefaultRouter

router = DefaultRouter()
# router.register('staff', views.)


urlpatterns = [
    path('mqtt-control/', views.mqtt_control_view),
]
