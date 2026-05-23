# ============================================================
# IPD FORMS ROLE-BASED ACCESS CONTROL
# ============================================================

from rest_framework.permissions import BasePermission

# Role definitions
NURSE_STATION = ['nurse_station', 'ipdnurse', 'nurse']
DOCTOR_ROD = ['doctor', 'rod', 'ipddoctor', 'physician']
NURSE_ATTENDANT = ['nurse_attendant', 'nurseattendant', 'attendant']

# Form access control matrix
FORM_PERMISSIONS = {
    # Form 1: Notice of Admission
    'notice_of_admission': {
        'full_input': NURSE_STATION + NURSE_ATTENDANT,
        'view_only': DOCTOR_ROD,
    },
    
    # Form 2: Patient Info (Maternity)
    'patient_info': {
        'full_input': NURSE_STATION + NURSE_ATTENDANT,
        'view_only': DOCTOR_ROD,
    },
    
    # Form 3: Consent Form
    'consent_form': {
        'full_input': NURSE_STATION + DOCTOR_ROD,
        'view_only': NURSE_ATTENDANT,
    },
    
    # Form 4: Clinical History & Physical Exam
    'clinical_history': {
        'full_input': DOCTOR_ROD,
        'view_only': NURSE_STATION + NURSE_ATTENDANT,
    },
    
    # Form 5: Physical Exam Continued
    'physical_exam_continued': {
        'full_input': DOCTOR_ROD,
        'view_only': NURSE_STATION + NURSE_ATTENDANT,
    },
    
    # Form 6: TPR Sheet
    'tpr_sheet': {
        'full_input': NURSE_STATION + NURSE_ATTENDANT,
        'view_only': DOCTOR_ROD,
    },
    
    # Form 7: Vital Signs
    'vital_signs': {
        'full_input': NURSE_STATION + NURSE_ATTENDANT,
        'view_only': DOCTOR_ROD,
    },
    
    # Form 8: IVF Sheet
    'ivf_sheet': {
        'full_input': NURSE_STATION,
        'view_only': DOCTOR_ROD + NURSE_ATTENDANT,
    },
    
    # Form 9: Medication Sheet
    'medication_sheet': {
        'full_input': NURSE_STATION,  # Administer/Sign
        'view_only': DOCTOR_ROD + NURSE_ATTENDANT,
    },
    
    # Form 10: Medication STAT/PRN
    'medication_stat_prn': {
        'full_input': NURSE_STATION + DOCTOR_ROD,  # Nurse administers, Doctor orders
        'view_only': NURSE_ATTENDANT,
    },
    
    # Form 11: Doctor's Order
    'doctors_order': {
        'full_input': DOCTOR_ROD,  # Write orders
        'execute': NURSE_STATION,  # Carry out/execute
        'view_only': NURSE_ATTENDANT,
    },
    
    # Form 12: Nurses' Notes
    'nurses_notes': {
        'full_input': NURSE_STATION,
        'view_only': DOCTOR_ROD + NURSE_ATTENDANT,
    },
    
    # Form 13: Diet List
    'diet_list': {
        'full_input': DOCTOR_ROD,
        'view_only': NURSE_STATION + NURSE_ATTENDANT,
    },
    
    # Form 14: Clinical Abstract & Summary
    'clinical_abstract': {
        'full_input': DOCTOR_ROD,
        'view_only': NURSE_STATION + NURSE_ATTENDANT,
    },
    
    # Form 15: I&O Monitoring
    'io_monitoring': {
        'full_input': NURSE_STATION + NURSE_ATTENDANT,
        'view_only': DOCTOR_ROD,
    },
    
    # Form 16: Discharge Plan
    'discharge_plan': {
        'full_input': NURSE_STATION + DOCTOR_ROD,
        'view_only': NURSE_ATTENDANT,
    },
    
    # Form 17: Discharge Notice
    'discharge_notice': {
        'full_input': NURSE_STATION + DOCTOR_ROD,
        'view_only': NURSE_ATTENDANT,
    },
    
    # Form 18: Clinical Referral Form
    'clinical_referral': {
        'full_input': NURSE_STATION + DOCTOR_ROD,
        'view_only': NURSE_ATTENDANT,
    },
    
    # Form 19: Informed Consent for Surgery
    'informed_consent_surgery': {
        'full_input': DOCTOR_ROD,  # Full input/Sign
        'prepare': NURSE_STATION,  # Prepare/Witness
        'view_only': NURSE_ATTENDANT,
    },
    
    # Form 20: Refusal of Treatment
    'refusal_of_treatment': {
        'full_input': DOCTOR_ROD,  # Full input/Sign
        'prepare': NURSE_STATION,  # Prepare/Witness
        'view_only': NURSE_ATTENDANT,
    },
    
    # Form 21: Clearance Slip
    'clearance_slip': {
        'full_input': NURSE_STATION + DOCTOR_ROD,
        'view_only': NURSE_ATTENDANT,
    },
    
    # Form 22: CART Forms
    'cart_forms': {
        'full_input': NURSE_STATION,
        'view_only': DOCTOR_ROD + NURSE_ATTENDANT,
    },
}


