from rest_framework import serializers
from apps.opd.models import PatientProfiling, EmergencyContact, OpdServiceSchedule
from datetime import datetime


class EmergencyContactSerializer(serializers.ModelSerializer):
    name = serializers.CharField(source='contact_name')
    province_code = serializers.SerializerMethodField()
    city_code = serializers.SerializerMethodField()
    barangay_code = serializers.SerializerMethodField()
    
    class Meta:
        model = EmergencyContact
        fields = [
            'emergency_contact_id', 'name', 'relationship', 'contact_number',
            'purok', 'barangay', 'city_municipal', 'province',
            'province_code', 'city_code', 'barangay_code'
        ]
    
    def get_province_code(self, obj):
        return obj.province
    
    def get_city_code(self, obj):
        return obj.city_municipal
    
    def get_barangay_code(self, obj):
        return obj.barangay


class PatientListSerializer(serializers.ModelSerializer):
    """Serializer for patient list API endpoint"""
    patient_id = serializers.SerializerMethodField()
    full_name = serializers.SerializerMethodField()
    age = serializers.SerializerMethodField()
    sex = serializers.CharField(source='gender')
    last_visit = serializers.SerializerMethodField()
    department = serializers.SerializerMethodField()
    status = serializers.SerializerMethodField()
    address = serializers.SerializerMethodField()
    extension = serializers.CharField(source='ext', allow_null=True)
    civil_status = serializers.CharField(allow_null=True)
    religion = serializers.CharField(allow_null=True)
    contact_number = serializers.CharField(allow_null=True)
    emergency_contact = serializers.SerializerMethodField()
    province_code = serializers.SerializerMethodField()
    city_code = serializers.SerializerMethodField()
    barangay_code = serializers.SerializerMethodField()
    photo_url = serializers.SerializerMethodField()
    
    class Meta:
        model = PatientProfiling
        fields = [
            'hospital_id', 'patient_id', 'full_name', 'lastname', 'firstname', 
            'middlename', 'extension', 'birthdate', 'age', 'sex', 'last_visit', 'department', 
            'status', 'is_active', 'photo_url', 'contact_number', 'address',
            'purok', 'barangay', 'city_municipal', 'province',
            'province_code', 'city_code', 'barangay_code',
            'civil_status', 'religion', 'emergency_contact'
        ]
    
    def get_patient_id(self, obj):
        """Convert patient_id to string"""
        return str(obj.patient_id)
    
    def get_full_name(self, obj):
        """Combine first and last name"""
        middle = f" {obj.middlename}" if obj.middlename else ""
        return f"{obj.lastname}, {obj.firstname}{middle}"
    
    def get_age(self, obj):
        """Calculate age from birthdate"""
        if obj.birthdate:
            today = datetime.now().date()
            age = today.year - obj.birthdate.year - ((today.month, today.day) < (obj.birthdate.month, obj.birthdate.day))
            return age
        return 0
    
    def get_last_visit(self, obj):
        """Return last visit date or current status"""
        return obj.updated_at.strftime('%b %d, %Y') if obj.updated_at else 'Never'
    
    def get_department(self, obj):
        """Return department from current status"""
        status_map = {
            'OUTPATIENT': 'OPD',
            'INPATIENT': 'IPD',
            'EMERGENCY': 'ER',
        }
        return status_map.get(obj.current_status, 'OPD')
    
    def get_status(self, obj):
        """Return patient status"""
        status_map = {
            'OUTPATIENT': 'Outpatient',
            'INPATIENT': 'Inpatient',
            'EMERGENCY': 'Emergency',
        }
        return status_map.get(obj.current_status, 'Outpatient')
    
    def get_address(self, obj):
        """Combine purok, barangay, city_municipal, and province into complete address"""
        address_parts = []
        if obj.purok:
            address_parts.append(obj.purok)
        if obj.barangay:
            address_parts.append(obj.barangay)
        if obj.city_municipal:
            address_parts.append(obj.city_municipal)
        if obj.province:
            address_parts.append(obj.province)
        return ', '.join(address_parts) if address_parts else None
    
    def get_emergency_contact(self, obj):
        """Return full emergency contact object"""
        if obj.current_emergency_contact:
            return EmergencyContactSerializer(obj.current_emergency_contact).data
        return None
    
    def get_province_code(self, obj):
        """Return province name as code (backend stores names, not codes)"""
        return obj.province
    
    def get_city_code(self, obj):
        """Return city_municipal name as code (backend stores names, not codes)"""
        return obj.city_municipal
    
    def get_barangay_code(self, obj):
        """Return barangay name as code (backend stores names, not codes)"""
        return obj.barangay
    
    def get_photo_url(self, obj):
        """Construct full media URL for patient photo"""
        if not obj.photo_url:
            return None
        
        # If it's already a full URL, return as-is
        if obj.photo_url.startswith('http://') or obj.photo_url.startswith('https://'):
            return obj.photo_url
        
        # If it's a relative path, construct the full URL
        # Get the request from context to build the full URL dynamically
        request = self.context.get('request')
        if request:
            # Use request.build_absolute_uri to construct full URL
            base_url = request.build_absolute_uri('/').rstrip('/')
            return f"{base_url}/media/{obj.photo_url.lstrip('/')}"
        
        # Fallback if no request context
        return f"/media/{obj.photo_url.lstrip('/')}"


