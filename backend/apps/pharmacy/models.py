from django.db import models


class PharmacySupplier(models.Model):
    """Pharmacy suppliers/vendors - matches pch.pharmacy_suppliers"""
    supplier_id = models.AutoField(primary_key=True)
    supplier_name = models.CharField(max_length=100, unique=True)
    delivery_days_avg = models.IntegerField(default=0)
    is_active = models.BooleanField(default=True)
    remarks = models.TextField(blank=True, null=True)
    trail = models.CharField(max_length=120, blank=True, null=True)

    class Meta:
        db_table = 'pharmacy_suppliers'
        managed = False

    def __str__(self):
        return self.supplier_name


class PharmacyLocation(models.Model):
    """Storage locations - matches pch.pharmacy_locations"""
    LOCATION_TYPES = [
        ('PHARMACY', 'Pharmacy'),
        ('CART', 'Cart'),
    ]
    
    location_id = models.AutoField(primary_key=True)
    location_name = models.CharField(max_length=80, unique=True)
    location_type = models.CharField(max_length=10, choices=LOCATION_TYPES)
    is_active = models.BooleanField(default=True)
    trail = models.CharField(max_length=120, blank=True, null=True)

    class Meta:
        db_table = 'pharmacy_locations'
        managed = False

    def __str__(self):
        return self.location_name


class PharmacyMedicine(models.Model):
    """Medicine catalog - matches pch.pharmacy_medicines exactly"""
    medicine_id = models.AutoField(primary_key=True)
    medicine_code = models.CharField(max_length=30, unique=True, blank=True, null=True)
    medicine_name = models.CharField(max_length=120)
    category = models.CharField(max_length=50)
    unit = models.CharField(max_length=20)
    reorder_level = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    unit_cost = models.DecimalField(max_digits=12, decimal_places=2, default=0, null=True, blank=True)
    is_active = models.BooleanField(default=True)
    trail = models.CharField(max_length=120, blank=True, null=True)

    class Meta:
        db_table = 'pharmacy_medicines'
        managed = False

    def __str__(self):
        return f"{self.medicine_name} ({self.medicine_code})"


class PharmacyStockBatch(models.Model):
    """Medicine batches - matches pch.pharmacy_stock_batches with unit_cost added"""
    batch_id = models.AutoField(primary_key=True)
    medicine = models.ForeignKey(PharmacyMedicine, on_delete=models.CASCADE, related_name='batches')
    batch_no = models.CharField(max_length=40)
    expiry_date = models.DateField()
    received_date = models.DateField(blank=True, null=True)
    unit_cost = models.DecimalField(max_digits=12, decimal_places=2, default=0, null=True, blank=True,
                                    help_text='Cost per unit for this specific batch')
    trail = models.CharField(max_length=120, blank=True, null=True)

    class Meta:
        db_table = 'pharmacy_stock_batches'
        managed = False
        unique_together = ['medicine', 'batch_no', 'expiry_date']

    def __str__(self):
        return f"{self.medicine.medicine_name} - {self.batch_no} (₱{self.unit_cost})"


class PharmacyInventoryBalance(models.Model):
    """Inventory balance - matches pch.pharmacy_inventory_balance exactly"""
    # Note: DB uses composite PK (medicine+batch+location). 
    # Django does not support composite PKs naturally.
    # To fix the "id does not exist" error, we mark medicine_id as the PK for Django ORM
    # but acknowledge that logic must handle batch/location uniquely.
    medicine = models.ForeignKey(PharmacyMedicine, on_delete=models.CASCADE, related_name='inventory', primary_key=True, db_column='medicine_id')
    batch = models.ForeignKey(PharmacyStockBatch, on_delete=models.CASCADE, related_name='balances', db_column='batch_id')
    location = models.ForeignKey(PharmacyLocation, on_delete=models.CASCADE, db_column='location_id')
    qty_on_hand = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    trail = models.CharField(max_length=120, blank=True, null=True)

    class Meta:
        db_table = 'pharmacy_inventory_balance'
        managed = False
        unique_together = [['medicine', 'batch', 'location']]

    def __str__(self):
        return f"{self.medicine.medicine_name} ({self.batch.batch_no}) at {self.location.location_name}: {self.qty_on_hand}"


