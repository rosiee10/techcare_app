"""
Custom permissions for OPD app - Patient data access control
"""
from rest_framework import permissions


class CanViewPatientData(permissions.BasePermission):
    """
    Permission to view patient data.
    Allowed roles: OPD Clerk, Nurse, Doctor, Admin
    """
    message = "You do not have permission to view patient data."
    
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        
        allowed_roles = ['OPD_CLERK', 'NURSE', 'DOCTOR', 'ADMIN']
        user_role = getattr(request.user, 'role', '').upper()
        
        return user_role in allowed_roles


class CanEditPatientData(permissions.BasePermission):
    """
    Permission to edit patient personal information.
    Allowed roles: OPD Clerk, Nurse, Admin
    Restrictions:
    - Cannot edit Hospital ID or Patient ID (immutable)
    - Must provide audit trail
    """
    message = "You do not have permission to edit patient data."
    
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        
        # Only allow edit for specific roles
        allowed_roles = ['OPD_CLERK', 'NURSE', 'ADMIN', 'CLERK']
        user_role = getattr(request.user, 'role', '').upper()
        
        return user_role in allowed_roles
    
    def has_object_permission(self, request, view, obj):
        """
        Check if user can edit this specific patient record
        """
        # Admin can edit any patient
        if getattr(request.user, 'role', '').upper() == 'ADMIN':
            return True
        
        # OPD Clerk and Nurse can only edit active patients
        if obj.is_active:
            return True
        
        return False


class CanDeletePatientData(permissions.BasePermission):
    """
    Permission to delete/deactivate patient records.
    Allowed roles: Admin only
    Note: We use soft delete (is_active=False) instead of hard delete
    """
    message = "Only administrators can delete patient records."
    
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        
        user_role = getattr(request.user, 'role', '').upper()
        return user_role == 'ADMIN'


class CanEditEmergencyContact(permissions.BasePermission):
    """
    Permission to edit emergency contact information.
    Allowed roles: OPD Clerk, Nurse, Admin
    """
    message = "You do not have permission to edit emergency contact information."
    
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        
        allowed_roles = ['OPD_CLERK', 'NURSE', 'ADMIN']
        user_role = getattr(request.user, 'role', '').upper()
        
        return user_role in allowed_roles


def get_editable_fields_for_role(user_role):
    """
    Returns list of fields that can be edited based on user role.
    
    Immutable fields (never editable):
    - hospital_id
    - patient_id
    - trail (original creation trail)
    - created_at
    
    Args:
        user_role: User's role (OPD_CLERK, NURSE, DOCTOR, ADMIN)
    
    Returns:
        list: Field names that can be edited
    """
    # Base editable fields for OPD Clerk and Nurse
    base_fields = [
        'firstname',
        'lastname',
        'middlename',
        'ext',
        'birthdate',
        'gender',
        'civil_status',
        'religion',
        'contact_number',
        'purok',
        'barangay',
        'city_municipal',
        'province',
        'photo_url',
    ]
    
    # Additional fields for Admin
    admin_fields = base_fields + [
        'current_status',
        'is_active',
    ]
    
    role_upper = user_role.upper()
    
    if role_upper == 'ADMIN':
        return admin_fields
    elif role_upper in ['OPD_CLERK', 'NURSE', 'CLERK']:
        return base_fields
    elif role_upper == 'DOCTOR':
        # Doctors can view but not edit personal info
        return []
    else:
        return []


def get_immutable_fields():
    """
    Returns list of fields that should never be edited.
    
    Returns:
        list: Immutable field names
    """
    return [
        'hospital_id',
        'patient_id',
        'trail',  # Original creation trail
        'created_at',
    ]


def validate_field_permissions(user_role, fields_to_update):
    """
    Validates if user has permission to update the requested fields.
    
    Args:
        user_role: User's role
        fields_to_update: List of field names to update
    
    Returns:
        tuple: (is_valid, error_message)
    """
    editable_fields = get_editable_fields_for_role(user_role)
    immutable_fields = get_immutable_fields()
    
    # Check for immutable fields
    attempted_immutable = [f for f in fields_to_update if f in immutable_fields]
    if attempted_immutable:
        return False, f"Cannot modify immutable fields: {', '.join(attempted_immutable)}"
    
    # Check for unauthorized fields
    unauthorized_fields = [f for f in fields_to_update if f not in editable_fields]
    if unauthorized_fields:
        return False, f"You do not have permission to edit: {', '.join(unauthorized_fields)}"
    
    return True, None
