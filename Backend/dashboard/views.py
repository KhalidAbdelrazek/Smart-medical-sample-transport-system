from django.db.models import Count
from django.db.models.functions import ExtractHour
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework import status
from common.utils.response import unified_response
from transport.models import TransportRequest
from cars.models import Car
from samples.models import BloodSample
from django.utils import timezone

class DashboardStatsView(APIView):
    """
    API View to aggregate statistics for different user roles.
    Role identification is performed via the authentication token (request.user).
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        
        
        # Get local time and date (Africa/Cairo)
        local_now = timezone.localtime(timezone.now())
        today = local_now.date()
        this_month = local_now.month
        this_year = local_now.year

        # Role-based logic
        if user.role == "DOCTOR":
            return self.get_doctor_stats(user, today, this_month, this_year)
        elif user.role == "STORAGE_EMPLOYEE":
            return self.get_storage_stats(today, this_month, this_year)
        elif user.role == "ADMIN":
            return self.get_admin_stats(today, this_month, this_year)
        else:
            return unified_response(
                success=False,
                message=f"User role '{user.role}' does not have a dashboard.",
                status=status.HTTP_403_FORBIDDEN
            )

    def get_doctor_stats(self, user, today, month, year):
        """
        Statistics for the Doctor's dashboard.
        Categorized by: successful, failed, completed (executed), and pending.
        Specific to the logged-in doctor.
        """
        # Monthly filtering implements the "reset" logic (results return to zero on 1st of month)
        monthly_requests = TransportRequest.objects.filter(
            requested_by=user,
            created_at__year=year,
            created_at__month=month
        )

        today_requests = monthly_requests.filter(created_at__date=today)

        stats = {
            "today": {
                "total_requests": today_requests.count(),
                "successful": today_requests.filter(status='SUCCESSFUL').count(),
                "failed": today_requests.filter(status='FAILED').count(),
                "completed_executed": today_requests.filter(status='EXECUTED').count(),
                "pending": today_requests.filter(status='PENDING').count(),
            },
            "monthly_summary": {
                "total_requests": monthly_requests.count(),
                "success_rate": self.calculate_rate(
                    monthly_requests.filter(status='SUCCESSFUL').count(),
                    monthly_requests.count()
                )
            }
        }
        return unified_response(
            success=True,
            message="Doctor dashboard statistics fetched successfully.",
            data=stats
        )

    def get_storage_stats(self, today, month, year):
        """
        Statistics for the Storage role.
        Tracks cars dispatched and samples added.
        """
        # Cars dispatched today: Count unique cars that have DISPATCHED requests today
        dispatches_today = TransportRequest.objects.filter(
            status='DISPATCHED',
            created_at__date=today
        ).values('assigned_car').distinct().count()

        samples_added_today = BloodSample.objects.filter(created_at__date=today).count()
        samples_added_month = BloodSample.objects.filter(
            created_at__year=year,
            created_at__month=month
        ).count()

        stats = {
            "today": {
                "cars_dispatched": dispatches_today,
                "samples_added": samples_added_today,
            },
            "this_month": {
                "total_samples_added": samples_added_month,
            },
            "supplementary": {
                "avg_samples_per_dispatch": self.calculate_avg_samples_per_dispatch(today)
            }
        }
        return unified_response(
            success=True,
            message="Storage dashboard statistics fetched successfully.",
            data=stats
        )

    def get_admin_stats(self, today, month, year):
        """
        Admin dashboard: Global statistics across all roles.
        """
        total_cars = Car.objects.count()
        
        # Total dispatches today across the whole system
        total_dispatches_today = TransportRequest.objects.filter(
            status='DISPATCHED',
            created_at__date=today
        ).values('assigned_car').distinct().count()

        # Total requests by all doctors combined
        total_requests_today = TransportRequest.objects.filter(created_at__date=today).count()
        total_requests_month = TransportRequest.objects.filter(
            created_at__year=year,
            created_at__month=month
        ).count()

        stats = {
            "global_overview": {
                "total_cars": total_cars,
                "total_samples_in_system": BloodSample.objects.count(),
            },
            "today_activity": {
                "total_car_dispatches": total_dispatches_today,
                "total_doctor_requests": total_requests_today,
            },
            "monthly_activity": {
                "total_doctor_requests": total_requests_month,
            },
            "supplementary": {
                "blood_type_distribution": self.get_blood_type_distribution(),
                "most_active_doctors": self.get_most_active_doctors(month, year),
                "peak_request_hours": self.get_peak_request_hours(month, year),
                "department_activity": self.get_department_activity(month, year),
                "shift_activity": self.get_shift_activity(month, year),
            }
        }
        return unified_response(
            success=True,
            message="Admin dashboard statistics fetched successfully.",
            data=stats
        )

    # --- Helper Methods for Supplementary Statistics ---

    def calculate_rate(self, count, total):
        if total == 0:
            return 0
        return round((count / total) * 100, 2)

    def calculate_avg_samples_per_dispatch(self, date):
        """Calculates average number of samples per car dispatch for a given date."""
        dispatches = TransportRequest.objects.filter(
            status='DISPATCHED',
            created_at__date=date
        ).values('assigned_car').annotate(sample_count=Count('id'))
        
        if not dispatches:
            return 0
        
        total_samples = sum(d['sample_count'] for d in dispatches)
        return round(total_samples / len(dispatches), 1)

    def get_blood_type_distribution(self):
        """Returns a breakdown of requests by blood type."""
        return list(BloodSample.objects.values('blood_type').annotate(count=Count('id')).order_by('-count'))

    def get_most_active_doctors(self, month, year):
        """Returns doctors with most requests this month."""
        return list(TransportRequest.objects.filter(
            created_at__year=year,
            created_at__month=month
        ).values('requested_by__full_name').annotate(count=Count('id')).order_by('-count')[:5])

    def get_peak_request_hours(self, month, year):
        """Returns request counts by hour of the day."""
        return list(
            TransportRequest.objects.filter(
                created_at__year=year, created_at__month=month
            )
            .annotate(hour=ExtractHour("created_at"))
            .values("hour")
            .annotate(count=Count("id"))
            .order_by("hour")
        )

    def get_department_activity(self, month, year):
        """Returns request counts by doctor department."""
        return list(TransportRequest.objects.filter(
            created_at__year=year,
            created_at__month=month
        ).values('requested_by__department').annotate(count=Count('id')).order_by('-count'))

    def get_shift_activity(self, month, year):
        """Returns request counts by doctor shift."""
        return list(TransportRequest.objects.filter(
            created_at__year=year,
            created_at__month=month
        ).values('requested_by__shift').annotate(count=Count('id')).order_by('-count'))
