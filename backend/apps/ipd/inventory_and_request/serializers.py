from rest_framework import serializers
from apps.opd.models import PatientProfiling
from .models import (
    IpdNoticeOfAdmission,
    DispensingSheet,
    DispensingSheetItem,
    CartForm,
    CartFormItem
)


class PatientProfilingBasicSerializer(serializers.ModelSerializer):
    """Basic serializer for patient search and selection"""
    full_name = serializers.SerializerMethodField()
    age = serializers.SerializerMethodField()
    
    class Meta:
        model = PatientProfiling
        fields = [
            'patient_id', 'hospital_id', 'firstname', 'lastname', 
            'middlename', 'ext', 'full_name', 'birthdate', 'age',
            'gender', 'contact_number',
            'purok', 'barangay', 'city_municipal', 'province',
            'current_status', 'is_active'
        ]
    
    def get_full_name(self, obj):
        middle = f" {obj.middlename}" if obj.middlename else ""
        ext = f" {obj.ext}" if obj.ext else ""
        return f"{obj.lastname}, {obj.firstname}{middle}{ext}"
    
    def get_age(self, obj):
        if obj.birthdate:
            from datetime import date
            today = date.today()
            return today.year - obj.birthdate.year - ((today.month, today.day) < (obj.birthdate.month, obj.birthdate.day))
        return None


class IpdNoticeOfAdmissionSerializer(serializers.ModelSerializer):
    """Serializer for IPD admission details (Notice of Admission)"""
    room_display = serializers.SerializerMethodField()
    
    class Meta:
        model = IpdNoticeOfAdmission
        fields = [
            'admission_id', 'hospital_id', 'admission_date', 
            'admitting_impression', 'admitting_physician', 'department',
            'room_display', 'status', 'bp', 'pr', 'temp', 'rr', 'weight', 'height', 'o2_sat',
            'submitted_by', 'submitted_date', 'approved_by', 'approved_date'
        ]
    
    def get_room_display(self, obj):
        # The new table doesn't have room_id, but has department
        return obj.department or "IPD Ward"


class DispensingSheetItemSerializer(serializers.ModelSerializer):
    """Serializer for dispensing sheet items"""
    medicine_name = serializers.SerializerMethodField()
    medicine_stock = serializers.SerializerMethodField()
    medicine_unit_cost = serializers.SerializerMethodField()
    
    class Meta:
        model = DispensingSheetItem
        fields = [
            'dispensing_item_id', 'date_requested', 'medicine_id', 
            'dosage', 'quantity', 'unit', 'unit_cost', 
            'total_cost', 'pharmacist_name',
            'medicine_name', 'medicine_stock', 'medicine_unit_cost'
        ]

    def get_medicine_name(self, obj):
        if obj.medicine_id:
            from apps.pharmacy.models import PharmacyMedicine
            medicine = PharmacyMedicine.objects.filter(medicine_id=obj.medicine_id).first()
            return medicine.medicine_name if medicine else "Unknown"
        return "Unknown"

    def get_medicine_stock(self, obj):
        if obj.medicine_id:
            from django.db.models import Sum
            from apps.pharmacy.models import PharmacyInventoryBalance
            # Cart/Floor Stock (Location 2)
            total = PharmacyInventoryBalance.objects.filter(
                medicine_id=obj.medicine_id,
                location_id=2
            ).aggregate(total=Sum('qty_on_hand'))['total'] or 0
            return float(total)
        return 0

    def get_medicine_unit_cost(self, obj):
        if obj.medicine_id:
            from apps.pharmacy.models import PharmacyMedicine
            medicine = PharmacyMedicine.objects.filter(medicine_id=obj.medicine_id).first()
            return float(medicine.unit_cost) if medicine and medicine.unit_cost else 0
        return 0


class DispensingSheetListSerializer(serializers.ModelSerializer):
    """List serializer for dispensing sheets"""
    patient_name = serializers.CharField(source='patient.__str__', read_only=True)
    patient_hospital_id = serializers.CharField(source='patient.hospital_id', read_only=True)
    item_count = serializers.SerializerMethodField()
    ward = serializers.SerializerMethodField()
    items = serializers.SerializerMethodField()
    
    class Meta:
        model = DispensingSheet
        fields = [
            'dispensing_id', 'patient_name', 'patient_hospital_id', 'request_date', 
            'request_time', 'status', 'requested_by_name', 'item_count', 'ward', 'items'
        ]
    
    def get_items(self, obj):
        # Only return items that have a medicine_id
        items = obj.items.filter(medicine_id__isnull=False)
        return DispensingSheetItemSerializer(items, many=True).data

    def get_item_count(self, obj):
        # Count only items that have a medicine_id
        return obj.items.filter(medicine_id__isnull=False).count()

    def get_ward(self, obj):
        if obj.admission:
            return obj.admission.department or "IPD Ward"
        return "IPD Ward"


