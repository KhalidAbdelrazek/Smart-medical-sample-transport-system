import paho.mqtt.client as mqtt

import ssl

import json
 
# --- CONFIGURATION ---

MQTT_HOST = "81758f399b5b46b9875ac5e5f1e3ef1e.s1.eu.hivemq.cloud"

MQTT_PORT = 8883

MQTT_USER = "hivemq.webclient.1764285829577"

MQTT_PASS = "bNtHo2#E,9>w18<CcOfF"
 
# Subscribe specifically to Cart  status

TOPIC = "carts/+/status"
 
# --- HARDWARE SETUP (Raspberry Pi Example) ---

# Set to True if running on a Pi, False if testing on PC

USE_GPIO = True
 
if USE_GPIO:

    import RPi.GPIO as GPIO

    SWITCH_PIN = 17

    GPIO.setmode(GPIO.BCM)

    GPIO.setup(SWITCH_PIN, GPIO.OUT)
 
def turn_switch_on():

    print(">>> ACTION: Switch turned ON")

    if USE_GPIO:

        GPIO.output(SWITCH_PIN, GPIO.HIGH)
 
def turn_switch_off():

    print(">>> ACTION: Switch turned OFF")

    if USE_GPIO:

        GPIO.output(SWITCH_PIN, GPIO.LOW)
 
def on_connect(client, userdata, flags, rc):

    print(f"Connected to HiveMQ with result code {rc}")

    client.subscribe(TOPIC)

    print(f"Subscribed to topic: {TOPIC}")
 
def on_message(client, userdata, msg):

    try:

        payload_str = msg.payload.decode()

        data = json.loads(payload_str)

        # Extract the data based on your API structure

        cart_id = data.get("cart")

        state = data.get("state")

        print(f"Received for Cart {cart_id}: State is {state}")
 
        # Logic for ON/OFF

        if state == "ON":

            turn_switch_on()

        elif state == "OFF":

            turn_switch_off()

        else:

            print(f"Unknown state received: {state}")
 
    except json.JSONDecodeError:

        print("Failed to decode JSON")

    except Exception as e:

        print(f"Error: {e}")
 
# --- MAIN EXECUTION ---

client = mqtt.Client()

client.username_pw_set(MQTT_USER, MQTT_PASS)

client.tls_set(cert_reqs=ssl.CERT_REQUIRED)
 
client.on_connect = on_connect

client.on_message = on_message
 
print("Connecting to broker...")

client.connect(MQTT_HOST, MQTT_PORT, 60)
 
try:

    client.loop_forever()

except KeyboardInterrupt:

    print("Disconnecting...")

    if USE_GPIO:

        GPIO.cleanup()
