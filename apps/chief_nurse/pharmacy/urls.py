"""
Chief Nurse - Pharmacy URLs
All pharmacy-related URL routes for Chief Nurse.
"""
from django.urls import path
from . import views

urlpatterns = [
    # Dashboard & Stats
    path('dashboard/', views.PharmacyDashboardView.as_view(), name='chief_nurse_pharmacy_dashboard'),
    path('purchase-requests/stats/', views.get_pharmacy_pr_stats, name='chief_nurse_pharmacy_pr_stats'),
    
    # Purchase Requests
    path('purchase-requests/', views.get_pharmacy_purchase_requests, name='chief_nurse_pharmacy_pr_list'),
    path('purchase-requests/<int:pr_id>/approve/', views.approve_pharmacy_purchase_request, name='chief_nurse_pharmacy_pr_approve'),
]
