from django.contrib import admin
from .models import ContactMessage


@admin.register(ContactMessage)
class ContactMessageAdmin(admin.ModelAdmin):
    list_display = ['full_name', 'email', 'phone', 'status', 'created_at']
    list_filter = ['status', 'created_at']
    search_fields = ['full_name', 'email', 'message']
    readonly_fields = ['ip_address', 'created_at', 'updated_at']
    list_editable = ['status']
    date_hierarchy = 'created_at'
