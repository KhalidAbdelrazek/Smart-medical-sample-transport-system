from rest_framework import serializers
from django.core.exceptions import ValidationError
from .models import Employee, EmployeeStatistics, Patient, Request, Response, Vehicle, Dispatch


class EmployeeSerializer(serializers.ModelSerializer):
    age = serializers.ReadOnlyField()

    class Meta:
        model = Employee
        fields = '__all__'


class EmployeeStatisticsSerializer(serializers.ModelSerializer):
    employee_name = serializers.CharField(source='employee.name', read_only=True)

    class Meta:
        model = EmployeeStatistics
        fields = '__all__'
        read_only_fields = ('processed_samples', 'processed_bags', 'dispatched_cars')


class PatientSerializer(serializers.ModelSerializer):
    age = serializers.ReadOnlyField()

    class Meta:
        model = Patient
        fields = '__all__'


class VehicleSerializer(serializers.ModelSerializer):
    is_available = serializers.ReadOnlyField()

    class Meta:
        model = Vehicle
        fields = '__all__'


class RequestSerializer(serializers.ModelSerializer):
    class Meta:
        model = Request
        fields = '__all__'



class ResponseSerializer(serializers.ModelSerializer):
    request_details = RequestSerializer(source='request', read_only=True)
    vehicle_name = serializers.CharField(source='vehicle.name', read_only=True)  # هنا اسم العربية

    class Meta:
        model = Response
        fields = ['id', 'request', 'vehicle', 'vehicle_name', 'handled_by', 'request_details']
        read_only_fields = ('status',)  # منع المستخدم من تعديل status

    def validate(self, attrs):
        vehicle = attrs.get('vehicle')
        if vehicle and vehicle.current_load >= vehicle.capacity:
            raise serializers.ValidationError("🚗 The vehicle is full! Cannot add a new Response.")
        return attrs


class DispatchSerializer(serializers.ModelSerializer):
    class Meta:
        model = Dispatch
        fields = '__all__'