class DispensingSheetDetailSerializer(serializers.ModelSerializer):
    """Detail serializer for dispensing sheets with items"""
    patient_name = serializers.CharField(source='patient.__str__', read_only=True)
    patient_hospital_id = serializers.CharField(source='patient.hospital_id', read_only=True)
    patient_address = serializers.SerializerMethodField()
    admission_date = serializers.DateField(source='admission.admission_date', read_only=True)
    admission_time = serializers.DateTimeField(source='admission.submitted_date', read_only=True)
    discharge_date = serializers.SerializerMethodField()
    ward = serializers.SerializerMethodField()
    items = serializers.SerializerMethodField()
    total_amount = serializers.SerializerMethodField()
    
    class Meta:
        model = DispensingSheet
        fields = [
            'dispensing_id', 'patient_name', 'patient_hospital_id', 'patient_address',
            'admission_date', 'admission_time', 'discharge_date', 'ward',
            'request_date', 'request_time', 'requested_by', 'requested_by_name', 
            'status', 'dispensed_by', 'dispensed_by_name', 'dispensed_date', 
            'items', 'created_at', 'trail', 'total_amount'
        ]

    def get_items(self, obj):
        # Only return items that have a medicine_id
        items = obj.items.filter(medicine_id__isnull=False)
        return DispensingSheetItemSerializer(items, many=True).data

    def get_total_amount(self, obj):
        # Calculate live total only from items that have a medicine_id
        total = 0
        for item in obj.items.filter(medicine_id__isnull=False):
            qty = item.quantity or 0
            # Get cost from medicine if unit_cost is not yet set in item
            if item.unit_cost:
                total += float(qty) * float(item.unit_cost)
            else:
                from apps.pharmacy.models import PharmacyMedicine
                medicine = PharmacyMedicine.objects.filter(medicine_id=item.medicine_id).first()
                if medicine and medicine.unit_cost:
                    total += float(qty) * float(medicine.unit_cost)
        return total

    def get_patient_address(self, obj):
        p = obj.patient
        parts = [p.purok, p.barangay, p.city_municipal, p.province]
        return ", ".join([str(part) for part in parts if part])

    def get_ward(self, obj):
        if obj.admission:
            return obj.admission.department or "IPD Ward"
        return "IPD Ward"

    def get_discharge_date(self, obj):
        # Since discharge_date is gone from admission table, we return None for now
        # Discharge details are likely in ipd_discharge_notice table
        return None


class DispensingSheetCreateSerializer(serializers.ModelSerializer):
    """Create serializer for dispensing sheets with nested items"""
    items = DispensingSheetItemSerializer(many=True, write_only=True)
    
    class Meta:
        model = DispensingSheet
        fields = [
            'patient', 'admission', 'requested_by', 'requested_by_name',
            'items', 'trail'
        ]
    
    def create(self, validated_data):
        items_data = validated_data.pop('items')
        dispensing_sheet = DispensingSheet.objects.create(**validated_data)
        
        for item_data in items_data:
            DispensingSheetItem.objects.create(
                dispensing_sheet=dispensing_sheet,
                **item_data
            )
        
        return dispensing_sheet


class CartFormItemSerializer(serializers.ModelSerializer):
    """Serializer for cart form items"""
    
    class Meta:
        model = CartFormItem
        fields = ['cart_item_id', 'date_taken', 'medicine_id', 'drug_name', 'quantity', 'administered_by']


class CartFormListSerializer(serializers.ModelSerializer):
    """List serializer for cart forms"""
    patient_name = serializers.CharField(source='patient.__str__', read_only=True)
    hospital_id = serializers.CharField(source='patient.hospital_id', read_only=True)
    item_count = serializers.SerializerMethodField()
    
    class Meta:
        model = CartForm
        fields = [
            'cart_form_id', 'patient_name', 'hospital_id', 'request_date',
            'status', 'requested_by_name', 'item_count'
        ]
    
    def get_item_count(self, obj):
        return obj.items.count()


class CartFormDetailSerializer(serializers.ModelSerializer):
    """Detail serializer for cart forms with items"""
    patient = PatientProfilingBasicSerializer(read_only=True)
    admission = IpdNoticeOfAdmissionSerializer(read_only=True)
    items = CartFormItemSerializer(many=True, read_only=True)
    
    class Meta:
        model = CartForm
        fields = [
            'cart_form_id', 'patient', 'admission', 'request_date',
            'requested_by', 'requested_by_name', 'status', 'from_location_id', 'items',
            'created_at', 'trail'
        ]


class CartFormCreateSerializer(serializers.ModelSerializer):
    """Create serializer for cart forms with nested items"""
    items = CartFormItemSerializer(many=True, write_only=True)
    
    class Meta:
        model = CartForm
        fields = [
            'patient', 'admission', 'requested_by', 'requested_by_name',
            'from_location_id', 'items', 'trail'
        ]
    
    def create(self, validated_data):
        items_data = validated_data.pop('items')
        cart_form = CartForm.objects.create(**validated_data)
        
        for item_data in items_data:
            CartFormItem.objects.create(
                cart_form=cart_form,
                **item_data
            )
        
        return cart_form
