"""
URL configuration for Patient Portal app.
"""
from django.urls import path
from .views import (
    PatientProfileView,
    PatientAppointmentsView,
    PatientLabResultsView,
    PatientPrescriptionsView,
    UpdatePatientProfileView,
    patient_dashboard_stats
)

urlpatterns = [
    # Patient Profile
    path('profile/', PatientProfileView.as_view(), name='patient-profile'),
    path('profile/update/', UpdatePatientProfileView.as_view(), name='patient-profile-update'),
    
    # Patient Dashboard Stats
    path('dashboard/stats/', patient_dashboard_stats, name='patient-dashboard-stats'),
    
    # Patient Medical Records
    path('appointments/', PatientAppointmentsView.as_view(), name='patient-appointments'),
    path('lab-results/', PatientLabResultsView.as_view(), name='patient-lab-results'),
    path('prescriptions/', PatientPrescriptionsView.as_view(), name='patient-prescriptions'),
]