class PharmacyTransaction(models.Model):
    """Inventory transactions - matches pch.pharmacy_transactions exactly"""
    TRANSACTION_TYPES = [
        ('IN', 'In'),
        ('OUT', 'Out'),
        ('TRANSFER', 'Transfer'),
        ('ADJUST', 'Adjust'),
    ]
    
    SERVICE_SOURCES = [
        ('OPD', 'OPD'),
        ('IPD', 'IPD'),
        ('CART', 'Cart'),
    ]
    
    transaction_id = models.AutoField(primary_key=True)
    transaction_datetime = models.DateTimeField(auto_now_add=True)
    transaction_type = models.CharField(max_length=10, choices=TRANSACTION_TYPES)
    medicine = models.ForeignKey(PharmacyMedicine, on_delete=models.CASCADE)
    batch = models.ForeignKey(PharmacyStockBatch, on_delete=models.CASCADE)
    from_location = models.ForeignKey(PharmacyLocation, on_delete=models.CASCADE, related_name='transactions_from', null=True, blank=True)
    to_location = models.ForeignKey(PharmacyLocation, on_delete=models.CASCADE, related_name='transactions_to', null=True, blank=True)
    qty = models.DecimalField(max_digits=12, decimal_places=2)
    reference_type = models.CharField(max_length=30, blank=True, null=True)
    reference_id = models.BigIntegerField(blank=True, null=True)
    service_source = models.CharField(max_length=10, choices=SERVICE_SOURCES, blank=True, null=True)
    remarks = models.TextField(blank=True, null=True)
    trail = models.CharField(max_length=120, blank=True, null=True)
    updated_trail = models.CharField(max_length=120, blank=True, null=True)

    class Meta:
        db_table = 'pharmacy_transactions'
        managed = False

    def __str__(self):
        return f"{self.transaction_type} - {self.medicine.medicine_name} ({self.qty})"


class OpdPrescription(models.Model):
    """OPD Prescriptions - matches pch.opd_prescription"""
    rx_id = models.AutoField(primary_key=True)
    order_id = models.IntegerField(blank=True, null=True)
    ltr_main_keyctr = models.IntegerField(blank=True, null=True)
    patient_id = models.IntegerField()
    medicine_id = models.IntegerField(blank=True, null=True)
    medicine_name_snapshot = models.CharField(max_length=120, blank=True, null=True)
    dosage = models.CharField(max_length=40, blank=True, null=True)
    frequency = models.CharField(max_length=40, blank=True, null=True)
    duration = models.CharField(max_length=40, blank=True, null=True)
    instructions = models.TextField(blank=True, null=True)

    class Meta:
        db_table = 'opd_prescription'
        managed = False


class PharmacyPurchaseRequest(models.Model):
    """Purchase requests - matches pch.pharmacy_purchase_requests exactly"""
    STATUS_CHOICES = [
        ('DRAFT', 'Draft'),
        ('SUBMITTED', 'Submitted'),
        ('APPROVED', 'Approved'),
        ('ON_DELIVERY', 'On Delivery'),
        ('DELIVERED', 'Delivered'),
        ('CANCELLED', 'Cancelled'),
    ]
    
    PURCHASE_TYPES = [
        ('REGULAR', 'Regular'),
        ('EMERGENCY', 'Emergency'),
    ]
    
    pr_id = models.AutoField(primary_key=True)
    pr_no = models.CharField(max_length=30, unique=True)
    requested_date = models.DateField(auto_now_add=True)
    purchase_type = models.CharField(max_length=10, choices=PURCHASE_TYPES, default='REGULAR')
    pr_status = models.CharField(max_length=15, choices=STATUS_CHOICES, default='DRAFT')
    expected_arrival_date = models.DateField(blank=True, null=True)
    cancel_reason = models.CharField(max_length=150, blank=True, null=True)
    updated_at = models.DateTimeField(auto_now=True)
    trail = models.CharField(max_length=120, blank=True, null=True)
    updated_trail = models.CharField(max_length=120, blank=True, null=True)

    class Meta:
        db_table = 'pharmacy_purchase_requests'
        managed = False

    def __str__(self):
        return f"PR #{self.pr_no}"


