# Chief Nurse - Kitchen URLs
# Your classmate should add kitchen-related URL routes here

from django.urls import path
from . import views

urlpatterns = [
    # Dashboard
    path('dashboard/', views.KitchenDashboardView.as_view(), name='chief_nurse_kitchen_dashboard'),
    
    # Orders
    path('orders/', views.KitchenOrdersView.as_view(), name='chief_nurse_kitchen_orders'),
    
    # Your classmate should add more kitchen routes here
]
