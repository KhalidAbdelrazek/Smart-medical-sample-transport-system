from rest_framework import generics
from rest_framework.authentication import TokenAuthentication
from rest_framework.permissions import IsAuthenticated
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
class EmployeeListGeneric(generics.ListCreateAPIView):
    queryset = Employee.objects.all()
    serializer_class = EmployeeSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


class EmployeeDetailGeneric(generics.RetrieveUpdateDestroyAPIView):
    queryset = Employee.objects.all()
    serializer_class = EmployeeSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


# ------------------- EmployeeStatistics -------------------
class EmployeeStatisticsListGeneric(generics.ListAPIView):
    queryset = EmployeeStatistics.objects.all()
    serializer_class = EmployeeStatisticsSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


class EmployeeStatisticsDetailGeneric(generics.RetrieveAPIView):
    queryset = EmployeeStatistics.objects.all()
    serializer_class = EmployeeStatisticsSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


# ------------------- Patient -------------------
class PatientListGeneric(generics.ListCreateAPIView):
    queryset = Patient.objects.all()
    serializer_class = PatientSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


class PatientDetailGeneric(generics.RetrieveUpdateDestroyAPIView):
    queryset = Patient.objects.all()
    serializer_class = PatientSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


# ------------------- Vehicle -------------------
class VehicleListGeneric(generics.ListCreateAPIView):
    queryset = Vehicle.objects.all()
    serializer_class = VehicleSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


class VehicleDetailGeneric(generics.RetrieveUpdateDestroyAPIView):
    queryset = Vehicle.objects.all()
    serializer_class = VehicleSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


# ------------------- Request -------------------
class RequestListGeneric(generics.ListCreateAPIView):
    queryset = Request.objects.all()
    serializer_class = RequestSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


class RequestDetailGeneric(generics.RetrieveUpdateDestroyAPIView):
    queryset = Request.objects.all()
    serializer_class = RequestSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


# ------------------- Response -------------------
class ResponseListGeneric(generics.ListCreateAPIView):
    queryset = Response.objects.all()
    serializer_class = ResponseSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


class ResponseDetailGeneric(generics.RetrieveUpdateDestroyAPIView):
    queryset = Response.objects.all()
    serializer_class = ResponseSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


# ------------------- Dispatch -------------------
class DispatchListGeneric(generics.ListCreateAPIView):
    queryset = Dispatch.objects.all()
    serializer_class = DispatchSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


class DispatchDetailGeneric(generics.RetrieveUpdateDestroyAPIView):
    queryset = Dispatch.objects.all()
    serializer_class = DispatchSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]
