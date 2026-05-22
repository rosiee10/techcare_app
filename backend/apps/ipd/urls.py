"""
URL Configuration for IPD app
"""
from django.urls import path, include

urlpatterns = [
    # Inventory and Request module (Dispensing Sheet, Cart Form)
    path('requests/', include('apps.ipd.inventory_and_request.urls')),
]
