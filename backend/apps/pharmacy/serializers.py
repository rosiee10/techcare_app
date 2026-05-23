from rest_framework import serializers
from .models import (
    PharmacySupplier, PharmacyLocation, PharmacyMedicine, PharmacyStockBatch,
    PharmacyInventoryBalance, PharmacyPurchaseRequest, PharmacyPurchaseRequestItem,
    PharmacyGoodsReceipt, PharmacyGoodsReceiptItem,
    PharmacyChargeSlip, PharmacyChargeSlipItem, PharmacyDispenseReceipt,
    PharmacyDispenseReceiptItem, PharmacyInventoryAdjustment, PharmacyInventoryAdjustmentItem,
    PharmacyTransaction, OpdPrescription
)


class PharmacySupplierSerializer(serializers.ModelSerializer):
    class Meta:
        model = PharmacySupplier
        fields = '__all__'
        read_only_fields = ['trail']


class PharmacyLocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = PharmacyLocation
        fields = '__all__'
        read_only_fields = ['trail']


class PharmacyMedicineSerializer(serializers.ModelSerializer):
    """Serializer for PharmacyMedicine - matches database schema exactly"""
    class Meta:
        model = PharmacyMedicine
        fields = ['medicine_id', 'medicine_code', 'medicine_name', 'category', 
                  'unit', 'reorder_level', 'unit_cost', 'is_active', 'trail']
        read_only_fields = ['trail']
        
    def to_representation(self, instance):
        """Ensure unit_cost is always returned as a number"""
        data = super().to_representation(instance)
        # Convert Decimal to float for JSON serialization
        if data.get('unit_cost') is not None:
            data['unit_cost'] = float(data['unit_cost'])
        return data


class PharmacyStockBatchSerializer(serializers.ModelSerializer):
    """Serializer for PharmacyStockBatch - matches database schema"""
    medicine_name = serializers.SerializerMethodField()
    quantity = serializers.SerializerMethodField()
    initial_qty = serializers.FloatField(write_only=True, required=False, default=0.0)
    
    class Meta:
        model = PharmacyStockBatch
        fields = ['batch_id', 'medicine', 'medicine_name', 'batch_no', 
                  'expiry_date', 'received_date', 'unit_cost', 'initial_qty', 'quantity', 'trail']
        read_only_fields = ['trail']
    
    def get_medicine_name(self, obj):
        if obj.medicine:
            return obj.medicine.medicine_name
        return None
    
    def get_quantity(self, obj):
        """Get total quantity from PHARMACY location only (not CART)"""
        from django.db.models import Sum
        # Filter inventory balance to only include PHARMACY locations, not CART
        total_qty = PharmacyInventoryBalance.objects.filter(
            batch=obj,
            location__location_type='PHARMACY'
        ).aggregate(total=Sum('qty_on_hand'))['total'] or 0
        return float(total_qty)


