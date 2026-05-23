from django.db import DatabaseError, IntegrityError
from django.db import models
from django.utils import timezone

from rest_framework import viewsets, status
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

from .models import (
    Endorsement,
    MswDocument,
    MswNotification,
    SocialWorkReferral,
    MswAssessment,
    MswApplication,
)
from .serializers import (
    EndorsementSerializer,
    MswDocumentSerializer,
    MswDocumentListSerializer,
    MswNotificationSerializer,
    SocialWorkReferralSerializer,
    MswAssessmentSerializer,
)


# ---------------------------------------------------------------------------
# Activity Log Helper
# ---------------------------------------------------------------------------

def _write_activity_log(
    module_name,
    action_type,
    description,
    submodule_name='',
    table_name='',
    record_id=None,
    patient_id=None,
    log_status='success',
    request=None,
):
    """
    Write a row to pch.activity_logs.
    Silently swallows errors so it never breaks the main request.
    """
    from django.db import connection as _conn
    try:
        ip_address = ''
        device_info = ''
        if request is not None:
            x_fwd = request.META.get('HTTP_X_FORWARDED_FOR', '')
            ip_address = (x_fwd.split(',')[0].strip() if x_fwd
                          else request.META.get('REMOTE_ADDR', ''))[:45]
            device_info = request.META.get('HTTP_USER_AGENT', '')[:150]

        with _conn.cursor() as cur:
            cur.execute("""
                INSERT INTO pch.activity_logs (
                    activity_datetime, module_name, submodule_name, table_name,
                    action_type, record_id, patient_id, description,
                    status, ip_address, device_info, trail
                ) VALUES (
                    NOW(), %s, %s, %s,
                    %s, %s, %s, %s,
                    %s, %s, %s, %s
                )
            """, [
                module_name[:20],
                submodule_name[:30],
                table_name[:50],
                action_type[:20],
                record_id,
                patient_id,
                description,
                log_status[:10],
                ip_address,
                device_info,
                '',
            ])
    except Exception as exc:
        print(f'[ACTIVITY LOG] Failed to write log: {exc}')



# ---------------------------------------------------------------------------
# Document Management — pch.msw_documents
# ---------------------------------------------------------------------------

