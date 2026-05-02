# {
#   "car_id": 3,
#   "batch_id": "8c280158-f062-47bb-b4ca-2e9f35a228fe",
#   "grouped_by_room": {
#     "101": [
#       {
#         "request_id": "ff8cf112-0204-43ed-851c-186ac21d3201",
#         "sample_id": "052d4ceb-5434-4ea3-8dac-7bedfabe2945",
#         "doctor_id": "d5b81c1e-b102-4110-94f0-7ead7ce7e774"
#       },
#       {
#         "request_id": "df6383aa-19a2-48d8-8c00-4127e50e80b9",
#         "sample_id": "ead830d5-04e5-4ba1-ad6f-bf661c07ab2e",
#         "doctor_id": "d5b81c1e-b102-4110-94f0-7ead7ce7e774"
#       }
#     ]
#   }
# }

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

def filter_sensors(left_samples: list[int], right_samples: list[int]):
    """
    Reads sensors multiple times and returns the majority value for stability.
    """
    if not left_samples or not right_samples:
        return None, None
        
    # Calculate majority
    left_majority = max(set(left_samples), key=left_samples.count)
    right_majority = max(set(right_samples), key=right_samples.count)
    
    return left_majority, right_majority

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
        action = "FORWARD"
        cmd = "F\n"
    elif left == 0 and right == 1:
        action = "TURN LEFT"
        cmd = "L\n"
    elif left == 1 and right == 0:
        action = "TURN RIGHT"
        cmd = "R\n"
    elif left == 1 and right == 1:
        action = "STOP"
        cmd = "S\n"
    else:
        action = "UNKNOWN"
        cmd = "S\n"
        
    return action, cmd
