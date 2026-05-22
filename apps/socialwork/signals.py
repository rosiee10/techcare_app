"""
Django signals for the Social Work app.

Responsibilities
----------------
1. Ensure social_worker_user_id is stamped on every new Endorsement.
2. Fire MswNotification when an endorsement status changes to Approved/Rejected
   → notify the social worker.

NOTE: The "endorsement_sent" notification (new endorsement → mayor/congressman)
is fired explicitly in perform_create (views.py) AFTER pack_from_payload() has
run, so the trail already contains patient_name and office at that point.
Firing it here (on post_save created=True) would read an empty trail and
produce "Unknown Patient" + wrong office.
"""

from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from django.utils import timezone

from .models import Endorsement, MswNotification


# ---------------------------------------------------------------------------
# Helper: create a notification record safely
# ---------------------------------------------------------------------------

def _create_notification(
    *,
    endorsement_id: int,
    notification_type: str,
    recipient_role: str,
    title: str,
    message: str,
    patient_name: str = '',
    office: str = '',
    letter_number: str = '',
    sender_user_id=None,
    recipient_user_id=None,
):
    """
    Low-level helper used by both the signal and perform_create.
    Accepts plain values so it can be called before or after an instance save.
    """
    try:
        MswNotification.objects.create(
            endorsement_id=endorsement_id,
            notification_type=notification_type,
            recipient_role=recipient_role,
            recipient_user_id=recipient_user_id,
            sender_user_id=sender_user_id,
            title=title,
            message=message,
            patient_name=patient_name or None,
            office=office or None,
            letter_number=letter_number or None,
        )
        print(
            f'[NOTIF] Created: type={notification_type} '
            f'role={recipient_role} endorsement={endorsement_id} '
            f'patient="{patient_name}" office="{office}"'
        )
    except Exception as exc:
        # Never let a notification failure break the main flow
        print(f'[NOTIF] WARNING: Failed to create notification: {exc}')


# ---------------------------------------------------------------------------
# Public helper called from perform_create (views.py)
# after pack_from_payload() has populated the trail
# ---------------------------------------------------------------------------

def _office_to_role(office: str) -> str | None:
    """Map the endorsement office field to a notification recipient_role."""
    if not office:
        return None
    office_lower = office.lower()
    if 'congressman' in office_lower or 'congress' in office_lower:
        return 'congressman'
    if 'mayor' in office_lower:
        return 'mayor'
    return None


def notify_endorsement_sent(endorsement: Endorsement) -> None:
    """
    Called from perform_create AFTER pack_from_payload() so the trail
    already has patient_name, office, etc.
    Fires an 'endorsement_sent' notification to the correct office role.
    """
    office       = endorsement.office or ''
    patient_name = endorsement.patient_name or ''
    letter_no    = endorsement.letter_number or ''
    sw_id        = endorsement.social_worker_user_id

    recipient_role = _office_to_role(office)
    if not recipient_role:
        print(f'[NOTIF] No matching role for office="{office}" — skipping notification')
        return

    _create_notification(
        endorsement_id=endorsement.endorsement_id,
        notification_type='endorsement_sent',
        recipient_role=recipient_role,
        sender_user_id=sw_id,
        title='New Endorsement Received',
        message=(
            f'A new endorsement (#{letter_no}) has been submitted for '
            f'{patient_name}. Please review and take action.'
        ),
        patient_name=patient_name,
        office=office,
        letter_number=letter_no,
    )


# ---------------------------------------------------------------------------
# Track previous status so post_save can detect changes
# ---------------------------------------------------------------------------

_previous_status: dict = {}


@receiver(pre_save, sender=Endorsement)
def capture_previous_status(sender, instance, **kwargs):
    """Store the current DB status before the save so post_save can diff it."""
    if instance.endorsement_id:
        try:
            old = Endorsement.objects.get(endorsement_id=instance.endorsement_id)
            _previous_status[instance.endorsement_id] = old.status or ''
        except Endorsement.DoesNotExist:
            _previous_status[instance.endorsement_id] = ''
    else:
        _previous_status[id(instance)] = ''


# ---------------------------------------------------------------------------
# post_save: handles status-change notifications only
# (new-endorsement notification is handled in perform_create)
# ---------------------------------------------------------------------------

@receiver(post_save, sender=Endorsement)
def handle_endorsement_notifications(sender, instance, created, **kwargs):
    """
    • New record  → stamp social_worker_user_id if missing (legacy fallback).
                    Notification is fired by perform_create, NOT here.
    • Status change → notify the social worker.
    """

    # ── 1. Stamp social_worker_user_id on new records (fallback) ───────────
    if created:
        trail_data = instance._trail_dict()
        if not trail_data.get('social_worker_user_id'):
            trail_data['social_worker_user_id'] = 32
            instance._set_trail(trail_data)
            Endorsement.objects.filter(
                endorsement_id=instance.endorsement_id
            ).update(trail=instance.trail)
            print(f'[SIGNAL] Stamped fallback social_worker_user_id on {instance.endorsement_id}')
        # Do NOT fire notification here — perform_create does it after pack_from_payload
        _previous_status.pop(id(instance), None)
        return

    # ── 2. Status-change notifications ─────────────────────────────────────
    prev_status = _previous_status.pop(instance.endorsement_id, '')
    current_status = (instance.status or '').capitalize()

    if not prev_status or not current_status or prev_status == current_status:
        return

    social_worker_id = instance.social_worker_user_id
    patient_name     = instance.patient_name or 'Patient'
    office           = instance.office or ''
    letter_no        = instance.letter_number or ''

    if current_status == 'Approved':
        _create_notification(
            endorsement_id=instance.endorsement_id,
            notification_type='endorsement_approved',
            recipient_role='social_worker',
            recipient_user_id=social_worker_id,
            title='Endorsement Approved',
            message=(
                f'Your endorsement (#{letter_no}) for {patient_name} '
                f'has been approved by {office}.'
            ),
            patient_name=patient_name,
            office=office,
            letter_number=letter_no,
        )

    elif current_status == 'Rejected':
        _create_notification(
            endorsement_id=instance.endorsement_id,
            notification_type='endorsement_rejected',
            recipient_role='social_worker',
            recipient_user_id=social_worker_id,
            title='Endorsement Rejected',
            message=(
                f'Your endorsement (#{letter_no}) for {patient_name} '
                f'has been rejected by {office}.'
            ),
            patient_name=patient_name,
            office=office,
            letter_number=letter_no,
        )