@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def documents(request):
    """
    GET  /api/socialwork/documents/?category=<name>  — list documents
    POST /api/socialwork/documents/                  — create document
    Body (POST): { filename, original_filename, category, file_data (base64),
                   patient_name, size, application_id (opt) }
    """
    if request.method == 'GET':
        category = request.GET.get('category')
        qs = MswDocument.objects.all()
        if category:
            qs = qs.filter(category=category)
        return Response(MswDocumentListSerializer(qs, many=True).data)

    # POST — create
    data = request.data
    patient_name = (data.get('patient_name') or '')[:50]
    size         = (data.get('size') or '')[:20]
    import json as _json
    trail = _json.dumps({'patient_name': patient_name, 'size': size})[:120]

    doc = MswDocument(
        application_id=data.get('application_id') or None,
        filename=(data.get('filename') or '')[:120],
        original_filename=(data.get('original_filename') or data.get('filename') or '')[:120],
        category=(data.get('category') or '')[:60],
        storage_path=data.get('file_data') or '',
        trail=trail,
        updated_trail=trail,
        updated_at=timezone.now(),
    )
    try:
        doc.save()
    except Exception as e:
        return Response({'success': False, 'message': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    _write_activity_log(
        module_name='SOCIAL_WORK',
        submodule_name='Document Management',
        table_name='msw_documents',
        action_type='UPLOAD',
        description=f'Uploaded document: {doc.original_filename or doc.filename}',
        record_id=doc.document_id,
        log_status='success',
        request=request,
    )
    return Response(MswDocumentSerializer(doc).data, status=status.HTTP_201_CREATED)


@api_view(['GET', 'DELETE'])
@permission_classes([IsAuthenticated])
def document_detail(request, document_id):
    """
    GET    /api/socialwork/documents/<id>/  — return full row incl. storage_path
    DELETE /api/socialwork/documents/<id>/  — delete document
    """
    try:
        doc = MswDocument.objects.get(document_id=document_id)
    except MswDocument.DoesNotExist:
        return Response({'error': 'Not found'}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'DELETE':
        doc.delete()
        return Response({'success': True})

    return Response(MswDocumentSerializer(doc).data)


# Map a patient_classification value -> social_work_referrals.status value
def _status_from_classification(classification):
    if not classification:
        return 'Pending'
    c = str(classification).strip().lower()
    # Eligible buckets
    if c in ('indigent', 'c1', 'c2'):
        return 'Approved'
    # Not eligible bucket
    if c in ('c3', 'pay', 'private', 'service', 'paying'):
        return 'Rejected'
    return 'Pending'


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_assessment(request):
    """
    POST /api/socialwork/assessments/
    Body: full assessment payload + optional hospital_no so we can update the
    matching social_work_referral status based on patient_classification.

    Returns: { success, assessment, referral_status (or null) }.
    """
    payload = dict(request.data) if hasattr(request.data, 'keys') else {}
    # DRF gives lists when using QueryDict — flatten single-value lists
    payload = {k: (v[0] if isinstance(v, list) and len(v) == 1 else v) for k, v in payload.items()}

    # Always stamp the social worker user id
    if request.user and request.user.is_authenticated:
        payload['msw_user_id'] = request.user.id

    if not payload.get('updated_at'):
        payload['updated_at'] = timezone.now().isoformat()

    hospital_no = payload.pop('hospital_no', None)
    patient_id = payload.pop('patient_id', None)
    classification = payload.get('patient_classification')
    new_status = _status_from_classification(classification)
    # NOTE: do NOT write status on msw_assessments — that column has its own
    # CHECK constraint distinct from social_work_referrals.status. Let the DB
    # default it. We only use new_status to update the referral row below.
    payload.pop('status', None)

    # ── Ensure we have an msw_applications row (FK is NOT NULL) ──────────────
    if not payload.get('application_id'):
        try:
            patient_id_int = int(patient_id) if patient_id is not None else None
        except (TypeError, ValueError):
            patient_id_int = None

        application = None
        if patient_id_int is not None:
            application = (MswApplication.objects
                           .filter(patient_id=patient_id_int)
                           .order_by('-application_id')
                           .first())
        if application is None:
            try:
                application = MswApplication.objects.create(
                    patient_id=patient_id_int,
                    application_number=f'APP-{patient_id_int or 0}-{int(timezone.now().timestamp())}',
                    application_type='Medical Assistance',
                    total_requested=0,
                    total_approved=0,
                    referral_source='Social Work',
                    date_of_admission=timezone.now().date(),
                    trail=f'auto-created by msw_user {payload.get("msw_user_id")}',
                    updated_at=timezone.now(),
                )
            except (DatabaseError, IntegrityError) as e:
                return Response(
                    {'success': False,
                     'message': f'Failed to create msw_applications row: {e}'},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                )
        payload['application_id'] = application.application_id

    serializer = MswAssessmentSerializer(data=payload)
    if not serializer.is_valid():
        return Response({'success': False, 'errors': serializer.errors},
                        status=status.HTTP_400_BAD_REQUEST)

    try:
        assessment = serializer.save()
    except (DatabaseError, IntegrityError) as e:
        return Response({'success': False, 'message': f'DB error: {e}'},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    # Update referral status (if we have a hospital_no to match against)
    referral_updated = None
    if hospital_no:
        try:
            updated = (SocialWorkReferral.objects
                       .filter(hospital_no=str(hospital_no).strip())
                       .update(status=new_status, updated_at=timezone.now()))
            referral_updated = {'hospital_no': hospital_no, 'rows': updated, 'status': new_status}
        except DatabaseError as e:
            referral_updated = {'hospital_no': hospital_no, 'error': str(e)}

    # Write activity log for assessment creation
    patient_id_for_log = None
    try:
        patient_id_for_log = int(patient_id) if patient_id is not None else None
    except (TypeError, ValueError):
        pass

    _write_activity_log(
        module_name='SOCIAL_WORK',
        submodule_name='Eligibility Screening',
        table_name='msw_assessments',
        action_type='CREATE',
        description=(
            f'Created eligibility screening'
            + (f' (classification: {classification})' if classification else '')
            + (f' for hospital no. {hospital_no}' if hospital_no else '')
        ),
        record_id=assessment.assessment_id,
        patient_id=patient_id_for_log,
        log_status='success',
        request=request,
    )

    return Response({
        'success': True,
        'assessment': MswAssessmentSerializer(assessment).data,
        'referral_update': referral_updated,
    }, status=status.HTTP_201_CREATED)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_referrals(request):
    """
    GET /api/socialwork/referrals/
        ?hospital_no=00-00-02   (optional, exact match)
        ?patient_id=2           (optional, exact match)
        ?search=foo             (optional, matches patient_name / hospital_no)
    Returns all matching referrals, each with nested items.
    """
    qs = SocialWorkReferral.objects.all().prefetch_related('items')

    hospital_no = request.query_params.get('hospital_no')
    if hospital_no:
        qs = qs.filter(hospital_no=hospital_no.strip())

    patient_id = request.query_params.get('patient_id')
    if patient_id:
        try:
            qs = qs.filter(patient_id=int(patient_id))
        except (TypeError, ValueError):
            pass

    search = request.query_params.get('search')
    if search:
        qs = qs.filter(
            models.Q(patient_name__icontains=search)
            | models.Q(hospital_no__icontains=search)
        )

    data = SocialWorkReferralSerializer(qs, many=True).data
    return Response({'success': True, 'count': len(data), 'results': data})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def referral_detail(request, pk):
    """GET /api/socialwork/referrals/<id>/  → single referral with items."""
    try:
        ref = SocialWorkReferral.objects.prefetch_related('items').get(pk=pk)
    except SocialWorkReferral.DoesNotExist:
        return Response({'success': False, 'message': 'Referral not found'},
                        status=status.HTTP_404_NOT_FOUND)
    return Response({'success': True, 'result': SocialWorkReferralSerializer(ref).data})

# Debug decorator to track all requests
def debug_requests(view_func):
    def wrapper(self, request, *args, **kwargs):
        print(f'[DEBUG] {view_func.__name__} called: {request.method} {request.path}')
        print(f'[DEBUG] User: {request.user.id if request.user else "None"}')
        print(f'[DEBUG] Data: {request.data}')
        return view_func(self, request, *args, **kwargs)
    return wrapper



VALID_STATUSES = ['Pending', 'Approved', 'Rejected']





class EndorsementViewSet(viewsets.ModelViewSet):

    """CRUD + filtering for Social Work endorsements backed by msw_endorsements.



    Filtering:

        GET /api/socialwork/endorsements/?office=Mayor's Office

        GET /api/socialwork/endorsements/?office=Congressman's Office



    Status update:

        POST /api/socialwork/endorsements/<id>/update_status/  body: {"status": "approved"}

    """
    
    def __init__(self, *args, **kwargs):
        print('[VIEWSET] EndorsementViewSet initialized')
        super().__init__(*args, **kwargs)



    queryset = Endorsement.objects.all()

    serializer_class = EndorsementSerializer

    permission_classes = [IsAuthenticated]

    pagination_class = None

    lookup_field = 'endorsement_id'

    lookup_url_kwarg = 'pk'



    def get_object(self):

        pk = self.kwargs.get(self.lookup_url_kwarg)

        print(f"[DEBUG] get_object called with pk={pk}, lookup_url_kwarg={self.lookup_url_kwarg}")

        try:

            return Endorsement.objects.get(endorsement_id=pk)

        except Endorsement.DoesNotExist:

            from django.http import Http404

            raise Http404(f"Endorsement with id={pk} not found")

        except Exception as exc:

            print(f"[DEBUG] get_object error: {exc}")

            raise



    def get_queryset(self):

        # Return all endorsements - filtering done in list()

        return Endorsement.objects.all()



    def list(self, request, *args, **kwargs):

        try:

            queryset = self.get_queryset()

            # Since office and status are stored in JSON/trail, filter in Python

            office = request.query_params.get('office')

            status_param = request.query_params.get('status')

            

            results = list(queryset)

            if office:

                results = [e for e in results if e.office and e.office.lower() == office.lower()]

            if status_param:

                results = [e for e in results if e.status and e.status.capitalize() == status_param.capitalize()]

            

            serializer = self.get_serializer(results, many=True)

            return Response(serializer.data)

        except Exception as exc:

            import traceback

            print(f"[ERROR] list endorsements failed: {exc}")

            print(traceback.format_exc())

            return Response(

                {'error': f'Server error: {str(exc)}'},

                status=status.HTTP_500_INTERNAL_SERVER_ERROR,

            )



    def perform_create(self, serializer):
        print(f'[VIEWSET perform_create] Creating endorsement for user: {self.request.user.id}')
        
        # Get all frontend data from request
        payload = dict(self.request.data)
        print(f'[VIEWSET perform_create] Frontend payload: {payload}')
        
        # Always add social_worker_user_id
        payload['social_worker_user_id'] = self.request.user.id
        print(f'[VIEWSET perform_create] Adding social_worker_user_id: {self.request.user.id}')
        
        # Create the endorsement instance first
        instance = serializer.save()
        
        # Pack the frontend payload data (includes all fields like patient_name, office, etc.)
        instance.pack_from_payload(payload)
        instance.save()
        
        print(f'[VIEWSET perform_create] Created endorsement {instance.endorsement_id} with trail: {instance._trail_dict()}')
        
        # Fire notification NOW — trail is fully populated with patient_name + office
        from .signals import notify_endorsement_sent
        notify_endorsement_sent(instance)
        print(f'[VIEWSET perform_create] Notification fired for office="{instance.office}"')

        # Write activity log
        _write_activity_log(
            module_name='SOCIAL_WORK',
            submodule_name='Endorsements',
            table_name='msw_endorsements',
            action_type='CREATE',
            description=f'Created endorsement for {instance.patient_name} → {instance.office}',
            record_id=instance.endorsement_id,
            log_status='success',
            request=self.request,
        )



    @debug_requests
    def create(self, request, *args, **kwargs):
        """Create with explicit DB-error handling so the frontend gets a readable message."""
        print(f'[VIEWSET CREATE] Create method called with data: {request.data}')
        print(f'[VIEWSET CREATE] User: {request.user.id if request.user else "None"}')
        
        serializer = self.get_serializer(data=request.data)
        if not serializer.is_valid():
            print(f'[VIEWSET CREATE] Validation failed: {serializer.errors}')
            return Response(
                {'error': 'Validation failed', 'details': serializer.errors},
                status=status.HTTP_400_BAD_REQUEST,
            )
        try:
            print(f'[VIEWSET CREATE] Calling perform_create...')
            self.perform_create(serializer)
            print(f'[VIEWSET CREATE] perform_create completed')
        except IntegrityError as exc:
            print(f'[VIEWSET CREATE] IntegrityError: {exc}')
            return Response(
                {'error': f'Database integrity error: {str(exc)}'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        except DatabaseError as exc:
            print(f'[VIEWSET CREATE] DatabaseError: {exc}')
            return Response(
                {'error': f'Database error: {str(exc)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )
        except Exception as exc:
            print(f'[VIEWSET CREATE] Exception: {exc}')
            return Response(
                {'error': f'Server error: {str(exc)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )
        headers = self.get_success_headers(serializer.data)
        print(f'[VIEWSET CREATE] Returning response: {serializer.data}')
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)



    def destroy(self, request, *args, **kwargs):

        """Disallow deletion of unmanaged-table records."""

        return Response(

            {'error': 'Deletion is not permitted on this table.'},

            status=status.HTTP_405_METHOD_NOT_ALLOWED,

        )



    @action(detail=True, methods=['post'], url_path='update_status')

    def update_status(self, request, pk=None):

        print(f"[DEBUG] update_status called with request.data={request.data}, kwargs={self.kwargs}")

        try:

            endorsement = self.get_object()

        except Exception as exc:

            print(f"[DEBUG] get_object failed: {exc}")

            import traceback

            return Response(

                {'error': f'Lookup failed: {str(exc)}', 'trace': traceback.format_exc()},

                status=status.HTTP_500_INTERNAL_SERVER_ERROR,

            )

        new_status = request.data.get('status', '').capitalize()

        print(f"[DEBUG] endorsement_id={endorsement.endorsement_id}, new_status={new_status}")

        if new_status not in VALID_STATUSES:

            return Response(

                {'error': f'Invalid status. Must be one of: {VALID_STATUSES}'},

                status=status.HTTP_400_BAD_REQUEST,

            )

        try:

            endorsement.status = new_status

            endorsement.updated_at = timezone.now()

            endorsement.save()

            print(f"[DEBUG] save succeeded")

        except Exception as exc:

            import traceback

            print(f"[DEBUG] save failed: {exc}")

            return Response(

                {

                    'error': f'Update failed: {str(exc)}',

                    'trace': traceback.format_exc(),

                },

                status=status.HTTP_500_INTERNAL_SERVER_ERROR,

            )

        # Determine which office performed the action for the module_name
        office = (endorsement.office or '').lower()
        if 'mayor' in office:
            module = 'MAYOR'
        elif 'congressman' in office or 'congress' in office:
            module = 'CONGRESSMAN'
        else:
            module = 'SOCIAL_WORK'

        _write_activity_log(
            module_name=module,
            submodule_name='Endorsements',
            table_name='msw_endorsements',
            action_type=new_status.upper(),
            description=(
                f'Endorsement {new_status.lower()} for {endorsement.patient_name}'
                f' (#{endorsement.endorsement_id})'
            ),
            record_id=endorsement.endorsement_id,
            log_status='success',
            request=request,
        )

        return Response({

            'endorsement_id': endorsement.endorsement_id,

            'status': endorsement.status,

            'updated_at': endorsement.updated_at.isoformat() if endorsement.updated_at else None,

        })





# ========== NOTIFICATION API ==========

# Role → recipient_role mapping used for filtering
_ROLE_MAP = {
    'social_worker': 'social_worker',
    'mayor':         'mayor',
    'congressman':   'congressman',
}


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_notifications(request):
    """
    Return notifications for the requesting user.

    Query params:
      ?role=social_worker|mayor|congressman   (required)
      ?unread_only=true                        (optional)
      ?endorsement_id=<int>                    (optional)

    The caller's user_id is used to filter recipient_user_id when the role
    is social_worker (personal notifications).  Mayor/congressman notifications
    are broadcast to the whole role (recipient_user_id IS NULL).
    """
    role = request.query_params.get('role', '').lower()
    if role not in _ROLE_MAP:
        return Response(
            {'error': f'role must be one of: {list(_ROLE_MAP.keys())}'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    recipient_role = _ROLE_MAP[role]
    qs = MswNotification.objects.filter(recipient_role=recipient_role)

    # For social_worker: show only their own notifications
    if recipient_role == 'social_worker':
        user_id = request.user.id
        qs = qs.filter(
            models.Q(recipient_user_id=user_id) | models.Q(recipient_user_id__isnull=True)
        )

    # Optional filters
    if request.query_params.get('unread_only', '').lower() == 'true':
        qs = qs.filter(is_read=False)

    endorsement_id = request.query_params.get('endorsement_id')
    if endorsement_id:
        qs = qs.filter(endorsement_id=endorsement_id)

    serializer = MswNotificationSerializer(qs, many=True)
    return Response({
        'count':         qs.count(),
        'unread_count':  qs.filter(is_read=False).count(),
        'notifications': serializer.data,
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def mark_notification_read(request, notification_id):
    """Mark a single notification as read."""
    try:
        notif = MswNotification.objects.get(notification_id=notification_id)
    except MswNotification.DoesNotExist:
        return Response({'error': 'Notification not found'}, status=status.HTTP_404_NOT_FOUND)

    if not notif.is_read:
        notif.is_read = True
        notif.read_at = timezone.now()
        notif.save(update_fields=['is_read', 'read_at'])

    return Response(MswNotificationSerializer(notif).data)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_notification(request, notification_id):
    """Permanently delete a single notification."""
    try:
        notif = MswNotification.objects.get(notification_id=notification_id)
    except MswNotification.DoesNotExist:
        return Response({'error': 'Notification not found'}, status=status.HTTP_404_NOT_FOUND)

    notif.delete()
    return Response({'deleted': notification_id}, status=status.HTTP_200_OK)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_all_notifications(request):
    """
    Delete all notifications for a given role.
    Body: { "role": "social_worker" | "mayor" | "congressman" }
    """
    role = request.data.get('role', '').lower()
    if role not in _ROLE_MAP:
        return Response(
            {'error': f'role must be one of: {list(_ROLE_MAP.keys())}'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    recipient_role = _ROLE_MAP[role]
    qs = MswNotification.objects.filter(recipient_role=recipient_role)

    if recipient_role == 'social_worker':
        user_id = request.user.id
        qs = qs.filter(
            models.Q(recipient_user_id=user_id) | models.Q(recipient_user_id__isnull=True)
        )

    deleted_count, _ = qs.delete()
    return Response({'deleted': deleted_count}, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def mark_all_notifications_read(request):
    """
    Mark all unread notifications as read for a given role.

    Body: { "role": "social_worker" | "mayor" | "congressman" }
    """
    role = request.data.get('role', '').lower()
    if role not in _ROLE_MAP:
        return Response(
            {'error': f'role must be one of: {list(_ROLE_MAP.keys())}'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    recipient_role = _ROLE_MAP[role]
    qs = MswNotification.objects.filter(recipient_role=recipient_role, is_read=False)

    if recipient_role == 'social_worker':
        user_id = request.user.id
        qs = qs.filter(
            models.Q(recipient_user_id=user_id) | models.Q(recipient_user_id__isnull=True)
        )

    now = timezone.now()
    updated = qs.update(is_read=True, read_at=now)
    return Response({'marked_read': updated})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def unread_notification_count(request):
    """
    Quick badge count endpoint.

    Query param: ?role=social_worker|mayor|congressman
    """
    role = request.query_params.get('role', '').lower()
    if role not in _ROLE_MAP:
        return Response(
            {'error': f'role must be one of: {list(_ROLE_MAP.keys())}'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    recipient_role = _ROLE_MAP[role]
    qs = MswNotification.objects.filter(recipient_role=recipient_role, is_read=False)

    if recipient_role == 'social_worker':
        user_id = request.user.id
        qs = qs.filter(
            models.Q(recipient_user_id=user_id) | models.Q(recipient_user_id__isnull=True)
        )

    return Response({'unread_count': qs.count()})


# ========== REPORT API ==========

import csv
from django.http import HttpResponse
from django.db.models import Count, Q
from django.db.models.functions import TruncMonth


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def endorsement_report_stats(request):
    """
    Pre-aggregated report stats for mayor/congressman dashboards.

    Query params:
      ?office=Mayor's Office | Congressman's Office   (required)
      ?period=all | this_month | last_3_months | this_year  (optional, default=all)

    Returns:
      - summary: total, approved, rejected, pending, total_amount
      - monthly_breakdown: list of {month, total, approved, rejected}
      - records: full list of endorsements matching the filters
    """
    from datetime import date

    office = request.query_params.get('office', '').strip()
    period = request.query_params.get('period', 'all').lower()

    if not office:
        return Response(
            {'error': 'office query param is required'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    # Base queryset — filter by office stored in trail
    # Since office is in the trail JSON we filter in Python after fetching
    all_endorsements = list(Endorsement.objects.all().order_by('-sent_at'))
    office_records = [e for e in all_endorsements if e.office and e.office.lower() == office.lower()]

    # Period filter
    today = date.today()
    if period == 'this_month':
        office_records = [
            e for e in office_records
            if e.sent_at and e.sent_at.year == today.year and e.sent_at.month == today.month
        ]
    elif period == 'last_3_months':
        # Go back to the 1st of the month 2 months ago
        month = today.month - 2
        year  = today.year
        if month <= 0:
            month += 12
            year  -= 1
        cutoff = date(year, month, 1)
        office_records = [
            e for e in office_records
            if e.sent_at and e.sent_at.date() >= cutoff
        ]
    elif period == 'this_year':
        office_records = [
            e for e in office_records
            if e.sent_at and e.sent_at.year == today.year
        ]

    # Summary
    total    = len(office_records)
    approved = sum(1 for e in office_records if (e.status or '').lower() == 'approved')
    rejected = sum(1 for e in office_records if (e.status or '').lower() == 'rejected')
    pending  = sum(1 for e in office_records if (e.status or '').lower() == 'pending')

    def _parse_amount(e):
        import re
        raw = str(e.amount_requested or 0)
        m = re.search(r'[\d,]+(?:\.\d+)?', raw)
        if m:
            try:
                return float(m.group().replace(',', ''))
            except ValueError:
                pass
        return 0.0

    total_amount = sum(_parse_amount(e) for e in office_records)

    # Monthly breakdown (last 12 months)
    from collections import defaultdict
    monthly = defaultdict(lambda: {'total': 0, 'approved': 0, 'rejected': 0, 'pending': 0})
    for e in office_records:
        if not e.sent_at:
            continue
        key = e.sent_at.strftime('%Y-%m')
        monthly[key]['total'] += 1
        s = (e.status or '').lower()
        if s == 'approved': monthly[key]['approved'] += 1
        elif s == 'rejected': monthly[key]['rejected'] += 1
        else: monthly[key]['pending'] += 1

    monthly_breakdown = [
        {'month': k, **v}
        for k, v in sorted(monthly.items())
    ]

    # Full record list
    from .serializers import EndorsementSerializer
    serializer = EndorsementSerializer(office_records, many=True)

    return Response({
        'office': office,
        'period': period,
        'summary': {
            'total':        total,
            'approved':     approved,
            'rejected':     rejected,
            'pending':      pending,
            'total_amount': round(total_amount, 2),
        },
        'monthly_breakdown': monthly_breakdown,
        'records': serializer.data,
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def endorsement_report_csv(request):
    """
    CSV export of endorsements for a given office.

    Query params:
      ?office=Mayor's Office | Congressman's Office   (required)
      ?period=all | this_month | last_3_months | this_year  (optional)
    """
    from datetime import date

    office = request.query_params.get('office', '').strip()
    period = request.query_params.get('period', 'all').lower()

    if not office:
        return Response({'error': 'office param required'}, status=400)

    all_endorsements = list(Endorsement.objects.all().order_by('-sent_at'))
    records = [e for e in all_endorsements if e.office and e.office.lower() == office.lower()]

    today = date.today()
    if period == 'this_month':
        records = [e for e in records
                   if e.sent_at and e.sent_at.year == today.year and e.sent_at.month == today.month]
    elif period == 'last_3_months':
        month = today.month - 2
        year  = today.year
        if month <= 0:
            month += 12
            year  -= 1
        cutoff = date(year, month, 1)
        records = [e for e in records if e.sent_at and e.sent_at.date() >= cutoff]
    elif period == 'this_year':
        records = [e for e in records if e.sent_at and e.sent_at.year == today.year]

    safe_office = office.replace("'", '').replace(' ', '_')
    filename = f'Endorsement_Report_{safe_office}_{today.strftime("%Y%m%d")}.csv'

    response = HttpResponse(content_type='text/csv')
    response['Content-Disposition'] = f'attachment; filename="{filename}"'

    writer = csv.writer(response)
    writer.writerow(['Date', 'Letter No.', 'Patient', 'Physician', 'Service Type',
                     'Amount', 'Hospital No.', 'Purpose', 'Status', 'Office'])

    for e in records:
        writer.writerow([
            e.sent_at.strftime('%Y-%m-%d') if e.sent_at else '',
            e.letter_number or '',
            e.patient_name or '',
            e.physician or '',
            e.service_type or '',
            str(e.amount_requested or ''),
            e.hospital_no or '',
            e.purpose or '',
            e.status or '',
            e.office or '',
        ])

    return response


# ========== SIGNATURE API ==========

from django.http import HttpResponse

from rest_framework.decorators import api_view, permission_classes

from rest_framework.permissions import IsAuthenticated

from django.db import connection



def ensure_signature_table():

    """Create the signature table if it doesn't exist"""

    with connection.cursor() as cursor:

        cursor.execute('''

            CREATE TABLE IF NOT EXISTS pch.msw_signature (

                id SERIAL PRIMARY KEY,

                user_id INTEGER REFERENCES pch.users(user_id),

                signature_image BYTEA NOT NULL,

                file_name VARCHAR(255),

                created_at TIMESTAMP DEFAULT NOW()

            );

        ''')



@api_view(['POST'])

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def upload_signature(request):
    """Upload signature to msw_signature table"""
    try:

        user_id = request.GET.get('user_id') or request.data.get('user_id')

        if not user_id:

            return Response({"error": "user_id required"}, status=400)

        

        file = request.FILES.get('file')

        if not file:

            return Response({"error": "No file uploaded"}, status=400)

        

        contents = file.read()

        

        # Ensure table exists

        ensure_signature_table()

        

        with connection.cursor() as cursor:

            # Delete old signature

            cursor.execute(

                "DELETE FROM pch.msw_signature WHERE user_id = %s",

                [user_id]

            )

            # Insert new signature

            cursor.execute(

                "INSERT INTO pch.msw_signature (user_id, signature_image, file_name) VALUES (%s, %s, %s) RETURNING id",

                [user_id, contents, file.name]

            )

            sig_id = cursor.fetchone()[0]

        

        return Response({"id": sig_id, "message": "Signature saved"})

        

    except Exception as e:

        print(f"Upload signature error: {e}")

        import traceback

        traceback.print_exc()

        return Response({"error": str(e)}, status=500)



@api_view(['GET'])

@permission_classes([IsAuthenticated])

def get_signature(request, user_id):

    """Retrieve signature image from msw_signature table"""

    try:

        print(f'[DEBUG] Getting signature for user_id: {user_id}')

        ensure_signature_table()

        

        with connection.cursor() as cursor:

            # Debug: Check all signatures in the table

            cursor.execute("SELECT user_id, file_name, created_at FROM pch.msw_signature ORDER BY created_at DESC")

            all_sigs = cursor.fetchall()

            print(f'[DEBUG] All signatures in database: {all_sigs}')

            

            cursor.execute(

                "SELECT signature_image FROM pch.msw_signature WHERE user_id = %s ORDER BY created_at DESC LIMIT 1",

                [user_id]

            )

            result = cursor.fetchone()

            print(f'[DEBUG] Query result for user {user_id}: {result is not None and "Found signature" or "No signature found"}')

        

        if not result:

            print(f'[DEBUG] No signature found for user_id: {user_id}')

            return Response({"error": "No signature found"}, status=404)

        

        print(f'[DEBUG] Returning signature image ({len(result[0])} bytes)')

        return HttpResponse(result[0], content_type='image/png')

        

    except Exception as e:

        print(f"Get signature error: {e}")

        import traceback

        traceback.print_exc()

        return Response({"error": str(e)}, status=500)



@api_view(['GET'])

@permission_classes([IsAuthenticated])

def debug_signatures(request):

    """Debug endpoint to see all signatures in database"""

    try:

        ensure_signature_table()

        

        with connection.cursor() as cursor:

            cursor.execute("SELECT user_id, file_name, LENGTH(signature_image) as size, created_at FROM pch.msw_signature ORDER BY created_at DESC")

            signatures = cursor.fetchall()

            

        return Response({

            "total_signatures": len(signatures),

            "signatures": [

                {

                    "user_id": sig[0],

                    "file_name": sig[1], 

                    "size_bytes": sig[2],

                    "created_at": sig[3].isoformat() if sig[3] else None

                }

                for sig in signatures

            ]

        })

        

    except Exception as e:

        print(f"Debug signatures error: {e}")

        return Response({"error": str(e)}, status=500)


# ========== ACTIVITY LOGS API ==========

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_activity_logs(request):
    """
    GET /api/socialwork/activity-logs/
    Returns activity logs from the pch.activity_logs table.

    Query params:
      ?role=mayor|congressman|social_worker   (required — filters by module_name)
      ?limit=50                               (optional, default 50, max 200)
      ?offset=0                               (optional, default 0)

    Maps role → module_name filter:
      mayor        → 'MAYOR'
      congressman  → 'CONGRESSMAN'
      social_worker → 'SOCIAL_WORK'
    """
    from django.db import connection

    ROLE_MODULE_MAP = {
        'mayor':         'MAYOR',
        'congressman':   'CONGRESSMAN',
        'social_worker': 'SOCIAL_WORK',
    }

    role = request.query_params.get('role', '').lower()
    if role not in ROLE_MODULE_MAP:
        return Response(
            {'error': f'role must be one of: {list(ROLE_MODULE_MAP.keys())}'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        limit  = min(int(request.query_params.get('limit',  50)), 200)
        offset = max(int(request.query_params.get('offset',  0)),   0)
    except (TypeError, ValueError):
        limit, offset = 50, 0

    module_name = ROLE_MODULE_MAP[role]

    try:
        with connection.cursor() as cursor:
            # Try filtering by module_name first; fall back to all logs if empty
            cursor.execute("""
                SELECT
                    activity_id,
                    activity_datetime,
                    module_name,
                    submodule_name,
                    table_name,
                    action_type,
                    record_id,
                    patient_id,
                    description,
                    status,
                    ip_address,
                    device_info,
                    trail
                FROM pch.activity_logs
                WHERE module_name = %s
                ORDER BY activity_datetime DESC
                LIMIT %s OFFSET %s
            """, [module_name, limit, offset])

            rows = cursor.fetchall()
            columns = [col[0] for col in cursor.description]

            # If no rows for this module, return all recent logs
            if not rows:
                cursor.execute("""
                    SELECT
                        activity_id,
                        activity_datetime,
                        module_name,
                        submodule_name,
                        table_name,
                        action_type,
                        record_id,
                        patient_id,
                        description,
                        status,
                        ip_address,
                        device_info,
                        trail
                    FROM pch.activity_logs
                    ORDER BY activity_datetime DESC
                    LIMIT %s OFFSET %s
                """, [limit, offset])
                rows = cursor.fetchall()
                columns = [col[0] for col in cursor.description]

            # Count total for pagination
            cursor.execute(
                "SELECT COUNT(*) FROM pch.activity_logs WHERE module_name = %s",
                [module_name]
            )
            total = cursor.fetchone()[0]

        logs = []
        for row in rows:
            entry = dict(zip(columns, row))
            # Serialize datetime
            if entry.get('activity_datetime'):
                entry['activity_datetime'] = entry['activity_datetime'].isoformat()
            logs.append(entry)

        return Response({
            'success': True,
            'total':   total,
            'count':   len(logs),
            'logs':    logs,
        })

    except Exception as exc:
        import traceback
        print(f'[ERROR] list_activity_logs: {exc}')
        print(traceback.format_exc())
        return Response(
            {'success': False, 'error': str(exc)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_activity_log(request):
    """
    POST /api/socialwork/activity-logs/
    Body: {
        module_name, submodule_name (opt), table_name (opt),
        action_type, record_id (opt), patient_id (opt),
        description, status (opt), trail (opt)
    }
    Writes a new row to pch.activity_logs.
    """
    from django.db import connection
    import json as _json

    data = request.data
    module_name    = (data.get('module_name')    or '')[:20]
    submodule_name = (data.get('submodule_name') or '')[:30]
    table_name     = (data.get('table_name')     or '')[:50]
    action_type    = (data.get('action_type')    or 'UPDATE')[:20]
    record_id      = data.get('record_id')
    patient_id     = data.get('patient_id')
    description    = data.get('description') or ''
    log_status     = (data.get('status') or 'success')[:10]
    trail          = (data.get('trail') or '')[:120]

    # Auto-capture IP and device info
    x_forwarded = request.META.get('HTTP_X_FORWARDED_FOR')
    ip_address  = (x_forwarded.split(',')[0] if x_forwarded else request.META.get('REMOTE_ADDR', ''))[:45]
    device_info = (request.META.get('HTTP_USER_AGENT', ''))[:150]

    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                INSERT INTO pch.activity_logs (
                    activity_datetime, module_name, submodule_name, table_name,
                    action_type, record_id, patient_id, description,
                    status, ip_address, device_info, trail
                ) VALUES (
                    NOW(), %s, %s, %s,
                    %s, %s, %s, %s,
                    %s, %s, %s, %s
                ) RETURNING activity_id
            """, [
                module_name, submodule_name, table_name,
                action_type, record_id, patient_id, description,
                log_status, ip_address, device_info, trail,
            ])
            activity_id = cursor.fetchone()[0]

        return Response({'success': True, 'activity_id': activity_id},
                        status=status.HTTP_201_CREATED)

    except Exception as exc:
        import traceback
        print(f'[ERROR] create_activity_log: {exc}')
        return Response(
            {'success': False, 'error': str(exc)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


# ========== MONTHLY REPORT API ==========

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def monthly_report(request):
    """
    GET /api/socialwork/reports/monthly/
    Returns financial assistance report data from social_work_referrals
    joined with patient_profiling.

    Query params:
      ?month=May          (required, month name)
      ?year=2026          (required, year)
      ?doctor=All         (optional)
      ?status=All         (optional, Approved/Pending/Rejected)
    """
    from django.db import connection as _conn
    import calendar

    month_name = request.query_params.get('month', '').strip()
    year_str   = request.query_params.get('year', '').strip()
    doctor     = request.query_params.get('doctor', 'All').strip()
    status_filter = request.query_params.get('status', 'All').strip()

    # Convert month name to number
    month_map = {m: i for i, m in enumerate(
        ['January','February','March','April','May','June',
         'July','August','September','October','November','December'], 1)}
    month_num = month_map.get(month_name)

    try:
        year_num = int(year_str)
    except (TypeError, ValueError):
        year_num = None

    try:
        with _conn.cursor() as cur:
            # Build query joining social_work_referrals with patient_profiling
            sql = """
                SELECT
                    r.id,
                    COALESCE(
                        CONCAT(p.lastname, ', ', p.firstname,
                               CASE WHEN p.middlename IS NOT NULL AND p.middlename != ''
                                    THEN ' ' || p.middlename ELSE '' END),
                        r.patient_name,
                        'Unknown'
                    ) AS patient_name,
                    COALESCE(
                        DATE_PART('year', AGE(p.birthdate))::int,
                        r.age,
                        0
                    ) AS age,
                    COALESCE(
                        TO_CHAR(p.birthdate, 'DD/MM/YYYY'),
                        ''
                    ) AS birth_date,
                    COALESCE(r.address, '') AS address,
                    COALESCE(r.referral_source, 'OPD') AS remarks,
                    COALESCE(r.doctor, '') AS physician,
                    r.total_bill_amount,
                    r.discount_amount,
                    r.amount_after_discount,
                    r.assistance_amount,
                    r.assistance_type,
                    r.status,
                    r.referral_date,
                    r.classification
                FROM pch.social_work_referrals r
                LEFT JOIN pch.patient_profiling p ON p.patient_id = r.patient_id
                WHERE 1=1
            """
            params = []

            if month_num and year_num:
                sql += " AND EXTRACT(MONTH FROM r.referral_date) = %s"
                sql += " AND EXTRACT(YEAR  FROM r.referral_date) = %s"
                params += [month_num, year_num]

            if doctor and doctor != 'All':
                sql += " AND r.doctor ILIKE %s"
                params.append(f'%{doctor}%')

            if status_filter and status_filter != 'All':
                sql += " AND r.status ILIKE %s"
                params.append(f'%{status_filter}%')

            sql += " ORDER BY r.referral_date DESC, r.id DESC"

            cur.execute(sql, params)
            rows = cur.fetchall()
            cols = [c[0] for c in cur.description]

            # Also fetch distinct doctors for filter dropdown
            cur.execute("""
                SELECT DISTINCT doctor FROM pch.social_work_referrals
                WHERE doctor IS NOT NULL AND doctor != ''
                ORDER BY doctor
            """)
            doctors = ['All'] + [row[0] for row in cur.fetchall()]

        records = []
        for row in rows:
            rec = dict(zip(cols, row))
            # Map assistance_type to service columns
            # We use total_bill_amount as the base and distribute by assistance_type
            total = float(rec.get('total_bill_amount') or 0)
            assistance = float(rec.get('assistance_amount') or 0)
            atype = (rec.get('assistance_type') or '').lower()

            # Map assistance type to service column
            xray = ultrasound = laboratory = medicine = consultation = 0.0
            oxygen = surgical = newborn = screening = ecg = supplies = misc = 0.0

            if 'x-ray' in atype or 'xray' in atype:
                xray = total
            elif 'ultrasound' in atype:
                ultrasound = total
            elif 'lab' in atype:
                laboratory = total
            elif 'medicine' in atype or 'medic' in atype or 'drug' in atype:
                medicine = total
            elif 'consult' in atype:
                consultation = total
            elif 'oxygen' in atype:
                oxygen = total
            elif 'surgical' in atype or 'surgery' in atype:
                surgical = total
            elif 'newborn' in atype:
                newborn = total
            elif 'screening' in atype or 'ecg' in atype:
                ecg = total
            elif 'supplies' in atype or 'supply' in atype:
                supplies = total
            else:
                misc = total

            records.append({
                'id':           rec['id'],
                'name':         rec['patient_name'] or '',
                'age':          int(rec['age'] or 0),
                'birth_date':   rec['birth_date'] or '',
                'address':      rec['address'] or '',
                'remarks':      rec['remarks'] or '',
                'physician':    rec['physician'] or '',
                'xray':         xray,
                'ultrasound':   ultrasound,
                'laboratory':   laboratory,
                'medicine':     medicine,
                'consultation': consultation,
                'oxygen':       oxygen,
                'surgical':     surgical,
                'newborn':      newborn,
                'screening':    screening,
                'ecg':          ecg,
                'supplies':     supplies,
                'misc_charges': misc,
                'actual_charges': float(rec.get('discount_amount') or 0),
                'total_actual':   total,
                'total_approved': float(rec.get('amount_after_discount') or total),
                'mayor_handumon': 0.0,
                'almonete_maip':  0.0,
                'status':         rec.get('status') or '',
                'classification': rec.get('classification') or '',
            })

        return Response({
            'success': True,
            'count':   len(records),
            'records': records,
            'doctors': doctors,
            'month':   month_name,
            'year':    year_str,
        })

    except Exception as exc:
        import traceback
        print(f'[ERROR] monthly_report: {exc}')
        print(traceback.format_exc())
        return Response(
            {'success': False, 'error': str(exc)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )