from rest_framework import serializers
from .models import Patient, Staff



class PatientSerializer(serializers.ModelSerializer):
    class Meta:
        model = Patient
        fields = ['id', 'name', 'age', 'gender', 'description', 'phone', 'email', 'password']


class StaffSerializer(serializers.ModelSerializer):
    class Meta:
        model = Staff
        fields = ['id', 'name', 'age', 'gender', 'phone', 'email', 'password']
