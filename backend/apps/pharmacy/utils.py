from django.utils import timezone
from datetime import datetime
import pytz
from django.db import connection


def get_user_info_from_db(user_id):
    """
    Get user information from pch.users table by user_id.
    
    Args:
        user_id: The user ID from the request.user
    
    Returns:
        Dictionary with user info: complete_name, username, user_role, sub_role, deployment
    """
    user_info = {
        'complete_name': '',
        'username': '',
        'user_role': '',
        'sub_role': None,
        'deployment': None,
    }
    
    if not user_id:
        return user_info
    
    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT username, firstname, middlename, lastname, user_role, sub_role, deployment
                FROM pch.users
                WHERE user_id = %s
            """, [user_id])
            row = cursor.fetchone()
            
            if row:
                username, firstname, middlename, lastname, user_role, sub_role, deployment = row
                
                # Build complete name: firstname + middlename + lastname
                name_parts = []
                if firstname:
                    name_parts.append(firstname)
                if middlename:
                    name_parts.append(middlename)
                if lastname:
                    name_parts.append(lastname)
                complete_name = ' '.join(name_parts).strip() or username
                
                user_info = {
                    'complete_name': complete_name,
                    'username': username or '',
                    'user_role': user_role or '',
                    'sub_role': sub_role,
                    'deployment': deployment,
                }
    except Exception as e:
        print(f"Error fetching user info: {e}")
    
    return user_info


def format_trail(user, ip_address=None):
    """
    Format trail string with user information and Philippine timezone.
    
    Format: complete name | username | role | sub role (skip if null) | deployment (skip if null) | date and time | ip address
    
    Args:
        user: User object (can be request.user with user_id)
        ip_address: Client IP address (optional)
    
    Returns:
        Formatted trail string
    """
    # Get Philippine timezone
    ph_tz = pytz.timezone('Asia/Manila')
    now_ph = timezone.now().astimezone(ph_tz)
    datetime_str = now_ph.strftime('%Y-%m-%d %H:%M:%S')
    
    # Get user_id from user object
    user_id = getattr(user, 'id', None) or getattr(user, 'user_id', None)
    
    # Get user information from database
    user_info = get_user_info_from_db(user_id)
    
    complete_name = user_info['complete_name']
    username = user_info['username']
    user_role = user_info['user_role']
    sub_role = user_info['sub_role']
    deployment = user_info['deployment']
    
    # Build trail parts, skipping null sub_role and deployment
    parts = [
        complete_name,
        username,
        user_role,
    ]
    
    # Add sub_role only if not null
    if sub_role:
        parts.append(sub_role)
    
    # Add deployment only if not null
    if deployment:
        parts.append(deployment)
    
    # Add datetime and IP address
    parts.append(datetime_str)
    parts.append(ip_address or '127.0.0.1')
    
    return ' | '.join(str(part) for part in parts)


def get_client_ip(request):
    """
    Get client IP address from request.
    
    Args:
        request: Django request object
    
    Returns:
        IP address string
    """
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        ip = x_forwarded_for.split(',')[0].strip()
    else:
        ip = request.META.get('REMOTE_ADDR', '127.0.0.1')
    return ip