def get_user_role(user):
    """
    Get user role from Django user object.
    Checks username and groups.
    """
    if not user or not user.is_authenticated:
        return None
    
    username = user.username.lower()
    
    # Check username patterns
    if any(role in username for role in DOCTOR_ROD):
        return 'doctor'
    elif any(role in username for role in NURSE_STATION):
        return 'nurse_station'
    elif any(role in username for role in NURSE_ATTENDANT):
        return 'nurse_attendant'
    
    # Check user groups
    if hasattr(user, 'groups'):
        user_groups = [g.name.lower() for g in user.groups.all()]
        if any(role in user_groups for role in DOCTOR_ROD):
            return 'doctor'
        elif any(role in user_groups for role in NURSE_STATION):
            return 'nurse_station'
        elif any(role in user_groups for role in NURSE_ATTENDANT):
            return 'nurse_attendant'
    
    # Default to view only
    return None


def get_form_permission(form_name, user):
    """
    Get permission level for a specific form and user.
    Returns: 'full_input', 'execute', 'prepare', 'view_only', or None
    """
    user_role = get_user_role(user)
    
    if not user_role:
        return 'view_only'
    
    if form_name not in FORM_PERMISSIONS:
        return 'view_only'
    
    permissions = FORM_PERMISSIONS[form_name]
    
    # Check each permission level
    for perm_level, allowed_roles in permissions.items():
        if user_role in allowed_roles or any(user_role in role for role in allowed_roles):
            return perm_level
    
    return 'view_only'


def can_edit_form(form_name, user):
    """
    Check if user can edit (save) a specific form.
    """
    permission = get_form_permission(form_name, user)
    return permission in ['full_input', 'execute', 'prepare']


def can_view_form(form_name, user):
    """
    Check if user can view a specific form.
    Everyone can view all forms.
    """
    return True


class FormPermission(BasePermission):
    """
    Custom permission class for form access control.
    Usage: @permission_classes([IsAuthenticated, FormPermission])
    """
    
    def has_permission(self, request, view):
        # Everyone can view (GET requests)
        if request.method == 'GET':
            return True
        
        # For POST/PUT/PATCH, check if user can edit
        form_name = getattr(view, 'form_name', None)
        if not form_name:
            return True  # No restriction if form_name not set
        
        return can_edit_form(form_name, request.user)


# Helper function to add permissions to response
def add_permissions_to_response(form_name, user, data):
    """
    Add permission information to API response.
    """
    permission = get_form_permission(form_name, user)
    user_role = get_user_role(user)
    
    data['permissions'] = {
        'user_role': user_role,
        'permission_level': permission,
        'can_edit': permission in ['full_input', 'execute', 'prepare'],
        'can_view': True,
        'is_read_only': permission == 'view_only',
    }
    
    return data
