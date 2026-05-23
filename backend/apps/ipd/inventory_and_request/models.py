from django.db import models
from apps.opd.models import PatientProfiling


from apps.pharmacy.models import (
    PharmacyMedicine,
    PharmacyStockBatch,
    PharmacyInventoryBalance,
    PharmacyLocation
)


class IpdCartInventory(models.Model):
    """
    Proxy model for Cart / Floor Stock inventory (Location ID 2).
    Maps to the pharmacy_inventory_balance table.
    """
    medicine = models.ForeignKey(PharmacyMedicine, on_delete=models.DO_NOTHING, related_name='cart_inventory', primary_key=True, db_column='medicine_id')
    batch = models.ForeignKey(PharmacyStockBatch, on_delete=models.DO_NOTHING, db_column='batch_id')
    location = models.ForeignKey(PharmacyLocation, on_delete=models.DO_NOTHING, db_column='location_id')
    qty_on_hand = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    trail = models.CharField(max_length=120, blank=True, null=True)

    class Meta:
        db_table = 'pharmacy_inventory_balance'
        managed = False
        unique_together = [['medicine', 'batch', 'location']]

    def __str__(self):
        return f"{self.medicine.medicine_name} - Qty: {self.qty_on_hand}"


class IpdDepartments(models.Model):
    """
    IPD Departments model
    """
    department_id = models.AutoField(primary_key=True)
    department_code = models.CharField(unique=True, max_length=10)
    department_name = models.CharField(max_length=50)
    description = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)

    class Meta:
        db_table = 'ipd_departments'
        managed = False

    def __str__(self):
        return self.department_name


class IpdRooms(models.Model):
    """
    IPD Rooms model
    """
    room_id = models.AutoField(primary_key=True)
    room_number = models.CharField(max_length=20)
    bed_code = models.CharField(max_length=10)
    department = models.ForeignKey(IpdDepartments, models.DO_NOTHING, blank=True, null=True)
    room_type = models.CharField(max_length=20)
    is_occupied = models.BooleanField(blank=True, null=True)
    capacity = models.IntegerField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)

    class Meta:
        db_table = 'ipd_rooms'
        managed = False

    def __str__(self):
        return f"Room {self.room_number} - Bed {self.bed_code}"


class IpdNoticeOfAdmission(models.Model):
    """
    IPD Notice of Admission model
    Maps to pch.ipd_notice_of_admission table
    """
    admission_id = models.AutoField(primary_key=True)
    patient = models.ForeignKey(
        PatientProfiling,
        on_delete=models.DO_NOTHING,
        db_column='patient_id',
        related_name='ipd_admissions'
    )
    hospital_id = models.CharField(max_length=20, blank=True, null=True)
    admission_date = models.DateField(blank=True, null=True)
    admitting_impression = models.TextField(blank=True, null=True, db_column='admitting_impression')
    
    # Vital signs at admission
    bp = models.CharField(max_length=20, blank=True, null=True)
    pr = models.CharField(max_length=20, blank=True, null=True)
    temp = models.CharField(max_length=20, blank=True, null=True)
    rr = models.CharField(max_length=20, blank=True, null=True)
    weight = models.CharField(max_length=20, blank=True, null=True)
    height = models.CharField(max_length=20, blank=True, null=True)
    o2_sat = models.CharField(max_length=20, blank=True, null=True)
    
    admitting_physician = models.CharField(max_length=100, blank=True, null=True)
    department = models.CharField(max_length=50, blank=True, null=True)
    
    # Status: pending, approved, rejected
    status = models.CharField(max_length=20, default='pending')
    
    submitted_by = models.CharField(max_length=100, blank=True, null=True)
    submitted_date = models.DateTimeField(blank=True, null=True)
    approved_by = models.CharField(max_length=100, blank=True, null=True)
    approved_date = models.DateTimeField(blank=True, null=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'ipd_notice_of_admission'
        managed = False

    def __str__(self):
        return f"Admission #{self.admission_id} - {self.patient}"


class DispensingSheet(models.Model):
    """
    Dispensing Sheet Model (Nurse Request)
    For pharmacy OPEN requests - nurse requests medicines for inpatient
    Maps to pch.ipd_services_dispensing
    """
    dispensing_id = models.AutoField(primary_key=True)
    
    # Link to patient from patient_profiling (master table)
    patient = models.ForeignKey(
        PatientProfiling,
        on_delete=models.CASCADE,
        db_column='patient_id',
        related_name='dispensing_sheets'
    )
    
    # Link to admission for ward/room context
    admission = models.ForeignKey(
        IpdNoticeOfAdmission,
        on_delete=models.CASCADE,
        db_column='admission_id',
        related_name='dispensing_sheets',
        blank=True,
        null=True
    )
    
    # Request metadata
    request_date = models.DateField(auto_now_add=True)
    request_time = models.TimeField(auto_now_add=True)
    requested_by = models.IntegerField()  # User ID of nurse
    requested_by_name = models.CharField(max_length=100)
    
    # Status tracking
    STATUS_CHOICES = [
        ('PENDING', 'Pending'),
        ('APPROVED', 'Approved'),
        ('DISPENSED', 'Dispensed'),
        ('REJECTED', 'Rejected'),
    ]
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='PENDING'
    )
    
    # Pharmacist info (filled when dispensed)
    dispensed_by = models.IntegerField(blank=True, null=True)
    dispensed_by_name = models.CharField(max_length=100, blank=True, null=True)
    dispensed_date = models.DateTimeField(blank=True, null=True)
    total_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    
    # Audit trail
    trail = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'ipd_services_dispensing'
        managed = False  # Set to False as per SQL-first approach
        ordering = ['-created_at']

    def __str__(self):
        return f"Dispensing Sheet #{self.dispensing_id} - {self.patient}"


