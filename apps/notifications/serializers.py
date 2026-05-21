from rest_framework import serializers
from .models import Notification


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = [
            'id', 'notification_type', 'title', 'message',
            'is_read', 'reference_id', 'reference_type', 'created_at',
        ]
        read_only_fields = ['id', 'created_at']
