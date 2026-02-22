from . import views
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import DoctorViewSet, NurseViewSet, PatientViewSet

# الـ Router ده هو اللي بيوزع العناوين أوتوماتيك
router = DefaultRouter()
router.register(r'doctors', DoctorViewSet)
router.register(r'nurses', NurseViewSet)
router.register(r'patients', PatientViewSet)

urlpatterns = [
    path('', include(router.urls)),

path('storage/', views.BloodStorageListView.as_view(), name='storage-list'),
path('samples/', views.BloodSampleCreateView.as_view(), name='sample-list-create'),
path('samples/<int:pk>/ship/', views.ShipSampleView.as_view(), name='ship-sample'),
]