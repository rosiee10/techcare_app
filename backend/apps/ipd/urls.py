"""
URL Configuration for IPD app
"""
from django.urls import path, include
from . import views

app_name = 'ipd'

urlpatterns = [
    # Inventory and Request module (Dispensing Sheet, Cart Form, Stock Card)
    path('requests/', include('apps.ipd.inventory_and_request.urls')),

    # Notice of Admission
    path('notice-of-admission/', views.create_notice_of_admission, name='create_notice_of_admission'),
    path('notice-of-admission/pending/', views.list_pending_admissions, name='list_pending_admissions'),
    path('notice-of-admission/<str:hospital_id>/', views.get_notice_of_admission, name='get_notice_of_admission'),

    # Maternity Patient Info
    path('maternity-patient-info/', views.save_maternity_patient_info, name='save_maternity_patient_info'),
    path('maternity-patient-info/<str:hospital_id>/', views.get_maternity_patient_info, name='get_maternity_patient_info'),

    # Vital Signs
    path('vital-signs/', views.save_vital_signs, name='save_vital_signs'),
    path('vital-signs/<str:hospital_id>/', views.get_vital_signs, name='get_vital_signs'),

    # Doctor's Order
    path('doctors-order/', views.save_doctors_order, name='save_doctors_order'),
    path('doctors-order/<str:hospital_id>/', views.get_doctors_order, name='get_doctors_order'),
    path('doctors-order/delete/<int:order_id>/', views.delete_doctors_order, name='delete_doctors_order'),

    # IVF Sheet
    path('ivf-sheet/', views.save_ivf_sheet, name='save_ivf_sheet'),
    path('ivf-sheet/<str:hospital_id>/', views.get_ivf_sheet, name='get_ivf_sheet'),

    # Medication Sheet
    path('medication-sheet/', views.save_medication_sheet, name='save_medication_sheet'),
    path('medication-sheet/<str:hospital_id>/', views.get_medication_sheet, name='get_medication_sheet'),

    # Medication STAT & PRN
    path('medication-stat-prn/', views.save_medication_stat_prn, name='save_medication_stat_prn'),
    path('medication-stat-prn/<str:hospital_id>/', views.get_medication_stat_prn, name='get_medication_stat_prn'),

    # Nurses Notes
    path('nurses-notes/', views.save_nurses_notes, name='save_nurses_notes'),
    path('nurses-notes/<str:hospital_id>/', views.get_nurses_notes, name='get_nurses_notes'),

    # TPR Sheet
    path('tpr-sheet/', views.save_tpr_sheet, name='save_tpr_sheet'),
    path('tpr-sheet/<str:hospital_id>/', views.get_tpr_sheet, name='get_tpr_sheet'),

    # I&O Monitoring
    path('io-monitoring/', views.save_io_monitoring, name='save_io_monitoring'),
    path('io-monitoring/<str:hospital_id>/', views.get_io_monitoring, name='get_io_monitoring'),

    # Consent Form
    path('consent-form/', views.save_consent_form, name='save_consent_form'),
    path('consent-form/<str:hospital_id>/', views.get_consent_form, name='get_consent_form'),

    # Clinical History
    path('clinical-history/', views.save_clinical_history, name='save_clinical_history'),
    path('clinical-history/<str:hospital_id>/', views.get_clinical_history, name='get_clinical_history'),

    # Physical Exam Continued
    path('physical-exam-continued/', views.save_physical_exam_continued, name='save_physical_exam_continued'),
    path('physical-exam-continued/<str:hospital_id>/', views.get_physical_exam_continued, name='get_physical_exam_continued'),

    # Clinical Abstract
    path('clinical-abstract/', views.save_clinical_abstract, name='save_clinical_abstract'),
    path('clinical-abstract/<str:hospital_id>/', views.get_clinical_abstract, name='get_clinical_abstract'),

    # Discharge Plan
    path('discharge-plan/', views.save_discharge_plan, name='save_discharge_plan'),
    path('discharge-plan/<str:hospital_id>/', views.get_discharge_plan, name='get_discharge_plan'),

    # Discharge Notice
    path('discharge-notice/', views.save_discharge_notice, name='save_discharge_notice'),
    path('discharge-notice/<str:hospital_id>/', views.get_discharge_notice, name='get_discharge_notice'),

    # Clinical Referral
    path('clinical-referral/', views.save_clinical_referral, name='save_clinical_referral'),
    path('clinical-referral/<str:hospital_id>/', views.get_clinical_referral, name='get_clinical_referral'),

    # Informed Consent Surgery
    path('informed-consent-surgery/', views.save_informed_consent_surgery, name='save_informed_consent_surgery'),
    path('informed-consent-surgery/<str:hospital_id>/', views.get_informed_consent_surgery, name='get_informed_consent_surgery'),

    # Refusal of Treatment
    path('refusal-of-treatment/', views.save_refusal_of_treatment, name='save_refusal_of_treatment'),
    path('refusal-of-treatment/<str:hospital_id>/', views.get_refusal_of_treatment, name='get_refusal_of_treatment'),

    # Discharge Slip
    path('discharge-slip/', views.save_discharge_slip, name='save_discharge_slip'),
    path('discharge-slip/<str:hospital_id>/', views.get_discharge_slip, name='get_discharge_slip'),

    # Bed Assignment
    path('update-bed-assignment/', views.update_patient_bed_assignment, name='update_patient_bed_assignment'),

    # Diet List
    path('diet-list/', views.save_diet_list, name='save_diet_list'),
    path('diet-list/<str:hospital_id>/', views.get_diet_list, name='get_diet_list'),

    # Weekly Statistics
    path('weekly-stats/', views.weekly_stats, name='weekly_stats'),
    path('weekly-forecast/', views.weekly_forecast, name='weekly_forecast'),

    # ARIMA Forecasting endpoints
    path('forecast/', views.disease_forecast, name='disease_forecast'),
    path('forecast/<str:disease_name>/', views.disease_forecast_detail, name='disease_forecast_detail'),
    path('forecast-alerts/', views.forecast_alerts, name='forecast_alerts'),
]
