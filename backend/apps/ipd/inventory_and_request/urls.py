"""
URL Configuration for IPD Inventory and Request module
"""
from django.urls import path
from . import views

urlpatterns = [
    # Inventory
    path('inventory/', views.IpdCartInventoryView.as_view(), name='ipd-cart-inventory'),
    path('inventory/pharmacy/', views.PharmacyInventoryView.as_view(), name='ipd-pharmacy-inventory'),
    
    # Patient Search
    path('patients/search/', views.IpdPatientSearchView.as_view(), name='ipd-patient-search'),
    path('patients/<int:patient_id>/', views.IpdPatientDetailView.as_view(), name='ipd-patient-detail'),
    
    # ==================== DISPENSING SHEET ====================
    path('dispensing/', views.DispensingSheetListView.as_view(), name='dispensing-list'),
    path('dispensing/create/', views.DispensingSheetCreateView.as_view(), name='dispensing-create'),
    path('dispensing/<int:dispensing_id>/', views.DispensingSheetDetailView.as_view(), name='dispensing-detail'),
    path('dispensing/<int:dispensing_id>/status/', views.DispensingSheetUpdateStatusView.as_view(), name='dispensing-status'),
    path('dispensing/<int:dispensing_id>/dispense/', views.DispensingSheetDispenseView.as_view(), name='dispensing-dispense'),
    
    # ==================== CART FORM ====================
    path('cart/', views.CartFormListView.as_view(), name='cart-list'),
    path('cart/create/', views.CartFormCreateView.as_view(), name='cart-create'),
    path('cart/<int:cart_form_id>/', views.CartFormDetailView.as_view(), name='cart-detail'),
    path('cart/<int:cart_form_id>/status/', views.CartFormUpdateStatusView.as_view(), name='cart-status'),
    path('cart/<int:cart_form_id>/verify/', views.CartFormVerifyView.as_view(), name='cart-verify'),
]
