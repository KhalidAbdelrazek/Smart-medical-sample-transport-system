"""
stats/tests.py

Tests for consolidated statistics API.
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


class AdminStatsEndpointTests(APITestCase):
    """Test consolidated admin statistics endpoint."""

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
            assigned_car=self.car,
            status='PENDING',
        )
        UserActivityLog.objects.create(
            user=self.doctor_user,
            action_type='REQUEST_CREATED',
            outcome='PENDING',
            transport_request=self.transport_request,
            sample_code=self.sample.sample_code,
        )
        UserActivityLog.objects.create(
            user=self.storage_user,
            action_type='REQUEST_LOADED',
            outcome='SUCCESS',
            transport_request=self.transport_request,
            sample_code=self.sample.sample_code,
        )
        UserActivityLog.objects.create(
            user=self.admin_user,
            action_type='REQUEST_CANCELLED',
            outcome='CANCELLED',
            transport_request=self.transport_request,
            sample_code=self.sample.sample_code,
        )

    def test_unified_endpoint_requires_admin(self):
        """Test that unified stats endpoint requires admin role."""
        self.client.force_authenticate(user=self.doctor_user)
        response = self.client.get('/api/admin/stats/')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/stats/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_unified_endpoint_returns_all_sections(self):
        """Test that endpoint returns all required sections."""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/stats/')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('data', response.data)
        data = response.data['data']

        self.assertIn('overview', data)
        self.assertIn('requests_timeseries', data)
        self.assertIn('user_activity', data)
        self.assertIn('user_activity_pagination', data)
        self.assertIn('top_users', data)
        self.assertIn('car_utilization', data)

    def test_overview_section_structure(self):
        """Test overview section has correct fields."""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/stats/')

        overview = response.data['data']['overview']
        self.assertIn('requests', overview)
        self.assertIn('dispatches', overview)
        self.assertIn('active_users_count', overview)
        self.assertIn('active_cars_count', overview)

        requests = overview['requests']
        self.assertIn('total', requests)
        self.assertIn('delivered', requests)
        self.assertIn('returned', requests)
        self.assertIn('cancelled', requests)
        self.assertIn('failed', requests)

    def test_user_activity_pagination(self):
        """Test user activity pagination metadata."""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/stats/')

        pagination = response.data['data']['user_activity_pagination']
        self.assertIn('page', pagination)
        self.assertIn('page_size', pagination)
        self.assertIn('total_count', pagination)
        self.assertIsInstance(pagination['page'], int)
        self.assertIsInstance(pagination['page_size'], int)
        self.assertIsInstance(pagination['total_count'], int)

    def test_pagination_params(self):
        """Test pagination query parameters work."""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/stats/?page=1&page_size=5')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        pagination = response.data['data']['user_activity_pagination']
        self.assertEqual(pagination['page'], 1)
        self.assertEqual(pagination['page_size'], 5)

    def test_top_params(self):
        """Test top query parameter limits top users."""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/stats/?top=5')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        top_users = response.data['data']['top_users']
        self.assertIn('ADMIN', top_users)
        self.assertIn('DOCTOR', top_users)
        self.assertIn('STORAGE_EMPLOYEE', top_users)
        self.assertLessEqual(len(top_users['ADMIN']), 5)
        self.assertLessEqual(len(top_users['DOCTOR']), 5)
        self.assertLessEqual(len(top_users['STORAGE_EMPLOYEE']), 5)

    def test_date_filtering(self):
        """Test date range filtering."""
        self.client.force_authenticate(user=self.admin_user)
        future_date = (date.today() + timedelta(days=30)).isoformat()
        response = self.client.get(f'/api/admin/stats/?start_date={future_date}&end_date={future_date}')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        overview = response.data['data']['overview']
        self.assertEqual(overview['requests']['total'], 0)

    def test_invalid_date_range(self):
        """Test that start_date > end_date returns validation error."""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/stats/?start_date=2026-04-20&end_date=2026-04-10')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_invalid_granularity(self):
        """Test invalid granularity returns validation error."""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/stats/?granularity=invalid')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_invalid_role(self):
        """Test invalid role returns validation error."""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/stats/?role=INVALID_ROLE')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_invalid_page(self):
        """Test invalid page number returns validation error."""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/stats/?page=0')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_invalid_page_size(self):
        """Test invalid page_size returns validation error."""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/stats/?page_size=0')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_top_out_of_range(self):
        """Test top parameter out of range returns validation error."""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/stats/?top=500')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_user_activity_fields(self):
        """Test user activity items have expected fields."""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/stats/')

        user_activity = response.data['data']['user_activity']
        self.assertGreater(len(user_activity), 0)
        item = user_activity[0]
        self.assertIn('user_id', item)
        self.assertIn('name', item)
        self.assertIn('role', item)
        self.assertIn('request_count', item)
        self.assertIn('success_count', item)
        self.assertIn('cancelled_count', item)
        self.assertIn('failed_count', item)

    def test_top_users_fields(self):
        """Test top users items have expected fields."""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/stats/')

        top_users = response.data['data']['top_users']
        self.assertIn('ADMIN', top_users)
        self.assertIn('DOCTOR', top_users)
        self.assertIn('STORAGE_EMPLOYEE', top_users)

        doctor_users = top_users['DOCTOR']
        self.assertGreater(len(doctor_users), 0)
        item = doctor_users[0]
        self.assertIn('user_id', item)
        self.assertIn('name', item)
        self.assertIn('role', item)
        self.assertIn('request_count', item)

    def test_car_utilization_fields(self):
        """Test car utilization items have expected fields."""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/stats/')

        car_util = response.data['data']['car_utilization']
        if len(car_util) > 0:
            item = car_util[0]
            self.assertIn('car_id', item)
            self.assertIn('car_number', item)
            self.assertIn('total_dispatches', item)
            self.assertIn('success_dispatches', item)
            self.assertIn('failed_dispatches', item)
            self.assertIn('cancelled_dispatches', item)
            self.assertIn('utilization_rate', item)

    def test_timeseries_fields(self):
        """Test timeseries items have expected fields."""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/stats/')

        timeseries = response.data['data']['requests_timeseries']
        if len(timeseries) > 0:
            item = timeseries[0]
            self.assertIn('date', item)
            self.assertIn('count', item)

    def test_role_filter(self):
        """Test role filter parameter works."""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/admin/stats/?role=DOCTOR')

        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_car_id_filter(self):
        """Test car_id filter parameter works."""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get(f'/api/admin/stats/?car_id={self.car.id}')

        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_granularity_params(self):
        """Test granularity parameter works."""
        self.client.force_authenticate(user=self.admin_user)

        for granularity in ['day', 'week', 'month']:
            response = self.client.get(f'/api/admin/stats/?granularity={granularity}')
            self.assertEqual(response.status_code, status.HTTP_200_OK)


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

        from transport.services import cancel_transport_request
        _, cancelled_request = cancel_transport_request(
            request_id=request_id,
            doctor=self.doctor_user,
        )

        self.assertEqual(cancelled_request.status, 'CANCELLED')
        self.assertIsNotNone(cancelled_request.cancelled_at)

        self.sample.refresh_from_db()
        self.assertEqual(self.sample.status, 'IN_STORAGE')

        activity_count = UserActivityLog.objects.filter(
            transport_request=cancelled_request
        ).count()
        self.assertGreater(activity_count, 0)

    def test_dispatch_creates_car_dispatch_record(self):
        """Test that dispatching a car creates a CarDispatch record."""
        from transport.services import add_sample_to_car
        add_sample_to_car(
            sample_code='TEST-001',
            car_id=self.car.id,
        )

        from transport.services import dispatch_car
        dispatched_requests, car_dispatch = dispatch_car(
            car_id=self.car.id,
        )

        self.assertIsNotNone(car_dispatch)
        self.assertEqual(car_dispatch.car, self.car)

        self.transport_request.refresh_from_db()
        self.assertEqual(self.transport_request.status, 'DISPATCHED')
        self.assertIsNotNone(self.transport_request.dispatched_at)

    def test_activity_logging(self):
        """Test that activities are logged correctly."""
        from transport.services import add_sample_to_car
        add_sample_to_car(
            sample_code='TEST-001',
            car_id=self.car.id,
        )

        activity_logs = UserActivityLog.objects.filter(
            transport_request=self.transport_request
        )

        self.assertGreater(activity_logs.count(), 0)

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

        # Create UserActivityLog entries (selectors now read from activity logs, not requests directly)
        for i in range(5):
            tr = TransportRequest.objects.filter(requested_by=self.doctor_user)[0]
            UserActivityLog.objects.create(
                user=self.doctor_user,
                action_type='REQUEST_CREATED',
                outcome='SUCCESS',
                transport_request=tr,
            )

        top_users = get_top_users()

        self.assertGreater(len(top_users), 0)

        if len(top_users) > 0:
            self.assertIn('request_count', top_users[0])
            self.assertIn('name', top_users[0])

    def test_date_filtering(self):
        """Test date range filtering."""
        from stats.selectors import get_request_stats

        future_date = date.today() + timedelta(days=30)
        stats = get_request_stats(
            start_date=future_date,
            end_date=future_date,
        )

        self.assertEqual(stats['total'], 0)