class PharmacyInventoryBalanceSerializer(serializers.ModelSerializer):
    """Serializer for PharmacyInventoryBalance - matches database schema"""
    medicine_name = serializers.SerializerMethodField()
    batch_no = serializers.SerializerMethodField()
    location_name = serializers.SerializerMethodField()
    expiry_date = serializers.SerializerMethodField()
    received_date = serializers.SerializerMethodField()
    unit = serializers.SerializerMethodField()
    unit_cost = serializers.SerializerMethodField()
    
    class Meta:
        model = PharmacyInventoryBalance
        fields = ['medicine', 'medicine_name', 'batch', 'batch_no', 
                  'location', 'location_name', 'qty_on_hand',
                  'expiry_date', 'received_date', 'unit', 'unit_cost', 'trail']
        read_only_fields = ['trail']
    
    def get_medicine_name(self, obj):
        if obj.medicine:
            return obj.medicine.medicine_name
        return None
    
    def get_batch_no(self, obj):
        if obj.batch:
            return obj.batch.batch_no
        return None
    
    def get_expiry_date(self, obj):
        if obj.batch:
            return obj.batch.expiry_date.isoformat() if obj.batch.expiry_date else None
        return None
    
    def get_received_date(self, obj):
        if obj.batch:
            return obj.batch.received_date.isoformat() if obj.batch.received_date else None
        return None
    
    def get_location_name(self, obj):
        if obj.location:
            return obj.location.location_name
        return None
    
    def get_unit(self, obj):
        if hasattr(obj, 'unit'):
            return obj.unit
        if obj.medicine:
            return obj.medicine.unit
        return None
        
    def get_unit_cost(self, obj):
        if hasattr(obj, 'unit_cost'):
            return float(obj.unit_cost) if obj.unit_cost else 0.0
        if obj.batch:
            return float(obj.batch.unit_cost) if obj.batch.unit_cost else 0.0
        return 0.0
    
    def create(self, validated_data):
        # Use raw SQL for composite key table
        # Handle both integer IDs and model objects
        medicine_val = validated_data['medicine']
        batch_val = validated_data['batch']
        location_val = validated_data['location']
        
        # Extract IDs
        medicine_id = medicine_val.medicine_id if hasattr(medicine_val, 'medicine_id') else medicine_val
        batch_id = batch_val.batch_id if hasattr(batch_val, 'batch_id') else batch_val
        location_id = location_val.location_id if hasattr(location_val, 'location_id') else location_val
        qty_on_hand = validated_data['qty_on_hand']
        
        # Insert into database
        from django.db import connection
        with connection.cursor() as cursor:
            cursor.execute(
                """INSERT INTO pharmacy_inventory_balance (medicine_id, batch_id, location_id, qty_on_hand)
                   VALUES (%s, %s, %s, %s)
                   ON CONFLICT (medicine_id, batch_id, location_id) 
                   DO UPDATE SET qty_on_hand = EXCLUDED.qty_on_hand""",
                [medicine_id, batch_id, location_id, qty_on_hand]
            )
        
        # Fetch related objects for the return instance
        from .models import PharmacyMedicine, PharmacyStockBatch, PharmacyLocation
        try:
            medicine = PharmacyMedicine.objects.get(pk=medicine_id)
        except:
            medicine = None
        try:
            batch = PharmacyStockBatch.objects.get(pk=batch_id)
        except:
            batch = None
        try:
            location = PharmacyLocation.objects.get(pk=location_id)
        except:
            location = None
        
        # Create instance without saving (mock for response)
        instance = PharmacyInventoryBalance(
            medicine=medicine,
            batch=batch,
            location=location,
            qty_on_hand=qty_on_hand
        )
        # Prevent Django from trying to save this mock instance
        instance.pk = medicine_id  # Set primary key so it looks like saved instance
        return instance


class PharmacyPurchaseRequestItemSerializer(serializers.ModelSerializer):
    """Serializer for PharmacyPurchaseRequestItem"""
    medicine_name_display = serializers.SerializerMethodField()
    goods_receipt_item = serializers.SerializerMethodField()
    
    class Meta:
        model = PharmacyPurchaseRequestItem
        fields = '__all__'
        read_only_fields = ['trail']
    
    def get_medicine_name_display(self, obj):
        # Return medicine_name field if set (for new medicines not in inventory)
        if obj.medicine_name:
            return obj.medicine_name
        # Otherwise return name from related medicine
        if obj.medicine:
            return obj.medicine.medicine_name
        return None
    
    def get_goods_receipt_item(self, obj):
        """Get the related goods receipt item if it exists using raw SQL"""
        try:
            from django.db import connection
            with connection.cursor() as cursor:
                cursor.execute("""
                    SELECT qty_received, unit_cost_actual, line_total_actual
                    FROM pharmacy_goods_receipt_items
                    WHERE pr_item_id = %s
                    LIMIT 1
                """, [obj.pr_item_id])
                row = cursor.fetchone()
                if row:
                    return {
                        'qty_received': float(row[0]) if row[0] is not None else None,
                        'unit_cost_actual': float(row[1]) if row[1] is not None else None,
                        'line_total_actual': float(row[2]) if row[2] is not None else None,
                    }
                else:
                    print(f"No goods receipt item found for PR item {obj.pr_item_id}")
        except Exception as e:
            print(f"Error fetching goods receipt item for PR item {obj.pr_item_id}: {e}")
        return None


