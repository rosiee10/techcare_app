from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'endorsements', views.EndorsementViewSet, basename='endorsement')

urlpatterns = [
    path('', include(router.urls)),

    # ── Notification API ──────────────────────────────────────────────────
    path('notifications/',                                    views.list_notifications,           name='msw_notifications_list'),
    path('notifications/count/',                              views.unread_notification_count,    name='msw_notifications_count'),
    path('notifications/<int:notification_id>/read/',         views.mark_notification_read,       name='msw_notification_read'),
    path('notifications/<int:notification_id>/delete/',       views.delete_notification,          name='msw_notification_delete'),
    path('notifications/read-all/',                           views.mark_all_notifications_read,  name='msw_notifications_read_all'),
    path('notifications/delete-all/',                         views.delete_all_notifications,     name='msw_notifications_delete_all'),

    # ── Report API ────────────────────────────────────────────────────────
    # GET  reports/stats/?office=Mayor's Office&period=all
    path('reports/stats/',  views.endorsement_report_stats, name='msw_report_stats'),
    # GET  reports/csv/?office=Mayor's Office&period=this_month
    path('reports/csv/',    views.endorsement_report_csv,   name='msw_report_csv'),

    # ── Social Work Referrals ────────────────────────────────────────────
    path('referrals/',                views.list_referrals,    name='msw_referrals_list'),
    path('referrals/<int:pk>/',       views.referral_detail,   name='msw_referral_detail'),

    # ── Eligibility Screening (msw_assessments) ─────────────────────────
    path('assessments/',              views.create_assessment, name='msw_assessment_create'),

    # ── Document Management (msw_documents) ─────────────────────────────
    path('documents/',                views.documents,         name='msw_documents_list'),
    path('documents/<int:document_id>/', views.document_detail, name='msw_document_detail'),

    # ── Signature API ─────────────────────────────────────────────────────
    path('api/signatures/upload',           views.upload_signature,   name='upload_signature'),
    path('api/signatures/<int:user_id>',    views.get_signature,      name='get_signature'),
    path('api/signatures/debug',            views.debug_signatures,   name='debug_signatures'),
    # ── Activity Logs ─────────────────────────────────────────────────────
    path('activity-logs/',  views.list_activity_logs,   name='msw_activity_logs_list'),
    path('activity-logs/create/', views.create_activity_log, name='msw_activity_log_create'),

    # ── Monthly Report ────────────────────────────────────────────────────
    path('reports/monthly/', views.monthly_report, name='msw_monthly_report'),
]
