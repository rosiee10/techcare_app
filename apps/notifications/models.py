from django.db import models
from django.conf import settings


class Notification(models.Model):
    NOTIFICATION_TYPES = [
        ('LOW_STOCK', 'Low Stock Alert'),
        ('PENDING_REQUEST', 'Pending Supply Request'),
        ('EXPIRY_ALERT', 'Expiry Alert'),
        ('INVENTORY_UPDATE', 'Inventory Update'),
        ('GENERAL', 'General'),
    ]

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='notifications',
    )
    notification_type = models.CharField(
        max_length=50, choices=NOTIFICATION_TYPES, default='GENERAL'
    )
    title = models.CharField(max_length=255)
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    is_deleted = models.BooleanField(default=False)
    reference_id = models.IntegerField(null=True, blank=True)
    reference_type = models.CharField(max_length=100, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'notifications'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.notification_type}: {self.title}"
