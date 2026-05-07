import datetime
import time

try:
    import RPi.GPIO as GPIO
except ImportError:
    from unittest.mock import MagicMock
    GPIO = MagicMock()

# ================= CONFIG =================
SENSOR_LEFT_PIN  = 17
SENSOR_RIGHT_PIN = 27

# How many consecutive reads must BOTH be BLACK before declaring intersection.
# At 115200 baud + tight loop the car covers ~0.3 mm per iteration, so 3 reads
# is enough to confirm a real 2 cm stripe without false positives.
INTERSECTION_CONFIRM_COUNT = 3
INTERSECTION_CONFIRM_DELAY = 0.005   # 5 ms between confirmation samples

# ================= UTILS =================
def get_timestamp():
    return datetime.datetime.now().strftime("%H:%M:%S.%f")[:-3]

# ================= GPIO =================
def setup_gpio():
    GPIO.setwarnings(False)
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(SENSOR_LEFT_PIN,  GPIO.IN)
    GPIO.setup(SENSOR_RIGHT_PIN, GPIO.IN)
    print(f"[{get_timestamp()}] GPIO ready — LEFT=Pin{SENSOR_LEFT_PIN}  RIGHT=Pin{SENSOR_RIGHT_PIN}")


def read_sensors():
    """
    Single raw read — no delay, no filtering.
    Used inside the fast detection loop for minimum latency.
    Returns (left, right): 1 = BLACK (line), 0 = WHITE (no line)
    """
    return GPIO.input(SENSOR_LEFT_PIN), GPIO.input(SENSOR_RIGHT_PIN)


def confirm_intersection() -> bool:
    """
    Confirms a REAL intersection (both sensors BLACK) by requiring
    INTERSECTION_CONFIRM_COUNT consecutive raw reads to all be (1,1).
    Any single (0,x) or (x,0) resets the counter.

    This eliminates false positives from thin-line edges or vibration.
    With a 2 cm black stripe and ~16x25 cm car the stripe will hold
    both sensors BLACK long enough to pass this check before the car
    physically crosses it.
    """
    consecutive = 0
    for _ in range(INTERSECTION_CONFIRM_COUNT):
        l, r = read_sensors()
        if l == 1 and r == 1:
            consecutive += 1
        else:
            return False   # Bail immediately on any non-black read
        time.sleep(INTERSECTION_CONFIRM_DELAY)
    return consecutive == INTERSECTION_CONFIRM_COUNT


def decide_movement(left: int, right: int):
    """
    Line-following logic:
      (0,0) → Both on white  → FORWARD
      (1,0) → Left on black  → veer LEFT  (right motor speed up)
      (0,1) → Right on black → veer RIGHT (left motor speed up)
      (1,1) → Both on black  → STOP (intersection — handled by caller)
    Returns (action_name, command_string)
    """
    if left == 0 and right == 0:
        return "FORWARD", "F\n"
    elif left == 1 and right == 0:
        return "LEFT",    "L\n"
    elif left == 0 and right == 1:
        return "RIGHT",   "R\n"
    else:
        return "STOP",    "S\n"


# ================= MQTT PAYLOAD HELPERS =================
def get_rooms(json_dispatch_data: dict):
    """
    Returns (list_of_rooms, batch_id) from a dispatch payload.
    Rooms preserve insertion order (Python 3.7+ dicts are ordered).
    """
    rooms    = list(json_dispatch_data.get("grouped_by_room", {}).keys())
    batch_id = json_dispatch_data.get("batch_id")
    return rooms, batch_id


def get_request_ids_for_room(json_dispatch_data: dict, room: str) -> list:
    """Returns all request_ids for a given room."""
    room_data = json_dispatch_data.get("grouped_by_room", {}).get(str(room), [])
    return [req.get("request_id") for req in room_data if req.get("request_id")]


def get_sample_ids_for_room(json_dispatch_data: dict, room: str) -> list:
    """Returns all sample_ids for a given room (used in arrival payload)."""
    room_data = json_dispatch_data.get("grouped_by_room", {}).get(str(room), [])
    return [req.get("sample_id") for req in room_data if req.get("sample_id")]