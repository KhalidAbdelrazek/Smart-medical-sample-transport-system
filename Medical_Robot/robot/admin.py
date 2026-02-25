from django.contrib import admin
from .models import *
# Register your models here.

admin.site.register(Patient)
admin.site.register(Vehicle)
admin.site.register(TransportRequest)
admin.site.register(TransportFulfillment)
admin.site.register(VehicleDispatch)
admin.site.register(Employee)
admin.site.register(EmployeeStatistics)


