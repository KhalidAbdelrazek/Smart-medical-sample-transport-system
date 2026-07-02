"""
transport/tests/test_dispatch.py

Tests for the ACK-gated dispatch flow, arrival handling, arrivals polling,
and doctor confirm/reject logic.
"""
from unittest.mock import patch, MagicMock
from uuid import uuid4

from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.exceptions import ValidationError
from rest_framework.test import APIClient

from cars.models import Car
from samples.models import BloodSample
from transport.models import TransportRequest
from transport.mqtt_client import MqttSubscriber
from transport.services import (
    build_grouped_dispatch_payload,
    dispatch_car,
    handle_arrival_event,
    confirm_delivery,
    confirm_return_handoff,
    reject_delivery,
)

User = get_user_model()

# Patch targets — mqtt_client functions are imported lazily in services.py
_PATCH_ACK = "transport.mqtt_client.publish_and_wait_for_ack"
_PATCH_PROCEED = "transport.mqtt_client.publish_proceed_command"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _create_doctor(email="doctor@test.com", name="Dr. Test"):
    return User.objects.create_user(
        email=email, password="testpass123", full_name=name, role="DOCTOR",
    )


def _create_storage(email="storage@test.com"):
    return User.objects.create_user(
        email=email, password="testpass123", full_name="Storage", role="STORAGE_EMPLOYEE",
    )


def _create_car(number="CAR-01", status="LOADING"):
    return Car.objects.create(car_number=number, status=status, capacity=10)


def _create_sample(name="Patient", blood_type="A+", status="REQUESTED"):
    return BloodSample.objects.create(
        patient_name=name, blood_type=blood_type, status=status,
    )


def _create_transport_request(sample, doctor, car, room="Room-101",
                              status="LOADED", request_type="DELIVERY"):
    return TransportRequest.objects.create(
        sample=sample,
        requested_by=doctor,
        room_number=room,
        assigned_car=car,
        status=status,
        request_type=request_type,
    )


# ===========================================================================
# 1. Grouped Payload Building
# ===========================================================================

class TestGroupedPayloadBuilding(TestCase):
    """Verify build_grouped_dispatch_payload groups requests by room."""

    def setUp(self):
        self.doctor = _create_doctor()
        self.car = _create_car()

    def test_groups_requests_by_room(self):
        """3 requests across 2 rooms → grouped_by_room has 2 keys."""
        s1 = _create_sample("P1")
        s2 = _create_sample("P2")
        s3 = _create_sample("P3")

        r1 = _create_transport_request(s1, self.doctor, self.car, room="Room-A")
        r2 = _create_transport_request(s2, self.doctor, self.car, room="Room-B")
        r3 = _create_transport_request(s3, self.doctor, self.car, room="Room-A")

        payload = build_grouped_dispatch_payload(self.car, [r1, r2, r3])

        self.assertIn("car_id", payload)
        self.assertIn("batch_id", payload)
        self.assertIn("grouped_by_room", payload)

        grouped = payload["grouped_by_room"]
        self.assertEqual(len(grouped), 2)
        self.assertIn("Room-A", grouped)
        self.assertIn("Room-B", grouped)
        self.assertEqual(len(grouped["Room-A"]), 2)
        self.assertEqual(len(grouped["Room-B"]), 1)

    def test_includes_request_id_sample_id_doctor_id(self):
        """Each entry in the grouped payload has the required fields."""
        s1 = _create_sample("P1")
        r1 = _create_transport_request(s1, self.doctor, self.car, room="Room-A")

        payload = build_grouped_dispatch_payload(self.car, [r1])
        entry = payload["grouped_by_room"]["Room-A"][0]

        self.assertEqual(entry["request_id"], str(r1.id))
        self.assertEqual(entry["sample_id"], str(s1.id))
        self.assertEqual(entry["doctor_id"], str(self.doctor.id))

    def test_single_room_single_request(self):
        """Edge case: one request, one room."""
        s1 = _create_sample("P1")
        r1 = _create_transport_request(s1, self.doctor, self.car, room="Room-X")

        payload = build_grouped_dispatch_payload(self.car, [r1])

        self.assertEqual(payload["car_id"], self.car.id)
        self.assertEqual(len(payload["grouped_by_room"]), 1)
        self.assertIn("Room-X", payload["grouped_by_room"])


