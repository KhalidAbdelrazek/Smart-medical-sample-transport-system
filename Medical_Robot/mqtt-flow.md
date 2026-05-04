# MQTT Flow

This document lists MQTT topics used in this project and example payloads (pretty JSON) with details.

## Quick Reference: Data Types

| Field | Type | Example | Used In |
|-------|------|---------|---------|
| `car_id` | **integer** | `1` | All topics |
| `batch_id` | string (UUID) | `"550e8400-e29b-41d4-a716-446655440000"` | dispatch, acks |
| `room` | string | `"Room2001"`, `"STORAGE"` | control, arrivals |
| `roomNumber` | string or integer | `"2001"` or `2001` | arrivals (legacy) |
| `request_id` | string (UUID) | `"660e8400-e29b-41d4-a716-446655440001"` | dispatch, arrivals |
| `sample_id` | string (UUID) | `"770e8400-e29b-41d4-a716-446655440002"` | dispatch |
| `doctor_id` | string (UUID) or null | `"880e8400-e29b-41d4-a716-446655440003"` | dispatch |
| `status` | string | `"OK"`, `"ERROR"` | acks |
| `command` | string | `"proceed"`, `"stop"` | control |
| `timestamp` | string (ISO8601) | `"2026-05-02T12:34:56Z"` | acks, arrivals, responses |
| `capacity` | **integer** | `10` | car responses |

---

## Topics and Payloads

1) Topic: carts/{cart}/status
- Purpose: Send cart state signals (from web UI) to devices or monitoring.
- Example topic: carts/1/status
- QoS: 1
- Payload (example):

```json
{
  "cart": "1",
  "state": "C"
}
```
- Fields:
  - cart: string - identifier of the robot/cart
  - state: string - e.g., "C" = make dispatch order

---

2) Topic: carts/1/command (default configured as TOPIC)
- Purpose: Dispatch commands published by the healthcare dispatch service.
- Example topic: carts/1/command
- QoS: configurable (default 1)
- Payload shape (built by build_dispatch_payload):

```json
{
  "data": [
    {
      "samples": ["PT-001", "PT-003"],
      "roomNumber": 2001
    },
    {
      "samples": ["PT-005"],
      "roomNumber": 2002
    }
  ]
}
```
- Fields:
  - data: array of objects grouped by room
    - samples: array of sample codes (strings)
    - roomNumber: integer room identifier

---

3) Topic helpers used by transport client (per-car topics)
- transport/commands/{car_id}/dispatch
   - Purpose: Dispatch a batch to a specific car and wait for ACK on ack topic.
   - Example topic: transport/commands/1/dispatch
   - Expected payload (example):

```json
{
  "car_id": 1,
  "batch_id": "550e8400-e29b-41d4-a716-446655440000",
  "grouped_by_room": {
    "Room2001": [
      {
        "request_id": "660e8400-e29b-41d4-a716-446655440001",
        "sample_id": "770e8400-e29b-41d4-a716-446655440002",
        "doctor_id": "880e8400-e29b-41d4-a716-446655440003"
      }
    ],
    "Room2002": [
      {
        "request_id": "990e8400-e29b-41d4-a716-446655440004",
        "sample_id": "aa0e8400-e29b-41d4-a716-446655440005",
        "doctor_id": "bb0e8400-e29b-41d4-a716-446655440006"
      }
    ]
  }
}
```
- Required/used fields:
   - car_id: **integer** - target car ID
   - batch_id: string - unique UUID identifier for ACK correlation
   - grouped_by_room: object - samples grouped by room destination
     - key: string - room number (e.g., "Room2001")
     - value: array of objects for that room
       - request_id: string - UUID of TransportRequest
       - sample_id: string - UUID of BloodSample
       - doctor_id: string or null - UUID of requesting doctor

- transport/commands/{car_id}/control
   - Purpose: Fire-and-forget control commands (proceed, stop)
   - Example topic: transport/commands/1/control
   - Example payloads:

Proceed command:
```json
{
  "car_id": 1,
  "command": "proceed",
  "room": "Room2001"
}
```

Stop command:
```json
{
  "car_id": 1,
  "command": "stop",
  "reason": "obstacle_detected"
}
```
- Fields:
   - car_id: **integer** - target car ID
   - command: string - "proceed" | "stop"
   - room: string (for proceed) - room destination (e.g., "Room2001", "STORAGE")
   - reason: optional string (for stop) - reason for stopping

