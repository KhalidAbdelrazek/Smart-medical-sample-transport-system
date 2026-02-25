from rest_framework import serializers
from django.core.exceptions import ValidationError
from drf_spectacular.utils import extend_schema_field
from drf_spectacular.types import OpenApiTypes
from .models import Employee, EmployeeStatistics, Patient, Request, Response, Vehicle, Dispatch


class EmployeeSerializer(serializers.ModelSerializer):
    age = serializers.SerializerMethodField()

    class Meta:
        model = Employee
        fields = ['id', 'employee_id', 'name', 'department', 'shift', 'birth_date', 'age', 'created_at', 'updated_at']

    @extend_schema_field(OpenApiTypes.INT)
    def get_age(self, obj):
        return obj.age


class EmployeeStatisticsSerializer(serializers.ModelSerializer):
    employee_name = serializers.CharField(source='employee.name', read_only=True)

    class Meta:
        model = EmployeeStatistics
        fields = ['id', 'employee', 'employee_name', 'processed_samples', 'processed_bags', 'dispatched_cars', 'created_at', 'updated_at']
        read_only_fields = ('processed_samples', 'processed_bags', 'dispatched_cars')


class PatientSerializer(serializers.ModelSerializer):
    age = serializers.SerializerMethodField()

    class Meta:
        model = Patient
        fields = ['id', 'name', 'phone', 'email', 'address', 'birth_date', 'blood_type', 'age', 'created_at', 'updated_at']

    @extend_schema_field(OpenApiTypes.INT)
    def get_age(self, obj):
        return obj.age


class VehicleSerializer(serializers.ModelSerializer):
    is_available = serializers.SerializerMethodField()

    class Meta:
        model = Vehicle
        fields = ['id', 'name', 'capacity', 'current_load', 'is_available', 'created_at', 'updated_at']

    @extend_schema_field(OpenApiTypes.BOOL)
    def get_is_available(self, obj):
        return obj.is_available


class RequestSerializer(serializers.ModelSerializer):
    class Meta:
        model = Request
        fields = ['id', 'request_type', 'blood_type', 'room_number', 'patient', 'created_by', 'created_at', 'updated_at']



class ResponseSerializer(serializers.ModelSerializer):
    request_details = RequestSerializer(source='request', read_only=True)
    vehicle_name = serializers.CharField(source='vehicle.name', read_only=True)

    class Meta:
        model = Response
        fields = ['id', 'request', 'vehicle', 'vehicle_name', 'handled_by', 'status', 'request_details', 'created_at', 'updated_at']
        read_only_fields = ('status',)

    def validate(self, attrs):
        vehicle = attrs.get('vehicle')
        if vehicle and vehicle.current_load >= vehicle.capacity:
            raise serializers.ValidationError("🚗 The vehicle is full! Cannot add a new Response.")
        return attrs


class DispatchSerializer(serializers.ModelSerializer):
    class Meta:
        model = Dispatch
        fields = ['id', 'vehicle', 'dispatched_by', 'dispatched_at', 'updated_at']
