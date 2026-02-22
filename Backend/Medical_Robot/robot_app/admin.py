from django.contrib import admin

# Register your models here.

from .models import Employee ,EmployeeStatistics , Patient , Request ,Response , Vehicle, Dispatch

admin.site.register(Employee)
admin.site.register(Patient)
admin.site.register(Request)
admin.site.register(Response)
admin.site.register(Vehicle)
admin.site.register(Dispatch)


@admin.register(EmployeeStatistics)
class EmployeeStatisticsAdmin(admin.ModelAdmin):
    readonly_fields = ('processed_samples', 'processed_bags', 'dispatched_cars')

    def has_add_permission(self, request):
        return False

    def has_delete_permission(self, request, obj=None):
        return False