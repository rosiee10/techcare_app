"""
URL configuration for OPD app.
"""
from django.urls import path
from . import views

urlpatterns = [
    path('', views.PatientListView.as_view(), name='patient-list'),
    path('register/', views.PatientRegistrationView.as_view(), name='patient-register'),
    path('photo/upload/', views.upload_patient_photo, name='patient-photo-upload'),
    path('service-schedule/', views.ServiceScheduleView.as_view(), name='service-schedule'),
    path('available-services/', views.AvailableServicesView.as_view(), name='available-services'),
    path('<str:hospital_id>/', views.PatientUpdateView.as_view(), name='patient-update'),
]
