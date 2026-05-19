"""
accounts/urls.py

URL routes for the accounts app.
"""
from django.urls import path
from .views import LoginView, AdminLoginView, ProfileView, AdminUsersListView

urlpatterns = [
    path('login/', LoginView.as_view(), name='auth-login'),
    path('admin/login/', AdminLoginView.as_view(), name='auth-admin-login'),
    path('profile/', ProfileView.as_view(), name='auth-profile'),
    path('admin/users/', AdminUsersListView.as_view(), name='admin-users-list'),
]
