from django.contrib import admin
from .models import Doctor, Nurse, Patient, BloodSample,BloodStorage

admin.site.register(Doctor)
admin.site.register(Nurse)
admin.site.register(Patient)

admin.site.register(BloodSample)
admin.site.register(BloodStorage)