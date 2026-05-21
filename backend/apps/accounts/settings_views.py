from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from .user_settings import UserSettings


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_settings(request):
    """Get current user's settings"""
    settings_obj, created = UserSettings.objects.get_or_create(
        user=request.user,
        defaults={
            'notifications_enabled': True,
            'email_notifications': True,
            'push_notifications': True,
            'dark_mode': False,
            'language': 'en'
        }
    )
    
    return Response({
        'notifications_enabled': settings_obj.notifications_enabled,
        'email_notifications': settings_obj.email_notifications,
        'push_notifications': settings_obj.push_notifications,
        'dark_mode': settings_obj.dark_mode,
        'language': settings_obj.language,
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def update_user_settings(request):
    """Update current user's settings"""
    settings_obj, created = UserSettings.objects.get_or_create(
        user=request.user,
        defaults={
            'notifications_enabled': True,
            'email_notifications': True,
            'push_notifications': True,
            'dark_mode': False,
            'language': 'en'
        }
    )
    
    # Update fields from request
    if 'notifications_enabled' in request.data:
        settings_obj.notifications_enabled = request.data['notifications_enabled']
    if 'email_notifications' in request.data:
        settings_obj.email_notifications = request.data['email_notifications']
    if 'push_notifications' in request.data:
        settings_obj.push_notifications = request.data['push_notifications']
    if 'dark_mode' in request.data:
        settings_obj.dark_mode = request.data['dark_mode']
    if 'language' in request.data:
        settings_obj.language = request.data['language']
    
    settings_obj.save()
    
    return Response({
        'message': 'Settings updated successfully',
        'settings': {
            'notifications_enabled': settings_obj.notifications_enabled,
            'email_notifications': settings_obj.email_notifications,
            'push_notifications': settings_obj.push_notifications,
            'dark_mode': settings_obj.dark_mode,
            'language': settings_obj.language,
        }
    })
