
from rest_framework import serializers
from .models import Doctor, Nurse, Patient

class DoctorSerializer(serializers.ModelSerializer):
    class Meta:
        model = Doctor
        fields = '__all__' # يعني هات كل الخانات (الاسم، التخصص، إلخ)

class NurseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Nurse
        fields = '__all__'

class PatientSerializer(serializers.ModelSerializer):
    # عشان يظهر اسم الدكتور والممرض بدل الأرقام في بيانات المريض
    doctor_name = serializers.ReadOnlyField(source='doctor.name')
    nurse_name = serializers.ReadOnlyField(source='nurse.name')

    class Meta:
        model = Patient
        fields='__all__'
from .models import BloodStorage

class BloodStorageSerializer(serializers.ModelSerializer):
    class Meta:
        model = BloodStorage
        fields = '__all__' # يعني ابعت كل البيانات (الفصيلة والعدد)
from .models import BloodSample
class BloodSampleSerializer(serializers.ModelSerializer):
    class Meta:
        model = BloodSample
        fields = '__all__' # هيبعت كل بيانات الطلب (الفصيلة، العدد، اسم المريض)
        
    def validate(self, data):
        blood_type = data.get('blood_type')
        requested_count = data.get('count')

        from .models import BloodStorage

        try:
            storage = BloodStorage.objects.get(blood_type=blood_type)        
            
            if requested_count > storage.available_count:
                raise serializers.ValidationError(f"الكمية غير متاحة! المخزن فيه {storage.available_count} أكياس بس من فصيلة {blood_type}."
                )
        except BloodStorage.DoesNotExist:
            raise serializers.ValidationError("الفصيلة دي مش متوفرة في المخزن حالياً.")

        return data