# ===========================================================================
# 2. Dispatch ACK Flow
# ===========================================================================

class TestDispatchAckFlow(TestCase):
    """Verify dispatch_car blocks for ACK and handles success/failure."""

    def setUp(self):
        self.doctor = _create_doctor()
        self.car = _create_car()
        self.sample = _create_sample("Patient ACK")
        self.request = _create_transport_request(
            self.sample, self.doctor, self.car, room="Room-101",
        )

    @patch(_PATCH_ACK, return_value=(True, None))
    def test_dispatch_succeeds_on_ok_ack(self, mock_ack):
        """When ACK is OK, requests become DISPATCHED."""
        dispatched, car = dispatch_car(self.car.id)

        self.assertEqual(len(dispatched), 1)
        self.assertEqual(car.status, "DISPATCHED")

        self.request.refresh_from_db()
        self.sample.refresh_from_db()
        self.assertEqual(self.request.status, "DISPATCHED")
        self.assertEqual(self.sample.status, "OUT_FOR_DELIVERY")
        mock_ack.assert_called_once()

    @patch(_PATCH_ACK,
           return_value=(False, "No ACK received from device after 2 attempt(s)"))
    def test_dispatch_fails_on_timeout(self, mock_ack):
        """When ACK times out, requests stay LOADED and ValidationError is raised."""
        with self.assertRaises(ValidationError) as ctx:
            dispatch_car(self.car.id)

        self.assertIn("device did not acknowledge", str(ctx.exception.detail))

        self.request.refresh_from_db()
        self.sample.refresh_from_db()
        self.car.refresh_from_db()

        self.assertEqual(self.request.status, "LOADED")
        self.assertEqual(self.sample.status, "REQUESTED")
        self.assertEqual(self.car.status, "LOADING")

    @patch(_PATCH_ACK,
           return_value=(False, "Device returned error ACK: motor fault"))
    def test_dispatch_fails_on_error_ack(self, mock_ack):
        """When device sends ERROR ACK, dispatch fails gracefully."""
        with self.assertRaises(ValidationError):
            dispatch_car(self.car.id)

        self.request.refresh_from_db()
        self.assertEqual(self.request.status, "LOADED")

    @patch(_PATCH_ACK)
    def test_dispatch_payload_is_grouped(self, mock_ack):
        """Verify the payload passed to publish_and_wait_for_ack is grouped by room."""
        mock_ack.return_value = (True, None)

        # Add a second sample in a different room
        s2 = _create_sample("P2")
        _create_transport_request(s2, self.doctor, self.car, room="Room-202")

        dispatch_car(self.car.id)

        call_kwargs = mock_ack.call_args
        payload = call_kwargs.kwargs.get("payload") or call_kwargs[1].get("payload") or call_kwargs[0][1]
        self.assertIn("grouped_by_room", payload)
        self.assertIn("Room-101", payload["grouped_by_room"])
        self.assertIn("Room-202", payload["grouped_by_room"])


# ===========================================================================
# 3. Arrival Handling
# ===========================================================================

