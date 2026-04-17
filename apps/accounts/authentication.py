from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework.exceptions import AuthenticationFailed
from django.db import connection


class CustomJWTAuthentication(JWTAuthentication):
    """
    Custom JWT authentication that works with PostgreSQL users table
    """
    
    def get_user(self, validated_token):
        """
        Retrieve user from PostgreSQL database using user_id from token
        """
        try:
            user_id = validated_token.get('user_id')
            
            if not user_id:
                raise AuthenticationFailed('Token contained no recognizable user identification')
            
            with connection.cursor() as cursor:
                cursor.execute("""
                    SELECT user_id, username, user_role, deployment, is_active
                    FROM pch.users
                    WHERE user_id = %s
                """, [user_id])
                
                row = cursor.fetchone()
                
                if not row:
                    raise AuthenticationFailed('User not found')
                
                # Create a simple user object
                class User:
                    def __init__(self, user_id, username, role, deployment, is_active):
                        self.id = user_id
                        self.user_id = user_id
                        self.username = username
                        self.role = role
                        self.deployment = deployment
                        self.is_active = is_active
                        self.is_authenticated = True
                    
                    def __str__(self):
                        return self.username
                
                user = User(
                    user_id=row[0],
                    username=row[1],
                    role=row[2],
                    deployment=row[3],
                    is_active=row[4]
                )
                
                if not user.is_active:
                    raise AuthenticationFailed('User account is disabled')
                
                return user
                
        except Exception as e:
            raise AuthenticationFailed(f'Authentication failed: {str(e)}')
