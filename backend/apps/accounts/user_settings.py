from django.db import models
from django.conf import settings


class UserSettings(models.Model):
    """User preferences and settings"""
    
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='settings'
    )
    
    # Notifications
    notifications_enabled = models.BooleanField(default=True)
    email_notifications = models.BooleanField(default=True)
    push_notifications = models.BooleanField(default=True)
    
    # Appearance
    dark_mode = models.BooleanField(default=False)
    
    # Language
    LANGUAGE_CHOICES = [
        ('en', 'English'),
        ('fil', 'Filipino'),
        ('ceb', 'Bisaya'),
    ]
    language = models.CharField(
        max_length=3,
        choices=LANGUAGE_CHOICES,
        default='en'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'pch.user_settings'
        verbose_name = 'User Settings'
        verbose_name_plural = 'Users Settings'
    
    def __str__(self):
        return f"Settings for {self.user.username}"
