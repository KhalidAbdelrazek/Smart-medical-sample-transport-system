from django.contrib import admin
from .models import *
# Register your models here.

@admin.register(Employee)
class EmployeeAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'employee_id', 'department', 'shift')
    readonly_fields = ('id', 'created_at', 'updated_at')

@admin.register(EmployeeStatistics)
class EmployeeStatisticsAdmin(admin.ModelAdmin):
    list_display = ('id', 'employee', 'processed_samples', 'processed_bags', 'dispatched_cars')
    readonly_fields = ('id', 'created_at', 'updated_at')

@admin.register(Patient)
class PatientAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'phone', 'blood_type')
    readonly_fields = ('id', 'created_at', 'updated_at')

@admin.register(Vehicle)
class VehicleAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'capacity', 'current_load')
    readonly_fields = ('id', 'created_at', 'updated_at')

@admin.register(TransportRequest)
class TransportRequestAdmin(admin.ModelAdmin):
    list_display = ('id', 'request_type', 'blood_type', 'room_number', 'patient')
    readonly_fields = ('id', 'created_at', 'updated_at')

@admin.register(TransportFulfillment)
class TransportFulfillmentAdmin(admin.ModelAdmin):
    list_display = ('id', 'request', 'status', 'vehicle', 'handled_by')
    readonly_fields = ('id', 'created_at', 'updated_at')

@admin.register(VehicleDispatch)
class VehicleDispatchAdmin(admin.ModelAdmin):
    list_display = ('id', 'vehicle', 'dispatched_by', 'dispatched_at')
    readonly_fields = ('id', 'dispatched_at', 'updated_at')