---

4) ACK and arrival topics (subscribed by the server)
- transport/acks/{car_id}
   - Purpose: Device ACKs for dispatch messages. The server waits for ACKs here.
   - Example topic: transport/acks/1
   - Expected payload (example):

```json
{
  "batch_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "OK",
  "message": "Accepted"
}
```
- Fields:
   - batch_id: string (UUID) - must match the dispatched batch_id for correlation
   - status: string - "OK" or "ERROR"
   - message: optional string with details

- transport/arrivals/{car_id}
    - Purpose: Notify that a car arrived at destination / room, or back at storage.
    - Example topic: transport/arrivals/1
    - Example payload (preferred format):

```json
{
  "car_id": 1,
  "room": "Room2001",
  "arrived_request_ids": ["660e8400-e29b-41d4-a716-446655440001", "770e8400-e29b-41d4-a716-446655440002"],
  "timestamp": "2026-05-02T12:34:56Z",
  "samples": ["PT-0001", "PT-0003"]
}
```

    - **Special case: Car arrival at STORAGE:**

```json
{
  "car_id": 1,
  "room": "STORAGE",
  "timestamp": "2026-05-02T12:34:56Z"
}
```
    - When `room="STORAGE"`, the car has arrived back at the storage area after completing all deliveries/returns.
    - The backend sets `car.arrived_at_storage` timestamp for later confirmation.

    - Backward-compatible payload (also accepted):

```json
{
  "car_id": 1,
  "roomNumber": "2001",
  "timestamp": "2026-05-02T12:34:56Z"
}
```
- Fields:
    - car_id: **integer** - the car that arrived
    - room: string (preferred) - room identifier (e.g., "Room2001", "Room2002", "STORAGE")
    - roomNumber: string or integer (compatibility alias for room)
    - arrived_request_ids: optional array of TransportRequest UUID strings
    - timestamp: string - ISO8601 format timestamp
    - samples: optional array of sample codes

---

Notes
- QoS levels and topic names are configurable via settings (see settings.TOPIC, MQTT_DISPATCH_QOS, etc.).
- The ACK flow requires batch_id correlation to avoid stale ACKs.
- All payloads are JSON-encoded strings when published.

---

## Car Return Workflow (STORAGE Arrival)

This section describes the complete flow for a car returning to storage and storage employee confirmation.

### 1. Device → Backend: Car Arrives at Storage

**MQTT Topic:** `transport/arrivals/{car_id}`

**Payload:**
```json
{
  "car_id": 1,
  "room": "STORAGE",
  "timestamp": "2026-05-02T15:45:30Z"
}
```

**Backend Processing (handle_arrival_event):**
- Detects `room == "STORAGE"`
- Sets `Car.arrived_at_storage = timestamp`
- No transport request updates (STORAGE has no associated requests)
- Logs the arrival event

### 2. Storage Employee: Poll for Returned Cars

**REST API Endpoint:** `GET /api/transport/returned-cars/`

**Permission:** `IsStorageEmployee`

**Response Example:**
```json
{
  "success": true,
  "message": "Found 2 returned car(s) awaiting confirmation",
  "data": {
    "returned_cars": [
      {
        "id": 1,
        "car_id": 1,
        "car_number": "C1",
        "status": "DISPATCHED",
        "arrived_at_storage": "2026-05-02T15:45:30Z",
        "capacity": 10,
        "created_at": "2026-04-20T10:00:00Z"
      },
      {
        "id": 2,
        "car_id": 2,
        "car_number": "C2",
        "status": "DISPATCHED",
        "arrived_at_storage": "2026-05-02T15:42:15Z",
        "capacity": 10,
        "created_at": "2026-04-20T10:00:00Z"
      }
    ]
  }
}
```

**Query Parameters:** None

**Response Fields:**
- `id`: **integer** - Car database ID (primary key)
- `car_id`: **integer** - Same as `id` (provided as alias for clarity)
- `car_number`: string - Unique car identifier string
- `status`: string - Current car status (DISPATCHED, LOADING, or IDLE)
- `arrived_at_storage`: string - ISO8601 timestamp when car arrived at storage
- `capacity`: **integer** - Maximum samples the car can carry
- `created_at`: string - ISO8601 timestamp when car was created in system

