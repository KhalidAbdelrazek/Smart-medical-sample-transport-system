from drf_spectacular.utils import extend_schema, OpenApiParameter, OpenApiTypes
from rest_framework import generics
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
class EmployeeListCreateView(generics.ListCreateAPIView):
    queryset = Employee.objects.all()
    serializer_class = EmployeeSerializer


class EmployeeRetrieveUpdateDestroyView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Employee.objects.all()
    serializer_class = EmployeeSerializer


# ------------------- EmployeeStatistics -------------------
class EmployeeStatisticsListView(generics.ListAPIView):
    queryset = EmployeeStatistics.objects.all()
    serializer_class = EmployeeStatisticsSerializer


class EmployeeStatisticsDetailView(generics.RetrieveAPIView):
    queryset = EmployeeStatistics.objects.all()
    serializer_class = EmployeeStatisticsSerializer


# ------------------- Patient -------------------
class PatientListCreateView(generics.ListCreateAPIView):
    queryset = Patient.objects.all()
    serializer_class = PatientSerializer


class PatientRetrieveUpdateDestroyView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Patient.objects.all()
    serializer_class = PatientSerializer


# ------------------- Vehicle -------------------
class VehicleListCreateView(generics.ListCreateAPIView):
    queryset = Vehicle.objects.all()
    serializer_class = VehicleSerializer


class VehicleRetrieveUpdateDestroyView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Vehicle.objects.all()
    serializer_class = VehicleSerializer


# ------------------- Request -------------------
class RequestListCreateView(generics.ListCreateAPIView):
    queryset = Request.objects.all()
    serializer_class = RequestSerializer


class RequestRetrieveUpdateDestroyView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Request.objects.all()
    serializer_class = RequestSerializer


# ------------------- Response -------------------
class ResponseListCreateView(generics.ListCreateAPIView):
    queryset = Response.objects.all()
    serializer_class = ResponseSerializer


class ResponseRetrieveUpdateDestroyView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Response.objects.all()
    serializer_class = ResponseSerializer


# ------------------- Dispatch -------------------
class DispatchListCreateView(generics.ListCreateAPIView):
    queryset = Dispatch.objects.all()
    serializer_class = DispatchSerializer


class DispatchRetrieveUpdateDestroyView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Dispatch.objects.all()
    serializer_class = DispatchSerializer