from rest_framework import permissions


class IsAdmin(permissions.BasePermission):
    """Permission for Admin users only"""
    def has_permission(self, request, view):
        return request.user and request.user.role == 'admin'


class IsDoctor(permissions.BasePermission):
    """Permission for Doctor users"""
    def has_permission(self, request, view):
        return request.user and request.user.role == 'doctor'


class IsNurse(permissions.BasePermission):
    """Permission for Nurse users"""
    def has_permission(self, request, view):
        return request.user and request.user.role == 'nurse'


class IsClerk(permissions.BasePermission):
    """Permission for Clerk users"""
    def has_permission(self, request, view):
        return request.user and request.user.role == 'clerk'


class IsLabTech(permissions.BasePermission):
    """Permission for Lab Technician users"""
    def has_permission(self, request, view):
        return request.user and request.user.role == 'lab_tech'


class IsPharmacist(permissions.BasePermission):
    """Permission for Pharmacist users"""
    def has_permission(self, request, view):
        return request.user and request.user.role == 'pharmacist'


class IsCashier(permissions.BasePermission):
    """Permission for Cashier users"""
    def has_permission(self, request, view):
        return request.user and request.user.role == 'cashier'


class IsKitchenStaff(permissions.BasePermission):
    """Permission for Kitchen Staff users"""
    def has_permission(self, request, view):
        return request.user and request.user.role == 'kitchen_staff'


class IsSocialWorker(permissions.BasePermission):
    """Permission for Social Worker users"""
    def has_permission(self, request, view):
        return request.user and request.user.role == 'social_worker'


class IsInventoryManager(permissions.BasePermission):
    """Permission for Inventory Manager users"""
    def has_permission(self, request, view):
        return request.user and request.user.role == 'inventory_manager'


class IsAdminOrDoctor(permissions.BasePermission):
    """Permission for Admin or Doctor users"""
    def has_permission(self, request, view):
        return request.user and request.user.role in ['admin', 'doctor']


class IsOPDStaff(permissions.BasePermission):
    """Permission for OPD department staff"""
    def has_permission(self, request, view):
        return request.user and request.user.department == 'opd'


class IsIPDStaff(permissions.BasePermission):
    """Permission for IPD department staff"""
    def has_permission(self, request, view):
        return request.user and request.user.department == 'ipd'


class IsBillingStaff(permissions.BasePermission):
    """Permission for Billing department staff"""
    def has_permission(self, request, view):
        return request.user and request.user.department == 'billing'


class IsSameDepartmentOrAdmin(permissions.BasePermission):
    """Permission to access data from same department or admin"""
    def has_permission(self, request, view):
        if not request.user:
            return False
        if request.user.role == 'admin':
            return True
        # Check if view has department parameter
        department = getattr(view, 'required_department', None)
        if department:
            return request.user.department == department
        return True
