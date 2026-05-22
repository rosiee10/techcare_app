from rest_framework import serializers
from apps.opd.models import PatientProfiling
from .models import (
    IpdPatientAdmissions,
    DispensingSheet,
    DispensingSheetItem,
    CartForm,
    CartFormItem,
    IpdCartInventory
)


class IpdCartInventorySerializer(serializers.ModelSerializer):
    """Serializer for Cart Inventory items"""
    medicine_name = serializers.CharField(source='medicine.medicine_name', read_only=True)
    medicine_code = serializers.CharField(source='medicine.medicine_code', read_only=True)
    category = serializers.CharField(source='medicine.category', read_only=True)
    unit = serializers.CharField(source='medicine.unit', read_only=True)
    
    class Meta:
        model = IpdCartInventory
        fields = [
            'medicine_id', 'medicine_name', 'medicine_code', 
            'category', 'unit', 'qty_on_hand'
        ]


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


class IpdPatientAdmissionsSerializer(serializers.ModelSerializer):
    """Serializer for IPD admission details"""
    room_display = serializers.SerializerMethodField()
    
    class Meta:
        model = IpdPatientAdmissions
        fields = [
            'admission_id', 'admission_date', 'admission_time',
            'discharge_date', 'discharge_time', 'room', 'department',
            'room_display', 'attending_doctor_id', 'admitting_diagnosis', 'status'
        ]
    
    def get_room_display(self, obj):
        room_info = f"Room {obj.room.room_number}" if obj.room else ""
        dept_info = obj.department.department_name if obj.department else ""
        
        if room_info and dept_info:
            return f"{dept_info} - {room_info}"
        return dept_info or room_info or "N/A"


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
            # Main Pharmacy (Location 1)
            total = PharmacyInventoryBalance.objects.filter(
                medicine_id=obj.medicine_id,
                location_id=1
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
    items = DispensingSheetItemSerializer(many=True, read_only=True)
    
    class Meta:
        model = DispensingSheet
        fields = [
            'dispensing_id', 'patient_name', 'patient_hospital_id', 'request_date', 
            'request_time', 'status', 'requested_by_name', 'item_count', 'ward', 'items'
        ]
    
    def get_item_count(self, obj):
        return obj.items.count()

    def get_ward(self, obj):
        if obj.admission and obj.admission.room:
            return f"Room {obj.admission.room.room_number}"
        return "IPD Ward"


class DispensingSheetDetailSerializer(serializers.ModelSerializer):
    """Detail serializer for dispensing sheets with items"""
    patient_name = serializers.CharField(source='patient.__str__', read_only=True)
    patient_hospital_id = serializers.CharField(source='patient.hospital_id', read_only=True)
    patient_address = serializers.SerializerMethodField()
    admission_date = serializers.DateField(source='admission.admission_date', read_only=True)
    admission_time = serializers.TimeField(source='admission.admission_time', read_only=True)
    discharge_date = serializers.DateField(source='admission.discharge_date', read_only=True)
    ward = serializers.SerializerMethodField()
    items = DispensingSheetItemSerializer(many=True, read_only=True)
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

    def get_total_amount(self, obj):
        # Calculate live total from items if sheet is not DISPENSED yet
        # Once dispensed, it might be using the stored field, but for UI preview we calculate it
        total = 0
        for item in obj.items.all():
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
        if obj.admission and obj.admission.room:
            return f"Room {obj.admission.room.room_number}"
        return "IPD Ward"


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
    admission = IpdPatientAdmissionsSerializer(read_only=True)
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
