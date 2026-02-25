# Create your views here.
from django.http import Http404
from rest_framework import status, viewsets, filters
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from rest_framework.decorators import api_view

from .models import Patient, Staff
from .serializers import PatientSerializer, StaffSerializer
from rest_framework import generics
from rest_framework.authentication import TokenAuthentication
from rest_framework.permissions import IsAuthenticated

from drf_spectacular.utils import extend_schema_view, extend_schema, OpenApiParameter
from drf_spectacular.types import OpenApiTypes


# Add authentication and permissions to your generic views

@extend_schema_view(
    list=extend_schema(description="Retrieve a list of all healthcare patients.", summary="List Healthcare Patients"),
    create=extend_schema(description="Create a new healthcare patient.", summary="Create Healthcare Patient")
)
class PatientListGeneric(generics.ListCreateAPIView):
    queryset = Patient.objects.all()
    serializer_class = PatientSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


@extend_schema_view(
    retrieve=extend_schema(description="Retrieve details of a specific patient.", summary="Retrieve Healthcare Patient"),
    update=extend_schema(description="Update a patient completely.", summary="Update Healthcare Patient"),
    partial_update=extend_schema(description="Partially update a patient.", summary="Patch Healthcare Patient"),
    destroy=extend_schema(description="Delete a patient.", summary="Delete Healthcare Patient")
)
class PatientDetailGeneric(generics.RetrieveUpdateDestroyAPIView):
    queryset = Patient.objects.all()
    serializer_class = PatientSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


@extend_schema_view(
    list=extend_schema(description="Retrieve a list of all staff members.", summary="List Staff"),
    create=extend_schema(description="Create a new staff member.", summary="Create Staff")
)
class StaffListGeneric(generics.ListCreateAPIView):
    queryset = Staff.objects.all()
    serializer_class = StaffSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


@extend_schema_view(
    retrieve=extend_schema(description="Retrieve details of a specific staff member.", summary="Retrieve Staff"),
    update=extend_schema(description="Update a staff member completely.", summary="Update Staff"),
    partial_update=extend_schema(description="Partially update a staff member.", summary="Patch Staff"),
    destroy=extend_schema(description="Delete a staff member.", summary="Delete Staff")
)
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

@extend_schema(
    parameters=[
        OpenApiParameter(name='cart', description='Identifier for the robot cart', required=True, type=OpenApiTypes.STR),
        OpenApiParameter(name='state', description='State ("C" for making the dispatch order)', required=True, type=OpenApiTypes.STR),
    ],
    responses={
        200: OpenApiTypes.OBJECT,
        400: OpenApiTypes.OBJECT,
        500: OpenApiTypes.OBJECT,
    },
    description="Control the specific device via MQTT by sending cart and state data.",
    summary="Control Device MQTT"
)
@api_view(['GET'])
def control_device(request):
    cart = request.GET.get('cart')
    state = request.GET.get('state') # "C" for making the dispatch order

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
            "state": state  # "C for making the dispatch order"
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

class TwoItemPagination(PageNumberPagination):
    page_size = 2
    page_size_query_param = 'page_size'
    max_page_size = 100