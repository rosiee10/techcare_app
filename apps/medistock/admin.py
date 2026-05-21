from django.contrib import admin
from .models import (
    MedistockCategory, MedistockUnit, MedistockDepartment, MedistockLocation,
    MedistockSupplyItem, MedistockSupplyBatch, MedistockInventoryBalance,
    MedistockGoodsReceipt, MedistockSupplyRequest, MedistockSupplyRequestItem,
    MedistockTransaction, MedistockReport,
)


@admin.register(MedistockCategory)
class MedistockCategoryAdmin(admin.ModelAdmin):
    list_display = ['category_id', 'category_name', 'description', 'is_active']
    search_fields = ['category_name']
    list_filter = ['is_active']


@admin.register(MedistockUnit)
class MedistockUnitAdmin(admin.ModelAdmin):
    list_display = ['unit_id', 'unit_name', 'unit_abbreviation', 'is_active']
    search_fields = ['unit_name']


@admin.register(MedistockDepartment)
class MedistockDepartmentAdmin(admin.ModelAdmin):
    list_display = ['department_id', 'department_name', 'department_code', 'is_active']
    search_fields = ['department_name']


@admin.register(MedistockLocation)
class MedistockLocationAdmin(admin.ModelAdmin):
    list_display = ['location_id', 'location_name', 'location_type', 'department', 'is_active']
    search_fields = ['location_name']
    list_filter = ['location_type', 'is_active']


@admin.register(MedistockSupplyItem)
class MedistockSupplyItemAdmin(admin.ModelAdmin):
    list_display = ['supply_id', 'supply_code', 'supply_name', 'category', 'unit', 'reorder_level', 'unit_cost', 'is_active']
    list_filter = ['category', 'unit', 'is_active']
    search_fields = ['supply_name', 'supply_code']


@admin.register(MedistockSupplyBatch)
class MedistockSupplyBatchAdmin(admin.ModelAdmin):
    list_display = ['batch_id', 'supply', 'batch_no', 'expiry_date', 'received_date', 'unit_cost', 'supplier_name']
    search_fields = ['batch_no', 'supply__supply_name']
    list_filter = ['expiry_date']


@admin.register(MedistockInventoryBalance)
class MedistockInventoryBalanceAdmin(admin.ModelAdmin):
    list_display = ['balance_id', 'supply', 'batch', 'location', 'qty_on_hand']
    search_fields = ['supply__supply_name', 'location__location_name']
    list_filter = ['location']


@admin.register(MedistockGoodsReceipt)
class MedistockGoodsReceiptAdmin(admin.ModelAdmin):
    list_display = ['gr_id', 'gr_no', 'pr', 'supplier_name', 'received_date', 'status']
    list_filter = ['status']
    search_fields = ['gr_no', 'supplier_name']


class MedistockSupplyRequestItemInline(admin.TabularInline):
    model = MedistockSupplyRequestItem
    extra = 0


@admin.register(MedistockSupplyRequest)
class MedistockSupplyRequestAdmin(admin.ModelAdmin):
    list_display = ['request_id', 'request_no', 'source_module', 'source_department', 'requested_by_name', 'request_date', 'status']
    list_filter = ['status', 'source_module']
    search_fields = ['request_no', 'requested_by_name', 'patient_name']
    inlines = [MedistockSupplyRequestItemInline]


@admin.register(MedistockTransaction)
class MedistockTransactionAdmin(admin.ModelAdmin):
    list_display = ['transaction_id', 'transaction_datetime', 'transaction_type', 'supply', 'batch', 'qty', 'source_module']
    list_filter = ['transaction_type', 'source_module']
    search_fields = ['supply__supply_name', 'patient_name', 'requested_by']


@admin.register(MedistockReport)
class MedistockReportAdmin(admin.ModelAdmin):
    list_display = ['report_id', 'report_type', 'period_type', 'date_from', 'date_to', 'generated_at']
    list_filter = ['report_type', 'period_type']
