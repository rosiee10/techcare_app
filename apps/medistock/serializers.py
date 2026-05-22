from rest_framework import serializers
from apps.pharmacy.models import PharmacyPurchaseRequest, PharmacyPurchaseRequestItem
from .models import (
    MedistockCategory, MedistockUnit, MedistockDepartment, MedistockLocation,
    MedistockSupplyItem, MedistockSupplyBatch, MedistockInventoryBalance,
    MedistockGoodsReceipt, MedistockGoodsReceiptItem,
    MedistockSupplyRequest, MedistockSupplyRequestItem,
    MedistockTransaction, MedistockReport,
    MedistockPurchaseRequest, MedistockPurchaseRequestItem,
    MedistockVStockSummary, MedistockVLowStock, MedistockVExpiryAlert,
    MedistockVMonthlyConsumption, MedistockVPendingRequest,
    MedistockVCartItem, MedistockVStockCard,
)


class MedistockCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = MedistockCategory
        fields = ['category_id', 'category_name', 'description', 'is_active', 'created_at']


class MedistockUnitSerializer(serializers.ModelSerializer):
    class Meta:
        model = MedistockUnit
        fields = ['unit_id', 'unit_name', 'unit_abbreviation', 'is_active', 'created_at']


class MedistockDepartmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = MedistockDepartment
        fields = ['department_id', 'department_name', 'department_code', 'is_active', 'created_at']


class MedistockLocationSerializer(serializers.ModelSerializer):
    department_name = serializers.CharField(source='department.department_name', read_only=True)

    class Meta:
        model = MedistockLocation
        fields = ['location_id', 'location_name', 'location_type', 'department', 'department_name', 'is_active', 'created_at']


class MedistockSupplyItemSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source='category.category_name', read_only=True)
    unit_name = serializers.CharField(source='unit.unit_name', read_only=True)
    unit_abbreviation = serializers.CharField(source='unit.unit_abbreviation', read_only=True)

    class Meta:
        model = MedistockSupplyItem
        fields = ['supply_id', 'supply_code', 'supply_name', 'category', 'category_name',
                  'unit', 'unit_name', 'unit_abbreviation', 'reorder_level', 'unit_cost',
                  'is_active', 'created_at', 'updated_at']


class MedistockSupplyBatchSerializer(serializers.ModelSerializer):
    supply_name = serializers.CharField(source='supply.supply_name', read_only=True)

    class Meta:
        model = MedistockSupplyBatch
        fields = ['batch_id', 'supply', 'supply_name', 'batch_no', 'expiry_date',
                  'received_date', 'unit_cost', 'supplier_name', 'created_at']


class MedistockInventoryBalanceSerializer(serializers.ModelSerializer):
    supply_name = serializers.CharField(source='supply.supply_name', read_only=True)
    category_name = serializers.CharField(source='supply.category.category_name', read_only=True)
    unit_name = serializers.CharField(source='supply.unit.unit_name', read_only=True)
    location_name = serializers.CharField(source='location.location_name', read_only=True)
    location_type = serializers.CharField(source='location.location_type', read_only=True)
    batch_no = serializers.CharField(source='batch.batch_no', read_only=True)
    expiry_date = serializers.DateField(source='batch.expiry_date', read_only=True)
    reorder_level = serializers.DecimalField(source='supply.reorder_level', max_digits=12, decimal_places=2, read_only=True)

    class Meta:
        model = MedistockInventoryBalance
        fields = ['balance_id', 'supply', 'supply_name', 'category_name', 'unit_name',
                  'batch', 'batch_no', 'expiry_date', 'location', 'location_name',
                  'location_type', 'qty_on_hand', 'reorder_level', 'created_at', 'updated_at']