class PatientProfilingSerializer(serializers.ModelSerializer):
    emergency_contact = EmergencyContactSerializer(
        source='current_emergency_contact',
        read_only=True
    )
    
    class Meta:
        model = PatientProfiling
        fields = [
            'patient_id', 'hospital_id', 'lastname', 'firstname', 'middlename', 'ext',
            'birthdate', 'gender', 'civil_status', 'religion', 'contact_number',
            'purok', 'barangay', 'city_municipal', 'province',
            'current_status', 'is_active', 'smoker', 'quitter', 'sticks_per_day', 'tiral',
            'photo_url', 'emergency_contact'
        ]


class ServiceScheduleSerializer(serializers.ModelSerializer):
    """Serializer for OPD Service Schedule"""
    # Computed fields for frontend
    name = serializers.CharField(source='service', read_only=True)
    code = serializers.CharField(source='service', read_only=True)
    hours = serializers.SerializerMethodField()
    is_open_today = serializers.BooleanField(source='active_today', read_only=True)
    weekly_schedule = serializers.SerializerMethodField()
    color_hex = serializers.SerializerMethodField()
    # Per-day schedule data
    daily_hours = serializers.SerializerMethodField()

    class Meta:
        model = OpdServiceSchedule
        fields = [
            'id', 'name', 'code', 'service_label', 'hours', 'is_open_today',
            'weekly_schedule', 'color_hex', 'days_open',
            'daily_hours', 'active_today', 'is_active', 'updated_at'
        ]

    def get_hours(self, obj):
        """Format hours - uses first available day from per-day schedule"""
        days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
        for day in days:
            open_time, close_time = obj.get_hours_for_day(day)
            if open_time and close_time:
                return f"{open_time.strftime('%I:%M %p')} - {close_time.strftime('%I:%M %p')}"
        return ""

    def get_daily_hours(self, obj):
        """Return per-day hours schedule"""
        days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
        daily_schedule = {}

        for day in days:
            open_time, close_time = obj.get_hours_for_day(day)
            if open_time and close_time:
                daily_schedule[day] = {
                    'open': open_time.strftime('%I:%M %p'),
                    'close': close_time.strftime('%I:%M %p'),
                    'formatted': f"{open_time.strftime('%I:%M %p')} - {close_time.strftime('%I:%M %p')}"
                }
            else:
                daily_schedule[day] = None

        return daily_schedule

    def get_weekly_schedule(self, obj):
        """Parse days_open string into boolean array [MON, TUE, WED, THU, FRI, SAT]"""
        days_map = {
            'Mon': 0, 'Tue': 1, 'Wed': 2, 'Thu': 3, 'Fri': 4, 'Sat': 5
        }
        schedule = [False] * 6  # MON-SAT

        if obj.days_open:
            for day_abbr, index in days_map.items():
                if day_abbr in obj.days_open:
                    schedule[index] = True

        return schedule

    def get_color_hex(self, obj):
        """Assign colors based on service code"""
        color_map = {
            'FAMED': '#2196F3',
            'PEDIA': '#4CAF50',
            'DENTAL': '#00BCD4',
            'SURGERY': '#9C27B0',
            'OBGYN': '#E91E63',
        }
        return color_map.get(obj.service, '#666666')