class PharmacyPurchaseRequestSerializer(serializers.ModelSerializer):
    """Serializer for PharmacyPurchaseRequest with nested items"""
    items = PharmacyPurchaseRequestItemSerializer(many=True, read_only=True)
    
    class Meta:
        model = PharmacyPurchaseRequest
        fields = '__all__'
        extra_kwargs = {
            'pr_no': {'required': False, 'allow_blank': True},
        }
        read_only_fields = ['trail', 'updated_trail']
    
    def create(self, validated_data):
        # Get context to access request
        request = self.context.get('request')
        from .utils import format_trail, get_client_ip
        
        # Get items from initial_data since items field is read_only
        items_data = self.initial_data.get('items', [])
        
        # Auto-generate PR number if not provided or empty (format: PR-001, PR-002, etc.)
        pr_no = validated_data.get('pr_no')
        if not pr_no or pr_no == '':
            # Get the latest PR by pr_id (most recently created)
            latest_pr = PharmacyPurchaseRequest.objects.order_by('-pr_id').first()
            
            if latest_pr and latest_pr.pr_no:
                # Extract digits from PR number (e.g., PR-001 → 1, PR-123 → 123)
                import re
                digits = re.findall(r'\d+', latest_pr.pr_no)
                if digits:
                    last_num = int(digits[-1])
                    new_num = last_num + 1
                else:
                    new_num = 1
            else:
                new_num = 1
            
            validated_data['pr_no'] = f'PR-{new_num:03d}'
        
        # Auto-set requested_date to today if not provided
        if not validated_data.get('requested_date'):
            from datetime import date
            validated_data['requested_date'] = date.today()

        # Extract medistock_pr_id if present (CSD-linked PR)
        medistock_pr_id = validated_data.pop('medistock_pr_id', None)
        if medistock_pr_id:
            validated_data['cancel_reason'] = f'CSD_ORIGIN:{medistock_pr_id}'

        # Set trail and updated_trail
        if request:
            trail_value = format_trail(request.user, get_client_ip(request))
            validated_data['trail'] = trail_value
            validated_data['updated_trail'] = trail_value

        purchase_request = PharmacyPurchaseRequest.objects.create(**validated_data)
        
        # Create items
        print(f"DEBUG: Creating {len(items_data)} items for PR {purchase_request.pr_no}")
        if items_data:
            for item_data in items_data:
                medicine_name = item_data.get('medicine_name', '')
                print(f"DEBUG: Looking up medicine: {medicine_name}")

                # Try to find medicine in inventory
                medicine = None
                if medicine_name:
                    medicine = PharmacyMedicine.objects.filter(
                        medicine_name__iexact=medicine_name
                    ).first()

                # If medicine not found, auto-create it ONLY for non-CSD items
                # CSD-derived items should not auto-create medicines to avoid
                # polluting the pharmacy inventory with non-medicine supplies
                if not medicine and medicine_name and not medistock_pr_id:
                    # Generate medicine code from first 4 letters of first word (uppercase)
                    first_word = medicine_name.split()[0] if medicine_name else ''
                    medicine_code = first_word[:4].upper() if first_word else 'MED'
                    if len(medicine_code) < 3:  # Ensure at least 3 characters
                        medicine_code = medicine_code.ljust(3, 'X')

                    # Get unit cost from purchase price (default 0 if not provided)
                    unit_cost = item_data.get('unit_price', 0)
                    category = item_data.get('category', 'Uncategorized')
                    if not category or category == '':
                        category = 'Uncategorized'

                    medicine = PharmacyMedicine.objects.create(
                        medicine_name=medicine_name,
                        medicine_code=medicine_code,
                        unit=item_data.get('unit', 'Piece'),
                        category=category,
                        reorder_level=100,  # Default reorder level
                        unit_cost=unit_cost,  # Store the purchase unit price
                        is_active=True
                    )
                    print(f"DEBUG: Auto-created new medicine: {medicine.medicine_id} with code {medicine_code}")

                print(f"DEBUG: Found/Created medicine: {medicine}")

                # Build remarks
                remarks = item_data.get('remarks', '')

                # Determine module and item type based on CSD origin
                if medistock_pr_id:
                    requested_by_module = 'CENTRAL_SUPPLY'
                    item_type = 'SUPPLY'
                else:
                    requested_by_module = 'PHARMACY'
                    item_type = 'MEDICINE'

                # Create the item with proper field mapping
                item = PharmacyPurchaseRequestItem.objects.create(
                    purchase_request=purchase_request,
                    medicine=medicine,  # Can be null for new medicines
                    medicine_name=medicine_name,  # Always store medicine name
                    requested_by_module=requested_by_module,
                    item_type=item_type,
                    qty_requested=item_data.get('quantity', 0),
                    unit_snapshot=item_data.get('unit', ''),
                    unit_cost_estimate=item_data.get('unit_price', 0),
                    line_total_estimate=item_data.get('total_price', 0),
                    remarks=remarks if remarks else None,
                    trail=trail_value if request else None
                )
                print(f"DEBUG: Created item: {item.pr_item_id}")
        
        return purchase_request


