from django.urls import path
from . import views

urlpatterns = [
    path('', views.notification_list, name='notification-list'),
    path('unread-count/', views.unread_count_view, name='notification-unread-count'),
    path('generate/', views.generate_notifications, name='notification-generate'),
    path('<int:pk>/read/', views.mark_read, name='notification-mark-read'),
    path('mark-all-read/', views.mark_all_read, name='notification-mark-all-read'),
    path('<int:pk>/delete/', views.delete_notification, name='notification-delete'),
]
