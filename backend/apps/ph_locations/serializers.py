from rest_framework import serializers
from .models import Region, Province, City, Barangay

class BarangaySerializer(serializers.ModelSerializer):
    class Meta:
        model = Barangay
        fields = ['code', 'name']

class CitySerializer(serializers.ModelSerializer):
    barangays = BarangaySerializer(many=True, read_only=True)
    
    class Meta:
        model = City
        fields = ['code', 'name', 'is_city', 'barangays']

class ProvinceSerializer(serializers.ModelSerializer):
    cities = CitySerializer(many=True, read_only=True)
    
    class Meta:
        model = Province
        fields = ['code', 'name', 'cities']

class RegionSerializer(serializers.ModelSerializer):
    provinces = ProvinceSerializer(many=True, read_only=True)
    
    class Meta:
        model = Region
        fields = ['code', 'name', 'provinces']