class PharmacyGoodsReceiptItemSerializer(serializers.ModelSerializer):
    """Serializer for PharmacyGoodsReceiptItem"""
    medicine_name = serializers.SerializerMethodField()
    
    class Meta:
        model = PharmacyGoodsReceiptItem
        fields = '__all__'
        read_only_fields = ['trail']
    
    def get_medicine_name(self, obj):
        if obj.medicine:
            return obj.medicine.medicine_name
        return None


class PharmacyGoodsReceiptSerializer(serializers.ModelSerializer):
    """Serializer for PharmacyGoodsReceipt"""
    items = PharmacyGoodsReceiptItemSerializer(many=True, read_only=True)
    
    class Meta:
        model = PharmacyGoodsReceipt
        fields = '__all__'
        read_only_fields = ['trail']


class PharmacyChargeSlipItemSerializer(serializers.ModelSerializer):
    """Serializer for PharmacyChargeSlipItem"""
    medicine_name = serializers.SerializerMethodField()
    
    class Meta:
        model = PharmacyChargeSlipItem
        fields = '__all__'
        read_only_fields = ['trail']
    
    def get_medicine_name(self, obj):
        if obj.medicine:
            return obj.medicine.medicine_name
        return None


class PharmacyChargeSlipSerializer(serializers.ModelSerializer):
    """Serializer for PharmacyChargeSlip"""
    items = PharmacyChargeSlipItemSerializer(many=True, read_only=True)
    
    class Meta:
        model = PharmacyChargeSlip
        fields = '__all__'
        read_only_fields = ['trail', 'updated_trail']


class PharmacyDispenseReceiptItemSerializer(serializers.ModelSerializer):
    """Serializer for PharmacyDispenseReceiptItem"""
    medicine_name = serializers.CharField(source='medicine.medicine_name', read_only=True)
    
    class Meta:
        model = PharmacyDispenseReceiptItem
        fields = '__all__'
        read_only_fields = ['trail']


class PharmacyDispenseReceiptSerializer(serializers.ModelSerializer):
    """Serializer for PharmacyDispenseReceipt"""
    items = PharmacyDispenseReceiptItemSerializer(many=True, read_only=True)
    patient_name = serializers.CharField(source='patient.__str__', read_only=True)
    patient_hospital_id = serializers.CharField(source='patient.hospital_id', read_only=True)
    ward = serializers.SerializerMethodField()
    
    class Meta:
        model = PharmacyDispenseReceipt
        fields = '__all__'
        read_only_fields = ['trail', 'updated_trail']

    def get_ward(self, obj):
        # We need to find the ward from the admission_id (Notice of Admission)
        if obj.admission_id:
            try:
                from apps.ipd.inventory_and_request.models import IpdNoticeOfAdmission
                admission = IpdNoticeOfAdmission.objects.get(pk=obj.admission_id)
                return admission.department or "IPD Ward"
            except:
                pass
        return "IPD Ward"


