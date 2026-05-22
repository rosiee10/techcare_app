from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Notification
from .serializers import NotificationSerializer
from apps.medistock.models import (
    MedistockVLowStock,
    MedistockVPendingRequest,
    MedistockVExpiryAlert,
)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def notification_list(request):
    notifications = Notification.objects.filter(
        user=request.user,
        is_deleted=False,
    )[:50]
    serializer = NotificationSerializer(notifications, many=True)
    unread = Notification.objects.filter(
        user=request.user,
        is_read=False,
        is_deleted=False,
    ).count()
    return Response({
        'notifications': serializer.data,
        'unread_count': unread,
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def unread_count_view(request):
    count = Notification.objects.filter(
        user=request.user,
        is_read=False,
        is_deleted=False,
    ).count()
    return Response({'unread_count': count})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def generate_notifications(request):
    """Generate notifications from current medistock state (idempotent)."""
    created = 0

    # 1. Low Stock Alerts
    try:
        for item in MedistockVLowStock.objects.all():
            exists = Notification.objects.filter(
                user=request.user,
                notification_type='LOW_STOCK',
                reference_id=item.supply_id,
                reference_type='supply_item',
                is_read=False,
                is_deleted=False,
            ).exists()
            if not exists:
                Notification.objects.create(
                    user=request.user,
                    notification_type='LOW_STOCK',
                    title='Low Stock Alert',
                    message=(
                        f'{item.supply_name} is running low '
                        f'({int(item.current_stock or 0)} units remaining). '
                        f'Consider restocking soon.'
                    ),
                    reference_id=item.supply_id,
                    reference_type='supply_item',
                )
                created += 1
    except Exception:
        pass

    # 2. Pending Supply Requests
    try:
        pending_count = MedistockVPendingRequest.objects.count()
        if pending_count > 0:
            exists = Notification.objects.filter(
                user=request.user,
                notification_type='PENDING_REQUEST',
                is_read=False,
                is_deleted=False,
            ).exists()
            if not exists:
                s = 's' if pending_count > 1 else ''
                Notification.objects.create(
                    user=request.user,
                    notification_type='PENDING_REQUEST',
                    title='Pending Supply Requests',
                    message=(
                        f'You have {pending_count} pending supply request{s} '
                        f'awaiting review and approval.'
                    ),
                )
                created += 1
    except Exception:
        pass

    # 3. Expiry Alerts
    try:
        for item in MedistockVExpiryAlert.objects.all():
            exists = Notification.objects.filter(
                user=request.user,
                notification_type='EXPIRY_ALERT',
                reference_id=item.batch_id,
                reference_type='batch',
                is_read=False,
                is_deleted=False,
            ).exists()
            if not exists:
                days = item.days_remaining or 0
                s = 's' if days != 1 else ''
                Notification.objects.create(
                    user=request.user,
                    notification_type='EXPIRY_ALERT',
                    title='Expiry Alert',
                    message=(
                        f'{item.supply_name} (Batch: {item.batch_no}) '
                        f'expires in {days} day{s}.'
                    ),
                    reference_id=item.batch_id,
                    reference_type='batch',
                )
                created += 1
    except Exception:
        pass

    unread = Notification.objects.filter(
        user=request.user,
        is_read=False,
        is_deleted=False,
    ).count()
    return Response({'generated': created, 'unread_count': unread})


@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def mark_read(request, pk):
    try:
        n = Notification.objects.get(pk=pk, user=request.user, is_deleted=False)
        n.is_read = True
        n.save(update_fields=['is_read', 'updated_at'])
        return Response({'success': True})
    except Notification.DoesNotExist:
        return Response({'error': 'Not found'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def mark_all_read(request):
    Notification.objects.filter(
        user=request.user,
        is_read=False,
        is_deleted=False,
    ).update(is_read=True)
    return Response({'success': True})


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_notification(request, pk):
    try:
        n = Notification.objects.get(pk=pk, user=request.user)
        n.is_deleted = True
        n.save(update_fields=['is_deleted', 'updated_at'])
        return Response({'success': True})
    except Notification.DoesNotExist:
        return Response({'error': 'Not found'}, status=status.HTTP_404_NOT_FOUND)
