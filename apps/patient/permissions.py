"""
Permissions for Patient Portal app.
"""
from rest_framework import permissions


class IsPatient(permissions.BasePermission):
    """
    Permission that checks if the user has the PATIENT role.
    """
    def has_permission(self, request, view):
        return (
            request.user and 
            hasattr(request.user, 'role') and 
            request.user.role == 'PATIENT'
        )


class IsOwnPatientProfile(permissions.BasePermission):
    """
    Permission that checks if the user is accessing their own patient profile.
    """
    def has_permission(self, request, view):
        # First check if user is authenticated and is a patient
        if not request.user or not hasattr(request.user, 'role'):
            return False
        return request.user.role == 'PATIENT'
    
    def has_object_permission(self, request, view, obj):
        # Check if the patient record belongs to the current user
        # This assumes user.patient_id is set for patient users
        return (
            hasattr(request.user, 'patient_id') and 
            obj.patient_id == request.user.patient_id
        )