class DispensingSheetItem(models.Model):
    """
    Individual medicine items in a dispensing sheet
    Maps to pch.ipd_services_dispensing_items
    """
    dispensing_item_id = models.AutoField(primary_key=True) # MATCH PHYSICAL COLUMN NAME
    dispensing_sheet = models.ForeignKey(
        DispensingSheet,
        on_delete=models.CASCADE,
        db_column='dispensing_id',
        related_name='items'
    )
    
    # Medicine details
    medicine_id = models.IntegerField(blank=True, null=True) # Link to pharmacy_medicines
    date_requested = models.DateField()
    dosage = models.CharField(max_length=100, blank=True, null=True)
    quantity = models.IntegerField()
    
    # Costing and Dispensing Info (Populated by Pharmacist)
    unit = models.CharField(max_length=20, blank=True, null=True)
    unit_cost = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    total_cost = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    
    # Pharmacist signature/confirmation
    pharmacist_name = models.CharField(max_length=100, blank=True, null=True)
    
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'ipd_services_dispensing_items'
        managed = False

    def __str__(self):
        return f"Item {self.item_id} for Sheet {self.dispensing_sheet_id}"


class CartForm(models.Model):
    """
    Cart Form Model
    For pharmacy CLOSED requests - nurse takes medicines from emergency cart
    Maps to pch.ipd_cart_forms
    """
    cart_form_id = models.AutoField(primary_key=True)
    
    # Link to patient from patient_profiling (master table)
    patient = models.ForeignKey(
        PatientProfiling,
        on_delete=models.CASCADE,
        db_column='patient_id',
        related_name='cart_forms'
    )
    
    # Link to admission for ward/room context
    admission = models.ForeignKey(
        IpdNoticeOfAdmission,
        on_delete=models.CASCADE,
        db_column='admission_id',
        related_name='cart_forms',
        blank=True,
        null=True
    )
    
    # Request metadata
    request_date = models.DateField(auto_now_add=True)
    requested_by = models.IntegerField()  # User ID of nurse
    requested_by_name = models.CharField(max_length=100)
    from_location_id = models.IntegerField(default=2) # 2 = Cart/Floor Stock
    
    # Status tracking
    STATUS_CHOICES = [
        ('PENDING', 'Pending'),
        ('VERIFIED', 'Verified'),
        ('REPLENISHED', 'Replenished'),
    ]
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='PENDING'
    )
    
    # Audit trail
    trail = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'ipd_cart_forms'
        managed = False
        ordering = ['-created_at']

    def __str__(self):
        return f"Cart Form #{self.cart_form_id} - {self.patient}"


class CartFormItem(models.Model):
    """
    Individual medicine items taken from cart
    Maps to pch.ipd_cart_form_items
    """
    cart_item_id = models.AutoField(primary_key=True)
    cart_form = models.ForeignKey(
        CartForm,
        on_delete=models.CASCADE,
        db_column='cart_form_id',
        related_name='items'
    )
    
    # Medicine details
    medicine_id = models.IntegerField(blank=True, null=True)
    date_taken = models.DateField()
    drug_name = models.CharField(max_length=255)  # Invoice-Dosage-Strength-Manufacturer
    quantity = models.IntegerField()
    
    # Administered by (RN/Entity)
    administered_by = models.CharField(max_length=100)
    
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'ipd_cart_form_items'
        managed = False

    def __str__(self):
        return f"{self.drug_name} x{self.quantity}"
