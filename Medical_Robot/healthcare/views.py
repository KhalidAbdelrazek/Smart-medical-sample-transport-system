# Create your views here.
from rest_framework.pagination import PageNumberPagination
from drf_spectacular.utils import extend_schema, OpenApiParameter, OpenApiTypes
from rest_framework.decorators import api_view


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