class TestArrivalHandling(TestCase):
    """Verify handle_arrival_event updates request statuses correctly."""

    def setUp(self):
        self.doctor = _create_doctor()
        self.car = _create_car(status="DISPATCHED")
        self.sample = _create_sample("Patient Arrival", status="OUT_FOR_DELIVERY")
        self.request = _create_transport_request(
            self.sample, self.doctor, self.car, room="Room-A",
            status="DISPATCHED", request_type="DELIVERY",
        )

    def test_arrival_event_sets_arrived_status(self):
        """Simulate arrival → requests become ARRIVED_AT_DOCTOR_DELIVERY."""
        count = handle_arrival_event(
            car_id=self.car.id,
            room="Room-A",
            arrived_request_ids=[str(self.request.id)],
        )
        self.assertEqual(count, 1)

        self.request.refresh_from_db()
        self.assertEqual(self.request.status, "ARRIVED_AT_DOCTOR_DELIVERY")
        self.assertIsNotNone(self.request.arrived_at)

    def test_arrival_is_idempotent(self):
        """Calling handle_arrival twice does not error and does not re-update."""
        handle_arrival_event(
            car_id=self.car.id,
            room="Room-A",
            arrived_request_ids=[str(self.request.id)],
        )
        # Call again — should be idempotent
        count = handle_arrival_event(
            car_id=self.car.id,
            room="Room-A",
            arrived_request_ids=[str(self.request.id)],
        )
        self.assertEqual(count, 0)  # No new updates

    def test_arrival_validates_car_id(self):
        """Unknown car_id raises ValidationError."""
        with self.assertRaises(ValidationError):
            handle_arrival_event(
                car_id=99999,
                room="Room-A",
                arrived_request_ids=[str(self.request.id)],
            )

    def test_arrival_skips_requests_not_on_car(self):
        """Request IDs not belonging to the car are skipped (with warning)."""
        other_car = _create_car(number="CAR-OTHER", status="DISPATCHED")
        count = handle_arrival_event(
            car_id=other_car.id,
            room="Room-A",
            arrived_request_ids=[str(self.request.id)],
        )
        self.assertEqual(count, 0)  # Not updated because request is on different car

    def test_arrival_rejects_wrong_room(self):
        """Request IDs with wrong room are not marked as arrived (Fix #3)."""
        count = handle_arrival_event(
            car_id=self.car.id,
            room="Room-WRONG",  # self.request is in Room-A
            arrived_request_ids=[str(self.request.id)],
        )
        self.assertEqual(count, 0)
        self.request.refresh_from_db()
        self.assertEqual(self.request.status, "DISPATCHED")  # unchanged

    def test_arrival_handles_return_type(self):
        """Return requests transition to ARRIVED_AT_DOCTOR (not DELIVERY)."""
        return_sample = _create_sample("Return P", status="WITH_DOCTOR")
        return_req = _create_transport_request(
            return_sample, self.doctor, self.car, room="Room-A",
            status="DISPATCHED", request_type="RETURN",
        )

        handle_arrival_event(
            car_id=self.car.id,
            room="Room-A",
            arrived_request_ids=[str(return_req.id)],
        )

        return_req.refresh_from_db()
        self.assertEqual(return_req.status, "ARRIVED_AT_DOCTOR")


# ===========================================================================
# 4. Arrivals Polling API
# ===========================================================================

class TestArrivalsPollingApi(TestCase):
    """Verify GET /api/transport/arrivals/ returns correct doctor-filtered data."""

    def setUp(self):
        self.client = APIClient()
        self.doctor1 = _create_doctor("doc1@test.com", "Dr. Alpha")
        self.doctor2 = _create_doctor("doc2@test.com", "Dr. Beta")
        self.car = _create_car(status="DISPATCHED")

    def test_doctor_sees_only_own_arrivals(self):
        """Two doctors in same room — each sees only their arrived samples."""
        s1 = _create_sample("P1", status="OUT_FOR_DELIVERY")
        s2 = _create_sample("P2", status="OUT_FOR_DELIVERY")

        _create_transport_request(
            s1, self.doctor1, self.car, room="Room-A",
            status="ARRIVED_AT_DOCTOR_DELIVERY",
        )
        _create_transport_request(
            s2, self.doctor2, self.car, room="Room-A",
            status="ARRIVED_AT_DOCTOR_DELIVERY",
        )

        # Doctor 1 polls
        self.client.force_authenticate(user=self.doctor1)
        resp = self.client.get("/api/transport/arrivals/")
        self.assertEqual(resp.status_code, 200)
        data = resp.json()["data"]
        self.assertEqual(len(data["arrivals"]), 1)
        self.assertEqual(data["arrivals"][0]["sample_id"], str(s1.id))

        # Doctor 2 polls
        self.client.force_authenticate(user=self.doctor2)
        resp = self.client.get("/api/transport/arrivals/")
        data = resp.json()["data"]
        self.assertEqual(len(data["arrivals"]), 1)
        self.assertEqual(data["arrivals"][0]["sample_id"], str(s2.id))

    def test_returns_empty_when_no_arrivals(self):
        """Clean state returns empty arrivals list."""
        self.client.force_authenticate(user=self.doctor1)
        resp = self.client.get("/api/transport/arrivals/")
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.json()["data"]["arrivals"], [])


