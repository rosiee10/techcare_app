from rest_framework import generics, status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db.models import Count, Q
from django.utils import timezone
from django.core.mail import send_mail
from .models import ContactMessage
from .serializers import ContactMessageSerializer, ContactMessageAdminSerializer, ContactReplySerializer


class ContactMessageCreateView(generics.CreateAPIView):
    """
    Public endpoint for submitting contact form messages.
    No authentication required.
    """
    queryset = ContactMessage.objects.all()
    serializer_class = ContactMessageSerializer
    permission_classes = [AllowAny]
    
    def perform_create(self, serializer):
        # Capture IP address if available
        ip_address = self.request.META.get('REMOTE_ADDR')
        if ip_address == '127.0.0.1':
            ip_address = self.request.META.get('HTTP_X_FORWARDED_FOR', ip_address)
        serializer.save(ip_address=ip_address)


class ContactMessageListView(generics.ListAPIView):
    """
    Admin endpoint for listing all contact messages.
    Supports filtering by status and search by name/email.
    """
    serializer_class = ContactMessageAdminSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = ContactMessage.objects.all()
        
        # Filter by status
        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        # Search by name or email
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(
                Q(full_name__icontains=search) | 
                Q(email__icontains=search) |
                Q(message__icontains=search)
            )
        
        return queryset


class ContactMessageDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    Admin endpoint for viewing, updating, or deleting a specific message.
    """
    queryset = ContactMessage.objects.all()
    serializer_class = ContactMessageAdminSerializer
    permission_classes = [IsAuthenticated]
    
    def perform_update(self, serializer):
        # Auto-update status to 'read' when viewing
        if self.request.data.get('mark_as_read'):
            serializer.save(status='read')
        else:
            serializer.save()


class ContactMessageStatsView(APIView):
    """
    Admin endpoint for getting message statistics.
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        stats = {
            'total': ContactMessage.objects.count(),
            'new': ContactMessage.objects.filter(status='new').count(),
            'read': ContactMessage.objects.filter(status='read').count(),
            'replied': ContactMessage.objects.filter(status='replied').count(),
            'archived': ContactMessage.objects.filter(status='archived').count(),
        }
        return Response(stats)


class ContactMessageBulkUpdateView(APIView):
    """
    Admin endpoint for bulk updating message status.
    """
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        message_ids = request.data.get('ids', [])
        new_status = request.data.get('status')
        
        if not message_ids or not new_status:
            return Response(
                {'error': 'ids and status are required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        updated = ContactMessage.objects.filter(
            id__in=message_ids
        ).update(status=new_status)
        
        return Response({'updated': updated})


class ContactMessageReplyView(APIView):
    """
    Admin endpoint for sending email reply to a contact message.
    """
    permission_classes = [IsAuthenticated]
    
    def post(self, request, pk):
        try:
            message = ContactMessage.objects.get(pk=pk)
        except ContactMessage.DoesNotExist:
            return Response(
                {'error': 'Message not found'}, 
                status=status.HTTP_404_NOT_FOUND
            )
        
        serializer = ContactReplySerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        subject = serializer.validated_data['subject']
        email_message = serializer.validated_data['message']
        
        # Send email
        try:
            send_mail(
                subject=subject,
                message=email_message,
                from_email='noreply@plaridelhospital.gov.ph',  # Update with your email
                recipient_list=[message.email],
                fail_silently=False,
            )
            
            # Update message record
            message.status = 'replied'
            message.reply_subject = subject
            message.reply_body = email_message
            message.replied_at = timezone.now()
            message.replied_by = request.user.username if request.user else None
            message.save()
            
            return Response({
                'success': True,
                'message': 'Reply sent successfully',
                'data': ContactMessageAdminSerializer(message).data
            })
            
        except Exception as e:
            return Response(
                {'error': f'Failed to send email: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
