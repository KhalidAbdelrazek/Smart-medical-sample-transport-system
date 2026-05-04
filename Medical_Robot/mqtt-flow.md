# MQTT Flow

This document lists MQTT topics used in this project and example payloads (pretty JSON) with details.

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
  "car_id": "1",
  "batch_id": "b12345",
  "data": [
    { "samples": ["PT-001"], "roomNumber": 1001 }
  ]
}
```
- Required/used fields:
  - car_id: string - target car
  - batch_id: string - unique identifier for ACK correlation
  - data: as per dispatch payload above

- transport/commands/{car_id}/control
  - Purpose: Fire-and-forget control commands (proceed, stop)
  - Example topic: transport/commands/1/control
  - Example payloads:

Proceed command:
```json
{
  "car_id": "1",
  "command": "proceed",
  "room": 2001
}
```

Stop command:
```json
{
  "car_id": "1",
  "command": "stop",
  "reason": "obstacle_detected"
}
```
- Fields:
  - car_id: string
  - command: string ("proceed" | "stop")
  - room: optional int (for proceed)
  - reason: optional string (for stop)

---

4) ACK and arrival topics (subscribed by the server)
- transport/acks/{car_id}
  - Purpose: Device ACKs for dispatch messages. The server waits for ACKs here.
  - Example topic: transport/acks/1
  - Expected payload (example):

```json
{
  "batch_id": "b12345",
  "status": "OK",
  "message": "Accepted"
}
```
- Fields:
  - batch_id: string - must match the dispatched batch_id
  - status: string - e.g., "OK" or "ERROR"
  - message: optional string with details

- transport/arrivals/{car_id}
  - Purpose: Notify that a car arrived at destination / room.
  - Example topic: transport/arrivals/1
  - Example payload (preferred format):

```json
{
  "car_id": "1",
  "room": "2001",
  "arrived_request_ids": ["c4d8f455-5f29-4fe6-95c0-22ef2ca64a09"],
  "timestamp": "2026-05-02T12:34:56Z",
  "samples": ["PT-001", "PT-003"]
}
```
  - Backward-compatible payload (also accepted):

```json
{
  "car_id": "1",
  "roomNumber": 2001,
  "timestamp": "2026-05-02T12:34:56Z"
}
```
- Fields:
  - car_id: string
  - room: string (preferred room identifier)
  - roomNumber: integer|string (compatibility alias for room)
  - arrived_request_ids: optional array of TransportRequest UUID strings
  - timestamp: ISO8601 string
  - samples: optional array of sample codes

---

Notes
- QoS levels and topic names are configurable via settings (see settings.TOPIC, MQTT_DISPATCH_QOS, etc.).
- The ACK flow requires batch_id correlation to avoid stale ACKs.
- All payloads are JSON-encoded strings when published.
