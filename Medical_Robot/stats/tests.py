"""
stats/tests.py

Tests for statistics and analytics module.
"""
from datetime import date, timedelta
from django.utils import timezone
from rest_framework.test import APITestCase
from rest_framework import status

from accounts.models import User
from samples.models import BloodSample
from cars.models import Car
from transport.models import TransportRequest
from stats.models import CarDispatch, UserActivityLog


class StatsEndpointTests(APITestCase):
    """Test admin statistics endpoints."""
    
    def setUp(self):
        """Set up test data."""
        # Create test users
        self.admin_user = User.objects.create_user(
            email='admin@test.com',
            full_name='Test Admin',
            password='testpass123',
            role='ADMIN',
        )
        
        self.doctor_user = User.objects.create_user(
            email='doctor@test.com',
            full_name='Test Doctor',
            password='testpass123',
            role='DOCTOR',
        )
        
        self.storage_user = User.objects.create_user(
            email='storage@test.com',
            full_name='Test Storage',
            password='testpass123',
            role='STORAGE_EMPLOYEE',
        )
        
        # Create test car
        self.car = Car.objects.create(
            car_number='CAR-001',
            status='IDLE',
        )
        
        # Create test sample
        self.sample = BloodSample.objects.create(
            sample_code='TEST-001',
            status='REQUESTED',
            is_in_storage=True,
        )
        
        # Create transport request
        self.transport_request = TransportRequest.objects.create(
            sample=self.sample,
            requested_by=self.doctor_user,
            room_number='101',
            assigned_car=self.car,
            status='PENDING',
        )
    
    def test_overview_requires_admin(self):
        """Test that overview endpoint requires admin role."""
        # Non-admin should get 403
        self.client.force_authenticate(user=self.doctor_user)
        response = self.client.get('/api/admin/stats/overview/')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        
        # Admin should get 200
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/stats/overview/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
    
    def test_overview_returns_stats(self):
        """Test that overview endpoint returns statistics."""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/stats/overview/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('data', response.data)
        data = response.data['data']
        self.assertIn('requests', data)
        self.assertIn('dispatches', data)
        self.assertIn('active_users_count', data)
        self.assertIn('active_cars_count', data)
    
    def test_top_users_endpoint(self):
        """Test top users endpoint."""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/stats/users/top/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('data', response.data)
        # Should return list of users
        self.assertIsInstance(response.data['data'], list)
    
    def test_car_utilization_endpoint(self):
        """Test car utilization endpoint."""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/stats/cars/utilization/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('data', response.data)


