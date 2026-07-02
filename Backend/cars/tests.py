"""
cars/tests.py

Tests for car management endpoints and services.
"""
from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.exceptions import NotFound
from rest_framework.test import APIClient

from cars.models import Car
from cars.services import get_car_details
from samples.models import BloodSample
from transport.models import TransportRequest

User = get_user_model()


class CarDetailsServiceTests(TestCase):
    """Tests for get_car_details service function."""

    def setUp(self):
        self.car = Car.objects.create(
            car_number="CAR-SERVICE-01",
            status="LOADING",
            capacity=5,
        )
        self.doctor = User.objects.create_user(
            email="doctor@test.com",
            password="testpass123",
            full_name="Dr. Test",
            role="DOCTOR",
        )

    def test_get_car_details_not_found(self):
        """Should raise NotFound for non-existent car."""
        with self.assertRaises(NotFound):
            get_car_details(999)

    def test_get_car_details_empty_car(self):
        """Empty car should have zero used capacity and full remaining capacity."""
        details = get_car_details(self.car.id)

        self.assertEqual(details['car_id'], self.car.id)
        self.assertEqual(details['car_number'], 'CAR-SERVICE-01')
        self.assertEqual(details['status'], 'LOADING')
        self.assertEqual(details['capacity'], 5)
        self.assertEqual(details['used_capacity'], 0)
        self.assertEqual(details['remaining_capacity'], 5)
        self.assertEqual(details['sample_codes'], [])

    def test_get_car_details_with_delivery_loaded(self):
        """DELIVERY in LOADED status should occupy a slot."""
        sample = BloodSample.objects.create(
            patient_name="Patient 1",
            blood_type="O+",
            status="OUT_FOR_DELIVERY",
        )
        TransportRequest.objects.create(
            sample=sample,
            requested_by=self.doctor,
            room_number="Room-101",
            assigned_car=self.car,
            status='LOADED',
            request_type='DELIVERY',
        )

        details = get_car_details(self.car.id)

        self.assertEqual(details['used_capacity'], 1)
        self.assertEqual(details['remaining_capacity'], 4)
        self.assertIn(sample.sample_code, details['sample_codes'])

    def test_get_car_details_with_delivery_dispatched(self):
        """DELIVERY in DISPATCHED status should occupy a slot."""
        sample = BloodSample.objects.create(
            patient_name="Patient 2",
            blood_type="A+",
            status="OUT_FOR_DELIVERY",
        )
        TransportRequest.objects.create(
            sample=sample,
            requested_by=self.doctor,
            room_number="Room-101",
            assigned_car=self.car,
            status='DISPATCHED',
            request_type='DELIVERY',
        )

        details = get_car_details(self.car.id)

        self.assertEqual(details['used_capacity'], 1)
        self.assertEqual(details['remaining_capacity'], 4)
        self.assertIn(sample.sample_code, details['sample_codes'])

    def test_get_car_details_with_return_loaded_for_return(self):
        """RETURN in LOADED_FOR_RETURN status should occupy a slot."""
        sample = BloodSample.objects.create(
            patient_name="Patient 3",
            blood_type="B+",
            status="WITH_DOCTOR",
            is_in_storage=False,
        )
        TransportRequest.objects.create(
            sample=sample,
            requested_by=self.doctor,
            room_number="Room-101",
            assigned_car=self.car,
            status='LOADED_FOR_RETURN',
            request_type='RETURN',
        )

        details = get_car_details(self.car.id)

        self.assertEqual(details['used_capacity'], 1)
        self.assertEqual(details['remaining_capacity'], 4)
        self.assertIn(sample.sample_code, details['sample_codes'])

    def test_get_car_details_with_return_dispatched(self):
        """RETURN in DISPATCHED status should occupy a slot."""
        sample = BloodSample.objects.create(
            patient_name="Patient 4",
            blood_type="AB+",
            status="WITH_DOCTOR",
            is_in_storage=False,
        )
        TransportRequest.objects.create(
            sample=sample,
            requested_by=self.doctor,
            room_number="Room-101",
            assigned_car=self.car,
            status='DISPATCHED',
            request_type='RETURN',
        )

        details = get_car_details(self.car.id)

        self.assertEqual(details['used_capacity'], 1)
        self.assertEqual(details['remaining_capacity'], 4)
        self.assertIn(sample.sample_code, details['sample_codes'])

    def test_get_car_details_mixed_delivery_and_return(self):
        """Mixed delivery and return should occupy slots correctly."""
        sample1 = BloodSample.objects.create(
            patient_name="Patient 5",
            blood_type="O+",
            status="OUT_FOR_DELIVERY",
        )
        sample2 = BloodSample.objects.create(
            patient_name="Patient 6",
            blood_type="A+",
            status="WITH_DOCTOR",
            is_in_storage=False,
        )

        TransportRequest.objects.create(
            sample=sample1,
            requested_by=self.doctor,
            room_number="Room-101",
            assigned_car=self.car,
            status='LOADED',
            request_type='DELIVERY',
        )
        TransportRequest.objects.create(
            sample=sample2,
            requested_by=self.doctor,
            room_number="Room-101",
            assigned_car=self.car,
            status='LOADED_FOR_RETURN',
            request_type='RETURN',
        )

        details = get_car_details(self.car.id)

        self.assertEqual(details['used_capacity'], 2)
        self.assertEqual(details['remaining_capacity'], 3)
        self.assertIn(sample1.sample_code, details['sample_codes'])
        self.assertIn(sample2.sample_code, details['sample_codes'])

    def test_get_car_details_exceeds_capacity(self):
        """Used capacity should never exceed total capacity."""
        # Add more samples than capacity
        for i in range(7):
            sample = BloodSample.objects.create(
                patient_name=f"Patient {i}",
                blood_type="O+",
                status="OUT_FOR_DELIVERY",
            )
            TransportRequest.objects.create(
                sample=sample,
                requested_by=self.doctor,
                room_number="Room-101",
                assigned_car=self.car,
                status='LOADED',
                request_type='DELIVERY',
            )

        details = get_car_details(self.car.id)

        self.assertEqual(details['used_capacity'], 7)
        self.assertEqual(details['remaining_capacity'], 0)  # Should be max(5-7, 0) = 0

    def test_get_car_details_return_pending_not_counted(self):
        """RETURN in PENDING or RETURN_REQUESTED should NOT occupy a slot."""
        sample = BloodSample.objects.create(
            patient_name="Patient 7",
            blood_type="O+",
            status="WITH_DOCTOR",
            is_in_storage=False,
        )
        TransportRequest.objects.create(
            sample=sample,
            requested_by=self.doctor,
            room_number="Room-101",
            assigned_car=self.car,
            status='RETURN_REQUESTED',
            request_type='RETURN',
        )

        details = get_car_details(self.car.id)

        self.assertEqual(details['used_capacity'], 0)
        self.assertEqual(details['remaining_capacity'], 5)
        self.assertEqual(details['sample_codes'], [])

    def test_get_car_details_delivery_pending_not_counted(self):
        """DELIVERY in PENDING should NOT occupy a slot."""
        sample = BloodSample.objects.create(
            patient_name="Patient 8",
            blood_type="O+",
            status="REQUESTED",
        )
        TransportRequest.objects.create(
            sample=sample,
            requested_by=self.doctor,
            room_number="Room-101",
            assigned_car=self.car,
            status='PENDING',
            request_type='DELIVERY',
        )

        details = get_car_details(self.car.id)

        self.assertEqual(details['used_capacity'], 0)
        self.assertEqual(details['remaining_capacity'], 5)
        self.assertEqual(details['sample_codes'], [])


