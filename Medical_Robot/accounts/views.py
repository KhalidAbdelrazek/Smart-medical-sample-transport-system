"""
accounts/views.py

API views for authentication and user profile.

Endpoints:
    POST /api/auth/login/         — Doctor + Storage Employee login
    POST /api/auth/admin/login/   — Admin-only login
    GET  /api/auth/profile/       — Get current user profile
"""
from drf_spectacular.utils import extend_schema, OpenApiExample
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .serializers import LoginSerializer, AdminLoginSerializer, ProfileSerializer
from .services import authenticate_staff, authenticate_admin


class LoginView(APIView):
    """
    POST /api/auth/login/
    For Doctors and Storage Employees only.
    Returns JWT access and refresh tokens.
    """
    permission_classes = []  # Public endpoint — no auth required to log in

    @extend_schema(
        tags=['Auth'],
        summary='Doctor & Storage Employee Login',
        description='Returns JWT tokens for Doctors and Storage Employees.',
        request=LoginSerializer,
        responses={200: {'type': 'object', 'properties': {
            'access': {'type': 'string'},
            'refresh': {'type': 'string'},
        }}},
        examples=[
            OpenApiExample('Doctor Login', value={
                'email': 'doctor1@bioroute.com',
                'password': 'AaAa112233_',
            }, request_only=True),
        ],
    )
    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        tokens = authenticate_staff(
            email=serializer.validated_data['email'],
            password=serializer.validated_data['password'],
        )
        return Response(tokens, status=status.HTTP_200_OK)


class AdminLoginView(APIView):
    """
    POST /api/auth/admin/login/
    For Admin users only.
    Returns JWT access and refresh tokens.
    """
    permission_classes = []  # Public endpoint

    @extend_schema(
        tags=['Auth'],
        summary='Admin Login',
        description='Returns JWT tokens for Admin users only.',
        request=AdminLoginSerializer,
        responses={200: {'type': 'object', 'properties': {
            'access': {'type': 'string'},
            'refresh': {'type': 'string'},
        }}},
        examples=[
            OpenApiExample('Admin Login', value={
                'email': 'admin@bioroute.com',
                'password': 'AaAa112233_',
            }, request_only=True),
        ],
    )
    def post(self, request):
        serializer = AdminLoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        tokens = authenticate_admin(
            email=serializer.validated_data['email'],
            password=serializer.validated_data['password'],
        )
        return Response(tokens, status=status.HTTP_200_OK)


class ProfileView(APIView):
    """
    GET /api/auth/profile/
    Returns the profile of the currently authenticated user.
    Response format matches Flutter app expectations.
    """
    permission_classes = [IsAuthenticated]

    @extend_schema(
        tags=['Auth'],
        summary='Get Current User Profile',
        description='Returns profile info: id, name, role, department, shift, employee_id.',
        responses={200: ProfileSerializer},
    )
    def get(self, request):
        serializer = ProfileSerializer(request.user)
        return Response(serializer.data, status=status.HTTP_200_OK)
