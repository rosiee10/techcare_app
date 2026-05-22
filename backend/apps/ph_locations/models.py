from django.db import models

class Region(models.Model):
    """Philippine Regions (NCR, CAR, Region I-XII, etc.)"""
    code = models.CharField(max_length=10, unique=True)
    name = models.CharField(max_length=100)
    
    class Meta:
        db_table = 'ph_regions'
        ordering = ['code']
    
    def __str__(self):
        return f"{self.code} - {self.name}"

class Province(models.Model):
    """Philippine Provinces"""
    code = models.CharField(max_length=10, unique=True)
    name = models.CharField(max_length=100)
    region = models.ForeignKey(Region, on_delete=models.CASCADE, related_name='provinces')
    
    class Meta:
        db_table = 'ph_provinces'
        ordering = ['name']
    
    def __str__(self):
        return self.name

class City(models.Model):
    """Cities and Municipalities"""
    code = models.CharField(max_length=10, unique=True)
    name = models.CharField(max_length=100)
    province = models.ForeignKey(Province, on_delete=models.CASCADE, related_name='cities')
    is_city = models.BooleanField(default=True)  # True = City, False = Municipality
    
    class Meta:
        db_table = 'ph_cities'
        ordering = ['name']
        verbose_name_plural = 'Cities'
    
    def __str__(self):
        return self.name

class Barangay(models.Model):
    """Barangays - smallest administrative division"""
    code = models.CharField(max_length=10, unique=True)
    name = models.CharField(max_length=100)
    city = models.ForeignKey(City, on_delete=models.CASCADE, related_name='barangays')
    
    class Meta:
        db_table = 'ph_barangays'
        ordering = ['name']
        verbose_name_plural = 'Barangays'
    
    def __str__(self):
        return self.name
