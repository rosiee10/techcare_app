from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views
from . import views_forecasting
from . import views_invoice
from . import views_sms
from .views_invoice import (
    save_opd_billing, save_nbb_social_work, save_philhealth_billing,
    save_nonmed_billing, save_promissory_note, update_soa_status,
    cashier_ipd_invoices, cashier_opd_invoices, social_work_referrals_list,
    cashier_promissory_notes_list,
)

router = DefaultRouter()
router.register(r'diagnosis', views.DiagnosisMaintenanceViewSet, basename='diagnosis')
router.register(r'lab-categories', views.LabCategoryViewSet, basename='lab-category')
router.register(r'lab-details', views.LabDetailViewSet, basename='lab-detail')

urlpatterns = [
    path('', include(router.urls)),
    path('forecast/diagnosis/', views_forecasting.diagnosis_forecast, name='forecast-diagnosis'),
    path('forecast/pricing/', views_forecasting.pricing_forecast, name='forecast-pricing'),
    path('forecast/summary/', views_forecasting.forecast_summary, name='forecast-summary'),
    path('forecast/revenue/', views_forecasting.revenue_forecast, name='forecast-revenue'),
    path('forecast/cashier-kpis/', views_forecasting.cashier_financial_kpis, name='forecast-cashier-kpis'),
    path('cashier/dashboard-summary/', views_forecasting.cashier_dashboard_summary, name='cashier-dashboard-summary'),
    path('invoices/', views_invoice.billing_invoices_list, name='billing-invoices'),
    path('opd-billing/save/', save_opd_billing, name='save-opd-billing'),
    path('sms/send-pn/', views_sms.send_pn_sms, name='send-pn-sms'),
    path('sms/test/', views_sms.test_sms, name='test-sms'),
    path('social-work/save/', save_nbb_social_work, name='save-nbb-social-work'),
    path('social-work/referrals/', social_work_referrals_list, name='social-work-referrals'),
    path('philhealth-billing/save/', save_philhealth_billing, name='save-philhealth-billing'),
    path('nonmed-billing/save/', save_nonmed_billing, name='save-nonmed-billing'),
    path('promissory-notes/save/', save_promissory_note, name='save-promissory-note'),
    path('cashier/ipd-invoices/', cashier_ipd_invoices, name='cashier-ipd-invoices'),
    path('cashier/opd-invoices/', cashier_opd_invoices, name='cashier-opd-invoices'),
    path('cashier/promissory-notes/', cashier_promissory_notes_list, name='cashier-promissory-notes'),
    path('cashier/update-soa-status/', update_soa_status, name='cashier-update-soa-status'),
]
