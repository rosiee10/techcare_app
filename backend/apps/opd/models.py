from django.db import models


class PatientProfiling(models.Model):
    """Patient profiling model matching pch.patient_profiling table"""
    patient_id = models.AutoField(primary_key=True)
    hospital_id = models.CharField(max_length=8, blank=True, null=True)
    lastname = models.CharField(max_length=50)
    firstname = models.CharField(max_length=50)
    middlename = models.CharField(max_length=50, blank=True, null=True)
    ext = models.CharField(max_length=5, blank=True, null=True)
    birthdate = models.DateField()
    gender = models.CharField(max_length=5)  # pch.gender_type
    civil_status = models.CharField(max_length=5)  # pch.civil_status_type
    religion = models.CharField(max_length=50, blank=True, null=True)
    contact_number = models.CharField(max_length=15, blank=True, null=True)
    purok = models.CharField(max_length=40, blank=True, null=True)
    barangay = models.CharField(max_length=80, blank=True, null=True)
    city_municipal = models.CharField(max_length=80, blank=True, null=True)
    province = models.CharField(max_length=50, blank=True, null=True)
    current_status = models.CharField(max_length=15, blank=True, null=True)  # pch.current_status_type
    is_active = models.BooleanField(default=True)
    smoker = models.BooleanField(default=False)
    quitter = models.BooleanField(default=True)
    sticks_per_day = models.IntegerField(blank=True, null=True)
    trail = models.CharField(max_length=120, blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)
    updated_trail = models.CharField(max_length=120, blank=True, null=True)
    photo_url = models.CharField(max_length=255, blank=True, null=True)
    current_emergency_contact = models.ForeignKey(
        'EmergencyContact',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='patients'
    )
    
    class Meta:
        db_table = 'patient_profiling'
        managed = False  # Table already exists in database
    
    def __str__(self):
        return f"{self.firstname} {self.lastname}"


class EmergencyContact(models.Model):
    """Emergency contact model"""
    emergency_contact_id = models.AutoField(primary_key=True)
    patient = models.ForeignKey(
        PatientProfiling,
        on_delete=models.CASCADE,
        related_name='emergency_contacts'
    )
    contact_name = models.CharField(max_length=100)
    relationship = models.CharField(max_length=50, blank=True, null=True)
    contact_number = models.CharField(max_length=15, blank=True, null=True)
    purok = models.CharField(max_length=40, blank=True, null=True)
    barangay = models.CharField(max_length=80, blank=True, null=True)
    city_municipal = models.CharField(max_length=80, blank=True, null=True)
    province = models.CharField(max_length=50, blank=True, null=True)
    trail = models.CharField(max_length=120, blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)
    updated_trail = models.CharField(max_length=120, blank=True, null=True)
    
    class Meta:
        db_table = 'patient_emergency_contacts'
        managed = False
    
    def __str__(self):
        return self.contact_name


class OpdRoomLocation(models.Model):
    """OPD Room Location model matching pch.opd_room_location table"""
    room_location_id = models.AutoField(primary_key=True)
    code = models.CharField(max_length=10, blank=True, null=True)
    room_name = models.CharField(max_length=80, blank=True, null=True)
    room_type = models.CharField(max_length=30, blank=True, null=True)
    service = models.CharField(max_length=30, blank=True, null=True)
    q_prefix = models.CharField(max_length=2, blank=True, null=True)
    doctor_id = models.IntegerField(blank=True, null=True)
    doctor_display = models.CharField(max_length=80, blank=True, null=True)
    status = models.CharField(max_length=10, blank=True, null=True)
    is_active = models.BooleanField(default=True)
    trail = models.CharField(max_length=120, blank=True, null=True)
    updated_trail = models.CharField(max_length=120, blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        db_table = 'opd_room_location'
        managed = False

    def __str__(self):
        return f"{self.code} - {self.room_name}"


class OpdServiceSchedule(models.Model):
    """OPD Service Schedule model matching pch.opd_service_schedule table"""
    id = models.AutoField(primary_key=True)
    service = models.CharField(max_length=10)
    service_label = models.CharField(max_length=80, blank=True, null=True)
    days_open = models.CharField(max_length=40, blank=True, null=True)
    # Per-day schedule fields (allows different hours per day)
    mon_open = models.TimeField(blank=True, null=True)
    mon_close = models.TimeField(blank=True, null=True)
    tue_open = models.TimeField(blank=True, null=True)
    tue_close = models.TimeField(blank=True, null=True)
    wed_open = models.TimeField(blank=True, null=True)
    wed_close = models.TimeField(blank=True, null=True)
    thu_open = models.TimeField(blank=True, null=True)
    thu_close = models.TimeField(blank=True, null=True)
    fri_open = models.TimeField(blank=True, null=True)
    fri_close = models.TimeField(blank=True, null=True)
    sat_open = models.TimeField(blank=True, null=True)
    sat_close = models.TimeField(blank=True, null=True)
    active_today = models.BooleanField(default=True)
    is_active = models.BooleanField(default=True)
    color_theme = models.CharField(max_length=20, blank=True, null=True, default='#2196F3')
    updated_trail = models.CharField(max_length=120, blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        db_table = 'opd_service_schedule'
        managed = False

    def __str__(self):
        return self.service

    def get_hours_for_day(self, day_code):
        """Get opening and closing hours for a specific day
        day_code: 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'
        Returns: (open_time, close_time) tuple or (None, None) if not set
        """
        day_map = {
            'Mon': (self.mon_open, self.mon_close),
            'Tue': (self.tue_open, self.tue_close),
            'Wed': (self.wed_open, self.wed_close),
            'Thu': (self.thu_open, self.thu_close),
            'Fri': (self.fri_open, self.fri_close),
            'Sat': (self.sat_open, self.sat_close),
        }
        return day_map.get(day_code, (None, None))

    def set_hours_for_day(self, day_code, open_time, close_time):
        """Set opening and closing hours for a specific day"""
        if day_code == 'Mon':
            self.mon_open, self.mon_close = open_time, close_time
        elif day_code == 'Tue':
            self.tue_open, self.tue_close = open_time, close_time
        elif day_code == 'Wed':
            self.wed_open, self.wed_close = open_time, close_time
        elif day_code == 'Thu':
            self.thu_open, self.thu_close = open_time, close_time
        elif day_code == 'Fri':
            self.fri_open, self.fri_close = open_time, close_time
        elif day_code == 'Sat':
            self.sat_open, self.sat_close = open_time, close_time