class MedistockGoodsReceiptSerializer(serializers.ModelSerializer):
    pr_no = serializers.CharField(source='pr.pr_no', read_only=True)
    pr_status = serializers.CharField(source='pr.pr_status', read_only=True)

    class Meta:
        model = MedistockGoodsReceipt
        fields = ['gr_id', 'gr_no', 'pr', 'pr_no', 'pr_status', 'supplier_name',
                  'received_date', 'status', 'verified_by', 'remarks', 'created_at']


class MedistockSupplyRequestItemSerializer(serializers.ModelSerializer):
    supply_name = serializers.CharField(source='supply.supply_name', read_only=True)
    unit_name = serializers.CharField(source='unit.unit_name', read_only=True)

    class Meta:
        model = MedistockSupplyRequestItem
        fields = ['request_item_id', 'request', 'supply', 'supply_name', 'item_name',
                  'qty_requested', 'qty_approved', 'qty_dispensed', 'batch',
                  'unit', 'unit_name', 'status', 'remarks', 'created_at']


class MedistockSupplyRequestSerializer(serializers.ModelSerializer):
    source_department_name = serializers.CharField(source='source_department.department_name', read_only=True)
    patient_firstname = serializers.CharField(source='patient.firstname', read_only=True)
    patient_lastname = serializers.CharField(source='patient.lastname', read_only=True)
    patient_hospital_id = serializers.CharField(source='patient.hospital_id', read_only=True)
    items = MedistockSupplyRequestItemSerializer(many=True, read_only=True)
    items_count = serializers.SerializerMethodField()

    class Meta:
        model = MedistockSupplyRequest
        fields = ['request_id', 'request_no', 'source_module', 'source_department',
                  'source_department_name', 'requested_by_name', 'request_date',
                  'required_date', 'status', 'patient', 'patient_firstname',
                  'patient_lastname', 'patient_hospital_id', 'patient_name', 'purpose',
                  'approved_by', 'approved_at', 'completed_at', 'remarks',
                  'created_at', 'updated_at', 'items', 'items_count']

    def get_items_count(self, obj):
        return obj.items.count()


class MedistockSupplyRequestListSerializer(serializers.ModelSerializer):
    source_department_name = serializers.CharField(source='source_department.department_name', read_only=True)
    patient_firstname = serializers.CharField(source='patient.firstname', read_only=True)
    patient_lastname = serializers.CharField(source='patient.lastname', read_only=True)
    items_count = serializers.SerializerMethodField()

    class Meta:
        model = MedistockSupplyRequest
        fields = ['request_id', 'request_no', 'source_module', 'source_department_name',
                  'requested_by_name', 'request_date', 'status', 'patient',
                  'patient_firstname', 'patient_lastname', 'patient_name', 'items_count']

    def get_items_count(self, obj):
        return obj.items.count()


class MedistockTransactionSerializer(serializers.ModelSerializer):
    supply_name = serializers.CharField(source='supply.supply_name', read_only=True)
    batch_no = serializers.CharField(source='batch.batch_no', read_only=True)
    from_location_name = serializers.CharField(source='from_location.location_name', read_only=True)
    to_location_name = serializers.CharField(source='to_location.location_name', read_only=True)
    department_name = serializers.CharField(source='department.department_name', read_only=True)
    patient_firstname = serializers.CharField(source='patient.firstname', read_only=True)
    patient_lastname = serializers.CharField(source='patient.lastname', read_only=True)

    class Meta:
        model = MedistockTransaction
        fields = ['transaction_id', 'transaction_datetime', 'transaction_type',
                  'supply', 'supply_name', 'batch', 'batch_no',
                  'from_location', 'from_location_name', 'to_location', 'to_location_name',
                  'qty', 'reference_type', 'reference_id', 'source_module',
                  'patient', 'patient_firstname', 'patient_lastname',
                  'patient_name', 'requested_by', 'department', 'department_name',
                  'remarks', 'created_at']


class MedistockReportSerializer(serializers.ModelSerializer):
    class Meta:
        model = MedistockReport
        fields = ['report_id', 'report_type', 'period_type', 'date_from', 'date_to',
                  'generated_by', 'generated_at', 'file_path', 'parameters', 'created_at']


