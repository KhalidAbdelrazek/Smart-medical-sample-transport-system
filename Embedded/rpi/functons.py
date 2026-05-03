import datetime
import time

try:
    import RPi.GPIO as GPIO
except ImportError:
    from unittest.mock import MagicMock
    GPIO = MagicMock()

# ================= CONFIG =================
SENSOR_LEFT_PIN = 17
SENSOR_RIGHT_PIN = 27
FILTER_SAMPLES = 3

# ================= UTILS =================
def get_timestamp():
    return datetime.datetime.now().strftime("%H:%M:%S.%f")[:-3]

# ================= GPIO =================
def setup_gpio():
    """Initializes the GPIO pins for the line sensors."""
    GPIO.setwarnings(False)
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(SENSOR_LEFT_PIN, GPIO.IN)
    GPIO.setup(SENSOR_RIGHT_PIN, GPIO.IN)
    print(f"[{get_timestamp()}] GPIO ready")

def read_sensors():
    """Reads raw values from the left and right sensors."""
    return GPIO.input(SENSOR_LEFT_PIN), GPIO.input(SENSOR_RIGHT_PIN)

def filter_sensors():
    """
    Reads sensors multiple times and returns the majority value for stability.
    """
    left_samples = []
    right_samples = []

    for _ in range(FILTER_SAMPLES):
        l, r = read_sensors()
        left_samples.append(l)
        right_samples.append(r)
        time.sleep(0.01)

    left = max(set(left_samples), key=left_samples.count)
    right = max(set(right_samples), key=right_samples.count)

    return left, right

# ================= LOGIC =================
def decide_movement(left: int, right: int):
    """
    Decides movement logic based on sensor readings.
    LEFT=0 and RIGHT=0 -> MOVE FORWARD
    LEFT=0 and RIGHT=1 -> TURN LEFT
    LEFT=1 and RIGHT=0 -> TURN RIGHT
    LEFT=1 and RIGHT=1 -> STOP
    
    Returns (action_name, command_string)
    """
    if left == 0 and right == 0:
        return "FORWARD", "F\n"
    elif left == 0 and right == 1:
        return "LEFT", "L\n"
    elif left == 1 and right == 0:
        return "RIGHT", "R\n"
    else:
        return "STOP", "S\n"

# ================= MQTT HELPERS =================
def get_rooms(json_dispatch_data: dict):
    """
    Extracts the list of rooms and the batch_id from the dispatch payload.
    """
    rooms = list(json_dispatch_data.get("grouped_by_room", {}).keys())
    return rooms, json_dispatch_data.get("batch_id")

def get_request_ids_for_room(json_dispatch_data: dict, room: str) -> list[str]:
    """
    Extracts all request IDs for a given room.
    """
    room_data = json_dispatch_data.get("grouped_by_room", {}).get(room, [])
    return [req.get("request_id") for req in room_data if req.get("request_id")]

def build_ack_payload(batch_id: str) -> dict:
    """
    Builds the ACK payload.
    """
    return {
        "status": "OK",
        "batch_id": batch_id
    }

def build_arrival_payload(room: str, request_ids: list[str]) -> dict:
    """
    Builds the ARRIVAL payload.
    """
    return {
        "room": room,
        "arrived_request_ids": request_ids
    }
