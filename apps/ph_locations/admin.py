from django.contrib import admin
from .models import Region, Province, City, Barangay

@admin.register(Region)
class RegionAdmin(admin.ModelAdmin):
    list_display = ['code', 'name']
    search_fields = ['name', 'code']

@admin.register(Province)
class ProvinceAdmin(admin.ModelAdmin):
    list_display = ['code', 'name', 'region']
    list_filter = ['region']
    search_fields = ['name', 'code']

@admin.register(City)
class CityAdmin(admin.ModelAdmin):
    list_display = ['code', 'name', 'province', 'is_city']
    list_filter = ['province', 'is_city']
    search_fields = ['name', 'code']

@admin.register(Barangay)
class BarangayAdmin(admin.ModelAdmin):
    list_display = ['code', 'name', 'city']
    list_filter = ['city__province']
    search_fields = ['name', 'code']
