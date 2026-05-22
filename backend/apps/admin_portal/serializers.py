from rest_framework import serializers
from .models import ContactMessage


class ContactMessageSerializer(serializers.ModelSerializer):
    """Serializer for contact form submissions"""
    
    class Meta:
        model = ContactMessage
        fields = ['id', 'full_name', 'email', 'phone', 'message', 'status', 'created_at']
        read_only_fields = ['id', 'status', 'created_at']


class ContactMessageAdminSerializer(serializers.ModelSerializer):
    """Serializer for admin panel - includes all fields including reply info"""
    
    class Meta:
        model = ContactMessage
        fields = ['id', 'full_name', 'email', 'phone', 'message', 'status', 
                  'ip_address', 'created_at', 'updated_at',
                  'reply_subject', 'reply_body', 'replied_at', 'replied_by']
        read_only_fields = ['id', 'ip_address', 'created_at', 'updated_at', 'replied_at']


class ContactReplySerializer(serializers.Serializer):
    """Serializer for sending email reply"""
    subject = serializers.CharField(max_length=200, required=True)
    message = serializers.CharField(required=True)