**Notes:**
- Returns cars where `arrived_at_storage IS NOT NULL` and `status IN ['DISPATCHED', 'LOADING']`
- Sorted by most recent arrival first (newest first)
- Storage employees can check this endpoint periodically to see returned cars
- Both `id` and `car_id` are provided for flexibility in client code

### 3. Storage Employee: Confirm Car Return

**REST API Endpoint:** `POST /api/transport/confirm-car-return/`

**Permission:** `IsStorageEmployee`

**Request Body:**
```json
{
  "car_id": 1
}
```

**Response Example:**
```json
{
  "success": true,
  "message": "Car return confirmed successfully",
  "data": {
    "car": {
      "id": 1,
      "car_number": "C1",
      "status": "IDLE"
    }
  }
}
```

**Backend Processing (confirm_car_returned):**
- Validates car exists
- Sets `Car.status = "IDLE"`
- Clears `arrived_at_storage` flag (set to same value for idempotency)
- Logs action: `CAR_STATUS_UPDATE`
- Returns updated car data

**Idempotency:**
- Calling this endpoint twice on the same car is safe
- Second call will have no-op behavior if car is already IDLE

### Complete Workflow Timeline

```
1. Car finishes all deliveries/returns
2. Car navigates back to storage (automatic routing)
3. Device sends: transport/arrivals/1 { car_id: 1, room: "STORAGE", ... }
4. Backend receives → sets car.arrived_at_storage = now
5. Storage UI polls GET /api/transport/returned-cars/ every 5-10 seconds
6. Storage employee sees car in the list
7. Storage employee clicks "Confirm Return" button
8. Frontend sends POST /api/transport/confirm-car-return/ { car_id: 1 }
9. Backend sets car.status = "IDLE"
10. Car is now available for next dispatch
```

---

## Summary of Updates from Previous Version

✅ **Fixed Issues in mqtt-flow.md:**

1. **`car_id` field type**
   - Was: string `"1"`
   - Now: **integer** `1`
   - Applies to: All MQTT topics and REST API responses

2. **Dispatch payload structure**
   - Was: `"data": [...]` with `"roomNumber": 1001` (integer)
   - Now: `"grouped_by_room": {...}` with string keys like `"Room2001"`
   - Reason: Better organizational clarity and string room identifiers

3. **Control command room field**
   - Was: `"room": 2001` (integer)
   - Now: `"room": "Room2001"` (string)
   - Reason: Consistency with database room_number field which is CharField

4. **Arrival event room field**
   - Was: `"room": "2001"` (ambiguous)
   - Now: `"room": "Room2001"` (explicit)
   - Also accepts: `"roomNumber"` for backward compatibility

5. **Data type documentation**
   - Added: Quick reference table at top of document
   - Shows: Which fields are integers vs strings
   - Examples: UUID format for request/sample/doctor IDs

6. **Response field types**
   - Was: Not clearly marked
   - Now: Marked with **integer** or string
   - Fields: `id`, `car_id`, `capacity` are integers
   - Example: `"capacity": 10` not `"capacity": "10"`

---

## Testing Your Implementation

To verify your Raspberry Pi sends the correct payloads, test with these JSON examples:

### Test: Arrival at Room
```bash
mosquitto_pub -h <broker> -u <user> -P <pass> \
  -t "transport/arrivals/1" \
  -m '{
    "car_id": 1,
    "room": "Room2001",
    "arrived_request_ids": ["660e8400-e29b-41d4-a716-446655440001"],
    "timestamp": "2026-05-04T12:00:00Z"
  }'
```

### Test: Arrival at Storage
```bash
mosquitto_pub -h <broker> -u <user> -P <pass> \
  -t "transport/arrivals/1" \
  -m '{
    "car_id": 1,
    "room": "STORAGE",
    "timestamp": "2026-05-04T12:00:00Z"
  }'
```

### Test: ACK Response
```bash
mosquitto_pub -h <broker> -u <user> -P <pass> \
  -t "transport/acks/1" \
  -m '{
    "batch_id": "550e8400-e29b-41d4-a716-446655440000",
    "status": "OK",
    "message": "Dispatch received and queued"
  }'
```

This section describes the complete flow when a car arrives at a doctor's room for delivery and sample returns.

### Timeline

