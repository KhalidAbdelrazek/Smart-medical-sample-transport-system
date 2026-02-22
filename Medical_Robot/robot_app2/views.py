
from rest_framework import viewsets
from .models import Doctor, Nurse, Patient
from .serializers import DoctorSerializer, NurseSerializer, PatientSerializer

# موظف خاص ببيانات الدكاترة
class DoctorViewSet(viewsets.ModelViewSet):
    queryset = Doctor.objects.all() # هيروح يجيب كل الدكاترة من الجدول
    serializer_class = DoctorSerializer # هيستخدم المترجم بتاع الدكتور

# موظف خاص ببيانات الممرضين
class NurseViewSet(viewsets.ModelViewSet):
    queryset = Nurse.objects.all()
    serializer_class = NurseSerializer

# موظف خاص ببيانات المرضى
class PatientViewSet(viewsets.ModelViewSet):
    queryset = Patient.objects.all()
    serializer_class=PatientSerializer
from rest_framework import generics
from .models import BloodStorage
from .serializers import BloodStorageSerializer

class BloodStorageListView(generics.ListAPIView):
    queryset = BloodStorage.objects.all()
    serializer_class = BloodStorageSerializer
from .models import BloodSample
from .serializers import BloodSampleSerializer

class BloodSampleCreateView(generics.ListCreateAPIView):
    queryset = BloodSample.objects.all()
    serializer_class = BloodSampleSerializer
from rest_framework.views import APIView
from rest_framework.response import Response
from .models import BloodSample

# class ShipSampleView(APIView):
#     def post(self, request, pk):
#         try:
#             sample = BloodSample.objects.get(pk=pk) # بنجيب العينة برقمها (ID)
#             if sample.is_shipped:
#                 return Response({"message": "العينة دي اتشحنت قبل كدة أصلاً!"}, status=400)
            
#             sample.ship_sample() # بنشغل الدالة السحرية اللي عملناها في الموديل
#             return Response({"message": "تم التحميل في العربية، والمخزن قل تلقائياً!"})
#         except BloodSample.DoesNotExist:
#             return Response({"message": "العينة مش موجودة"}, status=404)
class ShipSampleView(APIView):
    def post(self, request):
        blood_type = request.data.get('blood_type')
        new_quantity = int(request.data.get('quantity', 0))

        # هنا بنحاول نجيب الفصيلة لو موجودة، ولو مش موجودة بنعمل واحدة جديدة
        storage_item, created = BloodStorage.objects.get_or_create(
            blood_type=blood_type,
            defaults={'quantity': new_quantity}
        )

        if not created:
            # لو الفصيلة موجودة أصلاً، زود الكمية الجديدة على اللي عندنا
            storage_item.quantity += new_quantity
            storage_item.save()

        return Response({"message": "تمت إضافة الكمية وتحديث المخزن بنجاح"}, status=201)