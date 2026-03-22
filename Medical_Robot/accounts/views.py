from drf_spectacular.utils import extend_schema, OpenApiExample
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from common.utils.response import unified_response
from .models import User

from .serializers import LoginSerializer, AdminLoginSerializer, ProfileSerializer
from .services import authenticate_staff, authenticate_admin


class LoginView(APIView):
    """
    POST /api/auth/login/
    For Doctors and Storage Employees only.
    Returns JWT access and refresh tokens along with user profile.
    """
    permission_classes = []

    @extend_schema(
        tags=['Auth'],
        summary='Doctor & Storage Employee Login',
        description='Returns JWT tokens for Doctors and Storage Employees.',
        request=LoginSerializer,
        responses={200: {'type': 'object', 'properties': {
            'success': {'type': 'boolean'},
            'message': {'type': 'string'},
            'data': {'type': 'object', 'properties': {
                'access': {'type': 'string'},
                'refresh': {'type': 'string'},
                'user': {'type': 'object'}
            }},
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
        email = serializer.validated_data['email']
        tokens = authenticate_staff(
            email=email,
            password=serializer.validated_data['password'],
        )
        
        # Include user profile info
        user = User.objects.get(email=email)
        tokens['user'] = ProfileSerializer(user).data
        
        return unified_response(
            success=True,
            message="Login successful",
            data=tokens,
            status=status.HTTP_200_OK
        )


class AdminLoginView(APIView):
    """
    POST /api/auth/admin/login/
    For Admin users only.
    Returns JWT access and refresh tokens.
    """
    permission_classes = []

    @extend_schema(
        tags=['Auth'],
        summary='Admin Login',
        description='Returns JWT tokens for Admin users only.',
        request=AdminLoginSerializer,
        responses={200: {'type': 'object', 'properties': {
            'success': {'type': 'boolean'},
            'message': {'type': 'string'},
            'data': {'type': 'object'},
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
        email = serializer.validated_data['email']
        tokens = authenticate_admin(
            email=email,
            password=serializer.validated_data['password'],
        )
        
        user = User.objects.get(email=email)
        tokens['user'] = ProfileSerializer(user).data

        return unified_response(
            success=True,
            message="Admin login successful",
            data=tokens,
            status=status.HTTP_200_OK
        )


class ProfileView(APIView):
    """
    GET /api/auth/profile/
    Returns the profile of the currently authenticated user.
    """
    permission_classes = [IsAuthenticated]

    @extend_schema(
        tags=['Auth'],
        summary='Get Current User Profile',
        description='Returns profile info: id, name, email, role, department, shift, employee_id.',
        responses={200: ProfileSerializer},
    )
    def get(self, request):
        serializer = ProfileSerializer(request.user)
        return unified_response(
            success=True,
            message="Profile fetched successfully",
            data=serializer.data,
            status=status.HTTP_200_OK
        )
