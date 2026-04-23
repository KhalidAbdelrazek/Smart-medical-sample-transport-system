from django.contrib import admin
from django.urls import path, include
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView, SpectacularRedocView

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/swagger/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    path('api/docs/redoc/', SpectacularRedocView.as_view(url_name='schema'), name='redoc'),
    path('api/auth/', include('accounts.urls')),
    path('api/samples/', include('samples.urls')),
    path('api/transport/', include('transport.urls')),
    path('api/dashboard/', include('dashboard.urls')),
    path('api/analytics/', include('analytics.urls')),
    path('api/restrictions/', include('restrictions.urls')),
    path('', include('healthcare.urls')),
]
