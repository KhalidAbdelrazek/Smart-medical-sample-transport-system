from rest_framework import generics
from rest_framework.authentication import TokenAuthentication
from rest_framework.permissions import IsAuthenticated
from drf_spectacular.utils import extend_schema_view, extend_schema
from .models import Employee, EmployeeStatistics, Patient, TransportRequest, TransportFulfillment, Vehicle, VehicleDispatch
from .serializers import (
    EmployeeSerializer,
    EmployeeStatisticsSerializer,
    PatientSerializer,
    TransportRequestSerializer,
    TransportFulfillmentSerializer,
    VehicleSerializer,
    VehicleDispatchSerializer
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


# ------------------- TransportRequest -------------------
@extend_schema_view(
    list=extend_schema(description="Retrieve a list of all transport requests.", summary="List Transport Requests"),
    create=extend_schema(description="Create a new transport request.", summary="Create Transport Request")
)
class TransportRequestListGeneric(generics.ListCreateAPIView):
    queryset = TransportRequest.objects.all()
    serializer_class = TransportRequestSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


@extend_schema_view(
    retrieve=extend_schema(description="Retrieve details of a specific transport request.", summary="Retrieve Transport Request"),
    update=extend_schema(description="Update a transport request completely.", summary="Update Transport Request"),
    partial_update=extend_schema(description="Partially update a transport request.", summary="Patch Transport Request"),
    destroy=extend_schema(description="Delete a transport request.", summary="Delete Transport Request")
)
class TransportRequestDetailGeneric(generics.RetrieveUpdateDestroyAPIView):
    queryset = TransportRequest.objects.all()
    serializer_class = TransportRequestSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


# ------------------- TransportFulfillment -------------------
@extend_schema_view(
    list=extend_schema(description="Retrieve a list of all transport fulfillments.", summary="List Transport Fulfillments"),
    create=extend_schema(description="Create a new transport fulfillment.", summary="Create Transport Fulfillment")
)
class TransportFulfillmentListGeneric(generics.ListCreateAPIView):
    queryset = TransportFulfillment.objects.all()
    serializer_class = TransportFulfillmentSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


@extend_schema_view(
    retrieve=extend_schema(description="Retrieve details of a specific transport fulfillment.", summary="Retrieve Transport Fulfillment"),
    update=extend_schema(description="Update a transport fulfillment completely.", summary="Update Transport Fulfillment"),
    partial_update=extend_schema(description="Partially update a transport fulfillment.", summary="Patch Transport Fulfillment"),
    destroy=extend_schema(description="Delete a transport fulfillment.", summary="Delete Transport Fulfillment")
)
class TransportFulfillmentDetailGeneric(generics.RetrieveUpdateDestroyAPIView):
    queryset = TransportFulfillment.objects.all()
    serializer_class = TransportFulfillmentSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


# ------------------- VehicleDispatch -------------------
@extend_schema_view(
    list=extend_schema(description="Retrieve a list of all vehicle dispatches.", summary="List Vehicle Dispatches"),
    create=extend_schema(description="Create a new vehicle dispatch event.", summary="Create Vehicle Dispatch")
)
class VehicleDispatchListGeneric(generics.ListCreateAPIView):
    queryset = VehicleDispatch.objects.all()
    serializer_class = VehicleDispatchSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


@extend_schema_view(
    retrieve=extend_schema(description="Retrieve details of a specific vehicle dispatch.", summary="Retrieve Vehicle Dispatch"),
    update=extend_schema(description="Update a vehicle dispatch completely.", summary="Update Vehicle Dispatch"),
    partial_update=extend_schema(description="Partially update a vehicle dispatch.", summary="Patch Vehicle Dispatch"),
    destroy=extend_schema(description="Delete a vehicle dispatch.", summary="Delete Vehicle Dispatch")
)
class VehicleDispatchDetailGeneric(generics.RetrieveUpdateDestroyAPIView):
    queryset = VehicleDispatch.objects.all()
    serializer_class = VehicleDispatchSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]