```
1. Car Dispatched
   └─ Samples loaded, car sent to doctor's room

2. Car Arrives at Room
   ├─ MQTT: transport/arrivals/1 { room: "Room101", ... }
   ├─ Backend: Sets requests to ARRIVED_AT_DOCTOR_DELIVERY
   └─ Doctor UI: Shows "Sample arrived - Confirm receipt"

3. Doctor Confirms Delivery
   ├─ API: POST /api/transport/requests/{id}/confirm-delivery/
   ├─ Status: ARRIVED_AT_DOCTOR_DELIVERY → DELIVERED
   ├─ Sample: Sample status = "WITH_DOCTOR"
   ├─ Car: ⏸️ WAITS HERE (NO PROCEED YET)
   └─ Doctor UI: Shows "Return samples? Yes/No"

4a. Doctor Indicates Returns (if any)
   ├─ API: POST /api/transport/request-return/
   ├─ Creates: RETURN_REQUESTED requests for samples
   ├─ Doctor UI: "Return samples ready - Hand to car"
   └─ Car: Still waiting

4b. Doctor Confirms Return Handoff
   ├─ API: POST /api/transport/confirm-return-handoff/ ⭐ KEY ENDPOINT
   ├─ Status: RETURN_REQUESTED → LOADED_FOR_RETURN
   ├─ Check: _should_proceed_from_room()
   │  ├─ No ARRIVED_AT_DOCTOR_DELIVERY? ✓
   │  └─ No RETURN_REQUESTED or LOADED_FOR_RETURN? ✓
   ├─ Action: _publish_proceed_target() → MQTT proceed
   └─ Car: Proceeds to next room or STORAGE

5a. Alternative: No Returns
   ├─ API: POST /api/transport/confirm-return-handoff/ (still called)
   ├─ Result: loaded_count = 0 (no return samples)
   ├─ Action: _publish_proceed_target() → MQTT proceed
   └─ Car: Immediately proceeds (no returns to handle)

6. Car Proceeds to Next Room
   ├─ Car receives: transport/commands/1/control { command: "proceed", room: "Room102" }
   ├─ Car routes to next room
   └─ Returns to step 2 (MQTT arrival at next room)

OR (if all rooms done)

6. Car Returns to Storage
   ├─ Car receives: transport/commands/1/control { command: "proceed", room: "STORAGE" }
   ├─ Car routes to storage
   ├─ MQTT: transport/arrivals/1 { room: "STORAGE", ... }
   └─ Backend: Sets car.arrived_at_storage
```

### Key Points

1. **Delivery Confirmation is NOT final** - Car waits for return handling
2. **Return Handoff is the Gate** - Car only proceeds after this step
3. **No Returns = Fast Proceed** - Even with no returns, call confirm_return_handoff
4. **Rejection is Different** - Rejected deliveries proceed immediately (no returns to handle)

### API Call Sequence (Happy Path)

```
Step 1: GET /api/transport/arrivals/
   ↓
Step 2: POST /api/transport/requests/{id}/confirm-delivery/
   ↓
Step 3: GET /api/transport/return-status/ (check if returns needed)
   ↓
Step 4a: POST /api/transport/request-return/ (if returns needed)
   ├─ OR skip to Step 4b if no returns
   ↓
Step 4b: POST /api/transport/confirm-return-handoff/ ⭐ PROCEED TRIGGERED
   ↓
Step 5: Car receives MQTT proceed command
   ↓
Step 6: Car arrives at next room → back to Step 1
```

### Error Scenarios

**Doctor tries to confirm return handoff but no car at room:**
```json
{
  "success": false,
  "message": "No delivery car is at your room."
}
```

**Doctor confirms delivery of wrong status:**
```json
{
  "success": false,
  "message": "Only arrived deliveries can be confirmed. Current status: DELIVERED"
}
```

**Doctor tries to return samples from another doctor's room:**
```json
{
  "success": false,
  "message": "Permission denied"
}
```

Storage employees need to monitor when cars return to storage. The system provides multiple strategies:

### Strategy 1: Quick Count Polling (Recommended for UI)

**Endpoint:** `GET /api/transport/returned-cars/count/`

**Frequency:** Poll every 5-10 seconds (low overhead)

**Response:**
```json
{
  "success": true,
  "message": "Returned cars count retrieved",
  "data": {
    "count": 2,
    "has_returned_cars": true
  }
}
```

**Use Case:** 
- Storage UI displays badge/notification when `count > 0`
- On notification click, fetch full car list using detailed endpoint
- Minimal server load with frequent polling