# ── View Serializers (read-only) ─────────────────────────────────────────────

class MedistockVStockSummarySerializer(serializers.ModelSerializer):
    class Meta:
        model = MedistockVStockSummary
        fields = ['supply_id', 'supply_code', 'supply_name', 'category', 'unit',
                  'reorder_level', 'total_stock', 'main_stock', 'cart_stock', 'stock_status']


class MedistockVLowStockSerializer(serializers.ModelSerializer):
    class Meta:
        model = MedistockVLowStock
        fields = ['supply_id', 'supply_name', 'category', 'reorder_level', 'current_stock']


class MedistockVExpiryAlertSerializer(serializers.ModelSerializer):
    class Meta:
        model = MedistockVExpiryAlert
        fields = ['batch_id', 'batch_no', 'expiry_date', 'supply_id', 'supply_name',
                  'category', 'location_name', 'qty_on_hand', 'days_remaining']


class MedistockVMonthlyConsumptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = MedistockVMonthlyConsumption
        fields = ['supply_id', 'month', 'supply_name', 'category', 'consumed', 'tx_count']


class MedistockVPendingRequestSerializer(serializers.ModelSerializer):
    class Meta:
        model = MedistockVPendingRequest
        fields = ['request_id', 'request_no', 'source_module', 'source_department',
                  'status', 'patient_name', 'request_date', 'item_count', 'total_qty_requested']


class MedistockVCartItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = MedistockVCartItem
        fields = ['supply_id', 'supply_name', 'category', 'unit', 'location_id',
                  'location_name', 'location_type', 'batch_count', 'total_qty', 'nearest_expiry']


class MedistockVStockCardSerializer(serializers.ModelSerializer):
    class Meta:
        model = MedistockVStockCard
        fields = ['transaction_id', 'transaction_datetime', 'transaction_type',
                  'supply_name', 'batch_no', 'qty', 'from_location', 'to_location',
                  'reference_type', 'reference_id', 'patient_name', 'requested_by',
                  'department', 'remarks', 'source_module']


# ── Purchase Request (CSD → Pharmacy) ────────────────────────────────────────

class MedistockPRItemSerializer(serializers.ModelSerializer):
    supply_name = serializers.CharField(source='supply.supply_name', read_only=True)

    class Meta:
        model = MedistockPurchaseRequestItem
        fields = ['pr_item_id', 'supply', 'supply_name', 'qty_requested',
                  'unit_snapshot', 'unit_cost_estimate', 'line_total_estimate', 'remarks']


class MedistockPRSerializer(serializers.ModelSerializer):
    items = MedistockPRItemSerializer(many=True, read_only=True)
    items_count = serializers.SerializerMethodField()
    total_amount = serializers.SerializerMethodField()

    class Meta:
        model = MedistockPurchaseRequest
        fields = ['pr_id', 'pr_no', 'pr_date', 'purchase_type', 'fund', 'lgu',
                  'department', 'section', 'pr_status', 'updated_at', 'requested_by', 
                  'expected_arrival_date', 'cancel_reason', 'total_amount', 'remarks', 
                  'items', 'items_count']

    def get_items_count(self, obj):
        return obj.items.count()

    def get_total_amount(self, obj):
        return float(sum(float(i.line_total_estimate or 0) for i in obj.items.all()))


class MedistockPRListSerializer(serializers.ModelSerializer):
    items_count = serializers.SerializerMethodField()
    total_amount = serializers.SerializerMethodField()

    class Meta:
        model = MedistockPurchaseRequest
        fields = ['pr_id', 'pr_no', 'pr_date', 'purchase_type', 'fund', 'lgu',
                  'pr_status', 'updated_at', 'requested_by', 'total_amount', 'items_count']

    def get_items_count(self, obj):
        return obj.items.count()

    def get_total_amount(self, obj):
        return float(sum(float(i.line_total_estimate or 0) for i in obj.items.all()))
