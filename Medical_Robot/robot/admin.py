from django.contrib import admin
from .models import *
# Register your models here.

admin.site.register(Patient)
admin.site.register(Vehicle)
admin.site.register(Request)
admin.site.register(Response)
admin.site.register(Dispatch)
admin.site.register(Employee)
admin.site.register(EmployeeStatistics)