**Frontend Example:**
```javascript
// Poll for returned cars every 5 seconds
setInterval(async () => {
  const response = await fetch('/api/transport/returned-cars/count/');
  const data = await response.json();
  if (data.data.has_returned_cars) {
    updateNotificationBadge(data.data.count);
    // Optionally fetch full list on user action
  }
}, 5000);
```

---

### Strategy 2: Full List Polling (Initial Load)

**Endpoint:** `GET /api/transport/returned-cars/`

**Frequency:** Poll on-demand or every 30-60 seconds

**Response:**
```json
{
  "success": true,
  "message": "Found 2 returned car(s) awaiting confirmation",
  "data": {
    "returned_cars": [
      {
        "car_id": 1,
        "car_number": "C1",
        "status": "DISPATCHED",
        "arrived_at_storage": "2026-05-02T15:45:30Z",
        "capacity": 10
      }
    ]
  }
}
```

**Use Case:**
- Storage employee loads the returns dashboard
- Displays full list of returned cars with details
- Employee can confirm one or multiple returns

---

### Strategy 3: Background Polling with Management Command

**Command:** `python manage.py poll_returned_cars`

**Options:**
```bash
# Poll every 5 seconds (default)
python manage.py poll_returned_cars

# Poll every 10 seconds
python manage.py poll_returned_cars --interval 10

# Poll once and exit
python manage.py poll_returned_cars --once

# Show detailed info for each car
python manage.py poll_returned_cars --verbose
```

**Example Output:**
```
🚗 Starting returned cars polling...
   Polling every 5 second(s). Press Ctrl+C to stop.

✅ Found 2 car(s) awaiting storage confirmation
   • Car C1 (ID: 1) - Status: DISPATCHED - Arrived: 2026-05-02T15:45:30Z
   • Car C2 (ID: 2) - Status: DISPATCHED - Arrived: 2026-05-02T15:42:15Z
```

**Use Case:**
- Run in a separate terminal for monitoring
- Useful for testing and development
- Can be integrated with systemd/supervisor for production monitoring

**Setup as Background Service (systemd):**
```ini
[Unit]
Description=Medical Robot - Poll Returned Cars
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/path/to/project
ExecStart=/path/to/venv/bin/python manage.py poll_returned_cars --interval 5
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

---

### Strategy 4: Celery Periodic Tasks (Advanced)

**Available if Celery is configured.** See `transport/tasks.py`.

**Configuration in settings.py:**
```python
from celery.schedules import schedule

CELERY_BEAT_SCHEDULE = {
    'poll-returned-cars': {
        'task': 'transport.tasks.poll_returned_cars_task',
        'schedule': 5.0,  # Every 5 seconds
    },
    'notify-storage-employees': {
        'task': 'transport.tasks.notify_storage_employees_of_returned_cars',
        'schedule': 10.0,  # Every 10 seconds
    },
}
```

**Features:**
- Automatic background polling without manual command
- Optional email notifications to storage employees
- Scalable for production environments
- Requires Celery, Redis/RabbitMQ setup

**Use Case:**
- Production deployments
- Automatic email/SMS notifications
- Integration with external monitoring systems

---

## Recommended Polling Configuration

| Environment | Strategy | Interval | Notes |
|-------------|----------|----------|-------|
| **Development** | Management Command | 5-10s | Easy debugging, visible logs |
| **UI-Only** | Quick Count Polling | 5-10s | Low overhead, responsive UI |
| **Production (Small)** | Full List Polling | 30s | Simple, adequate for <5 cars |
| **Production (Large)** | Celery + Quick Count | 5-10s | Scalable, email alerts |

---

## Complete Storage Workflow with Polling

```
1. Device sends: transport/arrivals/1 { room: "STORAGE", ... }
2. Backend sets: car.arrived_at_storage = now
3. [Polling Strategy]
   - Quick Count (5s): storage_ui sees badge "2 cars returned"
   - Management Command (5s): terminal shows "Found 2 car(s)"
   - Celery Task (5s): auto-polls, sends optional email
4. Storage employee sees notification/badge
5. Employee clicks → GET /api/transport/returned-cars/
6. Employee sees full list and clicks "Confirm Return"
7. Backend: POST /api/transport/confirm-car-return/ { car_id: 1 }
8. Car becomes IDLE and is available for next dispatch
```