# ===========================================================================
# 5. Confirm / Reject Flow
# ===========================================================================

class TestConfirmRejectFlow(TestCase):
    """Verify confirm_delivery and reject_delivery behaviour."""

    def setUp(self):
        self.doctor = _create_doctor()
        self.car = _create_car(status="DISPATCHED")

    def _make_arrived_request(self, room="Room-A", doctor=None):
        sample = _create_sample(f"P-{uuid4().hex[:4]}", status="OUT_FOR_DELIVERY")
        return _create_transport_request(
            sample, doctor or self.doctor, self.car, room=room,
            status="ARRIVED_AT_DOCTOR_DELIVERY",
        )

    @patch(_PATCH_PROCEED)
    def test_confirm_sets_delivered(self, mock_proceed):
        """Confirming transitions to DELIVERED, sample to WITH_DOCTOR."""
        req = self._make_arrived_request()

        result = confirm_delivery(req.id, self.doctor)

        self.assertEqual(result.status, "DELIVERED")
        req.sample.refresh_from_db()
        self.assertEqual(req.sample.status, "WITH_DOCTOR")
        self.assertFalse(req.sample.is_in_storage)

    @patch(_PATCH_PROCEED)
    def test_reject_marks_failed(self, mock_proceed):
        """Rejecting transitions to FAILED, sample reverts to IN_STORAGE."""
        req = self._make_arrived_request()

        result = reject_delivery(req.id, self.doctor, reason="Wrong sample")

        self.assertEqual(result.status, "FAILED")
        self.assertEqual(result.status_note, "Wrong sample")
        req.sample.refresh_from_db()
        self.assertEqual(req.sample.status, "IN_STORAGE")
        self.assertTrue(req.sample.is_in_storage)

    @patch(_PATCH_PROCEED)
    def test_reject_triggers_proceed_when_room_empty(self, mock_proceed):
        """After rejecting the last arrived request in a room, proceed is sent."""
        req = self._make_arrived_request(room="Room-X")

        reject_delivery(req.id, self.doctor)

        mock_proceed.assert_called_once_with(car_id=self.car.id, room="STORAGE")

    @patch(_PATCH_PROCEED)
    def test_reject_no_proceed_when_others_waiting(self, mock_proceed):
        """If other doctors still have arrived requests in the room, no proceed."""
        doctor2 = _create_doctor("doc2@test.com", "Dr. Two")
        self._make_arrived_request(room="Room-Y")
        req2 = self._make_arrived_request(room="Room-Y", doctor=doctor2)

        # Doctor2 rejects — Doctor1 still waiting → no proceed
        reject_delivery(req2.id, doctor2)

        mock_proceed.assert_not_called()

    @patch(_PATCH_PROCEED)
    def test_confirm_last_in_room_triggers_proceed(self, mock_proceed):
        """After the last doctor in a room confirms, proceed is sent to next room or STORAGE."""
        req = self._make_arrived_request(room="Room-Z")

        confirm_delivery(req.id, self.doctor)

        # When only one room exists, car proceeds to STORAGE (no more rooms)
        mock_proceed.assert_called_once_with(car_id=self.car.id, room="STORAGE")

    @patch(_PATCH_PROCEED)
    def test_confirm_not_last_in_room_no_proceed(self, mock_proceed):
        """If another arrived request exists in the room, no proceed yet."""
        self._make_arrived_request(room="Room-Z")  # request 1
        req2 = self._make_arrived_request(room="Room-Z")  # request 2

        confirm_delivery(req2.id, self.doctor)

        mock_proceed.assert_not_called()

    @patch(_PATCH_PROCEED)
    def test_confirm_last_in_room_proceeds_to_next_room(self, mock_proceed):
        """After confirming last delivery in a room, car proceeds to the next room."""
        # Create requests in multiple rooms
        req1 = self._make_arrived_request(room="Room-A")
        self._make_arrived_request(room="Room-B")

        # Confirm delivery at Room-A
        confirm_delivery(req1.id, self.doctor)

        # Should proceed to next room (Room-B)
        mock_proceed.assert_called_once_with(car_id=self.car.id, room="Room-B")

    @patch(_PATCH_PROCEED)
    def test_reject_last_in_room_proceeds_to_next_room(self, mock_proceed):
        """After rejecting last delivery in a room, car proceeds to the next room."""
        req1 = self._make_arrived_request(room="Room-A")
        self._make_arrived_request(room="Room-B")

        reject_delivery(req1.id, self.doctor)

        mock_proceed.assert_called_once_with(car_id=self.car.id, room="Room-B")

    def test_confirm_wrong_doctor_raises(self):
        """Doctor cannot confirm another doctor's delivery."""
        from django.core.exceptions import PermissionDenied as DjangoPermDenied

        other_doctor = _create_doctor("other@test.com", "Dr. Other")
        req = self._make_arrived_request()

        with self.assertRaises(DjangoPermDenied):
            confirm_delivery(req.id, other_doctor)

    def test_confirm_wrong_status_raises(self):
        """Cannot confirm a request that is not in ARRIVED_AT_DOCTOR_DELIVERY."""
        sample = _create_sample("P", status="OUT_FOR_DELIVERY")
        req = _create_transport_request(
            sample, self.doctor, self.car, room="Room-A",
            status="DISPATCHED",
        )

        with self.assertRaises(ValidationError):
            confirm_delivery(req.id, self.doctor)


