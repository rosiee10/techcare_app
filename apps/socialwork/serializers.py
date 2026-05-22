from rest_framework import serializers
from .models import (
    Endorsement,
    MswDocument,
    MswNotification,
    SocialWorkReferral,
    SocialWorkReferralItem,
    MswAssessment,
)


class MswDocumentSerializer(serializers.ModelSerializer):
    """Serialises pch.msw_documents rows."""
    class Meta:
        model = MswDocument
        fields = [
            'document_id', 'application_id', 'filename', 'original_filename',
            'category', 'storage_path', 'trail', 'updated_trail', 'updated_at',
        ]
        read_only_fields = ('document_id',)


class MswDocumentListSerializer(serializers.ModelSerializer):
    """Lighter version used for list — omits storage_path bytes."""
    class Meta:
        model = MswDocument
        fields = [
            'document_id', 'application_id', 'filename', 'original_filename',
            'category', 'trail', 'updated_at',
        ]


class MswAssessmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = MswAssessment
        fields = '__all__'
        read_only_fields = ('assessment_id',)


class SocialWorkReferralItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = SocialWorkReferralItem
        fields = [
            'id', 'category', 'description', 'quantity',
            'unit_price', 'total', 'actual_amount',
            'philhealth_amount', 'excess_amount',
            'outside_amount', 'charge_to_maip',
            'source', 'created_at',
        ]


class SocialWorkReferralSerializer(serializers.ModelSerializer):
    items = SocialWorkReferralItemSerializer(many=True, read_only=True)

    class Meta:
        model = SocialWorkReferral
        fields = [
            'id', 'referral_source', 'patient_id', 'patient_name', 'hospital_no',
            'age', 'address', 'doctor', 'department', 'opd_no', 'bill_no',
            'classification', 'total_bill_amount', 'discount_type',
            'discount_amount', 'amount_after_discount', 'assistance_type',
            'assistance_amount', 'remarks', 'status',
            'referral_date', 'assessment_date', 'resolution_date',
            'assessed_by', 'approved_by', 'created_at', 'updated_at',
            'items',
        ]


class EndorsementSerializer(serializers.ModelSerializer):
    """
    Serializes Endorsement from the existing msw_endorsements table.
    DB columns are mapped directly; extra frontend fields come from the
    `trail` JSON property on the model.
    """

    # Frontend fields — accepted on write, returned from model property on read
    id = serializers.IntegerField(source='endorsement_id', read_only=True)
    patient_name = serializers.CharField(read_only=True)
    patient_id = serializers.IntegerField(read_only=True)
    physician = serializers.CharField(read_only=True)
    service_type = serializers.CharField(read_only=True)
    amount = serializers.CharField(read_only=True)
    hospital_no = serializers.CharField(read_only=True)
    purpose = serializers.CharField(read_only=True)
    office = serializers.CharField(read_only=True)
    issued_date = serializers.DateTimeField(read_only=True)
    user_id = serializers.IntegerField(source='application_id', read_only=True)
    social_worker_user_id = serializers.SerializerMethodField()
    financially_incapable = serializers.BooleanField(required=False, default=True)
    financially_capable = serializers.BooleanField(required=False, default=False)

    def get_social_worker_user_id(self, obj):
        """Get social worker user ID from trail JSON with debug logging"""
        social_worker_id = obj.social_worker_user_id
        print(f'[SERIALIZER] Endorsement {obj.endorsement_id}: social_worker_user_id = {social_worker_id}')
        print(f'[SERIALIZER] Trail data: {obj._trail_dict()}')
        
        # Fallback to default social worker ID if not set (for legacy endorsements)
        if social_worker_id is None:
            default_id = 32
            print(f'[SERIALIZER] Using fallback social_worker_user_id: {default_id}')
            return default_id
        
        return social_worker_id

    class Meta:
        model = Endorsement
        fields = [
            'id',
            'endorsement_id',
            'letter_number',
            'amount_requested',
            'status',
            'sent_at',
            'attachment_id',
            'updated_at',
            'user_id',
            'social_worker_user_id',
            'patient_name',
            'patient_id',
            'physician',
            'service_type',
            'amount',
            'hospital_no',
            'purpose',
            'office',
            'issued_date',
            'financially_incapable',
            'financially_capable',
        ]
        read_only_fields = ['endorsement_id', 'sent_at', 'updated_at']

    def create(self, validated_data):
        print(f'[SERIALIZER CREATE] Starting create with validated_data: {validated_data}')
        
        # Pop frontend-only fields so they are not passed as kwargs to the model
        frontend_fields = [
            'patient_name', 'patient_id', 'physician', 'service_type', 'amount',
            'hospital_no', 'purpose', 'office', 'issued_date',
            'financially_incapable', 'financially_capable',
        ]
        payload = {k: validated_data.pop(k) for k in frontend_fields if k in validated_data}
        
        print(f'[SERIALIZER CREATE] Payload before adding user: {payload}')

        instance = Endorsement(**validated_data)
        
        # Get the current user from context and add social_worker_user_id
        if hasattr(self, 'context') and 'request' in self.context:
            user = self.context['request'].user
            if user:
                payload['social_worker_user_id'] = user.id
                print(f'[SERIALIZER CREATE] Adding social_worker_user_id: {user.id}')
        
        print(f'[SERIALIZER CREATE] Final payload: {payload}')
        
        instance.pack_from_payload(payload)
        instance.save()
        print(f'[SERIALIZER CREATE] Created endorsement {instance.endorsement_id} with trail: {instance._trail_dict()}')
        return instance


class MswNotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = MswNotification
        fields = [
            'notification_id',
            'endorsement_id',
            'notification_type',
            'recipient_role',
            'recipient_user_id',
            'sender_user_id',
            'title',
            'message',
            'is_read',
            'created_at',
            'read_at',
            'patient_name',
            'office',
            'letter_number',
        ]
        read_only_fields = [
            'notification_id', 'created_at', 'read_at',
        ]
