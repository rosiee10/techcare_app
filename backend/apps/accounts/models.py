from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    """Custom User model for TechCare hospital management system"""
    
    ROLE_CHOICES = [
        ('admin', 'Administrator'),
        ('doctor', 'Doctor'),
        ('nurse', 'Nurse'),
        ('chief_nurse', 'Chief Nurse'),
        ('clerk', 'Clerk'),
        ('lab_tech', 'Laboratory Technician'),
        ('pharmacist', 'Pharmacist'),
        ('cashier', 'Cashier'),
        ('kitchen_staff', 'Kitchen Staff'),
        ('social_worker', 'Social Worker'),
        ('inventory_manager', 'Inventory Manager'),
        ('patient', 'Patient'),
    ]
    
    DEPARTMENT_CHOICES = [
        ('opd', 'Outpatient Department'),
        ('ipd', 'Inpatient Department'),
        ('laboratory', 'Laboratory'),
        ('pharmacy', 'Pharmacy'),
        ('billing', 'Billing'),
        ('kitchen', 'Kitchen'),
        ('medistock', 'Medical Stock'),
        ('socialwork', 'Social Work'),
        ('admin', 'Administration'),
    ]
    
    employee_id = models.CharField(max_length=20, unique=True, blank=True, null=True)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='clerk')
    department = models.CharField(max_length=20, choices=DEPARTMENT_CHOICES, default='opd')
    phone = models.CharField(max_length=15, blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    is_active_staff = models.BooleanField(default=True)
    date_joined_hospital = models.DateField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'pch.users'
        
    def __str__(self):
        return f"{self.employee_id or self.username} - {self.get_role_display()}"
