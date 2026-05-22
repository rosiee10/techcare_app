"""
Serializers for Patient Portal app.
Uses existing serializers from opd app where possible.
"""
from rest_framework import serializers
from apps.opd.models import PatientProfiling, EmergencyContact


class PatientPortalProfileSerializer(serializers.ModelSerializer):
    """Serializer for patient portal profile view"""
    emergency_contacts = serializers.SerializerMethodField()
    
    class Meta:
        model = PatientProfiling
        fields = [
            'patient_id', 'hospital_id', 'lastname', 'firstname', 
            'middlename', 'ext', 'birthdate', 'gender', 'civil_status',
            'religion', 'contact_number', 'purok', 'barangay', 
            'city_municipal', 'province', 'current_status', 
            'photo_url', 'emergency_contacts'
        ]
    
    def get_emergency_contacts(self, obj):
        from apps.opd.serializers import EmergencyContactSerializer
        contacts = EmergencyContact.objects.filter(patient=obj)
        return EmergencyContactSerializer(contacts, many=True).data


class PatientPortalUpdateSerializer(serializers.ModelSerializer):
    """Serializer for patient portal profile updates (limited fields)"""
    
    class Meta:
        model = PatientProfiling
        fields = [
            'contact_number', 'purok', 'barangay', 
            'city_municipal', 'province', 'religion'
        ]
