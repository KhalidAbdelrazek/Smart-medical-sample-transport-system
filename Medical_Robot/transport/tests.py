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

    def test_dispatch_car_publishes_payload_with_sample_room_pairs(self):
        with patch("transport.services.publish_dispatch_event", return_value=True) as publish_mock:
            dispatched_requests, dispatched_car = dispatch_car(self.car.id)

        self.assertEqual(len(dispatched_requests), 2)
        self.assertEqual(dispatched_car.status, "DISPATCHED")
        publish_mock.assert_called_once()

        payload = publish_mock.call_args.args[0]
        self.assertIn("data", payload)
        self.assertEqual(len(payload["data"]), 2)

        # Verify payload structure: data should have items grouped by room with sample codes
        room_data = {item["roomNumber"]: item["samples"] for item in payload["data"]}
        self.assertIn("Room-101", room_data)
        self.assertIn("Room-202", room_data)
        self.assertIn(self.sample_1.sample_code, room_data["Room-101"])
        self.assertIn(self.sample_2.sample_code, room_data["Room-202"])

    def test_dispatch_car_continues_when_mqtt_publish_returns_false(self):
        with patch("transport.services.publish_dispatch_event", return_value=False):
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

    def test_dispatch_car_continues_when_mqtt_publish_raises(self):
        with patch("transport.services.publish_dispatch_event", side_effect=RuntimeError("MQTT down")):
            dispatched_requests, dispatched_car = dispatch_car(self.car.id)

        self.assertEqual(len(dispatched_requests), 2)
        self.assertEqual(dispatched_car.status, "DISPATCHED")

        self.car.refresh_from_db()
        self.request_1.refresh_from_db()
        self.request_2.refresh_from_db()

        self.assertEqual(self.car.status, "DISPATCHED")
        self.assertEqual(self.request_1.status, "DISPATCHED")
        self.assertEqual(self.request_2.status, "DISPATCHED")


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
        self.assertEqual(return_request.status, "PENDING")
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

        with patch("transport.return_services.publish_dispatch_event", return_value=True):
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
        self.assertEqual(self.sample.status, "OUT_FOR_DELIVERY")
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

        with patch("transport.services.publish_dispatch_event", return_value=True):
            completed_req = complete_transport_request(
                request_id=req.id,
                actor=self.storage,
            )

        self.assertEqual(completed_req.status, "DELIVERED")
        sample.refresh_from_db()
        self.assertEqual(sample.status, "WITH_DOCTOR")
        self.assertEqual(sample.is_in_storage, False)

    def test_return_completion_moves_sample_back_to_in_storage(self):
        """Completing a RETURN request moves sample back to IN_STORAGE."""
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

        with patch("transport.services.publish_dispatch_event", return_value=True):
            completed_req = complete_transport_request(
                request_id=req.id,
                actor=self.storage,
            )

        self.assertEqual(completed_req.status, "RETURNED")
        sample.refresh_from_db()
        self.assertEqual(sample.status, "IN_STORAGE")
        self.assertEqual(sample.is_in_storage, True)

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

        self.assertEqual(req.status, "DELIVERED")
        self.assertEqual(sample.status, "IN_STORAGE")
        self.assertTrue(sample.is_in_storage)
        self.assertEqual(self.car.status, "IDLE")

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

        self.assertEqual(req.status, "DELIVERED")
        self.assertEqual(sample.status, "IN_STORAGE")
        self.assertTrue(sample.is_in_storage)
        self.assertEqual(self.car.status, "IDLE")
