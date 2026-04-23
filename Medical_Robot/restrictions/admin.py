"""
restrictions/admin.py
"""
from django.contrib import admin
from .models import SystemRestriction, RestrictedUser


@admin.register(SystemRestriction)
class SystemRestrictionAdmin(admin.ModelAdmin):
    list_display = ('restriction_type', 'mode', 'updated_at', 'updated_by')
    list_filter = ('mode', 'restriction_type')
    readonly_fields = ('updated_at',)

    def has_add_permission(self, request):
        # We only want the seeded rows to exist.
        return False

    def has_delete_permission(self, request, obj=None):
        # System restrictions should not be deleted.
        return False


@admin.register(RestrictedUser)
class RestrictedUserAdmin(admin.ModelAdmin):
    list_display = ('user', 'restriction', 'restricted_at', 'restricted_by')
    list_filter = ('restriction__restriction_type',)
    search_fields = ('user__full_name', 'user__email', 'user__employee_id')
    raw_id_fields = ('user',)
