from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    login_view,
    create_user,
    update_user,
    list_users,
    list_doctors,
    get_user_profile,
    update_own_profile,
    update_own_profile_full,
    change_password,
    logout_view,
    reset_user_password,
    upload_profile_photo,
    delete_profile_photo
)
from .password_reset import (
    request_password_reset,
    verify_otp_and_reset_password,
    admin_reset_user_password,
    verify_user_exists
)
from .settings_views import (
    get_user_settings,
    update_user_settings
)

urlpatterns = [
    # Authentication
    path('login/', login_view, name='login'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('change-password/', change_password, name='change_password'),
    path('logout/', logout_view, name='logout'),
    
    # User Management (Admin only)
    path('users/create/', create_user, name='create_user'),
    path('users/<int:user_id>/update/', update_user, name='update_user'),
    path('users/<int:user_id>/reset-password/', reset_user_password, name='reset_user_password'),
    path('users/list/', list_users, name='list_users'),
    path('doctors/list/', list_doctors, name='list_doctors'),
    
    # User Profile
    path('profile/', get_user_profile, name='user_profile'),
    path('profile/update/', update_own_profile, name='update_own_profile'),
    path('profile/update-full/', update_own_profile_full, name='update_own_profile_full'),
    path('profile/photo/', upload_profile_photo, name='upload_profile_photo'),
    path('profile/photo/delete/', delete_profile_photo, name='delete_profile_photo'),
    
    # Password Reset (Forgot Password)
    path('password-reset/verify-user/', verify_user_exists, name='verify_user_exists'),
    path('password-reset/request/', request_password_reset, name='request_password_reset'),
    path('password-reset/verify/', verify_otp_and_reset_password, name='verify_otp_reset'),
    path('users/<int:user_id>/admin-reset-password/', admin_reset_user_password, name='admin_reset_password'),
    
    # User Settings
    path('settings/', get_user_settings, name='get_user_settings'),
    path('settings/update/', update_user_settings, name='update_user_settings'),
]
