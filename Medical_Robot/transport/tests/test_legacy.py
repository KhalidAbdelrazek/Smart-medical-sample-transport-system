from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

from cars.models import Car
from samples.models import BloodSample
from transport.models import TransportRequest
from transport.services import dispatch_car


User = get_user_model()


class DispatchCarMqttIntegrationTests(TestCase):
    def setUp(self):
        self.doctor = User.objects.create_user(
            email="doctor.transport@test.com",
            password="testpass123",
            full_name="Dr. Transport",
            role="DOCTOR",
        )

        self.car = Car.objects.create(car_number="CAR-MQTT-01", status="LOADING")

        self.sample_1 = BloodSample.objects.create(
            patient_name="Patient One",
            blood_type="A+",
            status="REQUESTED",
        )
        self.sample_2 = BloodSample.objects.create(
            patient_name="Patient Two",
            blood_type="B+",
            status="REQUESTED",
        )

        self.request_1 = TransportRequest.objects.create(
            sample=self.sample_1,
            requested_by=self.doctor,
            room_number="Room-101",
            assigned_car=self.car,
            status="LOADED",
        )
        self.request_2 = TransportRequest.objects.create(
            sample=self.sample_2,
            requested_by=self.doctor,
            room_number="Room-202",
            assigned_car=self.car,
            status="LOADED",
        )

    def test_dispatch_car_publishes_grouped_payload(self):
        with patch("transport.mqtt_client.publish_and_wait_for_ack", return_value=(True, None)) as mock_ack:
            dispatched_requests, dispatched_car = dispatch_car(self.car.id)

        self.assertEqual(len(dispatched_requests), 2)
        self.assertEqual(dispatched_car.status, "DISPATCHED")
        mock_ack.assert_called_once()

        # Verify the new grouped payload format
        payload = mock_ack.call_args.kwargs.get("payload") or mock_ack.call_args[1].get("payload") or mock_ack.call_args[0][1]
        self.assertIn("grouped_by_room", payload)
        self.assertIn("Room-101", payload["grouped_by_room"])
        self.assertIn("Room-202", payload["grouped_by_room"])

    def test_dispatch_car_fails_when_ack_returns_false(self):
        """When ACK fails, dispatch should raise and leave requests unchanged."""
        from rest_framework.exceptions import ValidationError

        with patch("transport.mqtt_client.publish_and_wait_for_ack", return_value=(False, "No ACK")):
            with self.assertRaises(ValidationError):
                dispatch_car(self.car.id)

        self.car.refresh_from_db()
        self.request_1.refresh_from_db()
        self.request_2.refresh_from_db()
        self.sample_1.refresh_from_db()
        self.sample_2.refresh_from_db()

        # Everything should remain unchanged
        self.assertEqual(self.car.status, "LOADING")
        self.assertEqual(self.request_1.status, "LOADED")
        self.assertEqual(self.request_2.status, "LOADED")
        self.assertEqual(self.sample_1.status, "REQUESTED")
        self.assertEqual(self.sample_2.status, "REQUESTED")

    def test_dispatch_car_succeeds_on_ok_ack(self):
        with patch("transport.mqtt_client.publish_and_wait_for_ack", return_value=(True, None)):
            dispatched_requests, dispatched_car = dispatch_car(self.car.id)

        self.assertEqual(len(dispatched_requests), 2)
        self.assertEqual(dispatched_car.status, "DISPATCHED")

        self.car.refresh_from_db()
        self.request_1.refresh_from_db()
        self.request_2.refresh_from_db()
        self.sample_1.refresh_from_db()
        self.sample_2.refresh_from_db()

        self.assertEqual(self.car.status, "DISPATCHED")
        self.assertEqual(self.request_1.status, "DISPATCHED")
        self.assertEqual(self.request_2.status, "DISPATCHED")
        self.assertEqual(self.sample_1.status, "OUT_FOR_DELIVERY")
        self.assertEqual(self.sample_2.status, "OUT_FOR_DELIVERY")


