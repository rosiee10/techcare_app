from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User


@admin.register(User)
class CustomUserAdmin(UserAdmin):
    list_display = ['username', 'employee_id', 'role', 'department', 'is_active_staff', 'is_superuser']
    list_filter = ['role', 'department', 'is_active_staff', 'is_superuser']
    search_fields = ['username', 'employee_id', 'first_name', 'last_name']
    
    fieldsets = UserAdmin.fieldsets + (
        ('Hospital Information', {
            'fields': ('employee_id', 'role', 'department', 'phone', 'address', 'is_active_staff', 'date_joined_hospital'),
        }),
    )
