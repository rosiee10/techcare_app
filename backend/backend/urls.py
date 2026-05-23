"""
URL configuration for backend project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/6.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from apps.admin_portal.views import (
    ContactMessageCreateView,
    ContactMessageListView,
    ContactMessageDetailView,
    ContactMessageStatsView,
    ContactMessageBulkUpdateView,
    ContactMessageReplyView,
)
from apps.admin_portal.dashboard_views import get_dashboard_stats

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/', include('apps.accounts.urls')),
    
    # Dashboard API
    path('api/admin/dashboard/stats/', get_dashboard_stats, name='dashboard-stats'),
    
    # Contact Messages API
    path('api/contact/submit/', ContactMessageCreateView.as_view(), name='contact-submit'),
    path('api/contact/messages/', ContactMessageListView.as_view(), name='contact-list'),
    path('api/contact/messages/<int:pk>/', ContactMessageDetailView.as_view(), name='contact-detail'),
    path('api/contact/messages/<int:pk>/reply/', ContactMessageReplyView.as_view(), name='contact-reply'),
    path('api/contact/stats/', ContactMessageStatsView.as_view(), name='contact-stats'),
    path('api/contact/bulk-update/', ContactMessageBulkUpdateView.as_view(), name='contact-bulk-update'),
    
    # Philippine Locations API
    path('api/locations/', include('apps.ph_locations.urls')),
    
    # OPD API (includes patients and rooms)
    path('api/opd/', include('apps.opd.urls')),
    
    # Legacy patient API route (for backward compatibility)
    path('api/patients/', include('apps.opd.urls')),
    
    # Patient Portal API
    path('api/patient/', include('apps.patient.urls')),
    
    # Chief Nurse API
    path('api/chief-nurse/', include('apps.chief_nurse.urls')),
    
    # Pharmacy API
    path('api/pharmacy/', include('apps.pharmacy.urls')),
    
    # Medistock API
    path('api/medistock/', include('apps.medistock.urls')),

    # IPD API
    path('api/ipd/', include('apps.ipd.urls')),

    # Social Work API
    path('api/socialwork/', include('apps.socialwork.urls')),

]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