class ReturnFlowTests(TestCase):
    """Test reverse logistics: doctor return requests and batch collection."""

    def setUp(self):
        self.client = APIClient()

        self.storage = User.objects.create_user(
            email="storage@test.com",
            password="testpass123",
            full_name="Storage Employee",
            role="STORAGE_EMPLOYEE",
        )
        self.doctor = User.objects.create_user(
            email="doctor.return@test.com",
            password="testpass123",
            full_name="Dr. Return",
            role="DOCTOR",
        )

        self.car = Car.objects.create(car_number="CAR-RETURN-01", status="IDLE", capacity=5)

        self.sample = BloodSample.objects.create(
            patient_name="Return Patient",
            blood_type="O+",
            status="WITH_DOCTOR",
            is_in_storage=False,
        )

    def test_doctor_can_request_return_for_delivered_sample(self):
        """Doctor can create a return request for a sample they have."""
        from transport.return_services import request_sample_return

        self.sample.status = "WITH_DOCTOR"
        self.sample.is_in_storage = False
        self.sample.save()

        orig_request = TransportRequest.objects.create(
            sample=self.sample,
            requested_by=self.doctor,
            room_number="Room-101",
            status="DELIVERED",
            request_type="DELIVERY",
        )

        return_request = request_sample_return(
            sample_code=self.sample.sample_code,
            doctor=self.doctor,
        )

        self.assertEqual(return_request.request_type, "RETURN")
        self.assertEqual(return_request.status, "RETURN_REQUESTED")
        self.assertEqual(return_request.sample.id, self.sample.id)
        self.assertEqual(return_request.room_number, "Room-101")

    def test_doctor_return_request_unknown_sample_raises_not_found(self):
        from transport.return_services import request_sample_return
        from rest_framework.exceptions import NotFound

        with self.assertRaises(NotFound):
            request_sample_return(sample_code="PT-9999", doctor=self.doctor)

    def test_start_return_collection_enforces_capacity(self):
        """Cannot select more returns than car capacity."""
        from transport.return_services import start_return_collection
        from rest_framework.exceptions import ValidationError

        self.car.capacity = 2
        self.car.save()

        requests = []
        for i in range(3):
            sample = BloodSample.objects.create(
                patient_name=f"Patient {i}",
                blood_type="O+",
                status="WITH_DOCTOR",
                is_in_storage=False,
            )
            req = TransportRequest.objects.create(
                sample=sample,
                requested_by=self.doctor,
                room_number=f"Room-{i}",
                status="PENDING",
                request_type="RETURN",
            )
            requests.append(req)

        with self.assertRaises(ValidationError):
            start_return_collection(
                car_id=self.car.id,
                selected_request_ids=[str(req.id) for req in requests],
                actor=self.storage,
            )

    def test_start_return_collection_requires_selection(self):
        from transport.return_services import start_return_collection
        from rest_framework.exceptions import ValidationError

        with self.assertRaises(ValidationError):
            start_return_collection(
                car_id=self.car.id,
                selected_request_ids=[],
                actor=self.storage,
            )

    def test_start_return_collection_dispatches_selected_requests(self):
        from transport.return_services import start_return_collection

        req = TransportRequest.objects.create(
            sample=self.sample,
            requested_by=self.doctor,
            room_number="Room-101",
            status="PENDING",
            request_type="RETURN",
        )

        with patch("transport.mqtt_client.publish_and_wait_for_ack", return_value=(True, None)):
            dispatched_requests, car = start_return_collection(
                car_id=self.car.id,
                selected_request_ids=[str(req.id)],
                actor=self.storage,
            )

        self.assertEqual(len(dispatched_requests), 1)
        self.assertEqual(car.status, "DISPATCHED")

        req.refresh_from_db()
        self.sample.refresh_from_db()
        self.car.refresh_from_db()

        self.assertEqual(req.status, "DISPATCHED")
        self.assertEqual(req.assigned_car_id, self.car.id)
        self.assertEqual(self.sample.status, "WITH_DOCTOR")
        self.assertFalse(self.sample.is_in_storage)
        self.assertEqual(self.car.status, "DISPATCHED")

    def test_delivery_completion_moves_sample_to_with_doctor(self):
        """Completing a DELIVERY request moves sample to WITH_DOCTOR state."""
        from transport.services import complete_transport_request

        sample = BloodSample.objects.create(
            patient_name="Delivery Test",
            blood_type="AB+",
            status="OUT_FOR_DELIVERY",
        )
        req = TransportRequest.objects.create(
            sample=sample,
            requested_by=self.doctor,
            room_number="Room-150",
            status="DISPATCHED",
            assigned_car=self.car,
            request_type="DELIVERY",
        )

        completed_req = complete_transport_request(
            request_id=req.id,
            actor=self.storage,
        )

        self.assertEqual(completed_req.status, "DELIVERED")
        sample.refresh_from_db()
        self.assertEqual(sample.status, "WITH_DOCTOR")
        self.assertEqual(sample.is_in_storage, False)

    def test_return_completion_marks_arrived_at_doctor(self):
        """Completing a RETURN request marks arrival and waits for doctor confirmation."""
        from transport.services import complete_transport_request

        sample = BloodSample.objects.create(
            patient_name="Return Complete Test",
            blood_type="B-",
            status="OUT_FOR_DELIVERY",
            is_in_storage=False,
        )
        req = TransportRequest.objects.create(
            sample=sample,
            requested_by=self.doctor,
            room_number="Room-160",
            status="DISPATCHED",
            assigned_car=self.car,
            request_type="RETURN",
        )

        completed_req = complete_transport_request(
            request_id=req.id,
            actor=self.storage,
        )

        self.assertEqual(completed_req.status, "ARRIVED_AT_DOCTOR")
        sample.refresh_from_db()
        self.assertEqual(sample.status, "WITH_DOCTOR")
        self.assertEqual(sample.is_in_storage, False)

    def test_confirm_returned_samples_marks_samples_in_storage(self):
        from transport.return_services import confirm_returned_samples

        sample = BloodSample.objects.create(
            patient_name="Batch Return",
            blood_type="A-",
            status="OUT_FOR_DELIVERY",
            is_in_storage=False,
        )
        req = TransportRequest.objects.create(
            sample=sample,
            requested_by=self.doctor,
            room_number="Room-170",
            status="DISPATCHED",
            assigned_car=self.car,
            request_type="RETURN",
        )
        self.car.status = "DISPATCHED"
        self.car.save()

        updated_requests = confirm_returned_samples(
            sample_codes=[sample.sample_code],
            actor=self.storage,
        )

        self.assertEqual(len(updated_requests), 1)
        req.refresh_from_db()
        sample.refresh_from_db()
        self.car.refresh_from_db()

        self.assertEqual(req.status, "RETURN_CONFIRMED")
        self.assertEqual(sample.status, "IN_STORAGE")
        self.assertTrue(sample.is_in_storage)
        self.assertEqual(self.car.status, "IDLE")


class ReturnBatchApiTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.storage = User.objects.create_user(
            email="storage.batch@test.com",
            password="testpass123",
            full_name="Storage Batch",
            role="STORAGE_EMPLOYEE",
        )
        self.doctor = User.objects.create_user(
            email="doctor.batch@test.com",
            password="testpass123",
            full_name="Dr. Batch",
            role="DOCTOR",
        )
        self.car = Car.objects.create(
            car_number="CAR-BATCH-01",
            status="IDLE",
            capacity=5,
        )

        self.sample_1 = BloodSample.objects.create(
            patient_name="Batch Patient 1",
            blood_type="A+",
            status="WITH_DOCTOR",
            is_in_storage=False,
        )
        self.sample_2 = BloodSample.objects.create(
            patient_name="Batch Patient 2",
            blood_type="B+",
            status="WITH_DOCTOR",
            is_in_storage=False,
        )

        for sample in [self.sample_1, self.sample_2]:
            TransportRequest.objects.create(
                sample=sample,
                requested_by=self.doctor,
                room_number="Room-500",
                status="ARRIVED_AT_DOCTOR_DELIVERY",
                request_type="DELIVERY",
            )

    def test_request_return_creates_same_batch_for_many_samples(self):
        self.client.force_authenticate(user=self.doctor)
        response = self.client.post(
            "/api/transport/request-return/",
            {"sample_ids": [str(self.sample_1.id), str(self.sample_2.id)]},
            format="json",
        )

        self.assertEqual(response.status_code, 201)
        payload = response.json()["data"]
        self.assertIsNotNone(payload["batch_id"])
        self.assertEqual(len(payload["requests"]), 2)

        batch_ids = {request["batch_id"] for request in payload["requests"]}
        statuses = {request["status"] for request in payload["requests"]}
        self.assertEqual(len(batch_ids), 1)
        self.assertEqual(statuses, {"RETURN_REQUESTED"})

    def test_storage_can_view_grouped_return_requests(self):
        self.client.force_authenticate(user=self.doctor)
        create_response = self.client.post(
            "/api/transport/request-return/",
            {"sample_ids": [str(self.sample_1.id), str(self.sample_2.id)]},
            format="json",
        )
        self.assertEqual(create_response.status_code, 201)

        self.client.force_authenticate(user=self.storage)
        response = self.client.get("/api/transport/return-requests/")
        self.assertEqual(response.status_code, 200)

        groups = response.json()["data"]
        self.assertEqual(len(groups), 1)
        self.assertEqual(groups[0]["room"], "Room-500")
        self.assertEqual(len(groups[0]["samples"]), 2)

    def test_storage_can_partially_approve_and_dispatch_batch(self):
        self.client.force_authenticate(user=self.doctor)
        create_response = self.client.post(
            "/api/transport/request-return/",
            {"sample_ids": [str(self.sample_1.id), str(self.sample_2.id)]},
            format="json",
        )
        batch_id = create_response.json()["data"]["batch_id"]

        self.client.force_authenticate(user=self.storage)
        with patch("transport.mqtt_client.publish_and_wait_for_ack", return_value=(True, None)):
            response = self.client.post(
                "/api/transport/approve-return/",
                {
                    "batch_id": batch_id,
                    "selected_sample_ids": [str(self.sample_1.id)],
                },
                format="json",
            )
        self.assertEqual(response.status_code, 200)

        request_one = TransportRequest.objects.get(
            sample=self.sample_1,
            batch_id=batch_id,
            request_type="RETURN",
        )
        request_two = TransportRequest.objects.get(
            sample=self.sample_2,
            batch_id=batch_id,
            request_type="RETURN",
        )
        self.assertEqual(request_one.status, "DISPATCHED")
        self.assertEqual(request_two.status, "RETURN_REQUESTED")

    def test_doctor_polls_arrived_status_and_confirms_idempotently(self):
        self.client.force_authenticate(user=self.doctor)
        create_response = self.client.post(
            "/api/transport/request-return/",
            {"sample_ids": [str(self.sample_1.id)]},
            format="json",
        )
        batch_id = create_response.json()["data"]["batch_id"]
        return_request = TransportRequest.objects.get(
            sample=self.sample_1,
            batch_id=batch_id,
            request_type="RETURN",
        )
        return_request.status = "ARRIVED_AT_DOCTOR"
        return_request.assigned_car = self.car
        return_request.save(update_fields=["status", "assigned_car"])

        status_response = self.client.get("/api/transport/return-status/")
        self.assertEqual(status_response.status_code, 200)
        rows = status_response.json()["data"]
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["status"], "ARRIVED_AT_DOCTOR")

        confirm_response = self.client.post(
            "/api/transport/confirm-return/",
            {"batch_id": batch_id},
            format="json",
        )
        self.assertEqual(confirm_response.status_code, 200)

        return_request.refresh_from_db()
        self.sample_1.refresh_from_db()
        self.assertEqual(return_request.status, "RETURN_CONFIRMED")
        self.assertEqual(self.sample_1.status, "IN_STORAGE")
        self.assertTrue(self.sample_1.is_in_storage)

        second_confirm = self.client.post(
            "/api/transport/confirm-return/",
            {"batch_id": batch_id},
            format="json",
        )
        self.assertEqual(second_confirm.status_code, 200)

    def test_confirm_returned_samples_api_updates_by_sample_code_list(self):
        sample = BloodSample.objects.create(
            patient_name="API Return",
            blood_type="AB-",
            status="OUT_FOR_DELIVERY",
            is_in_storage=False,
        )
        req = TransportRequest.objects.create(
            sample=sample,
            requested_by=self.doctor,
            room_number="Room-180",
            status="DISPATCHED",
            assigned_car=self.car,
            request_type="RETURN",
        )
        self.car.status = "DISPATCHED"
        self.car.save()

        self.client.force_authenticate(user=self.storage)
        response = self.client.post(
            "/api/transport/confirm-returned-samples/",
            {"sample_codes": [sample.sample_code]},
            format="json",
        )

        self.assertEqual(response.status_code, 200)

        req.refresh_from_db()
        sample.refresh_from_db()
        self.car.refresh_from_db()

        self.assertEqual(req.status, "RETURN_CONFIRMED")
        self.assertEqual(sample.status, "IN_STORAGE")
        self.assertTrue(sample.is_in_storage)
        self.assertEqual(self.car.status, "IDLE")
