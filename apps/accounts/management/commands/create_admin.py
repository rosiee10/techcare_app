from django.core.management.base import BaseCommand
from django.contrib.auth.hashers import make_password
from django.db import connection


class Command(BaseCommand):
    help = 'Creates initial admin account for TechCare Hospital Management System'

    def handle(self, *args, **options):
        username = 'admin'
        password = 'Admin@2026'  # Default password - must be changed on first login
        
        # Hash the password using Django's secure password hasher
        hashed_password = make_password(password)
        
        with connection.cursor() as cursor:
            # Check if admin already exists
            cursor.execute(
                "SELECT user_id FROM pch.users WHERE username = %s",
                [username]
            )
            
            if cursor.fetchone():
                self.stdout.write(
                    self.style.WARNING(f'Admin user "{username}" already exists.')
                )
                return
            
            # Create admin user
            cursor.execute("""
                INSERT INTO pch.users (
                    username,
                    user_password,
                    lastname,
                    firstname,
                    middlename,
                    name_ext,
                    user_role,
                    deployment,
                    email,
                    contact_number,
                    is_active,
                    is_verified,
                    must_change_pw,
                    trail,
                    updated_trail
                ) VALUES (
                    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
                )
            """, [
                username,
                hashed_password,
                'Administrator',
                'System',
                None,
                None,
                'ADMIN',
                'ADMIN',
                'admin@techcare.hospital',
                '09123456789',
                True,
                True,
                True,  # Must change password on first login
                'System Created',
                'Initial Setup'
            ])
        
        self.stdout.write(
            self.style.SUCCESS(
                f'Successfully created admin user "{username}" with password "{password}"'
            )
        )
        self.stdout.write(
            self.style.WARNING(
                'IMPORTANT: Admin must change password on first login for security.'
            )
        )
