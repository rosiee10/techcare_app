from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.db import connection
from django.utils import timezone
from datetime import timedelta

from apps.accounts.models import User
from apps.admin_portal.models import ContactMessage


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_dashboard_stats(request):
    """Get dashboard statistics"""
    
    # Get user counts
    with connection.cursor() as cursor:
        cursor.execute("SELECT COUNT(*) FROM pch.users WHERE is_active = true")
        total_users = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM pch.users WHERE is_active = true AND last_login >= NOW() - INTERVAL '24 hours'")
        active_today = cursor.fetchone()[0]
    
    # Get contact message counts
    new_messages = ContactMessage.objects.filter(status='new').count()
    total_messages = ContactMessage.objects.count()
    
    # Get patient count (from patients table if exists)
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT COUNT(*) FROM pch.patients WHERE is_active = true")
            total_patients = cursor.fetchone()[0]
    except:
        total_patients = 0
    
    # Recent activity (last 5 contact messages)
    recent_messages = ContactMessage.objects.order_by('-created_at')[:5]
    recent_activity = []
    for msg in recent_messages:
        recent_activity.append({
            'id': msg.id,
            'type': 'contact_message',
            'title': f"New message from {msg.full_name}",
            'description': msg.message[:50] + '...' if len(msg.message) > 50 else msg.message,
            'time': msg.created_at.strftime('%Y-%m-%d %H:%M'),
            'status': msg.status,
        })
    
    # System alerts
    alerts = []
    if new_messages > 0:
        alerts.append({
            'type': 'warning',
            'message': f'{new_messages} new contact message{"s" if new_messages > 1 else ""}',
            'time': 'Just now',
        })
    
    return Response({
        'stats': {
            'total_users': total_users,
            'active_today': active_today,
            'total_patients': total_patients,
            'total_messages': total_messages,
            'new_messages': new_messages,
        },
        'recent_activity': recent_activity,
        'alerts': alerts,
    })
