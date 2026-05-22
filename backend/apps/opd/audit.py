"""
Audit logging system for patient data changes
Tracks who changed what, when, and from what value to what value
"""
from datetime import datetime
from django.db import models
from .models import PatientProfiling


class PatientAuditLog(models.Model):
    """
    Audit log for patient data changes.
    Tracks all modifications to patient records for compliance and security.
    """
    # Reference to patient
    patient = models.ForeignKey(
        PatientProfiling,
        on_delete=models.CASCADE,
        related_name='audit_logs'
    )
    
    # Who made the change
    user_id = models.IntegerField(help_text="ID of user who made the change")
    username = models.CharField(max_length=100, help_text="Username of user who made the change")
    user_fullname = models.CharField(max_length=200, help_text="Full name of user")
    user_role = models.CharField(max_length=50, help_text="Role of user (OPD_CLERK, NURSE, etc.)")
    
    # What was changed
    action = models.CharField(
        max_length=20,
        choices=[
            ('CREATE', 'Created'),
            ('UPDATE', 'Updated'),
            ('DELETE', 'Deleted'),
            ('RESTORE', 'Restored'),
        ],
        help_text="Type of action performed"
    )
    field_name = models.CharField(max_length=100, blank=True, help_text="Name of field that was changed")
    old_value = models.TextField(blank=True, help_text="Previous value before change")
    new_value = models.TextField(blank=True, help_text="New value after change")
    
    # When and where
    timestamp = models.DateTimeField(auto_now_add=True, help_text="When the change was made")
    ip_address = models.GenericIPAddressField(help_text="IP address of user")
    
    # Additional context
    reason = models.TextField(blank=True, help_text="Optional reason for the change")
    
    class Meta:
        db_table = 'patient_audit_log'
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['patient', '-timestamp']),
            models.Index(fields=['user_id', '-timestamp']),
            models.Index(fields=['action', '-timestamp']),
        ]
    
    def __str__(self):
        return f"{self.username} {self.action} {self.field_name} on {self.timestamp}"


def log_patient_change(patient, user, request, action, field_name='', old_value='', new_value='', reason=''):
    """
    Helper function to create an audit log entry.
    
    Args:
        patient: PatientProfiling instance
        user: User who made the change
        request: HTTP request object (for IP address)
        action: Type of action (CREATE, UPDATE, DELETE, RESTORE)
        field_name: Name of field changed (for UPDATE)
        old_value: Previous value (for UPDATE)
        new_value: New value (for UPDATE)
        reason: Optional reason for change
    
    Returns:
        PatientAuditLog instance
    """
    ip_address = request.META.get('REMOTE_ADDR', 'unknown')
    
    audit_entry = PatientAuditLog.objects.create(
        patient=patient,
        user_id=user.id,
        username=user.username,
        user_fullname=f"{getattr(user, 'firstname', '')} {getattr(user, 'lastname', '')}".strip() or user.username,
        user_role=getattr(user, 'role', 'UNKNOWN'),
        action=action,
        field_name=field_name,
        old_value=str(old_value),
        new_value=str(new_value),
        ip_address=ip_address,
        reason=reason,
    )
    
    return audit_entry


def log_patient_update(patient, user, request, changes_dict, reason=''):
    """
    Log multiple field changes for a patient update.
    
    Args:
        patient: PatientProfiling instance
        user: User who made the changes
        request: HTTP request object
        changes_dict: Dictionary of {field_name: (old_value, new_value)}
        reason: Optional reason for changes
    
    Returns:
        list: List of created audit log entries
    """
    audit_entries = []
    
    for field_name, (old_value, new_value) in changes_dict.items():
        # Skip if values are the same
        if old_value == new_value:
            continue
        
        entry = log_patient_change(
            patient=patient,
            user=user,
            request=request,
            action='UPDATE',
            field_name=field_name,
            old_value=old_value,
            new_value=new_value,
            reason=reason
        )
        audit_entries.append(entry)
    
    return audit_entries


def get_patient_audit_history(patient, limit=50):
    """
    Get audit history for a patient.
    
    Args:
        patient: PatientProfiling instance
        limit: Maximum number of entries to return
    
    Returns:
        QuerySet of PatientAuditLog entries
    """
    return PatientAuditLog.objects.filter(patient=patient)[:limit]


def get_user_audit_history(user_id, limit=50):
    """
    Get audit history for a specific user.
    
    Args:
        user_id: ID of user
        limit: Maximum number of entries to return
    
    Returns:
        QuerySet of PatientAuditLog entries
    """
    return PatientAuditLog.objects.filter(user_id=user_id)[:limit]


def format_audit_entry(entry):
    """
    Format an audit log entry for display.
    
    Args:
        entry: PatientAuditLog instance
    
    Returns:
        dict: Formatted audit entry
    """
    return {
        'timestamp': entry.timestamp.strftime('%Y-%m-%d %H:%M:%S'),
        'user': entry.user_fullname,
        'username': entry.username,
        'role': entry.user_role,
        'action': entry.get_action_display(),
        'field': entry.field_name,
        'old_value': entry.old_value,
        'new_value': entry.new_value,
        'ip_address': entry.ip_address,
        'reason': entry.reason,
    }