class PharmacyPurchaseRequestItem(models.Model):
    """Purchase request items - matches pch.pharmacy_purchase_request_items exactly"""
    MODULE_CHOICES = [
        ('PHARMACY', 'Pharmacy'),
        ('CENTRAL_SUPPLY', 'Central Supply'),
    ]
    
    ITEM_TYPES = [
        ('MEDICINE', 'Medicine'),
        ('SUPPLY', 'Supply'),
    ]
    
    pr_item_id = models.AutoField(primary_key=True)
    purchase_request = models.ForeignKey(PharmacyPurchaseRequest, on_delete=models.CASCADE, related_name='items', db_column='pr_id')
    requested_by_module = models.CharField(max_length=20, choices=MODULE_CHOICES)
    item_type = models.CharField(max_length=10, choices=ITEM_TYPES)
    medicine = models.ForeignKey(PharmacyMedicine, on_delete=models.CASCADE, null=True, blank=True)
    medicine_name = models.CharField(max_length=255, blank=True, null=True)  # For new medicines not in inventory
    medistock_item_id = models.BigIntegerField(null=True, blank=True)
    qty_requested = models.DecimalField(max_digits=12, decimal_places=2)
    unit_snapshot = models.CharField(max_length=20, blank=True, null=True)
    unit_cost_estimate = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    line_total_estimate = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    remarks = models.TextField(blank=True, null=True)
    trail = models.CharField(max_length=120, blank=True, null=True)

    class Meta:
        db_table = 'pharmacy_purchase_request_items'
        managed = False

    def __str__(self):
        if self.medicine:
            return f"{self.medicine.medicine_name} x {self.qty_requested}"
        return f"Item #{self.pr_item_id} x {self.qty_requested}"


class PharmacyGoodsReceipt(models.Model):
    """Goods receipts - matches pch.pharmacy_goods_receipts exactly"""
    STATUS_CHOICES = [
        ('RECEIVED', 'Received'),
    ]
    
    gr_id = models.AutoField(primary_key=True)
    gr_no = models.CharField(max_length=30, unique=True)
    pr = models.ForeignKey(PharmacyPurchaseRequest, on_delete=models.CASCADE)
    supplier = models.ForeignKey(PharmacySupplier, on_delete=models.CASCADE)
    received_at = models.DateTimeField(auto_now_add=True)
    status = models.CharField(max_length=15, choices=STATUS_CHOICES, default='RECEIVED')
    verified_by = models.IntegerField(null=True, blank=True)
    verified_at = models.DateTimeField(null=True, blank=True)
    remarks = models.TextField(blank=True, null=True)
    trail = models.CharField(max_length=120, blank=True, null=True)

    class Meta:
        db_table = 'pharmacy_goods_receipts'
        managed = False

    def __str__(self):
        return f"GR #{self.gr_no}"


