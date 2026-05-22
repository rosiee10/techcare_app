"""
URL configuration for Chief Nurse app.
"""
from django.urls import path, include
from .views import (
    WardDashboardView,
    NurseAssignmentsView,
    PatientStatusView,
    BedManagementView,
    NursingScheduleView,
    chief_nurse_dashboard_stats,
)


urlpatterns = [
    # Dashboard Stats
    path('dashboard/stats/', chief_nurse_dashboard_stats, name='chief-nurse-dashboard-stats'),
    
    # Ward Management
    path('wards/', WardDashboardView.as_view(), name='chief-nurse-wards'),
    
    # Nurse Management
    path('nurses/assignments/', NurseAssignmentsView.as_view(), name='chief-nurse-assignments'),
    path('nurses/schedule/', NursingScheduleView.as_view(), name='chief-nurse-schedule'),
    
    # Patient Management
    path('patients/status/', PatientStatusView.as_view(), name='chief-nurse-patient-status'),
    
    # Bed Management
    path('beds/', BedManagementView.as_view(), name='chief-nurse-beds'),
    
    # Pharmacy Module (Your code - all routes in pharmacy/urls.py)
    path('pharmacy/', include('apps.chief_nurse.pharmacy.urls')),
    
    # Kitchen Module (Classmate's code)
    path('kitchen/', include('apps.chief_nurse.kitchen.urls')),
]
