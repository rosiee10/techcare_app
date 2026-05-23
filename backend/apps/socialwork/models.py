import json

from django.db import models

from django.conf import settings


# ---------------------------------------------------------------------------
# Social Work Referral (maps to existing pch.social_work_referrals table)
# ---------------------------------------------------------------------------

class SocialWorkReferral(models.Model):
    """Read-only mapping for pch.social_work_referrals."""

    id = models.AutoField(primary_key=True)
    referral_source = models.CharField(max_length=10, blank=True, null=True)

    # Optional FKs to other SOA tables (kept as plain ints — managed=False)
    soa_opd_id = models.IntegerField(blank=True, null=True)
    soa_nbb_id = models.IntegerField(blank=True, null=True)
    soa_nonmed_id = models.IntegerField(blank=True, null=True)
    soa_philhealth_id = models.IntegerField(blank=True, null=True)

    # Patient linkage (nullable FK column we added via migration)
    patient_id = models.IntegerField(blank=True, null=True)

    patient_name = models.CharField(max_length=200, blank=True, null=True)
    hospital_no = models.CharField(max_length=50, blank=True, null=True)
    age = models.IntegerField(blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    doctor = models.CharField(max_length=100, blank=True, null=True)
    department = models.CharField(max_length=80, blank=True, null=True)
    opd_no = models.CharField(max_length=50, blank=True, null=True)
    bill_no = models.CharField(max_length=50, blank=True, null=True)
    classification = models.CharField(max_length=20, blank=True, null=True)

    total_bill_amount = models.DecimalField(max_digits=12, decimal_places=2, blank=True, null=True)
    discount_type = models.CharField(max_length=20, blank=True, null=True)
    discount_amount = models.DecimalField(max_digits=12, decimal_places=2, blank=True, null=True)
    amount_after_discount = models.DecimalField(max_digits=12, decimal_places=2, blank=True, null=True)
    assistance_type = models.CharField(max_length=100, blank=True, null=True)
    assistance_amount = models.DecimalField(max_digits=12, decimal_places=2, blank=True, null=True)

    remarks = models.TextField(blank=True, null=True)
    status = models.CharField(max_length=30, blank=True, null=True)

    referral_date = models.DateField(blank=True, null=True)
    assessment_date = models.DateField(blank=True, null=True)
    resolution_date = models.DateField(blank=True, null=True)

    assessed_by = models.CharField(max_length=100, blank=True, null=True)
    approved_by = models.CharField(max_length=100, blank=True, null=True)

    created_at = models.DateTimeField(blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        db_table = 'social_work_referrals'
        managed = False
        ordering = ['-id']


class SocialWorkReferralItem(models.Model):
    """Read-only mapping for pch.social_work_referral_items."""

    id = models.AutoField(primary_key=True)
    referral = models.ForeignKey(
        SocialWorkReferral,
        on_delete=models.DO_NOTHING,
        db_column='referral_id',
        related_name='items',
    )
    category = models.CharField(max_length=80, blank=True, null=True)
    description = models.CharField(max_length=200, blank=True, null=True)
    quantity = models.IntegerField(blank=True, null=True)
    unit_price = models.DecimalField(max_digits=12, decimal_places=2, blank=True, null=True)
    total = models.DecimalField(max_digits=12, decimal_places=2, blank=True, null=True)
    actual_amount = models.DecimalField(max_digits=12, decimal_places=2, blank=True, null=True)
    philhealth_amount = models.DecimalField(max_digits=12, decimal_places=2, blank=True, null=True)
    excess_amount = models.DecimalField(max_digits=12, decimal_places=2, blank=True, null=True)
    outside_amount = models.DecimalField(max_digits=12, decimal_places=2, blank=True, null=True)
    charge_to_maip = models.DecimalField(max_digits=12, decimal_places=2, blank=True, null=True)
    source = models.CharField(max_length=50, blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        db_table = 'social_work_referral_items'
        managed = False
        ordering = ['id']


# ---------------------------------------------------------------------------
# MSW Assessment (eligibility screening) — maps to existing pch.msw_assessments
# ---------------------------------------------------------------------------

class MswApplication(models.Model):
    """Minimal mapping for pch.msw_applications (referenced by msw_assessments)."""

    application_id = models.AutoField(primary_key=True)
    patient_id = models.IntegerField(blank=True, null=True)
    application_number = models.CharField(max_length=32, blank=True, null=True)
    application_type = models.CharField(max_length=50, blank=True, null=True)
    # NOTE: status has a CHECK constraint; let DB default it.
    total_requested = models.DecimalField(max_digits=12, decimal_places=2, blank=True, null=True)
    total_approved = models.DecimalField(max_digits=12, decimal_places=2, blank=True, null=True)
    referral_source = models.CharField(max_length=50, blank=True, null=True)
    date_of_admission = models.DateField(blank=True, null=True)
    trail = models.CharField(max_length=120, blank=True, null=True)
    updated_trail = models.CharField(max_length=120, blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        db_table = 'msw_applications'
        managed = False
        ordering = ['-application_id']


class MswDocument(models.Model):
    """Mapping for pch.msw_documents — stores uploaded / generated documents."""

    document_id = models.BigAutoField(primary_key=True)
    application_id = models.BigIntegerField(blank=True, null=True)
    filename = models.CharField(max_length=120)
    original_filename = models.CharField(max_length=120, blank=True, null=True)
    category = models.CharField(max_length=60, blank=True, null=True)
    storage_path = models.TextField(blank=True, null=True)   # base64 content on web
    trail = models.CharField(max_length=120, blank=True, null=True)   # JSON metadata
    updated_trail = models.CharField(max_length=120, blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        db_table = 'msw_documents'
        managed = False
        ordering = ['-document_id']


class MswAssessment(models.Model):
    """Eligibility screening assessment row written by the social worker."""

    assessment_id = models.AutoField(primary_key=True)
    application_id = models.BigIntegerField(blank=True, null=True)  # patient_profiling FK
    msw_user_id = models.IntegerField(blank=True, null=True)
    date_of_interview = models.DateField(blank=True, null=True)

    informant_name = models.CharField(max_length=80, blank=True, null=True)
    informant_relation = models.CharField(max_length=30, blank=True, null=True)
    informant_contact = models.CharField(max_length=30, blank=True, null=True)

    type_of_living_arrangement = models.CharField(max_length=80, blank=True, null=True)
    highest_educational_attainment = models.CharField(max_length=80, blank=True, null=True)
    occupation = models.CharField(max_length=80, blank=True, null=True)

    patient_monthly_income = models.DecimalField(max_digits=12, decimal_places=2, blank=True, null=True)
    light_source = models.CharField(max_length=40, blank=True, null=True)
    fuel_source = models.CharField(max_length=40, blank=True, null=True)
    water_source = models.CharField(max_length=40, blank=True, null=True)

    total_household_income = models.DecimalField(max_digits=14, decimal_places=2, blank=True, null=True)
    household_size = models.IntegerField(blank=True, null=True)
    # NOTE: per_capita_income is a Postgres GENERATED column
    # (total_household_income / household_size). It must NOT be inserted by
    # Django, so we intentionally do not declare it on the model.

    financially_capable = models.BooleanField(default=False)
    financially_incapacitated = models.BooleanField(default=False)
    indigent_financially_incapable = models.BooleanField(default=False)

    sub_non_philhealth_c1 = models.BooleanField(default=False)
    sub_non_philhealth_c2 = models.BooleanField(default=False)
    sub_non_philhealth_c3 = models.BooleanField(default=False)

    member_artisanal_fishfolk = models.BooleanField(default=False)
    member_farmer_landless = models.BooleanField(default=False)
    member_urban_poor = models.BooleanField(default=False)
    member_victims_disaster = models.BooleanField(default=False)
    member_formal_labor_migrant = models.BooleanField(default=False)
    member_informal_sector = models.BooleanField(default=False)
    member_senior_citizen = models.BooleanField(default=False)
    member_indigenous_peoples = models.BooleanField(default=False)
    member_pwd = models.BooleanField(default=False)
    member_others = models.BooleanField(default=False)
    others_specify = models.TextField(blank=True, null=True)

    patient_classification = models.CharField(max_length=30, blank=True, null=True)
    coe_issued = models.BooleanField(default=False)
    coe_number = models.CharField(max_length=50, blank=True, null=True)
    coe_issued_at = models.DateTimeField(blank=True, null=True)

    overall_recommendation = models.TextField(blank=True, null=True)
    final_remarks = models.TextField(blank=True, null=True)

    # NOTE: status has a CHECK constraint with a fixed enum and a DB default.
    # We intentionally don't declare it here so Django lets the DB default fill
    # the value on INSERT.
    trail = models.CharField(max_length=120, blank=True, null=True)
    updated_trail = models.CharField(max_length=120, blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        db_table = 'msw_assessments'
        managed = False
        ordering = ['-assessment_id']


# ---------------------------------------------------------------------------
# Notification model
# ---------------------------------------------------------------------------

class MswNotification(models.Model):
    """
    Notification table for Social Work ↔ Mayor/Congressman endorsement flow.

    Recipient roles:
      - 'social_worker'  → notified when mayor/congressman approves or rejects
      - 'mayor'          → notified when a social worker sends an endorsement
      - 'congressman'    → notified when a social worker sends an endorsement

    notification_type values:
      - 'endorsement_sent'     → SW sent endorsement to mayor/congressman
      - 'endorsement_approved' → mayor/congressman approved an endorsement
      - 'endorsement_rejected' → mayor/congressman rejected an endorsement
    """

    NOTIFICATION_TYPES = [
        ('endorsement_sent',     'Endorsement Sent'),
        ('endorsement_approved', 'Endorsement Approved'),
        ('endorsement_rejected', 'Endorsement Rejected'),
    ]

    RECIPIENT_ROLES = [
        ('social_worker', 'Social Worker'),
        ('mayor',         'Mayor'),
        ('congressman',   'Congressman'),
    ]

    notification_id   = models.AutoField(primary_key=True)
    endorsement_id    = models.IntegerField(db_index=True)          # FK-like ref to msw_endorsements
    notification_type = models.CharField(max_length=30, choices=NOTIFICATION_TYPES)
    recipient_role    = models.CharField(max_length=20, choices=RECIPIENT_ROLES)
    recipient_user_id = models.IntegerField(null=True, blank=True)  # specific user, NULL = broadcast to role
    sender_user_id    = models.IntegerField(null=True, blank=True)  # who triggered the notification
    title             = models.CharField(max_length=120)
    message           = models.TextField()
    is_read           = models.BooleanField(default=False)
    created_at        = models.DateTimeField(auto_now_add=True)
    read_at           = models.DateTimeField(null=True, blank=True)

    # Snapshot fields so the notification is self-contained
    patient_name      = models.CharField(max_length=120, blank=True, null=True)
    office            = models.CharField(max_length=80,  blank=True, null=True)
    letter_number     = models.CharField(max_length=64,  blank=True, null=True)

    class Meta:
        db_table = 'msw_notifications'
        ordering = ['-created_at']

    def __str__(self):
        return f"[{self.notification_type}] → {self.recipient_role} | {self.title}"





class Signature(models.Model):

    """

    Maps to the existing pch.msw_signature table.

    Stores user signatures as BYTEA image data.

    """

    id = models.BigAutoField(primary_key=True)

    user = models.ForeignKey(

        settings.AUTH_USER_MODEL,

        on_delete=models.CASCADE,

        db_column='user_id',

        to_field='id'

    )

    signature_image = models.BinaryField()

    file_name = models.CharField(max_length=255, blank=True, null=True)

    created_at = models.DateTimeField(auto_now_add=True)



    class Meta:

        db_table = 'pch.msw_signature'

        managed = False  # Existing table - Django won't create/alter

        ordering = ['-created_at']



    def __str__(self):

        return f"Signature for {self.user} at {self.created_at}"





class Endorsement(models.Model):

    """

    Maps to the existing pch.msw_endorsements table.

    Extra frontend fields (patient_name, physician, office, etc.)

    are packed into the trail column as JSON.

    """



    endorsement_id = models.BigAutoField(primary_key=True, db_column='endorsement_id')

    application_id = models.BigIntegerField(null=True, blank=True)

    letter_number = models.CharField(max_length=64, blank=True, null=True)

    amount_requested = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)

    status = models.CharField(max_length=20, blank=True, null=True, default='Pending')

    sent_at = models.DateTimeField(null=True, blank=True)

    attachment_id = models.BigIntegerField(null=True, blank=True)

    trail = models.CharField(max_length=500, blank=True, null=True)

    updated_trail = models.CharField(max_length=500, blank=True, null=True)

    updated_at = models.DateTimeField(null=True, blank=True)



    class Meta:

        db_table = 'msw_endorsements'

        managed = False  # Existing table — Django will not create/alter it

        ordering = ['-sent_at']



    # ------------------------------------------------------------------

    # trail helpers

    # ------------------------------------------------------------------

    def _trail_dict(self):

        if not self.trail:

            return {}

        try:

            return json.loads(self.trail)

        except (json.JSONDecodeError, TypeError):

            return {}



    def _set_trail(self, data_dict):

        existing = self._trail_dict()

        existing.update(data_dict)

        # Keep within 120 chars; if too large, trim values

        raw = json.dumps(existing, default=str)

        if len(raw) > 120:

            # Compact by keeping only essential keys if too long
            # IMPORTANT: always keep social_worker_user_id so signature loads correctly

            compact = {k: v for k, v in existing.items()

                       if k in ('patient_name', 'office', 'physician', 'status', 'social_worker_user_id')}

            raw = json.dumps(compact, default=str)

        self.trail = raw



    # ------------------------------------------------------------------

    # Computed properties read from trail JSON

    # ------------------------------------------------------------------

    @property

    def patient_name(self):

        return self._trail_dict().get('patient_name', 'Unknown Patient')



    @property

    def patient_id(self):

        return self._trail_dict().get('patient_id')



    @property

    def physician(self):

        return self._trail_dict().get('physician')



    @property

    def service_type(self):

        return self._trail_dict().get('service_type')



    @property

    def amount(self):

        # Return amount_requested as string for frontend parity

        if self.amount_requested is not None:

            return f'PHP {self.amount_requested}'

        return self._trail_dict().get('amount')



    @property

    def hospital_no(self):

        return self._trail_dict().get('hospital_no')



    @property

    def purpose(self):

        return self._trail_dict().get('purpose')



    @property

    def office(self):

        return self._trail_dict().get('office', "Mayor's Office")



    @property

    def issued_date(self):

        val = self._trail_dict().get('issued_date')

        if val:

            from django.utils.dateparse import parse_datetime

            dt = parse_datetime(val)

            if dt:

                return dt

        return self.sent_at



    @property

    def financially_incapable(self):

        return self._trail_dict().get('financially_incapable', True)



    @property

    def financially_capable(self):

        return self._trail_dict().get('financially_capable', False)



    @property

    def social_worker_user_id(self):

        return self._trail_dict().get('social_worker_user_id')



    # ------------------------------------------------------------------

    # Pack frontend payload into trail + DB fields on save

    # ------------------------------------------------------------------

    def pack_from_payload(self, payload):

        """Call before saving a new endorsement."""

        from decimal import Decimal

        from django.utils import timezone

        import datetime, uuid, re



        # Numeric amount: strip 'PHP ' prefix if present

        raw_amount = payload.get('amount') or payload.get('amount_requested')

        if raw_amount:

            m = re.search(r'[\d,]+(?:\.\d+)?', str(raw_amount))

            if m:

                try:

                    self.amount_requested = Decimal(m.group().replace(',', ''))

                except ValueError:

                    pass



        raw_status = payload.get('status', 'Pending')

        self.status = raw_status.capitalize()[:20]

        if not self.letter_number:

            self.letter_number = f"END-{datetime.date.today().strftime('%Y%m%d')}-{uuid.uuid4().hex[:6].upper()}"



        # Ensure timestamps are set so the DB never sees NULL on required cols

        now = timezone.now()

        if self.sent_at is None:

            self.sent_at = now

        if self.updated_at is None:

            self.updated_at = now



        # Store all frontend metadata in trail JSON

        trail_fields = ('patient_name', 'patient_id', 'physician', 'office',

                        'service_type', 'hospital_no', 'purpose', 'issued_date',

                        'financially_incapable', 'financially_capable', 'social_worker_user_id')

        data = {k: payload[k] for k in trail_fields if k in payload and payload[k] is not None}

        self._set_trail(data)



    def save(self, *args, **kwargs):
        """Override save to ensure social_worker_user_id is always present"""
        print(f'[MODEL SAVE] Saving endorsement {self.endorsement_id}')
        
        # Get current trail data
        trail_data = self._trail_dict()
        print(f'[MODEL SAVE] Current trail: {trail_data}')
        
        # Check if social_worker_user_id is missing
        if 'social_worker_user_id' not in trail_data or trail_data['social_worker_user_id'] is None:
            print(f'[MODEL SAVE] Adding social_worker_user_id = 32')
            trail_data['social_worker_user_id'] = 32
            self._set_trail(trail_data)
            print(f'[MODEL SAVE] Updated trail: {trail_data}')
        
        # Call the original save method
        super().save(*args, **kwargs)

    def __str__(self):

        return f"{self.patient_name} -> {self.office} ({self.status})"