class PharmacyGoodsReceiptItem(models.Model):
    """Goods receipt items - matches pch.pharmacy_goods_receipt_items exactly"""
    gr_item_id = models.AutoField(primary_key=True)
    goods_receipt = models.ForeignKey(PharmacyGoodsReceipt, on_delete=models.CASCADE, related_name='items')
    pr_item = models.ForeignKey(PharmacyPurchaseRequestItem, on_delete=models.CASCADE, null=True, blank=True)
    medicine = models.ForeignKey(PharmacyMedicine, on_delete=models.CASCADE)
    batch = models.ForeignKey(PharmacyStockBatch, on_delete=models.CASCADE)
    location = models.ForeignKey(PharmacyLocation, on_delete=models.CASCADE)
    qty_ordered = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    qty_received = models.DecimalField(max_digits=12, decimal_places=2)
    expiry_date = models.DateField()
    unit_cost_actual = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    line_total_actual = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    remarks = models.TextField(blank=True, null=True)
    trail = models.CharField(max_length=120, blank=True, null=True)

    class Meta:
        db_table = 'pharmacy_goods_receipt_items'
        managed = False


class PharmacyChargeSlip(models.Model):
    """Charge slips - matches pch.pharmacy_charge_slips exactly"""
    STATUS_CHOICES = [
        ('FOR_BILLING', 'For Billing'),
        ('PAID', 'Paid'),
        ('CANCELLED', 'Cancelled'),
    ]
    
    charge_slip_id = models.AutoField(primary_key=True)
    charge_slip_no = models.CharField(max_length=30, unique=True)
    rx_id = models.IntegerField()
    patient_id = models.IntegerField()
    status = models.CharField(max_length=15, choices=STATUS_CHOICES, default='FOR_BILLING')
    billing_paid_at = models.DateTimeField(null=True, blank=True)
    remarks = models.CharField(max_length=150, blank=True, null=True)
    trail = models.CharField(max_length=120, blank=True, null=True)
    updated_trail = models.CharField(max_length=120, blank=True, null=True)

    class Meta:
        db_table = 'pharmacy_charge_slips'
        managed = False

    def __str__(self):
        return f"CS #{self.charge_slip_no}"


class PharmacyChargeSlipItem(models.Model):
    """Charge slip items - matches pch.pharmacy_charge_slip_items exactly"""
    charge_slip_item_id = models.AutoField(primary_key=True)
    charge_slip = models.ForeignKey(PharmacyChargeSlip, on_delete=models.CASCADE, related_name='items')
    medicine = models.ForeignKey(PharmacyMedicine, on_delete=models.CASCADE)
    qty = models.DecimalField(max_digits=12, decimal_places=2)
    unit_cost = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    line_total = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    trail = models.CharField(max_length=120, blank=True, null=True)

    class Meta:
        db_table = 'pharmacy_charge_slip_items'
        managed = False


