"""
Medical_Robot/urls.py — Root URL configuration
"""
from django.contrib import admin
from django.urls import path, include
from healthcare import views as healthcare_views

from drf_spectacular.views import (
    SpectacularAPIView,
    SpectacularRedocView,
    SpectacularSwaggerView,
)

urlpatterns = [
    # ── Admin ────────────────────────────────────────────────────────────────
    path('admin/', admin.site.urls),

    # ── API Schema & Docs (drf-spectacular) ──────────────────────────────────
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/swagger/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    path('api/docs/redoc/', SpectacularRedocView.as_view(url_name='schema'), name='redoc'),

    # ── New BioRoute API Apps ─────────────────────────────────────────────────
    path('api/auth/', include('accounts.urls')),
    path('api/samples/', include('samples.urls')),
    path('api/transport/', include('transport.urls')),

    # ── Existing Healthcare / MQTT (DO NOT MODIFY) ───────────────────────────
    path('', include('healthcare.urls')),
]
