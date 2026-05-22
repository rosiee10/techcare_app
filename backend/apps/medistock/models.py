from django.db import models
from apps.pharmacy.models import PharmacyPurchaseRequest
from apps.opd.models import PatientProfiling


class MedistockCategory(models.Model):
    category_id = models.AutoField(primary_key=True)
    category_name = models.CharField(max_length=255)
    description = models.CharField(max_length=255, blank=True, null=True)
    trail = models.CharField(max_length=120, blank=True, null=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'medistock_categories'
        ordering = ['category_name']

    def __str__(self):
        return self.category_name


class MedistockUnit(models.Model):
    unit_id = models.AutoField(primary_key=True)
    unit_name = models.CharField(max_length=255)
    unit_abbreviation = models.CharField(max_length=50, blank=True, null=True)
    trail = models.CharField(max_length=120, blank=True, null=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'medistock_units'
        ordering = ['unit_name']

    def __str__(self):
        return self.unit_name


class MedistockDepartment(models.Model):
    department_id = models.AutoField(primary_key=True)
    department_name = models.CharField(max_length=255)
    department_code = models.CharField(max_length=50, blank=True, null=True)
    trail = models.CharField(max_length=120, blank=True, null=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'medistock_departments'
        ordering = ['department_name']

    def __str__(self):
        return self.department_name


class MedistockLocation(models.Model):
    location_id = models.AutoField(primary_key=True)
    location_name = models.CharField(max_length=255)
    location_type = models.CharField(max_length=100, blank=True, null=True)
    trail = models.CharField(max_length=120, blank=True, null=True)
    department = models.ForeignKey(MedistockDepartment, models.DO_NOTHING, db_column='department_id', blank=True, null=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'medistock_locations'
        ordering = ['location_name']

    def __str__(self):
        return self.location_name


class MedistockSupplyItem(models.Model):
    supply_id = models.AutoField(primary_key=True)
    supply_code = models.CharField(max_length=100, blank=True, null=True)
    supply_name = models.CharField(max_length=255)
    category = models.ForeignKey(MedistockCategory, models.DO_NOTHING, db_column='category_id')
    unit = models.ForeignKey(MedistockUnit, models.DO_NOTHING, db_column='unit_id', blank=True, null=True)
    reorder_level = models.IntegerField(default=0)
    reorder_qty = models.IntegerField(default=0)
    is_expiry_tracked = models.BooleanField(default=False)
    unit_cost = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    trail = models.CharField(max_length=120, blank=True, null=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(blank=True, null=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        managed = False
        db_table = 'medistock_supply_items'
        ordering = ['supply_name']

    def __str__(self):
        return self.supply_name


class MedistockSupplyBatch(models.Model):
    batch_id = models.AutoField(primary_key=True)
    supply = models.ForeignKey(MedistockSupplyItem, models.DO_NOTHING, db_column='supply_id')
    batch_no = models.CharField(max_length=255)
    expiry_date = models.DateField(blank=True, null=True)
    received_date = models.DateField(blank=True, null=True)
    unit_cost = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    supplier_name = models.CharField(max_length=255, blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'medistock_supply_batches'
        ordering = ['-batch_id']

    def __str__(self):
        return self.batch_no


class MedistockInventoryBalance(models.Model):
    balance_id = models.AutoField(primary_key=True)
    supply = models.ForeignKey(MedistockSupplyItem, models.DO_NOTHING, db_column='supply_id')
    batch = models.ForeignKey(MedistockSupplyBatch, models.DO_NOTHING, db_column='batch_id')
    location = models.ForeignKey(MedistockLocation, models.DO_NOTHING, db_column='location_id')
    qty_on_hand = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    created_at = models.DateTimeField(blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'medistock_inventory_balance'

    def __str__(self):
        return f"{self.supply} - {self.location} ({self.qty_on_hand})"


class MedistockGoodsReceipt(models.Model):
    gr_id = models.AutoField(primary_key=True)
    gr_no = models.CharField(max_length=255)
    pr = models.ForeignKey(PharmacyPurchaseRequest, models.DO_NOTHING, db_column='pr_id')
    supplier_name = models.CharField(max_length=255, blank=True, null=True)
    received_date = models.DateTimeField(blank=True, null=True)
    status = models.CharField(max_length=50, blank=True, null=True)
    verified_by = models.IntegerField(blank=True, null=True)
    remarks = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'medistock_goods_receipts'
        ordering = ['-gr_id']

    def __str__(self):
        return self.gr_no


class MedistockGoodsReceiptItem(models.Model):
    gr_item_id = models.AutoField(primary_key=True)
    gr = models.ForeignKey(MedistockGoodsReceipt, models.DO_NOTHING, db_column='gr_id')
    pr_item_id = models.IntegerField(blank=True, null=True)
    supply = models.ForeignKey(MedistockSupplyItem, models.DO_NOTHING, db_column='supply_id')
    batch = models.ForeignKey(MedistockSupplyBatch, models.DO_NOTHING, db_column='batch_id')
    location = models.ForeignKey(MedistockLocation, models.DO_NOTHING, db_column='location_id')
    qty_ordered = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    qty_received = models.DecimalField(max_digits=12, decimal_places=2)
    unit_cost_actual = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    line_total_actual = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    expiry_date = models.DateField(blank=True, null=True)
    remarks = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'medistock_goods_receipt_items'


class MedistockSupplyRequest(models.Model):
    request_id = models.AutoField(primary_key=True)
    request_no = models.CharField(max_length=255)
    source_module = models.CharField(max_length=100)
    source_department = models.ForeignKey(MedistockDepartment, models.DO_NOTHING, db_column='source_department_id', blank=True, null=True)
    requested_by_user_id = models.IntegerField(blank=True, null=True)
    requested_by_name = models.CharField(max_length=255, blank=True, null=True)
    patient = models.ForeignKey(PatientProfiling, models.DO_NOTHING, db_column='patient_id', blank=True, null=True)
    request_date = models.DateTimeField(blank=True, null=True)
    required_date = models.DateField(blank=True, null=True)
    status = models.CharField(max_length=50, blank=True, null=True)
    patient_name = models.CharField(max_length=255, blank=True, null=True)
    purpose = models.TextField(blank=True, null=True)

    approved_by = models.IntegerField(blank=True, null=True)
    approved_at = models.DateTimeField(blank=True, null=True)
    completed_at = models.DateTimeField(blank=True, null=True)
    remarks = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'medistock_supply_requests'
        ordering = ['-request_id']

    def __str__(self):
        return self.request_no


class MedistockSupplyRequestItem(models.Model):
    request_item_id = models.AutoField(primary_key=True)
    request = models.ForeignKey(MedistockSupplyRequest, models.DO_NOTHING, db_column='request_id', related_name='items')
    supply = models.ForeignKey(MedistockSupplyItem, models.DO_NOTHING, db_column='supply_id', blank=True, null=True)
    item_name = models.CharField(max_length=255)
    qty_requested = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    qty_approved = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    qty_dispensed = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    batch = models.ForeignKey(MedistockSupplyBatch, models.DO_NOTHING, db_column='batch_id', blank=True, null=True)
    unit = models.ForeignKey(MedistockUnit, models.DO_NOTHING, db_column='unit_id', blank=True, null=True)
    status = models.CharField(max_length=50, blank=True, null=True)
    remarks = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'medistock_supply_request_items'

    def __str__(self):
        return self.item_name


class MedistockTransaction(models.Model):
    transaction_id = models.AutoField(primary_key=True)
    transaction_datetime = models.DateTimeField(blank=True, null=True)
    transaction_type = models.CharField(max_length=100)
    patient = models.ForeignKey(PatientProfiling, models.DO_NOTHING, db_column='patient_id', blank=True, null=True)
    supply = models.ForeignKey(MedistockSupplyItem, models.DO_NOTHING, db_column='supply_id')
    batch = models.ForeignKey(MedistockSupplyBatch, models.DO_NOTHING, db_column='batch_id')
    from_location = models.ForeignKey(MedistockLocation, models.DO_NOTHING, db_column='from_location_id', blank=True, null=True, related_name='tx_from')
    to_location = models.ForeignKey(MedistockLocation, models.DO_NOTHING, db_column='to_location_id', blank=True, null=True, related_name='tx_to')
    qty = models.DecimalField(max_digits=12, decimal_places=2)
    reference_type = models.CharField(max_length=100, blank=True, null=True)
    reference_id = models.BigIntegerField(blank=True, null=True)
    source_module = models.CharField(max_length=100, blank=True, null=True)
    patient_name = models.CharField(max_length=255, blank=True, null=True)
    requested_by = models.CharField(max_length=255, blank=True, null=True)
    department = models.ForeignKey(MedistockDepartment, models.DO_NOTHING, db_column='department_id', blank=True, null=True)
    remarks = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'medistock_transactions'
        ordering = ['-transaction_id']

    def __str__(self):
        return f"{self.transaction_type} - {self.supply}"


class MedistockReport(models.Model):
    report_id = models.AutoField(primary_key=True)
    report_type = models.CharField(max_length=100)
    period_type = models.CharField(max_length=50)
    date_from = models.DateField()
    date_to = models.DateField()
    generated_by = models.IntegerField(blank=True, null=True)
    generated_at = models.DateTimeField(blank=True, null=True)
    file_path = models.CharField(max_length=255, blank=True, null=True)
    parameters = models.JSONField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'medistock_reports'
        ordering = ['-report_id']


class MedistockPurchaseRequest(models.Model):
    STATUS_CHOICES = [
        ('DRAFT', 'Draft'),
        ('SUBMITTED', 'Submitted'),
        ('FOR_APPROVAL', 'For Approval'),
        ('APPROVED', 'Approved'),
        ('ON_DELIVERY', 'On Delivery'),
        ('DELIVERED', 'Delivered'),
        ('CANCELLED', 'Cancelled'),
    ]
    
    pr_id = models.AutoField(primary_key=True)
    pr_no = models.CharField(max_length=30, unique=True)
    pr_date = models.DateField(auto_now_add=True)
    purchase_type = models.CharField(max_length=20, default='REGULAR')
    pr_status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='DRAFT')
    lgu = models.CharField(max_length=100, blank=True, null=True)
    department = models.ForeignKey(MedistockDepartment, models.DO_NOTHING, db_column='department_id', blank=True, null=True)
    section = models.CharField(max_length=100, blank=True, null=True)
    fund = models.CharField(max_length=100, blank=True, null=True)
    requested_by = models.CharField(max_length=120, blank=True, null=True)
    expected_arrival_date = models.DateField(blank=True, null=True)
    cancel_reason = models.TextField(blank=True, null=True)
    total_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    remarks = models.TextField(blank=True, null=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        managed = False
        db_table = 'medistock_purchase_requests'
        ordering = ['-pr_id']

    def __str__(self):
        return self.pr_no


class MedistockPurchaseRequestItem(models.Model):
    pr_item_id = models.AutoField(primary_key=True)
    purchase_request = models.ForeignKey(MedistockPurchaseRequest, on_delete=models.CASCADE, related_name='items')
    supply = models.ForeignKey(MedistockSupplyItem, models.DO_NOTHING, db_column='supply_id')
    qty_requested = models.DecimalField(max_digits=12, decimal_places=2)
    unit_snapshot = models.CharField(max_length=50, blank=True, null=True)
    unit_cost_estimate = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    line_total_estimate = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    remarks = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'medistock_purchase_request_items'

    def __str__(self):
        return f"{self.supply.supply_name} ({self.qty_requested})"


# ── Read-only Database Views ────────────────────────────────────────────────

class MedistockVStockSummary(models.Model):
    supply_id = models.IntegerField(primary_key=True)
    supply_code = models.CharField(max_length=100, blank=True, null=True)
    supply_name = models.CharField(max_length=255, blank=True, null=True)
    category = models.CharField(max_length=255, blank=True, null=True)
    unit = models.CharField(max_length=50, blank=True, null=True)
    reorder_level = models.DecimalField(max_digits=12, decimal_places=2, blank=True, null=True)
    total_stock = models.DecimalField(max_digits=12, decimal_places=2, blank=True, null=True)
    main_stock = models.DecimalField(max_digits=12, decimal_places=2, blank=True, null=True)
    cart_stock = models.DecimalField(max_digits=12, decimal_places=2, blank=True, null=True)
    stock_status = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'medistock_v_stock_summary'


class MedistockVLowStock(models.Model):
    supply_id = models.IntegerField(primary_key=True)
    supply_name = models.CharField(max_length=255, blank=True, null=True)
    category = models.CharField(max_length=255, blank=True, null=True)
    reorder_level = models.DecimalField(max_digits=12, decimal_places=2, blank=True, null=True)
    current_stock = models.DecimalField(max_digits=12, decimal_places=2, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'medistock_v_low_stock'


class MedistockVExpiryAlert(models.Model):
    batch_id = models.IntegerField(primary_key=True)
    batch_no = models.CharField(max_length=255, blank=True, null=True)
    expiry_date = models.DateField(blank=True, null=True)
    supply_id = models.IntegerField(blank=True, null=True)
    supply_name = models.CharField(max_length=255, blank=True, null=True)
    category = models.CharField(max_length=255, blank=True, null=True)
    location_name = models.CharField(max_length=255, blank=True, null=True)
    qty_on_hand = models.DecimalField(max_digits=12, decimal_places=2, blank=True, null=True)
    days_remaining = models.IntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'medistock_v_expiry_alerts'


class MedistockVMonthlyConsumption(models.Model):
    supply_id = models.IntegerField(primary_key=True)
    month = models.DateTimeField(blank=True, null=True)
    supply_name = models.CharField(max_length=255, blank=True, null=True)
    category = models.CharField(max_length=255, blank=True, null=True)
    consumed = models.DecimalField(max_digits=12, decimal_places=2, blank=True, null=True)
    tx_count = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'medistock_v_monthly_consumption'


class MedistockVPendingRequest(models.Model):
    request_id = models.IntegerField(primary_key=True)
    request_no = models.CharField(max_length=255, blank=True, null=True)
    source_module = models.CharField(max_length=100, blank=True, null=True)
    source_department = models.CharField(max_length=255, blank=True, null=True)
    status = models.CharField(max_length=50, blank=True, null=True)
    patient_name = models.CharField(max_length=255, blank=True, null=True)
    request_date = models.DateTimeField(blank=True, null=True)
    item_count = models.BigIntegerField(blank=True, null=True)
    total_qty_requested = models.DecimalField(max_digits=12, decimal_places=2, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'medistock_v_pending_requests'


class MedistockVCartItem(models.Model):
    supply_id = models.IntegerField(primary_key=True)
    supply_name = models.CharField(max_length=255, blank=True, null=True)
    category = models.CharField(max_length=255, blank=True, null=True)
    unit = models.CharField(max_length=50, blank=True, null=True)
    location_id = models.IntegerField(blank=True, null=True)
    location_name = models.CharField(max_length=255, blank=True, null=True)
    location_type = models.CharField(max_length=100, blank=True, null=True)
    batch_count = models.BigIntegerField(blank=True, null=True)
    total_qty = models.DecimalField(max_digits=12, decimal_places=2, blank=True, null=True)
    nearest_expiry = models.DateField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'medistock_v_cart_items'


class MedistockVStockCard(models.Model):
    transaction_id = models.IntegerField(primary_key=True)
    transaction_datetime = models.DateTimeField(blank=True, null=True)
    transaction_type = models.CharField(max_length=100, blank=True, null=True)
    supply_name = models.CharField(max_length=255, blank=True, null=True)
    batch_no = models.CharField(max_length=255, blank=True, null=True)
    qty = models.DecimalField(max_digits=12, decimal_places=2, blank=True, null=True)
    from_location = models.CharField(max_length=255, blank=True, null=True)
    to_location = models.CharField(max_length=255, blank=True, null=True)
    reference_type = models.CharField(max_length=100, blank=True, null=True)
    reference_id = models.BigIntegerField(blank=True, null=True)
    patient_name = models.CharField(max_length=255, blank=True, null=True)
    requested_by = models.CharField(max_length=255, blank=True, null=True)
    department = models.CharField(max_length=255, blank=True, null=True)
    remarks = models.TextField(blank=True, null=True)
    source_module = models.CharField(max_length=100, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'medistock_v_stock_card'
