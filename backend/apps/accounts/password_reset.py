"""
Password Reset functionality with OTP
Handles forgot password, OTP verification, and password reset
"""
import random
import string
from datetime import timedelta
from django.conf import settings
from django.core.mail import send_mail
from django.db import connection
from django.utils import timezone
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from .permissions import IsAdmin


def generate_otp(length=6):
    """Generate a random OTP code"""
    return ''.join(random.choices(string.digits, k=length))


def validate_password_strength(password):
    """
    Validate password strength
    Requirements:
    - At least 8 characters
    - At least 1 uppercase letter
    - At least 1 lowercase letter
    - At least 1 number
    """
    if len(password) < 8:
        return False, 'Password must be at least 8 characters long'
    
    if not any(char.isupper() for char in password):
        return False, 'Password must contain at least 1 uppercase letter'
    
    if not any(char.islower() for char in password):
        return False, 'Password must contain at least 1 lowercase letter'
    
    if not any(char.isdigit() for char in password):
        return False, 'Password must contain at least 1 number'
    
    return True, 'Password is valid'


@api_view(['POST'])
@permission_classes([AllowAny])
def verify_user_exists(request):
    """
    Verify if user exists by username or email
    POST data: { "username": "username" } or { "email": "email@example.com" }
    Returns: { "exists": true/false, "email": "masked_email" }
    """
    username = request.data.get('username')
    email = request.data.get('email')
    
    if not username and not email:
        return Response(
            {'error': 'Username or email is required'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    with connection.cursor() as cursor:
        if username:
            cursor.execute("""
                SELECT user_id, email, firstname, lastname
                FROM pch.users
                WHERE username = %s AND is_active = TRUE
            """, [username])
        else:
            cursor.execute("""
                SELECT user_id, email, firstname, lastname
                FROM pch.users
                WHERE email = %s AND is_active = TRUE
            """, [email])
        
        user = cursor.fetchone()
        
        if not user:
            return Response({
                'exists': False,
                'message': 'Account not found. Please check your username or email.'
            }, status=status.HTTP_200_OK)
        
        user_id, user_email, firstname, lastname = user
        masked_email = user_email[:3] + '***' + user_email[user_email.index('@'):]
        
        return Response({
            'exists': True,
            'email': masked_email,
            'message': 'Account found. You can proceed with password reset.'
        }, status=status.HTTP_200_OK)


def send_otp_email(email, otp_code, user_name):
    """Send OTP code via email"""
    subject = 'Plaridel Community Hospital - Password Reset OTP'
    message = f"""Hello {user_name},

You have requested to reset your password for your Plaridel Community Hospital account.

Your One-Time Password (OTP) is: {otp_code}

This OTP will expire in {settings.OTP_EXPIRY_MINUTES} minutes.

If you did not request this password reset, please ignore this email or contact your system administrator.

Best regards,
TECHCARE - PLARIDEL COMMUNITY HOSPITAL
"""
    
    try:
        send_mail(
            subject,
            message,
            settings.DEFAULT_FROM_EMAIL,
            [email],
            fail_silently=False,
        )
        return True
    except Exception as e:
        print(f"Error sending email: {str(e)}")
        return False


@api_view(['POST'])
@permission_classes([AllowAny])
def request_password_reset(request):
    """Request password reset - sends OTP to users email."""
    username = request.data.get('username')
    email = request.data.get('email')
    
    if not username and not email:
        return Response(
            {'error': 'Username or email is required'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    with connection.cursor() as cursor:
        if username:
            cursor.execute("""
                SELECT user_id, username, email, firstname, lastname
                FROM pch.users
                WHERE username = %s AND is_active = TRUE
            """, [username])
        else:
            cursor.execute("""
                SELECT user_id, username, email, firstname, lastname
                FROM pch.users
                WHERE email = %s AND is_active = TRUE
            """, [email])
        
        user = cursor.fetchone()
        
        if not user:
            return Response(
                {'message': 'If the account exists, an OTP has been sent to the registered email'},
                status=status.HTTP_200_OK
            )
        
        user_id, username, user_email, firstname, lastname = user
        
        if not user_email:
            return Response(
                {'error': 'No email address associated with this account. Please contact administrator.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        otp_code = generate_otp(settings.OTP_LENGTH)
        expires_at = timezone.now() + timedelta(minutes=settings.OTP_EXPIRY_MINUTES)
        ip_address = request.META.get('REMOTE_ADDR', '')
        
        cursor.execute("""
            UPDATE pch.password_reset_otp
            SET is_used = TRUE, used_at = %s
            WHERE user_id = %s AND is_used = FALSE
        """, [timezone.now(), user_id])
        
        cursor.execute("""
            INSERT INTO pch.password_reset_otp 
            (user_id, email, otp_code, expires_at, ip_address)
            VALUES (%s, %s, %s, %s, %s)
        """, [user_id, user_email, otp_code, expires_at, ip_address])
        
        user_name = f"{firstname} {lastname}".strip() or username
        email_sent = send_otp_email(user_email, otp_code, user_name)
        
        if not email_sent:
            return Response(
                {'error': 'Failed to send OTP email. Please try again later.'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    return Response({
        'message': 'OTP has been sent to your registered email address',
        'email': user_email[:3] + '***' + user_email[user_email.index('@'):]
    }, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([AllowAny])
def verify_otp_and_reset_password(request):
    """Verify OTP and reset password"""
    try:
        username = request.data.get('username')
        otp_code = request.data.get('otp_code')
        new_password = request.data.get('new_password', '')
        
        if not username or not otp_code:
            return Response(
                {'error': 'Username and OTP code are required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT user_id FROM pch.users WHERE username = %s
            """, [username])
            
            user = cursor.fetchone()
            if not user:
                return Response(
                    {'error': 'Invalid username or OTP'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            user_id = user[0]
            
            cursor.execute("""
                SELECT otp_id, expires_at, is_used
                FROM pch.password_reset_otp
                WHERE user_id = %s AND otp_code = %s
                ORDER BY created_at DESC
                LIMIT 1
            """, [user_id, otp_code])
            
            otp_record = cursor.fetchone()
            
            if not otp_record:
                return Response(
                    {'error': 'Invalid OTP code'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            otp_id, expires_at, is_used = otp_record
            
            if is_used:
                return Response(
                    {'error': 'This OTP has already been used'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            if timezone.now() > expires_at:
                return Response(
                    {'error': 'OTP has expired. Please request a new one.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            if not new_password or len(new_password) == 0:
                return Response({
                    'message': 'OTP verified successfully. You can now set your new password.',
                    'otp_verified': True
                }, status=status.HTTP_200_OK)
            
            is_valid, message = validate_password_strength(new_password)
            if not is_valid:
                return Response(
                    {'error': message},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            from django.contrib.auth.hashers import make_password
            hashed_password = make_password(new_password)
            
            cursor.execute("""
                UPDATE pch.users
                SET user_password = %s,
                    must_change_pw = FALSE,
                    updated_at = %s
                WHERE user_id = %s
            """, [hashed_password, timezone.now(), user_id])
            
            cursor.execute("""
                UPDATE pch.password_reset_otp
                SET is_used = TRUE, used_at = %s
                WHERE otp_id = %s
            """, [timezone.now(), otp_id])
        
        return Response({
            'message': 'Password has been reset successfully. You can now login with your new password.'
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        print(f"Error in verify_otp_and_reset_password: {str(e)}")
        return Response(
            {'error': f'Server error: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
@permission_classes([IsAuthenticated, IsAdmin])
def admin_reset_user_password(request, user_id):
    """Admin endpoint to reset any user's password"""
    new_password = request.data.get('new_password')
    
    if not new_password:
        return Response(
            {'error': 'New password is required'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    if len(new_password) < 8:
        return Response(
            {'error': 'Password must be at least 8 characters long'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    with connection.cursor() as cursor:
        cursor.execute("""
            SELECT username, email, firstname, lastname
            FROM pch.users
            WHERE user_id = %s
        """, [user_id])
        
        user = cursor.fetchone()
        if not user:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        username, email, firstname, lastname = user
        
        from django.contrib.auth.hashers import make_password
        hashed_password = make_password(new_password)
        
        cursor.execute("""
            UPDATE pch.users
            SET password = %s,
                must_change_pw = TRUE,
                updated_at = %s
            WHERE user_id = %s
        """, [hashed_password, timezone.now(), user_id])
        
        if email:
            try:
                user_name = f"{firstname} {lastname}".strip() or username
                subject = 'TECHCARE - Plaridel Community Hospital - Password Reset by Administrator'
                message = f"""Hello {user_name},

Your password has been reset by a system administrator.

Your temporary password is: {new_password}

For security reasons, you will be required to change this password upon your next login.

If you did not request this password reset, please contact your system administrator immediately.

Best regards,
TECHCARE - Plaridel Community Hospital
"""
                
                send_mail(
                    subject,
                    message,
                    settings.DEFAULT_FROM_EMAIL,
                    [email],
                    fail_silently=True,
                )
            except Exception as e:
                print(f"Error sending notification email: {str(e)}")
    
    return Response({
        'message': f'Password has been reset for user {username}. User will be required to change password on next login.'
    }, status=status.HTTP_200_OK)
