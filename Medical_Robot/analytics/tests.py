"""
analytics/tests.py

Comprehensive tests for request analytics and storage employee logs analytics endpoints.
"""
from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status
from datetime import date, timedelta
import uuid

from transport.models import TransportRequest
from samples.models import BloodSample
from cars.models import Car
from analytics.models import StorageEmployeeLog

User = get_user_model()


class RequestAnalyticsTests(TestCase):
    """Tests for /api/analytics/requests/ endpoint."""

    def setUp(self):
        """Set up test data."""
        self.client = APIClient()
        
        # Create users
        self.doctor = User.objects.create_user(
            email='doctor@test.com',
            password='testpass123',
            full_name='Dr. John Doe',
            role='DOCTOR'
        )
        self.admin = User.objects.create_user(
            email='admin@test.com',
            password='testpass123',
            full_name='Admin User',
            role='ADMIN'
        )
        self.other_doctor = User.objects.create_user(
            email='doctor2@test.com',
            password='testpass123',
            full_name='Dr. Jane Smith',
            role='DOCTOR'
        )
        
        # Create car
        self.car = Car.objects.create(car_number='CAR-01', status='IDLE')
        
        # Create blood sample
        self.sample = BloodSample.objects.create(
            patient_name='John Patient',
            sample_code='PT-0001',
            blood_type='A+',
        )
        
        # Create transport requests
        for i in range(5):
            TransportRequest.objects.create(
                sample=self.sample,
                requested_by=self.doctor,
                room_number=f'Room {i}',
                assigned_car=self.car,
                status='DELIVERED'
            )
        
        for i in range(3):
            TransportRequest.objects.create(
                sample=self.sample,
                requested_by=self.doctor,
                room_number=f'Room {i}',
                assigned_car=self.car,
                status='FAILED'
            )
        
        for i in range(2):
            TransportRequest.objects.create(
                sample=self.sample,
                requested_by=self.other_doctor,
                room_number=f'Room {i}',
                assigned_car=self.car,
                status='DELIVERED'
            )

    def test_doctor_can_access_own_analytics(self):
        """Test that doctors can access their own request analytics."""
        self.client.force_authenticate(user=self.doctor)
        response = self.client.get('/api/analytics/requests/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertTrue(data['success'])
        self.assertEqual(data['data']['summary']['total_requests'], 8)
        self.assertEqual(data['data']['summary']['succeeded'], 5)
        self.assertEqual(data['data']['summary']['failed'], 3)

    def test_doctor_cannot_filter_by_role(self):
        """Test that non-admin users cannot filter by role."""
        self.client.force_authenticate(user=self.doctor)
        response = self.client.get('/api/analytics/requests/?role=DOCTOR')
        
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        data = response.json()
        self.assertFalse(data['success'])

    def test_doctor_cannot_filter_by_user_id(self):
        """Test that non-admin users cannot filter by user_id."""
        self.client.force_authenticate(user=self.doctor)
        response = self.client.get(f'/api/analytics/requests/?user_id={self.other_doctor.id}')
        
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_admin_can_filter_by_role(self):
        """Test that admins can filter by role."""
        self.client.force_authenticate(user=self.admin)
        response = self.client.get('/api/analytics/requests/?role=DOCTOR')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertTrue(data['success'])

    def test_admin_can_filter_by_user_id(self):
        """Test that admins can filter by specific user."""
        self.client.force_authenticate(user=self.admin)
        response = self.client.get(f'/api/analytics/requests/?user_id={self.doctor.id}')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertTrue(data['success'])
        self.assertEqual(data['data']['summary']['total_requests'], 8)

    def test_admin_can_search_by_name(self):
        """Test that admins can search by user name."""
        self.client.force_authenticate(user=self.admin)
        response = self.client.get('/api/analytics/requests/?search=John')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertTrue(data['success'])
        self.assertEqual(data['data']['summary']['total_requests'], 8)

    def test_admin_can_search_by_email(self):
        """Test that admins can search by user email."""
        self.client.force_authenticate(user=self.admin)
        response = self.client.get('/api/analytics/requests/?search=doctor@test.com')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertTrue(data['success'])
        self.assertEqual(data['data']['summary']['total_requests'], 8)

    def test_invalid_date_range(self):
        """Test that invalid date ranges are rejected."""
        self.client.force_authenticate(user=self.doctor)
        today = date.today()
        yesterday = today - timedelta(days=1)
        response = self.client.get(f'/api/analytics/requests/?start_date={today}&end_date={yesterday}')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_granularity_day(self):
        """Test granularity='day' returns timeseries by day."""
        self.client.force_authenticate(user=self.doctor)
        response = self.client.get('/api/analytics/requests/?granularity=day')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertTrue(data['success'])
        self.assertIn('timeseries', data['data'])

    def test_granularity_month(self):
        """Test granularity='month' returns timeseries by month."""
        self.client.force_authenticate(user=self.doctor)
        response = self.client.get('/api/analytics/requests/?granularity=month')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertTrue(data['success'])

    def test_unauthenticated_user_denied(self):
        """Test that unauthenticated users are denied."""
        response = self.client.get('/api/analytics/requests/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_response_structure(self):
        """Test response has correct structure with summary and timeseries."""
        self.client.force_authenticate(user=self.doctor)
        response = self.client.get('/api/analytics/requests/')
        
        data = response.json()['data']
        self.assertIn('summary', data)
        self.assertIn('timeseries', data)
        self.assertIn('total_requests', data['summary'])
        self.assertIn('succeeded', data['summary'])
        self.assertIn('failed', data['summary'])
        self.assertIn('cancelled', data['summary'])
        self.assertIn('returned', data['summary'])


class StorageEmployeeLogsAnalyticsTests(TestCase):
    """Tests for /api/analytics/storage-employees/logs/ endpoint."""

    def setUp(self):
        """Set up test data."""
        self.client = APIClient()
        
        # Create users
        self.storage_emp1 = User.objects.create_user(
            email='storage1@test.com',
            password='testpass123',
            full_name='John Storage',
            role='STORAGE_EMPLOYEE'
        )
        self.storage_emp2 = User.objects.create_user(
            email='storage2@test.com',
            password='testpass123',
            full_name='Jane Storage',
            role='STORAGE_EMPLOYEE'
        )
        self.doctor = User.objects.create_user(
            email='doctor@test.com',
            password='testpass123',
            full_name='Dr. Test',
            role='DOCTOR'
        )
        self.admin = User.objects.create_user(
            email='admin@test.com',
            password='testpass123',
            full_name='Admin User',
            role='ADMIN'
        )
        
        # Create car
        self.car = Car.objects.create(car_number='CAR-02', status='IDLE')
        
        # Create blood sample
        self.sample = BloodSample.objects.create(
            patient_name='John Patient',
            sample_code='PT-0002',
            blood_type='B-',
        )
        
        # Create transport request
        self.transport_request = TransportRequest.objects.create(
            sample=self.sample,
            requested_by=self.doctor,
            room_number='Room 101',
            assigned_car=self.car,
            status='PENDING'
        )
        
        # Create storage employee logs for emp1
        for i in range(5):
            StorageEmployeeLog.objects.create(
                employee=self.storage_emp1,
                action='CAR_DISPATCH',
                description=f'Dispatch car {i}',
                car=self.car
            )
        
        for i in range(3):
            StorageEmployeeLog.objects.create(
                employee=self.storage_emp1,
                action='SAMPLE_REMOVED_FROM_CAR',
                description=f'Removed sample {i}',
                transport_request=self.transport_request
            )
        
        # Create logs for emp2
        for i in range(2):
            StorageEmployeeLog.objects.create(
                employee=self.storage_emp2,
                action='SAMPLE_ADDED_TO_CAR',
                description=f'Added sample {i}',
                transport_request=self.transport_request
            )

    def test_storage_employee_can_access_own_logs(self):
        """Test that storage employees can access their own logs."""
        self.client.force_authenticate(user=self.storage_emp1)
        response = self.client.get('/api/analytics/storage-employees/logs/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertTrue(data['success'])
        self.assertEqual(data['data']['summary']['total_actions'], 8)
        self.assertEqual(data['data']['summary']['car_dispatch'], 5)
        self.assertEqual(data['data']['summary']['sample_removed_from_car'], 3)

    def test_storage_employee_cannot_see_other_logs(self):
        """Test that storage employees only see their own logs."""
        self.client.force_authenticate(user=self.storage_emp1)
        response = self.client.get('/api/analytics/storage-employees/logs/')
        
        data = response.json()
        # emp1 should see 8 logs, not emp2's 2 logs
        self.assertEqual(data['data']['summary']['total_actions'], 8)

    def test_doctor_cannot_access_logs(self):
        """Test that doctors cannot access storage employee logs."""
        self.client.force_authenticate(user=self.doctor)
        response = self.client.get('/api/analytics/storage-employees/logs/')
        
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_admin_can_see_all_logs(self):
        """Test that admins can see all storage employee logs."""
        self.client.force_authenticate(user=self.admin)
        response = self.client.get('/api/analytics/storage-employees/logs/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertTrue(data['success'])
        # Should see all 10 logs (5+3 from emp1, 2 from emp2)
        self.assertEqual(data['data']['summary']['total_actions'], 10)

    def test_admin_can_filter_by_employee(self):
        """Test that admins can filter by specific employee."""
        self.client.force_authenticate(user=self.admin)
        response = self.client.get(f'/api/analytics/storage-employees/logs/?employee_id={self.storage_emp1.id}')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertEqual(data['data']['summary']['total_actions'], 8)

    def test_admin_can_filter_by_action(self):
        """Test that admins can filter by action type."""
        self.client.force_authenticate(user=self.admin)
        response = self.client.get('/api/analytics/storage-employees/logs/?action=CAR_DISPATCH')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertEqual(data['data']['summary']['car_dispatch'], 5)

    def test_admin_can_search_by_name(self):
        """Test that admins can search by employee name."""
        self.client.force_authenticate(user=self.admin)
        response = self.client.get('/api/analytics/storage-employees/logs/?search=John')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertTrue(data['success'])
        self.assertEqual(data['data']['summary']['total_actions'], 8)

    def test_admin_can_search_by_email(self):
        """Test that admins can search by employee email."""
        self.client.force_authenticate(user=self.admin)
        response = self.client.get('/api/analytics/storage-employees/logs/?search=storage1@test.com')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertTrue(data['success'])
        self.assertEqual(data['data']['summary']['total_actions'], 8)

    def test_storage_employee_cannot_use_search_filter(self):
        """Test that storage employees cannot use search filter."""
        self.client.force_authenticate(user=self.storage_emp1)
        response = self.client.get('/api/analytics/storage-employees/logs/?search=storage')
        
        # Should be successful but search is ignored, only their own logs shown
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertEqual(data['data']['summary']['total_actions'], 8)

    def test_granularity_day(self):
        """Test granularity='day' works correctly."""
        self.client.force_authenticate(user=self.storage_emp1)
        response = self.client.get('/api/analytics/storage-employees/logs/?granularity=day')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertIn('timeseries', data['data'])

    def test_granularity_month(self):
        """Test granularity='month' works correctly."""
        self.client.force_authenticate(user=self.storage_emp1)
        response = self.client.get('/api/analytics/storage-employees/logs/?granularity=month')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_invalid_date_range(self):
        """Test that invalid date ranges are rejected."""
        self.client.force_authenticate(user=self.storage_emp1)
        today = date.today()
        yesterday = today - timedelta(days=1)
        response = self.client.get(f'/api/analytics/storage-employees/logs/?start_date={today}&end_date={yesterday}')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_unauthenticated_user_denied(self):
        """Test that unauthenticated users are denied."""
        response = self.client.get('/api/analytics/storage-employees/logs/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_response_structure(self):
        """Test response has correct structure with all action fields."""
        self.client.force_authenticate(user=self.storage_emp1)
        response = self.client.get('/api/analytics/storage-employees/logs/')
        
        data = response.json()['data']
        self.assertIn('summary', data)
        self.assertIn('timeseries', data)
        
        # Check all action fields exist in summary
        summary = data['summary']
        self.assertIn('total_actions', summary)
        self.assertIn('car_dispatch', summary)
        self.assertIn('sample_removed_from_car', summary)
        self.assertIn('sample_added_to_car', summary)
        self.assertIn('car_status_update', summary)
        self.assertIn('transport_request_update', summary)
        self.assertIn('other', summary)

    def test_timeseries_has_all_action_counts(self):
        """Test that timeseries includes counts for all action types."""
        self.client.force_authenticate(user=self.storage_emp1)
        response = self.client.get('/api/analytics/storage-employees/logs/')
        
        timeseries = response.json()['data']['timeseries']
        if timeseries:
            point = timeseries[0]
            self.assertIn('period', point)
            self.assertIn('total', point)
            self.assertIn('car_dispatch', point)
            self.assertIn('sample_removed_from_car', point)
            self.assertIn('sample_added_to_car', point)
            self.assertIn('car_status_update', point)
            self.assertIn('transport_request_update', point)
            self.assertIn('other', point)