class PharmacyDispenseReceipt(models.Model):
    """Dispense receipts - matches pch.pharmacy_dispense_receipts exactly"""
    STATUS_CHOICES = [
        ('PENDING', 'Pending'),
        ('RECEIVED', 'Received'),
        ('CANCELLED', 'Cancelled'),
    ]
    
    receipt_id = models.AutoField(primary_key=True)
    receipt_no = models.CharField(max_length=30, unique=True)
    ipd_dispensing_id = models.IntegerField(null=True, blank=True)
    ipd_cart_form_id = models.IntegerField(null=True, blank=True)
    admission_id = models.IntegerField(null=True, blank=True) # Altered to allow NULL in SQL turn
    patient = models.ForeignKey('opd.PatientProfiling', on_delete=models.CASCADE, db_column='patient_id')
    from_location_id = models.IntegerField(default=1)
    dispensing_date = models.DateField(auto_now_add=True)
    charge_slip_no = models.CharField(max_length=20, blank=True, null=True)
    total_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    received_status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='RECEIVED')
    dispensed_by = models.IntegerField(null=True, blank=True)
    remarks = models.TextField(blank=True, null=True)
    trail = models.TextField(blank=True, null=True)
    updated_trail = models.CharField(max_length=120, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'pharmacy_dispense_receipts'
        managed = False

    def __str__(self):
        return f"Receipt #{self.receipt_no}"


class PharmacyDispenseReceiptItem(models.Model):
    """Dispense receipt items - matches pch.pharmacy_dispense_receipt_items exactly"""
    receipt_item_id = models.AutoField(primary_key=True)
    dispense_receipt = models.ForeignKey(PharmacyDispenseReceipt, on_delete=models.CASCADE, related_name='items', db_column='receipt_id')
    medicine = models.ForeignKey(PharmacyMedicine, on_delete=models.CASCADE, null=True, blank=True, db_column='medicine_id')
    supply_id = models.IntegerField(null=True, blank=True)
    item_type = models.CharField(max_length=20, null=True, blank=True)
    item_code = models.CharField(max_length=30)
    item_description = models.CharField(max_length=255, blank=True, null=True)
    quantity = models.DecimalField(max_digits=12, decimal_places=2)
    unit = models.CharField(max_length=20, blank=True, null=True)
    unit_cost = models.DecimalField(max_digits=12, decimal_places=2)
    total_cost = models.DecimalField(max_digits=12, decimal_places=2)
    batch_id = models.IntegerField(null=True, blank=True)
    from_location_id = models.IntegerField(null=True, blank=True)
    line_status = models.CharField(max_length=15, default='DISPENSED')
    remarks = models.TextField(blank=True, null=True)
    trail = models.CharField(max_length=120, blank=True, null=True)

    class Meta:
        db_table = 'pharmacy_dispense_receipt_items'
        managed = False


class PharmacyInventoryAdjustment(models.Model):
    """Inventory adjustments - matches pch.pharmacy_inventory_adjustments exactly"""
    ADJUSTMENT_TYPES = [
        ('DAMAGED', 'Damaged'),
        ('EXPIRED', 'Expired'),
        ('DISPOSED', 'Disposed'),
        ('COUNT_VARIANCE', 'Count Variance'),
        ('RETURN', 'Return'),
    ]
    
    adj_id = models.AutoField(primary_key=True)
    adj_type = models.CharField(max_length=20, choices=ADJUSTMENT_TYPES)
    location = models.ForeignKey(PharmacyLocation, on_delete=models.CASCADE)
    remarks = models.TextField(blank=True, null=True)
    trail = models.CharField(max_length=120, blank=True, null=True)
    updated_trail = models.CharField(max_length=120, blank=True, null=True)

    class Meta:
        db_table = 'pharmacy_inventory_adjustments'
        managed = False

    def __str__(self):
        return f"Adjustment {self.adj_id} - {self.adj_type}"


class PharmacyInventoryAdjustmentItem(models.Model):
    """Inventory adjustment items - matches pch.pharmacy_inventory_adjustment_items exactly"""
    adj_item_id = models.AutoField(primary_key=True)
    adjustment = models.ForeignKey(PharmacyInventoryAdjustment, on_delete=models.CASCADE, related_name='items')
    medicine = models.ForeignKey(PharmacyMedicine, on_delete=models.CASCADE)
    batch = models.ForeignKey(PharmacyStockBatch, on_delete=models.CASCADE)
    qty = models.DecimalField(max_digits=12, decimal_places=2)
    trail = models.CharField(max_length=120, blank=True, null=True)

    class Meta:
        db_table = 'pharmacy_inventory_adjustment_items'
        managed = False


class PharmacySupplyPrice(models.Model):
    """Supply pricing set by pharmacist - matches pch.pharmacy_supply_price exactly"""
    price_id = models.AutoField(primary_key=True)
    supply_id = models.IntegerField()
    batch_id = models.IntegerField(null=True, blank=True)
    unit_price = models.DecimalField(max_digits=12, decimal_places=2)
    effective_date = models.DateField()
    is_active = models.BooleanField(default=True)
    set_by_id = models.IntegerField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'pharmacy_supply_price'
        managed = False

    def __str__(self):
        return f"Supply {self.supply_id} @ ₱{self.unit_price}"
