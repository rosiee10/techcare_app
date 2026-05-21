"""
URL configuration for OPD app.
"""
from django.urls import path
from .views import (
    PatientListView, PatientUpdateView, PatientRegistrationView,
    RoomLocationView, OpdServiceView, CreateServiceView, DeleteServiceView
)

urlpatterns = [
    # Room Location API endpoints
    path('rooms/', RoomLocationView.as_view(), name='room-list'),
    path('rooms/<int:pk>/', RoomLocationView.as_view(), name='room-detail'),
    
    # OPD Services API endpoints
    path('services/', OpdServiceView.as_view(), name='service-list'),
    path('services/create/', CreateServiceView.as_view(), name='service-create'),
    path('services/<int:pk>/delete/', DeleteServiceView.as_view(), name='service-delete'),
    
    # Patient API endpoints
    path('', PatientListView.as_view(), name='patient-list'),
    path('register/', PatientRegistrationView.as_view(), name='patient-register'),
    path('<int:pk>/update/', PatientUpdateView.as_view(), name='patient-update'),
]