class TestMqttArrivalPayloadCompatibility(TestCase):
    """Verify arrival payload compatibility fields are accepted by subscriber."""

    @patch("transport.services.handle_arrival_event")
    def test_arrival_accepts_room_number_field(self, mock_handle_arrival):
        subscriber = MqttSubscriber()

        subscriber._handle_arrival(
            car_id=3,
            payload={
                "roomNumber": 2001,
                "timestamp": "2026-05-02T12:34:56Z",
            },
        )

        mock_handle_arrival.assert_called_once_with(
            car_id=3,
            room="2001",
            arrived_request_ids=None,
            timestamp="2026-05-02T12:34:56Z",
        )


# ===========================================================================
# 6. Confirm Return Handoff
# ===========================================================================

class TestConfirmReturnHandoffFlow(TestCase):
    """Verify direct handoff behavior from WITH_DOCTOR samples."""

    def setUp(self):
        self.client = APIClient()
        self.doctor = _create_doctor()
        self.car = _create_car(status="DISPATCHED")
        self.client.force_authenticate(user=self.doctor)

    def _make_active_delivery(self, room="Room-A"):
        sample = _create_sample(f"D-{uuid4().hex[:4]}", status="WITH_DOCTOR")
        return _create_transport_request(
            sample,
            self.doctor,
            self.car,
            room=room,
            status="DELIVERED",
            request_type="DELIVERY",
        )

    def _make_eligible_with_doctor_sample(self, room="Room-A"):
        sample = _create_sample(f"W-{uuid4().hex[:4]}", status="WITH_DOCTOR")
        sample.is_in_storage = False
        sample.save(update_fields=["is_in_storage", "updated_at"])
        _create_transport_request(
            sample,
            self.doctor,
            self.car,
            room=room,
            status="DELIVERED",
            request_type="DELIVERY",
        )
        return sample

    def _make_return_request(self, sample, room="Room-A"):
        return _create_transport_request(
            sample,
            self.doctor,
            self.car,
            room=room,
            status="RETURN_REQUESTED",
            request_type="RETURN",
        )

    @patch(_PATCH_PROCEED)
    def test_confirm_return_handoff_creates_and_loads_from_with_doctor(self, mock_proceed):
        self._make_active_delivery()
        sample = self._make_eligible_with_doctor_sample()

        result = confirm_return_handoff(
            doctor=self.doctor,
            sample_codes=[sample.sample_code],
        )

        self.assertEqual(result["loaded_count"], 1)
        self.assertEqual(result["loaded_sample_codes"], [sample.sample_code])
        self.assertEqual(result["skipped_sample_codes"], [])

        return_request = TransportRequest.objects.get(
            sample=sample,
            request_type="RETURN",
        )
        self.assertEqual(return_request.status, "LOADED_FOR_RETURN")
        self.assertEqual(return_request.assigned_car_id, self.car.id)
        self.assertIsNotNone(return_request.loaded_at)

        sample.refresh_from_db()
        self.assertEqual(sample.status, "OUT_FOR_DELIVERY")
        self.assertFalse(sample.is_in_storage)
        mock_proceed.assert_called_once_with(car_id=self.car.id, room="STORAGE")

    @patch(_PATCH_PROCEED)
    def test_confirm_return_handoff_loads_existing_return_request(self, mock_proceed):
        self._make_active_delivery()
        sample = self._make_eligible_with_doctor_sample()
        return_request = self._make_return_request(sample=sample)

        result = confirm_return_handoff(
            doctor=self.doctor,
            sample_codes=[sample.sample_code],
        )

        self.assertEqual(result["loaded_count"], 1)
        self.assertEqual(result["loaded_sample_codes"], [sample.sample_code])
        self.assertEqual(result["skipped_sample_codes"], [])

        return_request.refresh_from_db()
        self.assertEqual(return_request.status, "LOADED_FOR_RETURN")
        self.assertEqual(return_request.assigned_car_id, self.car.id)
        self.assertIsNotNone(return_request.loaded_at)

        sample.refresh_from_db()
        self.assertEqual(sample.status, "OUT_FOR_DELIVERY")
        self.assertFalse(sample.is_in_storage)
        mock_proceed.assert_called_once_with(car_id=self.car.id, room="STORAGE")

    @patch(_PATCH_PROCEED)
    def test_confirm_return_handoff_skips_invalid_or_ineligible_codes(self, mock_proceed):
        self._make_active_delivery()
        valid_sample = self._make_eligible_with_doctor_sample()
        ineligible_sample = _create_sample("Ineligible", status="IN_STORAGE")

        result = confirm_return_handoff(
            doctor=self.doctor,
            sample_codes=[
                valid_sample.sample_code,
                "PT-UNKNOWN",
                ineligible_sample.sample_code,
            ],
        )

        self.assertEqual(result["loaded_count"], 1)
        self.assertEqual(result["loaded_sample_codes"], [valid_sample.sample_code])
        self.assertEqual(
            result["skipped_sample_codes"],
            ["PT-UNKNOWN", ineligible_sample.sample_code],
        )

        valid_sample.refresh_from_db()
        self.assertEqual(valid_sample.status, "OUT_FOR_DELIVERY")
        self.assertFalse(valid_sample.is_in_storage)
        self.assertFalse(
            TransportRequest.objects.filter(
                sample=ineligible_sample,
                request_type="RETURN",
            ).exists()
        )
        mock_proceed.assert_called_once_with(car_id=self.car.id, room="STORAGE")

    @patch(_PATCH_PROCEED)
    def test_confirm_return_handoff_api_returns_loaded_and_skipped_lists(self, mock_proceed):
        self._make_active_delivery()
        valid_sample = self._make_eligible_with_doctor_sample()

        response = self.client.post(
            "/api/transport/confirm-return-handoff/",
            {"sample_codes": [valid_sample.sample_code, "PT-UNKNOWN"]},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()["data"]
        self.assertEqual(data["loaded_count"], 1)
        self.assertEqual(data["loaded_sample_codes"], [valid_sample.sample_code])
        self.assertEqual(data["skipped_sample_codes"], ["PT-UNKNOWN"])

        valid_sample.refresh_from_db()
        self.assertEqual(valid_sample.status, "OUT_FOR_DELIVERY")
        self.assertFalse(valid_sample.is_in_storage)
        mock_proceed.assert_called_once_with(car_id=self.car.id, room="STORAGE")

    def test_confirm_return_handoff_api_requires_sample_codes(self):
        self._make_active_delivery()

        response = self.client.post(
            "/api/transport/confirm-return-handoff/",
            {},
            format="json",
        )
        self.assertEqual(response.status_code, 400)

    @patch(_PATCH_PROCEED)
    def test_confirm_return_handoff_api_all_invalid_codes_returns_partial_success(self, mock_proceed):
        self._make_active_delivery()

        response = self.client.post(
            "/api/transport/confirm-return-handoff/",
            {"sample_codes": ["PT-UNKNOWN"]},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()["data"]
        self.assertEqual(data["loaded_count"], 0)
        self.assertEqual(data["loaded_sample_codes"], [])
        self.assertEqual(data["skipped_sample_codes"], ["PT-UNKNOWN"])
        mock_proceed.assert_called_once_with(car_id=self.car.id, room="STORAGE")


# ===========================================================================
# 7. Confirm/Reject API Endpoints
# ===========================================================================

class TestConfirmRejectApi(TestCase):
    """Verify the REST API endpoints for confirm and reject delivery."""

    def setUp(self):
        self.client = APIClient()
        self.doctor = _create_doctor()
        self.car = _create_car(status="DISPATCHED")
        self.client.force_authenticate(user=self.doctor)

    def _make_arrived_request(self):
        sample = _create_sample(f"P-{uuid4().hex[:4]}", status="OUT_FOR_DELIVERY")
        return _create_transport_request(
            sample, self.doctor, self.car, room="Room-A",
            status="ARRIVED_AT_DOCTOR_DELIVERY",
        )

    @patch(_PATCH_PROCEED)
    def test_confirm_delivery_api(self, mock_proceed):
        req = self._make_arrived_request()
        resp = self.client.post(f"/api/transport/requests/{req.id}/confirm-delivery/")
        self.assertEqual(resp.status_code, 200)
        self.assertTrue(resp.json()["success"])

        req.refresh_from_db()
        self.assertEqual(req.status, "DELIVERED")

    @patch(_PATCH_PROCEED)
    def test_reject_delivery_api(self, mock_proceed):
        req = self._make_arrived_request()
        resp = self.client.post(
            f"/api/transport/requests/{req.id}/reject-delivery/",
            {"reason": "Damaged tube"},
            format="json",
        )
        self.assertEqual(resp.status_code, 200)

        req.refresh_from_db()
        self.assertEqual(req.status, "FAILED")
        self.assertEqual(req.status_note, "Damaged tube")

    @patch(_PATCH_PROCEED)
    def test_reject_delivery_api_empty_reason(self, mock_proceed):
        """Reject without providing a reason defaults to 'Rejected by doctor'."""
        req = self._make_arrived_request()
        resp = self.client.post(
            f"/api/transport/requests/{req.id}/reject-delivery/",
            {},
            format="json",
        )
        self.assertEqual(resp.status_code, 200)

        req.refresh_from_db()
        self.assertEqual(req.status, "FAILED")
        self.assertEqual(req.status_note, "Rejected by doctor")