class PharmacyInventoryAdjustmentItemSerializer(serializers.ModelSerializer):
    """Serializer for PharmacyInventoryAdjustmentItem"""
    medicine_name = serializers.SerializerMethodField()
    
    class Meta:
        model = PharmacyInventoryAdjustmentItem
        fields = '__all__'
        read_only_fields = ['trail']
    
    def get_medicine_name(self, obj):
        if obj.medicine:
            return obj.medicine.medicine_name
        return None


class PharmacyInventoryAdjustmentSerializer(serializers.ModelSerializer):
    """Serializer for PharmacyInventoryAdjustment"""
    items = PharmacyInventoryAdjustmentItemSerializer(many=True, read_only=True)
    
    class Meta:
        model = PharmacyInventoryAdjustment
        fields = '__all__'
        read_only_fields = ['trail', 'updated_trail']


class PharmacyTransactionSerializer(serializers.ModelSerializer):
    """Serializer for PharmacyTransaction"""
    medicine_name = serializers.SerializerMethodField()
    
    class Meta:
        model = PharmacyTransaction
        fields = '__all__'
        read_only_fields = ['trail', 'updated_trail']
    
    def get_medicine_name(self, obj):
        if obj.medicine:
            return obj.medicine.medicine_name
        return None


# Custom serializers for dashboard stats
class DashboardStatsSerializer(serializers.Serializer):
    total_medicines = serializers.IntegerField()
    low_stock_count = serializers.IntegerField()
    expiring_soon = serializers.IntegerField()
    pending_prs = serializers.IntegerField()
    today_dispensed = serializers.IntegerField(required=False, default=0)
    pending_dispensing_sheets = serializers.ListField(
        child=serializers.DictField(), required=False, default=list
    )
    approved_prs = serializers.ListField(
        child=serializers.DictField(), required=False, default=list
    )
    low_stock_alerts = serializers.ListField(
        child=serializers.DictField(), required=False, default=list
    )
    expiry_alerts = serializers.ListField(
        child=serializers.DictField(), required=False, default=list
    )


class LowStockAlertSerializer(serializers.Serializer):
    medicine_id = serializers.IntegerField()
    medicine_name = serializers.CharField()
    current_stock = serializers.IntegerField()
    reorder_level = serializers.IntegerField()


class ExpiryAlertSerializer(serializers.Serializer):
    batch_id = serializers.IntegerField()
    medicine_name = serializers.CharField()
    batch_no = serializers.CharField()
    expiry_date = serializers.DateField()
    days_until_expiry = serializers.IntegerField()


class SuccessResponseSerializer(serializers.Serializer):
    success = serializers.BooleanField()
    message = serializers.CharField()
    data = serializers.DictField(required=False)


class ForecastingStatsSerializer(serializers.Serializer):
    high_demand_count = serializers.IntegerField()
    medium_demand_count = serializers.IntegerField()
    low_demand_count = serializers.IntegerField()
    critical_stock_count = serializers.IntegerField()
    top_dispensed = serializers.ListField(child=serializers.DictField())
    demand_trends = serializers.DictField()
    monthly_distribution = serializers.ListField(child=serializers.DictField())
    stock_analysis = serializers.DictField()
    forecast_table = serializers.ListField(child=serializers.DictField())


class OpdPrescriptionSerializer(serializers.ModelSerializer):
    """Serializer for OPD Prescriptions"""
    patient_name = serializers.SerializerMethodField()
    
    class Meta:
        model = OpdPrescription
        fields = '__all__'
    
    def get_patient_name(self, obj):
        from apps.opd.models import PatientProfiling
        try:
            patient = PatientProfiling.objects.get(patient_id=obj.patient_id)
            return f"{patient.firstname} {patient.lastname}"
        except PatientProfiling.DoesNotExist:
            return 'Unknown'
