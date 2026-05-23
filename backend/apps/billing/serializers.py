from rest_framework import serializers
from .models import DiagnosisMaintenance, LabDetailMaintenance, LabCategoryMaintenance


class DiagnosisMaintenanceSerializer(serializers.ModelSerializer):
    total_fee = serializers.SerializerMethodField()

    class Meta:
        model = DiagnosisMaintenance
        fields = ['code', 'description', 'hospital_fee', 'prof_fee', 'total_fee', 'updated_at']
        read_only_fields = ['updated_at']

    def get_total_fee(self, obj):
        return float(obj.hospital_fee) + float(obj.prof_fee)


class LabCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = LabCategoryMaintenance
        fields = ['lab_code', 'lab_desc', 'emergency', 'is_active', 'display_order']


class LabDetailSerializer(serializers.ModelSerializer):
    lab_code = serializers.CharField(source='lab_code.lab_code', read_only=True)
    lab_desc = serializers.CharField(source='lab_code.lab_desc', read_only=True)
    lab_code_id = serializers.CharField(write_only=True, required=False)

    class Meta:
        model = LabDetailMaintenance
        fields = [
            'lab_keyctr', 'lab_code', 'lab_code_id', 'lab_desc',
            'lab_detail_desc', 'amt_wph', 'amt_woph', 'amt_emergency',
            'is_active', 'is_requestable', 'is_available',
            'display_order', 'updated_at',
        ]
        read_only_fields = ['lab_keyctr', 'updated_at']

    def create(self, validated_data):
        lab_code_id = validated_data.pop('lab_code_id', None)
        if not lab_code_id:
            raise serializers.ValidationError({'lab_code_id': 'This field is required for creating a service.'})
        try:
            category = LabCategoryMaintenance.objects.get(lab_code=lab_code_id)
        except LabCategoryMaintenance.DoesNotExist:
            raise serializers.ValidationError({'lab_code_id': f'Category "{lab_code_id}" does not exist.'})
        validated_data['lab_code'] = category
        return LabDetailMaintenance.objects.create(**validated_data)
