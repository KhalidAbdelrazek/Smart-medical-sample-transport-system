from django.contrib import admin
from .models import Employee, EmployeeStatistics, Patient, Vehicle, Request, Response, Dispatch

@admin.register(Employee)
class EmployeeAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'role', 'is_active', 'created_at', 'updated_at')
    list_filter = ('role', 'is_active')
    search_fields = ('name', 'role')

@admin.register(EmployeeStatistics)
class EmployeeStatisticsAdmin(admin.ModelAdmin):
    list_display = ('id', 'employee', 'total_requests', 'completed_requests', 'success_rate', 'last_updated')
    list_filter = ('employee',)
    search_fields = ('employee__name',)

@admin.register(Patient)
class PatientAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'age', 'gender', 'location', 'created_at', 'updated_at')
    list_filter = ('gender',)
    search_fields = ('name', 'location')

@admin.register(Vehicle)
class VehicleAdmin(admin.ModelAdmin):
    list_display = ('id', 'vehicle_id', 'vehicle_type', 'status', 'current_location', 'created_at', 'updated_at')
    list_filter = ('vehicle_type', 'status')
    search_fields = ('vehicle_id', 'vehicle_type')

@admin.register(Request)
class RequestAdmin(admin.ModelAdmin):
    list_display = ('id', 'patient', 'vehicle', 'status', 'priority', 'created_at', 'updated_at')
    list_filter = ('status', 'priority', 'vehicle')
    search_fields = ('patient__name', 'vehicle__vehicle_id')

@admin.register(Response)
class ResponseAdmin(admin.ModelAdmin):
    list_display = ('id', 'request', 'employee', 'response_type', 'response_time', 'created_at', 'updated_at')
    list_filter = ('response_type', 'employee')
    search_fields = ('request__id', 'employee__name')

@admin.register(Dispatch)
class DispatchAdmin(admin.ModelAdmin):
    list_display = ('id', 'request', 'vehicle', 'dispatch_time', 'estimated_delivery_time', 'actual_delivery_time', 'status', 'created_at', 'updated_at')
    list_filter = ('status', 'vehicle')
    search_fields = ('request__id', 'vehicle__vehicle_id')