class CarDetailsAPITests(TestCase):
    """Tests for car details API endpoint."""

    def setUp(self):
        self.client = APIClient()
        self.storage = User.objects.create_user(
            email="storage@test.com",
            password="testpass123",
            full_name="Storage",
            role="STORAGE_EMPLOYEE",
        )
        self.doctor = User.objects.create_user(
            email="doctor@test.com",
            password="testpass123",
            full_name="Dr. Test",
            role="DOCTOR",
        )
        self.car = Car.objects.create(
            car_number="CAR-API-01",
            status="LOADING",
            capacity=5,
        )

    def test_car_details_api_not_authenticated(self):
        """Unauthenticated request should return 401."""
        response = self.client.get(f"/api/cars/{self.car.id}/details/")
        self.assertEqual(response.status_code, 401)

    def test_car_details_api_forbidden_doctor(self):
        """Doctor should not have access (storage only)."""
        self.client.force_authenticate(user=self.doctor)
        response = self.client.get(f"/api/cars/{self.car.id}/details/")
        self.assertEqual(response.status_code, 403)

    def test_car_details_api_not_found(self):
        """Non-existent car should return 404."""
        self.client.force_authenticate(user=self.storage)
        response = self.client.get("/api/cars/999/details/")
        self.assertEqual(response.status_code, 404)

    def test_car_details_api_success(self):
        """Storage employee should get car details successfully."""
        sample = BloodSample.objects.create(
            patient_name="Patient",
            blood_type="O+",
            status="OUT_FOR_DELIVERY",
        )
        TransportRequest.objects.create(
            sample=sample,
            requested_by=self.doctor,
            room_number="Room-101",
            assigned_car=self.car,
            status='LOADED',
            request_type='DELIVERY',
        )

        self.client.force_authenticate(user=self.storage)
        response = self.client.get(f"/api/cars/{self.car.id}/details/")

        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertTrue(payload['success'])
        
        data = payload['data']
        self.assertEqual(data['car_id'], self.car.id)
        self.assertEqual(data['car_number'], 'CAR-API-01')
        self.assertEqual(data['capacity'], 5)
        self.assertEqual(data['used_capacity'], 1)
        self.assertEqual(data['remaining_capacity'], 4)
        self.assertIn(sample.sample_code, data['sample_codes'])
