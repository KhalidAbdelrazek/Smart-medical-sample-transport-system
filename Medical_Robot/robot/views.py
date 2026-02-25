from rest_framework import generics
from rest_framework.authentication import TokenAuthentication
from rest_framework.permissions import IsAuthenticated
from drf_spectacular.utils import extend_schema_view, extend_schema
from .models import Employee, EmployeeStatistics, Patient, Request, Response, Vehicle, Dispatch
from .serializers import (
    EmployeeSerializer,
    EmployeeStatisticsSerializer,
    PatientSerializer,
    RequestSerializer,
    ResponseSerializer,
    VehicleSerializer,
    DispatchSerializer
)


# ------------------- Employee -------------------
@extend_schema_view(
    list=extend_schema(description="Retrieve a list of all employees.", summary="List Employees"),
    create=extend_schema(description="Create a new employee.", summary="Create Employee")
)
class EmployeeListGeneric(generics.ListCreateAPIView):
    queryset = Employee.objects.all()
    serializer_class = EmployeeSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


@extend_schema_view(
    retrieve=extend_schema(description="Retrieve details of a specific employee.", summary="Retrieve Employee"),
    update=extend_schema(description="Update an employee completely.", summary="Update Employee"),
    partial_update=extend_schema(description="Partially update an employee.", summary="Patch Employee"),
    destroy=extend_schema(description="Delete an employee.", summary="Delete Employee")
)
class EmployeeDetailGeneric(generics.RetrieveUpdateDestroyAPIView):
    queryset = Employee.objects.all()
    serializer_class = EmployeeSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


# ------------------- EmployeeStatistics -------------------
@extend_schema_view(
    list=extend_schema(description="Retrieve a list of all employee statistics.", summary="List Employee Statistics")
)
class EmployeeStatisticsListGeneric(generics.ListAPIView):
    queryset = EmployeeStatistics.objects.all()
    serializer_class = EmployeeStatisticsSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


@extend_schema_view(
    retrieve=extend_schema(description="Retrieve details of a specific employee's statistics.", summary="Retrieve Employee Statistics")
)
class EmployeeStatisticsDetailGeneric(generics.RetrieveAPIView):
    queryset = EmployeeStatistics.objects.all()
    serializer_class = EmployeeStatisticsSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


# ------------------- Patient -------------------
@extend_schema_view(
    list=extend_schema(description="Retrieve a list of all patients.", summary="List Patients"),
    create=extend_schema(description="Create a new patient.", summary="Create Patient")
)
class PatientListGeneric(generics.ListCreateAPIView):
    queryset = Patient.objects.all()
    serializer_class = PatientSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


@extend_schema_view(
    retrieve=extend_schema(description="Retrieve details of a specific patient.", summary="Retrieve Patient"),
    update=extend_schema(description="Update a patient completely.", summary="Update Patient"),
    partial_update=extend_schema(description="Partially update a patient.", summary="Patch Patient"),
    destroy=extend_schema(description="Delete a patient.", summary="Delete Patient")
)
class PatientDetailGeneric(generics.RetrieveUpdateDestroyAPIView):
    queryset = Patient.objects.all()
    serializer_class = PatientSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


# ------------------- Vehicle -------------------
@extend_schema_view(
    list=extend_schema(description="Retrieve a list of all vehicles.", summary="List Vehicles"),
    create=extend_schema(description="Create a new vehicle.", summary="Create Vehicle")
)
class VehicleListGeneric(generics.ListCreateAPIView):
    queryset = Vehicle.objects.all()
    serializer_class = VehicleSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


@extend_schema_view(
    retrieve=extend_schema(description="Retrieve details of a specific vehicle.", summary="Retrieve Vehicle"),
    update=extend_schema(description="Update a vehicle completely.", summary="Update Vehicle"),
    partial_update=extend_schema(description="Partially update a vehicle.", summary="Patch Vehicle"),
    destroy=extend_schema(description="Delete a vehicle.", summary="Delete Vehicle")
)
class VehicleDetailGeneric(generics.RetrieveUpdateDestroyAPIView):
    queryset = Vehicle.objects.all()
    serializer_class = VehicleSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


# ------------------- Request -------------------
@extend_schema_view(
    list=extend_schema(description="Retrieve a list of all requests.", summary="List Requests"),
    create=extend_schema(description="Create a new request.", summary="Create Request")
)
class RequestListGeneric(generics.ListCreateAPIView):
    queryset = Request.objects.all()
    serializer_class = RequestSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


@extend_schema_view(
    retrieve=extend_schema(description="Retrieve details of a specific request.", summary="Retrieve Request"),
    update=extend_schema(description="Update a request completely.", summary="Update Request"),
    partial_update=extend_schema(description="Partially update a request.", summary="Patch Request"),
    destroy=extend_schema(description="Delete a request.", summary="Delete Request")
)
class RequestDetailGeneric(generics.RetrieveUpdateDestroyAPIView):
    queryset = Request.objects.all()
    serializer_class = RequestSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


# ------------------- Response -------------------
@extend_schema_view(
    list=extend_schema(description="Retrieve a list of all responses.", summary="List Responses"),
    create=extend_schema(description="Create a new response.", summary="Create Response")
)
class ResponseListGeneric(generics.ListCreateAPIView):
    queryset = Response.objects.all()
    serializer_class = ResponseSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


@extend_schema_view(
    retrieve=extend_schema(description="Retrieve details of a specific response.", summary="Retrieve Response"),
    update=extend_schema(description="Update a response completely.", summary="Update Response"),
    partial_update=extend_schema(description="Partially update a response.", summary="Patch Response"),
    destroy=extend_schema(description="Delete a response.", summary="Delete Response")
)
class ResponseDetailGeneric(generics.RetrieveUpdateDestroyAPIView):
    queryset = Response.objects.all()
    serializer_class = ResponseSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


# ------------------- Dispatch -------------------
@extend_schema_view(
    list=extend_schema(description="Retrieve a list of all dispatches.", summary="List Dispatches"),
    create=extend_schema(description="Create a new dispatch event.", summary="Create Dispatch")
)
class DispatchListGeneric(generics.ListCreateAPIView):
    queryset = Dispatch.objects.all()
    serializer_class = DispatchSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


@extend_schema_view(
    retrieve=extend_schema(description="Retrieve details of a specific dispatch.", summary="Retrieve Dispatch"),
    update=extend_schema(description="Update a dispatch completely.", summary="Update Dispatch"),
    partial_update=extend_schema(description="Partially update a dispatch.", summary="Patch Dispatch"),
    destroy=extend_schema(description="Delete a dispatch.", summary="Delete Dispatch")
)
class DispatchDetailGeneric(generics.RetrieveUpdateDestroyAPIView):
    queryset = Dispatch.objects.all()
    serializer_class = DispatchSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]
