from drf_spectacular.utils import extend_schema, OpenApiExample
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from common.utils.response import unified_response
from .models import User

from .serializers import (
    LoginSerializer, 
    AdminLoginSerializer, 
    ProfileSerializer,
    AdminUsersListFilterSerializer,
    AdminUsersListResponseSerializer,
    UserListSerializer,
)
from .services import authenticate_staff, authenticate_admin, get_admin_users_list
from accounts.permissions import IsAdminRole


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


class AdminUsersListView(APIView):
    """
    GET /api/admin/users/
    
    Admin-only endpoint to list all users with pagination and search.
    Supports filtering by role and searching by name/email.
    """
    permission_classes = [IsAuthenticated, IsAdminRole]

    @extend_schema(
        tags=['Admin Users'],
        summary='Get list of all users (admin only)',
        description='Returns paginated list of users. Supports filtering by role and searching by name/email (case-insensitive).',
        parameters=[AdminUsersListFilterSerializer],
        responses=AdminUsersListResponseSerializer,
    )
    def get(self, request):
        """
        Handle GET request for user list.
        
        Query Parameters:
            - role: Filter by role (DOCTOR, STORAGE_EMPLOYEE, ADMIN)
            - search: Search by name or email (case-insensitive)
            - page: Page number (default: 1)
            - page_size: Items per page (default: 20, max: 100)
        """
        # Parse and validate filter parameters
        filter_serializer = AdminUsersListFilterSerializer(data=request.query_params)
        filter_serializer.is_valid(raise_exception=True)
        params = filter_serializer.validated_data

        # Extract filters
        role = params.get('role')
        search = params.get('search')
        page = params.get('page', 1)
        page_size = params.get('page_size', 20)

        # Get users list
        data = get_admin_users_list(
            role=role,
            search=search,
            page=page,
            page_size=page_size,
        )

        # Serialize users
        data['users'] = UserListSerializer(data['users'], many=True).data

        # Serialize response
        serializer = AdminUsersListResponseSerializer(data)

        return unified_response(
            success=True,
            message='Users retrieved successfully',
            data=serializer.data,
        )
