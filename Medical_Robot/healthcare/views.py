# Create your views here.
from django.http import Http404
from rest_framework import status, viewsets, filters
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination



from .models import Patient, Staff
from .serializers import PatientSerializer, StaffSerializer
from rest_framework import generics
from rest_framework.authentication import TokenAuthentication
from rest_framework.permissions import IsAuthenticated


# Add authentication and permissions to your generic views
    
class PatientListGeneric(generics.ListCreateAPIView):
    queryset = Patient.objects.all()
    serializer_class = PatientSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


class PatientDetailGeneric(generics.RetrieveUpdateDestroyAPIView):
    queryset = Patient.objects.all()
    serializer_class = PatientSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


class StaffListGeneric(generics.ListCreateAPIView):
    queryset = Staff.objects.all()
    serializer_class = StaffSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


class StaffDetailGeneric(generics.RetrieveUpdateDestroyAPIView):
    queryset = Staff.objects.all()
    serializer_class = StaffSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]
    
    

#----------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------



import json
import ssl
import paho.mqtt.client as mqtt
from django.conf import settings
from django.http import JsonResponse
from .models import SensorReading

def control_device(request):
    cart = request.GET.get('cart')
    state = request.GET.get('state') # "ON" or "OFF"

    if not cart or not state:
        return JsonResponse({"error": "Missing parameters"}, status=400)

    # 1. Define Topic
    topic = f"carts/{cart}/status"
    
    # 2. Setup the Client (Same logic as your Command, but for sending)
    client = mqtt.Client()
    
    # Security (Crucial for HiveMQ Cloud)
    client.username_pw_set(settings.MQTT_USERNAME, settings.MQTT_PASSWORD)
    client.tls_set(cert_reqs=ssl.CERT_REQUIRED, tls_version=ssl.PROTOCOL_TLS)

    try:
        # 3. Connect (with a timeout so the website doesn't hang)
        client.connect(settings.BROKER_URL, settings.BROKER_PORT, keepalive=60)
        client.loop_start()
        
        # Create the JSON payload
        payload_dict = {
            "cart": cart,
            "state": state  # "ON" or "OFF"
            }
        payload_json = json.dumps(payload_dict)

        # 4. Publish the JSON string with QoS=1
        client.publish(topic, payload_json, qos=1)
        
        # 5. Disconnect after a brief delay to allow publish to complete
        import time
        time.sleep(0.5)
        client.loop_stop()
        client.disconnect()
        
        # # 6. Save to database after successful publish
        # SensorReading.objects.create(
        #     cart=cart,
        #     state=state,
        #     position="N/A",  # Set default or get from request if available
        #     load="N/A"       # Set default or get from request if available
        # )
        
        return JsonResponse({"status": "Signal sent successfully", "topic": topic})

    except Exception as e:
        # Log the error for debugging
        print(f"MQTT Publish Error: {e}")
        return JsonResponse({"status": "Failed to reach Broker", "error": str(e)}, status=500)

# class based views
class PatientList(APIView):
    def get(self, request):
        patients = Patient.objects.all()
        serializer = PatientSerializer(patients, many=True)
        return Response(serializer.data, status = status.HTTP_200_OK)

    def post(self, request):
        serializer = PatientSerializer(data = request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(status=status.HTTP_400_BAD_REQUEST)



class PatientInfo(APIView):
    def get_object(self, pk):
        try:
            return Patient.objects.get(pk=pk)
        except Patient.DoesNotExist:
            raise Http404
        
    def get(self, request, pk):
        patient = self.get_object(pk)
        serializer = PatientSerializer(patient)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def put(self, request, pk):
        patient = self.get_object(pk)
        serializer = PatientSerializer(patient, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(status=status.HTTP_400_BAD_REQUEST)
    
    def delete(self, pk):
        patient = self.get_object(pk)
        patient.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)









class StaffList(APIView):
    def get(self, request):
        staff = Staff.objects.all()
        serializer = StaffSerializer(staff, many=True)
        return Response(serializer.data, status = status.HTTP_200_OK)

    def post(self, request):
        serializer = StaffSerializer(data = request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(status=status.HTTP_400_BAD_REQUEST)
                

class StaffInfo(APIView):
    def get_object(self, pk):
        try:
            return Staff.objects.get(pk=pk)
        except Staff.DoesNotExist:
            raise Http404
        
    def get(self, request, pk):
        staff = self.get_object(pk)
        serializer = StaffSerializer(staff)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def put(self, request, pk):
        staff = self.get_object(pk)
        serializer = StaffSerializer(staff, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(status=status.HTTP_400_BAD_REQUEST)
    
    def delete(self, request, pk):
        staff = self.get_object(pk)
        staff.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
    
    
class TwoItemPagination(PageNumberPagination):
    page_size = 2
    page_size_query_param = 'page_size'
    max_page_size = 100


class StaffView(viewsets.ModelViewSet):
    queryset = Staff.objects.all()
    serializer_class = StaffSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['name']


class PatientView(viewsets.ModelViewSet):
    queryset = Patient.objects.all()
    serializer_class = PatientSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['name']

#----------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------

# class PatientListGeneric(generics.ListCreateAPIView):
#     queryset = Patient.objects.all()
#     serializer_class = PatientSerializer

# class PatientDetailGeneric(generics.RetrieveUpdateDestroyAPIView):
#     queryset = Patient.objects.all()
#     serializer_class = PatientSerializer

# class StaffListGeneric(generics.ListCreateAPIView):
#     queryset = Staff.objects.all()
#     serializer_class = StaffSerializer

# class StaffDetailGeneric(generics.RetrieveUpdateDestroyAPIView):
#     queryset = Staff.objects.all()
#     serializer_class = StaffSerializer        
    
