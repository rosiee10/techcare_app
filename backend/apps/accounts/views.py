from rest_framework import generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth.hashers import check_password, make_password
from django.db import connection
from django.utils import timezone
from datetime import datetime

from .permissions import IsAdmin


def dict_fetchall(cursor):
    """Return all rows from a cursor as a dict"""
    columns = [col[0] for col in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


def dict_fetchone(cursor):
    """Return one row from a cursor as a dict"""
    columns = [col[0] for col in cursor.description]
    row = cursor.fetchone()
    return dict(zip(columns, row)) if row else None


@api_view(['POST'])
@permission_classes([AllowAny])
def login_view(request):
    """
    Secure login endpoint with JWT token generation
    Validates credentials against PostgreSQL users table
    Also supports patient login using hospital_id and lastname@hospital_id
    """
    username = request.data.get('username')
    password = request.data.get('password')

    if not username or not password:
        return Response(
            {'error': 'Username and password are required'},
            status=status.HTTP_400_BAD_REQUEST
        )

    with connection.cursor() as cursor:
        # Fetch user from database
        cursor.execute("""
            SELECT user_id, username, user_password, lastname, firstname,
                   middlename, user_role, deployment, sub_role, email, is_active,
                   is_verified, must_change_pw
            FROM pch.users
            WHERE username = %s
        """, [username])

        user = dict_fetchone(cursor)

        # If no user found, try patient login with hospital_id
        if not user:
            try:
                # Check if username is a hospital_id in patient_profiling
                cursor.execute("""
                    SELECT patient_id, hospital_id, lastname, firstname, middlename,
                           contact_number, birthdate, gender
                    FROM pch.patient_profiling
                    WHERE hospital_id = %s AND is_active = TRUE
                """, [username])

                patient = dict_fetchone(cursor)

                if patient:
                    # Expected password format: lastname@hospital_id (strip whitespace from lastname)
                    expected_password = f"{patient['lastname'].strip()}@{patient['hospital_id']}"

                    # Verify the provided password matches expected format (case-insensitive compare)
                    if password.upper() == expected_password.upper():
                        # Check if patient already has a user account
                        cursor.execute("""
                            SELECT user_id, username, user_password, user_role, is_active,
                                   is_verified, must_change_pw
                            FROM pch.users
                            WHERE username = %s AND user_role = 'patient'
                        """, [username])

                        existing_user = dict_fetchone(cursor)

                        if existing_user:
                            # Use existing user account
                            user = existing_user
                            user['firstname'] = patient['firstname']
                            user['lastname'] = patient['lastname']
                            user['middlename'] = patient['middlename']
                            user['email'] = None
                            user['deployment'] = None
                            user['sub_role'] = None
                        else:
                            # Create new user account for patient
                            hashed_password = make_password(password)
                            cursor.execute("""
                                INSERT INTO pch.users
                                (username, user_password, lastname, firstname, middlename,
                                 user_role, deployment, sub_role, email, contact_number,
                                 is_active, is_verified, must_change_pw, trail, updated_trail)
                                VALUES (%s, %s, %s, %s, %s, 'patient', '', '', NULL, '',
                                        TRUE, TRUE, TRUE, 'Patient Portal Auto-Created', 'Patient Portal Auto-Created')
                                RETURNING user_id
                            """, [username, hashed_password, patient['lastname'].strip(),
                                  patient['firstname'], patient['middlename'] or ''])

                            user_id = cursor.fetchone()[0]

                            user = {
                                'user_id': user_id,
                                'username': username,
                                'lastname': patient['lastname'].strip(),
                                'firstname': patient['firstname'],
                                'middlename': patient['middlename'],
                                'user_role': 'patient',
                                'deployment': None,
                                'sub_role': None,
                                'email': None,
                                'is_active': True,
                                'is_verified': True,
                                'must_change_pw': True,
                            }

                        # Update last login for patient user
                        cursor.execute("""
                            UPDATE pch.users
                            SET last_login = %s
                            WHERE user_id = %s
                        """, [timezone.now(), user['user_id']])

                        # Generate JWT tokens for patient
                        refresh = RefreshToken()
                        refresh['user_id'] = user['user_id']
                        refresh['username'] = user['username']
                        refresh['role'] = 'patient'
                        refresh['deployment'] = None

                        return Response({
                            'access': str(refresh.access_token),
                            'refresh': str(refresh),
                            'user': {
                                'id': user['user_id'],
                                'username': user['username'],
                                'firstname': user['firstname'],
                                'lastname': user['lastname'],
                                'middlename': user['middlename'],
                                'role': 'patient',
                                'deployment': None,
                                'sub_role': None,
                                'email': None,
                                'is_active': user.get('is_active', True),
                                'is_verified': user.get('is_verified', True),
                                'must_change_pw': user.get('must_change_pw', True),
                            }
                        })

                    else:
                        return Response(
                            {'error': 'Invalid credentials'},
                            status=status.HTTP_401_UNAUTHORIZED
                        )

                return Response(
                    {'error': 'Invalid credentials'},
                    status=status.HTTP_401_UNAUTHORIZED
                )
            except Exception as e:
                import traceback
                print(f"Patient login error: {str(e)}")
                print(traceback.format_exc())
                return Response(
                    {'error': f'Patient login failed: {str(e)}'},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )

        # Check if user is active
        if not user['is_active']:
            return Response(
                {'error': 'Account is deactivated. Contact administrator.'},
                status=status.HTTP_403_FORBIDDEN
            )

        # Verify password
        if not check_password(password, user['user_password']):
            return Response(
                {'error': 'Invalid credentials'},
                status=status.HTTP_401_UNAUTHORIZED
            )

        # Update last login
        cursor.execute("""
            UPDATE pch.users
            SET last_login = %s
            WHERE user_id = %s
        """, [timezone.now(), user['user_id']])

        # Generate JWT tokens
        refresh = RefreshToken()
        refresh['user_id'] = user['user_id']
        refresh['username'] = user['username']
        refresh['role'] = user['user_role']
        refresh['deployment'] = user['deployment']

        return Response({
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'user': {
                'id': user['user_id'],
                'username': user['username'],
                'firstname': user['firstname'],
                'lastname': user['lastname'],
                'middlename': user['middlename'],
                'role': user['user_role'],
                'deployment': user['deployment'],
                'sub_role': user['sub_role'],
                'email': user['email'],
                'is_active': user['is_active'],
                'is_verified': user['is_verified'],
                'must_change_pw': user['must_change_pw'],
            }
        })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_user(request):
    """Create new user - Admin only"""
    # Check if user is admin and get admin details
    with connection.cursor() as cursor:
        cursor.execute("""
            SELECT user_role, username, firstname, lastname, middlename 
            FROM pch.users WHERE user_id = %s
        """, [request.user.id])
        admin_user = cursor.fetchone()
        
        if not admin_user or admin_user[0] != 'ADMIN':
            return Response(
                {'error': 'Only administrators can create user accounts'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Format admin fullname
        admin_username = admin_user[1]
        admin_fullname = f"{admin_user[2]} {admin_user[4] + ' ' if admin_user[4] else ''}{admin_user[3]}".strip()
        current_datetime = timezone.now().strftime('%Y-%m-%d %H:%M:%S')
        trail_value = f"{admin_username}|{admin_fullname}|{current_datetime}"
    
    # Validate required fields
    required_fields = ['username', 'password', 'firstname', 'lastname', 'user_role', 'admin_password']
    for field in required_fields:
        if not request.data.get(field):
            return Response(
                {'error': f'{field} is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
    
    # Get user_role and deployment
    user_role_raw = request.data.get('user_role', '')
    user_role = str(user_role_raw).strip().upper()
    deployment = request.data.get('deployment')
    
    # Roles that don't require deployment
    # Using a flexible check for Social Work and Mayor's Office variants
    is_social_worker = 'SOCIAL' in user_role and ('WORK' in user_role or 'WORKER' in user_role)
    is_mayors_office = 'MAYOR' in user_role and 'OFFICE' in user_role
    
    roles_without_deployment = [
        'CASHIER', 'PHARMACIST', 'CONGRESSMAN', 'ICD CODER', 'ADMIN'
    ]
    
    # Validate deployment for roles that require it
    if not (is_social_worker or is_mayors_office or user_role in roles_without_deployment) and not deployment:
        print(f"DEBUG: Validation failed. Raw role: '{user_role_raw}', Normalized role: '{user_role}', Deployment: '{deployment}'")
        return Response(
            {'error': 'deployment is required'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Verify admin password for security
    admin_password = request.data.get('admin_password')
    with connection.cursor() as cursor:
        cursor.execute("""
            SELECT user_password FROM pch.users WHERE user_id = %s
        """, [request.user.id])
        admin_data = cursor.fetchone()
        
        if not admin_data or not check_password(admin_password, admin_data[0]):
            return Response(
                {'error': 'Invalid admin password. Account creation denied.'},
                status=status.HTTP_403_FORBIDDEN
            )
    
    username = request.data.get('username')
    password = request.data.get('password')
    firstname = request.data.get('firstname')
    lastname = request.data.get('lastname')
    middlename = request.data.get('middlename')
    name_ext = request.data.get('name_ext')
    user_role = request.data.get('user_role')
    deployment = request.data.get('deployment') or ''
    sub_role = request.data.get('sub_role')  # RN or ATTENDANT for nurses
    email = request.data.get('email')
    contact_number = request.data.get('contact_number')
    
    # Hash password
    hashed_password = make_password(password)
    
    with connection.cursor() as cursor:
        # Check if username already exists
        cursor.execute("""
            SELECT user_id FROM pch.users WHERE username = %s
        """, [username])
        
        if cursor.fetchone():
            return Response(
                {'error': 'Username already exists'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Create user
        cursor.execute("""
            INSERT INTO pch.users (
                username, user_password, lastname, firstname, middlename,
                name_ext, user_role, deployment, sub_role, email, contact_number,
                is_active, is_verified, must_change_pw, trail, updated_trail
            ) VALUES (
                %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
            ) RETURNING user_id
        """, [
            username, hashed_password, lastname, firstname, middlename,
            name_ext, user_role, deployment, sub_role, email, contact_number,
            True, True, True,  # is_active, is_verified, must_change_pw
            trail_value,
            trail_value
        ])
        
        user_id = cursor.fetchone()[0]
    
    return Response({
        'message': 'User created successfully',
        'user_id': user_id,
        'username': username
    }, status=status.HTTP_201_CREATED)


@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_user(request, user_id):
    """Update user - Admin only"""
    # Check if user is admin and get admin details
    with connection.cursor() as cursor:
        cursor.execute("""
            SELECT user_role, username, firstname, lastname, middlename 
            FROM pch.users WHERE user_id = %s
        """, [request.user.id])
        admin_user = cursor.fetchone()
        
        if not admin_user or admin_user[0] != 'ADMIN':
            return Response(
                {'error': 'Only administrators can update user accounts'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Format admin fullname and trail
        admin_username = admin_user[1]
        admin_fullname = f"{admin_user[2]} {admin_user[4] + ' ' if admin_user[4] else ''}{admin_user[3]}".strip()
        current_datetime = timezone.now().strftime('%Y-%m-%d %H:%M:%S')
        updated_trail_value = f"{admin_username}|{admin_fullname}|{current_datetime}"
        
        # Check if user exists
        cursor.execute("""
            SELECT user_id FROM pch.users WHERE user_id = %s
        """, [user_id])
        
        if not cursor.fetchone():
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Build update query dynamically based on provided fields
        update_fields = []
        params = []
        
        if 'firstname' in request.data:
            update_fields.append('firstname = %s')
            params.append(request.data['firstname'])
        
        if 'lastname' in request.data:
            update_fields.append('lastname = %s')
            params.append(request.data['lastname'])
        
        if 'middlename' in request.data:
            update_fields.append('middlename = %s')
            params.append(request.data.get('middlename'))
        
        if 'extname' in request.data:
            update_fields.append('name_ext = %s')
            params.append(request.data.get('extname'))
        
        if 'user_role' in request.data:
            update_fields.append('user_role = %s')
            params.append(request.data['user_role'])
        
        if 'deployment' in request.data:
            update_fields.append('deployment = %s')
            params.append(request.data['deployment'])
        
        if 'email' in request.data:
            update_fields.append('email = %s')
            params.append(request.data['email'])
        
        if 'contact_no' in request.data:
            update_fields.append('contact_number = %s')
            params.append(request.data.get('contact_no'))
        
        if 'is_active' in request.data:
            update_fields.append('is_active = %s')
            params.append(request.data['is_active'])
        
        # Always update the updated_trail
        update_fields.append('updated_trail = %s')
        params.append(updated_trail_value)
        
        if not update_fields:
            return Response(
                {'error': 'No fields to update'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Add user_id to params
        params.append(user_id)
        
        # Execute update
        cursor.execute(f"""
            UPDATE pch.users 
            SET {', '.join(update_fields)}
            WHERE user_id = %s
        """, params)
    
    return Response({
        'message': 'User updated successfully',
        'user_id': user_id
    }, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_users(request):
    """List all users - Admin only"""
    with connection.cursor() as cursor:
        cursor.execute("""
            SELECT user_role FROM pch.users WHERE user_id = %s
        """, [request.user.id])
        result = cursor.fetchone()
        
        if not result or result[0] != 'ADMIN':
            return Response(
                {'error': 'Only administrators can view user list'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        cursor.execute("""
            SELECT user_id, username, lastname, firstname, middlename, name_ext,
                   user_role, deployment, sub_role, email, contact_number,
                   is_active, last_login
            FROM pch.users
            ORDER BY lastname, firstname
        """)
        
        users = dict_fetchall(cursor)
        
        # Convert null values to empty strings for frontend compatibility
        for user in users:
            user['middlename'] = user.get('middlename') or ''
            user['name_ext'] = user.get('name_ext') or ''
            user['deployment'] = user.get('deployment') or ''
            user['sub_role'] = user.get('sub_role') or ''
            user['email'] = user.get('email') or ''
            user['contact_number'] = user.get('contact_number') or ''
    
    return Response({'users': users}, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_doctors(request):
    """List all active doctors excluding IPD"""
    with connection.cursor() as cursor:
        cursor.execute("""
            SELECT user_id, username, lastname, firstname, middlename, name_ext,
                   email, contact_number
            FROM pch.users
            WHERE user_role = 'DOCTOR' AND is_active = true AND deployment != 'IPD'
            ORDER BY lastname, firstname
        """)
        
        doctors = dict_fetchall(cursor)
    
    # Format doctor names
    formatted_doctors = []
    for doctor in doctors:
        full_name = f"Dr. {doctor['firstname']}"
        if doctor['middlename']:
            full_name += f" {doctor['middlename']}"
        full_name += f" {doctor['lastname']}"
        if doctor['name_ext']:
            full_name += f" {doctor['name_ext']}"
        
        formatted_doctors.append({
            'id': doctor['user_id'],
            'name': full_name,
            'username': doctor['username'],
            'email': doctor['email'],
            'contact_number': doctor['contact_number'],
        })
    
    return Response({
        'success': True,
        'data': formatted_doctors,
        'count': len(formatted_doctors)
    }, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def update_own_profile(request):
    """
    Update current user's own profile
    Users can only update their own personal information, not role/deployment
    """
    user_id = request.user.id
    
    # Get current user for audit trail
    with connection.cursor() as cursor:
        cursor.execute("""
            SELECT username, firstname, lastname, middlename 
            FROM pch.users WHERE user_id = %s
        """, [user_id])
        current_user = cursor.fetchone()
        
        if not current_user:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Format updated trail
        username = current_user[0]
        fullname = f"{current_user[2]} {current_user[3] + ' ' if current_user[3] else ''}{current_user[1]}".strip()
        current_datetime = timezone.now().strftime('%Y-%m-%d %H:%M:%S')
        updated_trail_value = f"{username}|{fullname}|{current_datetime}"
        
        # Build update query for allowed fields only
        update_fields = []
        params = []
        
        if 'firstname' in request.data:
            update_fields.append('firstname = %s')
            params.append(request.data['firstname'])
        
        if 'lastname' in request.data:
            update_fields.append('lastname = %s')
            params.append(request.data['lastname'])
        
        if 'middlename' in request.data:
            update_fields.append('middlename = %s')
            params.append(request.data.get('middlename'))
        
        if 'email' in request.data:
            update_fields.append('email = %s')
            params.append(request.data['email'])
        
        if 'contact_number' in request.data:
            update_fields.append('contact_number = %s')
            params.append(request.data.get('contact_number'))
        
        if not update_fields:
            return Response(
                {'error': 'No fields to update'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Add audit trail and user_id to params
        update_fields.append('updated_trail = %s')
        params.append(updated_trail_value)
        params.append(user_id)
        
        # Execute update
        cursor.execute(f"""
            UPDATE pch.users 
            SET {', '.join(update_fields)}
            WHERE user_id = %s
        """, params)
        
        # Get updated user data
        cursor.execute("""
            SELECT user_id, username, lastname, firstname, middlename,
                   user_role, deployment, sub_role, email, contact_number,
                   is_active, must_change_pw
            FROM pch.users
            WHERE user_id = %s
        """, [user_id])
        
        updated_user = dict_fetchone(cursor)
    
    return Response({
        'message': 'Profile updated successfully',
        'user': updated_user
    }, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_profile(request):
    """Get current user profile and permissions including user_profile table data"""
    with connection.cursor() as cursor:
        # Get user data from pch.users
        cursor.execute("""
            SELECT user_id, username, lastname, firstname, middlename, name_ext,
                   user_role, deployment, sub_role, email, contact_number,
                   is_active, is_verified, must_change_pw, last_login
            FROM pch.users
            WHERE user_id = %s
        """, [request.user.id])
        
        user = dict_fetchone(cursor)
        
        if not user:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Get profile data from user_profile table
        cursor.execute("""
            SELECT profile_id, gender, birthdate, civil_status,
                   street_address, barangay, city_municipal, province, zip_code,
                   emergency_contact_name, emergency_contact_number, emergency_contact_relationship,
                   profile_photo_url
            FROM user_profile
            WHERE user_id = %s
        """, [request.user.id])
        
        profile = dict_fetchone(cursor)
    
    # Define role-based permissions
    role = user['user_role'].upper().replace(' ', '_')
    permissions = {
        'is_admin': role == 'ADMIN',
        'is_doctor': role == 'DOCTOR',
        'is_nurse': role == 'NURSE',
        'is_clerk': role == 'CLERK',
        'is_lab_tech': role == 'LAB_TECH',
        'is_pharmacist': role == 'PHARMACIST',
        'is_cashier': role == 'CASHIER',
        'is_kitchen_staff': role == 'KITCHEN_STAFF',
        'is_social_worker': role in ['SOCIAL_WORKER', 'SOCIAL_WORK'],
        'can_manage_users': role == 'ADMIN',
        'can_view_patients': role in ['ADMIN', 'DOCTOR', 'NURSE', 'CLERK'],
        'can_prescribe': role == 'DOCTOR',
        'can_dispense_meds': role == 'PHARMACIST',
    }
    
    return Response({
        'user': user,
        'profile': profile,
        'permissions': permissions
    }, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def update_own_profile_full(request):
    """
    Update current user's full profile including user_profile table
    Users can update personal info, demographics, address, emergency contact, and bio
    """
    user_id = request.user.id
    
    with connection.cursor() as cursor:
        # Get current user for audit trail
        cursor.execute("""
            SELECT username, firstname, lastname, middlename 
            FROM pch.users WHERE user_id = %s
        """, [user_id])
        current_user = cursor.fetchone()
        
        if not current_user:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Format updated trail
        username = current_user[0]
        fullname = f"{current_user[2]} {current_user[3] + ' ' if current_user[3] else ''}{current_user[1]}".strip()
        current_datetime = timezone.now().strftime('%Y-%m-%d %H:%M:%S')
        updated_trail_value = f"{username}|{fullname}|{current_datetime}"
        
        # Update pch.users fields if provided
        user_update_fields = []
        user_params = []
        
        if 'firstname' in request.data:
            user_update_fields.append('firstname = %s')
            user_params.append(request.data['firstname'])
        
        if 'lastname' in request.data:
            user_update_fields.append('lastname = %s')
            user_params.append(request.data['lastname'])
        
        if 'middlename' in request.data:
            user_update_fields.append('middlename = %s')
            user_params.append(request.data.get('middlename'))
        
        if 'email' in request.data:
            user_update_fields.append('email = %s')
            user_params.append(request.data['email'])
        
        if 'contact_number' in request.data:
            user_update_fields.append('contact_number = %s')
            user_params.append(request.data.get('contact_number'))
        
        if user_update_fields:
            user_update_fields.append('updated_trail = %s')
            user_params.append(updated_trail_value)
            user_params.append(user_id)
            
            cursor.execute(f"""
                UPDATE pch.users 
                SET {', '.join(user_update_fields)}
                WHERE user_id = %s
            """, user_params)
        
        # Check if user_profile record exists
        cursor.execute("""
            SELECT profile_id FROM user_profile WHERE user_id = %s
        """, [user_id])
        
        profile_exists = cursor.fetchone()
        
        # Build user_profile update fields
        profile_fields = [
            'gender', 'birthdate', 'civil_status',
            'street_address', 'barangay', 'city_municipal', 'province', 'zip_code',
            'emergency_contact_name', 'emergency_contact_number', 'emergency_contact_relationship',
            'bio'
        ]
        
        profile_update_fields = []
        profile_params = []
        
        for field in profile_fields:
            if field in request.data:
                profile_update_fields.append(f'{field} = %s')
                profile_params.append(request.data.get(field))
        
        if profile_update_fields:
            if profile_exists:
                # Update existing profile
                profile_update_fields.append('updated_trail = %s')
                profile_params.append(updated_trail_value)
                profile_params.append(user_id)
                
                cursor.execute(f"""
                    UPDATE user_profile 
                    SET {', '.join(profile_update_fields)}
                    WHERE user_id = %s
                """, profile_params)
            else:
                # Create new profile record
                profile_insert_fields = ['user_id'] + [f for f in profile_fields if f in request.data]
                profile_insert_values = [user_id] + [request.data.get(f) for f in profile_fields if f in request.data]
                
                placeholders = ', '.join(['%s'] * len(profile_insert_values))
                
                cursor.execute(f"""
                    INSERT INTO user_profile ({', '.join(profile_insert_fields)})
                    VALUES ({placeholders})
                """, profile_insert_values)
        
        # Get updated user data
        cursor.execute("""
            SELECT user_id, username, lastname, firstname, middlename, name_ext,
                   user_role, deployment, sub_role, email, contact_number,
                   is_active, is_verified, must_change_pw
            FROM pch.users
            WHERE user_id = %s
        """, [user_id])
        
        updated_user = dict_fetchone(cursor)
        
        # Get updated profile data
        cursor.execute("""
            SELECT profile_id, gender, birthdate, civil_status,
                   street_address, barangay, city_municipal, province, zip_code,
                   emergency_contact_name, emergency_contact_number, emergency_contact_relationship,
                   profile_photo_url
            FROM user_profile
            WHERE user_id = %s
        """, [user_id])
        
        updated_profile = dict_fetchone(cursor)
    
    return Response({
        'message': 'Profile updated successfully',
        'user': updated_user,
        'profile': updated_profile
    }, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def change_password(request):
    """
    Change user password endpoint
    Requires current password verification
    Sets must_change_pw to False after successful change
    """
    current_password = request.data.get('current_password')
    new_password = request.data.get('new_password')
    
    if not current_password or not new_password:
        return Response(
            {'error': 'Current password and new password are required'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Validate new password strength
    if len(new_password) < 8:
        return Response(
            {'error': 'Password must be at least 8 characters long'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Check for uppercase letter
    if not any(c.isupper() for c in new_password):
        return Response(
            {'error': 'Password must contain at least one uppercase letter'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Check for lowercase letter
    if not any(c.islower() for c in new_password):
        return Response(
            {'error': 'Password must contain at least one lowercase letter'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Check for number
    if not any(c.isdigit() for c in new_password):
        return Response(
            {'error': 'Password must contain at least one number'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    with connection.cursor() as cursor:
        # Get current user data
        cursor.execute("""
            SELECT user_id, username, user_password, firstname, lastname
            FROM pch.users 
            WHERE user_id = %s
        """, [request.user.id])
        
        user = dict_fetchone(cursor)
        
        if not user:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Verify current password
        if not check_password(current_password, user['user_password']):
            return Response(
                {'error': 'Current password is incorrect'},
                status=status.HTTP_401_UNAUTHORIZED
            )
        
        # Check if new password is same as current
        if check_password(new_password, user['user_password']):
            return Response(
                {'error': 'New password must be different from current password'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Hash new password
        hashed_password = make_password(new_password)
        
        # Update password and set must_change_pw to False
        cursor.execute("""
            UPDATE pch.users 
            SET user_password = %s, 
                must_change_pw = FALSE,
                updated_at = %s
            WHERE user_id = %s
        """, [hashed_password, timezone.now(), user['user_id']])
        
        # Get updated user data
        cursor.execute("""
            SELECT user_id, username, firstname, lastname, middlename, 
                   user_role, deployment, email, must_change_pw
            FROM pch.users 
            WHERE user_id = %s
        """, [user['user_id']])
        
        updated_user = dict_fetchone(cursor)
    
    return Response({
        'message': 'Password changed successfully',
        'user': {
            'id': updated_user['user_id'],
            'username': updated_user['username'],
            'firstname': updated_user['firstname'],
            'lastname': updated_user['lastname'],
            'middlename': updated_user['middlename'],
            'role': updated_user['user_role'],
            'deployment': updated_user['deployment'],
            'email': updated_user['email'],
            'must_change_pw': updated_user['must_change_pw']
        }
    }, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout_view(request):
    """Logout endpoint - clears client-side tokens"""
    return Response({
        'message': 'Successfully logged out. Please clear tokens on client side.'
    }, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def reset_user_password(request, user_id):
    """
    Reset user password to default (Pch@2026) - Admin only
    Sets must_change_pw to True to force password change on next login
    """
    # Check if user is admin
    with connection.cursor() as cursor:
        cursor.execute("""
            SELECT user_role, username, firstname, lastname, middlename 
            FROM pch.users WHERE user_id = %s
        """, [request.user.id])
        admin_user = cursor.fetchone()
        
        if not admin_user or admin_user[0] != 'ADMIN':
            return Response(
                {'error': 'Only administrators can reset user passwords'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Format admin fullname and trail
        admin_username = admin_user[1]
        admin_fullname = f"{admin_user[2]} {admin_user[4] + ' ' if admin_user[4] else ''}{admin_user[3]}".strip()
        current_datetime = timezone.now().strftime('%Y-%m-%d %H:%M:%S')
        updated_trail_value = f"{admin_username}|{admin_fullname}|{current_datetime}"
        
        # Check if target user exists
        cursor.execute("""
            SELECT user_id, username, firstname, lastname 
            FROM pch.users WHERE user_id = %s
        """, [user_id])
        
        target_user = cursor.fetchone()
        
        if not target_user:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Hash the default password
        default_password = 'Pch@2026'
        hashed_password = make_password(default_password)
        
        # Update password and set must_change_pw to True
        cursor.execute("""
            UPDATE pch.users 
            SET user_password = %s, 
                must_change_pw = TRUE,
                updated_trail = %s,
                updated_at = %s
            WHERE user_id = %s
        """, [hashed_password, updated_trail_value, timezone.now(), user_id])
    
    return Response({
        'message': 'Password reset successfully',
        'new_password': default_password
    }, status=status.HTTP_200_OK)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def upload_profile_photo(request):
    """
    Upload profile photo for current user
    Stores photo in MEDIA_ROOT/profile_photos/
    Updates profile_photo field in user_profile table
    """
    try:
        if 'photo' not in request.FILES:
            return Response(
                {'error': 'No photo file provided'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        photo = request.FILES['photo']
        
        # Validate file type
        allowed_types = ['image/jpeg', 'image/png', 'image/jpg']
        if photo.content_type not in allowed_types:
            return Response(
                {'error': 'Only JPEG and PNG images are allowed'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Validate file size (max 5MB)
        if photo.size > 5 * 1024 * 1024:
            return Response(
                {'error': 'File size must be less than 5MB'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        user_id = request.user.id
        
        # Generate unique filename
        ext = photo.name.split('.')[-1]
        filename = f"user_{user_id}_{int(timezone.now().timestamp())}.{ext}"
        
        # Save file to media/profile_photos/
        from django.conf import settings
        import os
        
        upload_dir = os.path.join(settings.MEDIA_ROOT, 'profile_photos')
        os.makedirs(upload_dir, exist_ok=True)
        
        file_path = os.path.join(upload_dir, filename)
        
        with open(file_path, 'wb+') as destination:
            for chunk in photo.chunks():
                destination.write(chunk)
        
        # Update user_profile table with photo URL
        photo_url = f"/media/profile_photos/{filename}"
        
        with connection.cursor() as cursor:
            # Check if profile exists
            cursor.execute("""
                SELECT profile_id FROM user_profile WHERE user_id = %s
            """, [user_id])
            
            profile = cursor.fetchone()
            
            if profile:
                # Update existing profile
                cursor.execute("""
                    UPDATE user_profile 
                    SET profile_photo_url = %s,
                        updated_at = %s
                    WHERE user_id = %s
                """, [photo_url, timezone.now(), user_id])
            else:
                # Create new profile with photo
                cursor.execute("""
                    INSERT INTO user_profile (user_id, profile_photo_url, created_at, updated_at)
                    VALUES (%s, %s, %s, %s)
                """, [user_id, photo_url, timezone.now(), timezone.now()])
        
        return Response({
            'message': 'Profile photo uploaded successfully',
            'photo_url': photo_url
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        return Response({
            'error': f'Failed to upload photo: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_profile_photo(request):
    """
    Delete profile photo for current user
    """
    user_id = request.user.id
    
    with connection.cursor() as cursor:
        # Get current photo URL
        cursor.execute("""
            SELECT profile_photo_url FROM user_profile WHERE user_id = %s
        """, [user_id])
        
        result = cursor.fetchone()
        if not result or not result[0]:
            return Response(
                {'error': 'No profile photo found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        photo_url = result[0]
        
        # Delete file from storage
        from django.conf import settings
        import os
        
        if photo_url and photo_url.startswith('/media/'):
            file_path = os.path.join(settings.BASE_DIR, photo_url.lstrip('/'))
            if os.path.exists(file_path):
                os.remove(file_path)
        
        # Update database to remove photo URL
        cursor.execute("""
            UPDATE user_profile 
            SET profile_photo_url = NULL,
                updated_at = %s
            WHERE user_id = %s
        """, [timezone.now(), user_id])
    
    return Response({
        'message': 'Profile photo deleted successfully'
    }, status=status.HTTP_200_OK)
