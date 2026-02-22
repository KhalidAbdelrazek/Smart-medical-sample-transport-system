from django.db import models

# 1. جدول الدكتور (ضفت لك فيه التليفون عشان يكون كامل زي ما تحبي)

class Doctor(models.Model):
    name = models.CharField(max_length=100)
    phone = models.CharField(max_length=15, blank=True, null=True)
    
    def __str__(self):
        return self.name

# 2. جدول المريض (بالخانات اللي إنتي كنتِ كاتباها في الصورة 4)
class Patient(models.Model):
    name = models.CharField(max_length=100)
    age = models.IntegerField(null=True, blank=True)
    phone = models.CharField(max_length=15, blank=True, null=True)
    email = models.EmailField(blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    doctor = models.ForeignKey(Doctor, on_delete=models.CASCADE, related_name='patients')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name # هنا صلحنا غلطة الـ nam اللي كانت مطلعالك صفحة صفراء

# 3. جدول المخزن (Storage) - ده اللي هيعرفنا الأكياس المتاحة
class BloodStorage(models.Model):
    BLOOD_TYPES = [
        ('A+', 'A+'), ('A-', 'A-'), ('B+', 'B+'), ('B-', 'B-'),
        ('AB+', 'AB+'), ('AB-', 'AB-'), ('O+', 'O+'), ('O-', 'O-'),
    ]
    blood_type = models.CharField(max_length=5, choices=BLOOD_TYPES, unique=True)
    available_count = models.IntegerField(default=0)

    def __str__(self):
        return f"{self.blood_type} - {self.available_count} units"

# 4. جدول طلبات العينات (Blood Sample)
class BloodSample(models.Model):
    BLOOD_TYPES = [
        ('A+', 'A+'), ('A-', 'A-'), ('B+', 'B+'), ('B-', 'B-'),
        ('AB+', 'AB+'), ('AB-', 'AB-'), ('O+', 'O+'), ('O-', 'O-'),
    ]
    
    # منيو الأرقام اللي طلبتيها (من 1 لـ 10 مثلاً)
    COUNT_CHOICES = [(i, str(i)) for i in range(1, 11)]

    patient = models.ForeignKey(Patient, on_delete=models.CASCADE)
    blood_type = models.CharField(max_length=5, choices=BLOOD_TYPES)
    # هنا الـ count بقت منيو (choices)
    count = models.IntegerField(choices=COUNT_CHOICES, default=1) 
    requested_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Request: {self.blood_type} ({self.count}) for {self.patient.name}"

    is_shipped = models.BooleanField(default=False) # خانة جديدة عشان نعرف العينة طلعت ولا لأ

    def ship_sample(self):
        if not self.is_shipped:
            # 1. بنجيب الفصيلة من المخزن
            from .models import BloodStorage
            storage = BloodStorage.objects.get(blood_type=self.blood_type)
            
            # 2. بنطرح العدد اللي انطلب من المخزن
            storage.available_count -= self.count
            storage.save()
            
            # 3. بنعلم إنها خلاص اتشحنت
            self.is_shipped = True
            self.save()
class Nurse(models.Model):
    name = models.CharField(max_length=100)
    phone = models.CharField(max_length=15, blank=True, null=True)
    
    def __str__(self):
        return self.name