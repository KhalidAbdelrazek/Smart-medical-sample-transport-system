from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.test import TestCase

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