class TransportLifecycleTests(APITestCase):
    """Test transport lifecycle with statistics tracking."""
    
    def setUp(self):
        """Set up test data."""
        self.doctor_user = User.objects.create_user(
            email='doctor@test.com',
            full_name='Test Doctor',
            password='testpass123',
            role='DOCTOR',
        )
        
        self.storage_user = User.objects.create_user(
            email='storage@test.com',
            full_name='Test Storage',
            password='testpass123',
            role='STORAGE_EMPLOYEE',
        )
        
        self.car = Car.objects.create(
            car_number='CAR-001',
            status='IDLE',
        )
        
        self.sample = BloodSample.objects.create(
            sample_code='TEST-001',
            status='REQUESTED',
            is_in_storage=True,
        )
        
        self.transport_request = TransportRequest.objects.create(
            sample=self.sample,
            requested_by=self.doctor_user,
            room_number='101',
            status='PENDING',
        )
    
    def test_cancel_preserves_history(self):
        """Test that cancelling a request preserves history instead of deleting."""
        request_id = self.transport_request.id
        
        # Cancel the request
        from transport.services import cancel_transport_request
        cancelled_request = cancel_transport_request(
            request_id=request_id,
            doctor=self.doctor_user,
            note='Test cancellation',
        )
        
        # Request should still exist but with CANCELLED status
        self.assertEqual(cancelled_request.status, 'CANCELLED')
        self.assertEqual(cancelled_request.status_note, 'Test cancellation')
        self.assertIsNotNone(cancelled_request.cancelled_at)
        
        # Sample should be back in storage
        self.sample.refresh_from_db()
        self.assertEqual(self.sample.status, 'IN_STORAGE')
        
        # Activity log should be created
        activity_count = UserActivityLog.objects.filter(
            transport_request=cancelled_request
        ).count()
        self.assertGreater(activity_count, 0)
    
    def test_dispatch_creates_car_dispatch_record(self):
        """Test that dispatching a car creates a CarDispatch record."""
        # First, add sample to car
        from transport.services import add_sample_to_car
        add_sample_to_car(
            sample_code='TEST-001',
            car_id=self.car.id,
        )
        
        # Now dispatch
        from transport.services import dispatch_car
        dispatched_requests, car_dispatch = dispatch_car(
            car_id=self.car.id,
            dispatched_by=self.storage_user,
        )
        
        # Should create a CarDispatch record
        self.assertIsNotNone(car_dispatch)
        self.assertEqual(car_dispatch.car, self.car)
        self.assertEqual(car_dispatch.dispatched_by, self.storage_user)
        self.assertEqual(car_dispatch.request_count, 1)
        
        # Transport request should be dispatched
        self.transport_request.refresh_from_db()
        self.assertEqual(self.transport_request.status, 'DISPATCHED')
        self.assertIsNotNone(self.transport_request.dispatched_at)
    
    def test_activity_logging(self):
        """Test that activities are logged correctly."""
        # Add sample to car
        from transport.services import add_sample_to_car
        add_sample_to_car(
            sample_code='TEST-001',
            car_id=self.car.id,
        )
        
        # Check activity log
        activity_logs = UserActivityLog.objects.filter(
            transport_request=self.transport_request
        )
        
        self.assertGreater(activity_logs.count(), 0)
        
        # Should have REQUEST_LOADED action
        loaded_action = activity_logs.filter(action_type='REQUEST_LOADED').first()
        self.assertIsNotNone(loaded_action)


class StatisticsSelectorsTests(APITestCase):
    """Test statistics selector functions."""
    
    def setUp(self):
        """Set up test data."""
        self.admin_user = User.objects.create_user(
            email='admin@test.com',
            full_name='Test Admin',
            password='testpass123',
            role='ADMIN',
        )
        
        self.doctor_user = User.objects.create_user(
            email='doctor@test.com',
            full_name='Test Doctor',
            password='testpass123',
            role='DOCTOR',
        )
        
        self.car = Car.objects.create(
            car_number='CAR-001',
            status='IDLE',
        )
        
        # Create multiple transport requests with different statuses
        for i in range(5):
            sample = BloodSample.objects.create(
                sample_code=f'TEST-{i:03d}',
                status='REQUESTED',
                is_in_storage=True,
            )
            
            TransportRequest.objects.create(
                sample=sample,
                requested_by=self.doctor_user,
                room_number=f'{100+i}',
                assigned_car=self.car,
                status='PENDING' if i < 2 else 'DISPATCHED',
            )
    
    def test_get_request_stats(self):
        """Test request statistics aggregation."""
        from stats.selectors import get_request_stats
        
        stats = get_request_stats()
        
        self.assertIn('total', stats)
        self.assertIn('delivered', stats)
        self.assertIn('returned', stats)
        self.assertIn('cancelled', stats)
        self.assertIn('failed', stats)
        self.assertEqual(stats['total'], 5)
    
    def test_get_top_users(self):
        """Test top users aggregation."""
        from stats.selectors import get_top_users
        
        top_users = get_top_users()
        
        # Should return at least one user
        self.assertGreater(len(top_users), 0)
        
        # Should have request_count
        if len(top_users) > 0:
            self.assertIn('request_count', top_users[0])
    
    def test_date_filtering(self):
        """Test date range filtering."""
        from stats.selectors import get_request_stats
        
        # Filter with future dates - should return 0
        future_date = date.today() + timedelta(days=30)
        stats = get_request_stats(
            start_date=future_date,
            end_date=future_date,
        )
        
        self.assertEqual(stats['total'], 0)
