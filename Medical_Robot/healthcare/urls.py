from django.urls import path, include
from . import views
from rest_framework.routers import DefaultRouter
from rest_framework.authtoken.views import obtain_auth_token

router = DefaultRouter()
# router.register('staff', views.)


urlpatterns = [
    path('auth/token/', obtain_auth_token, name='token'),
    path('readings/', views.control_device),
]
