"""
Views for OPD app - Patient registration and management.
"""
import json
import os
from datetime import datetime
from django.conf import settings
from django.utils import timezone

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import api_view, permission_classes
from django.db import transaction
from .models import PatientProfiling, EmergencyContact, OpdServiceSchedule
from .serializers import PatientProfilingSerializer, EmergencyContactSerializer, PatientListSerializer
from .permissions import CanEditPatientData, validate_field_permissions, get_immutable_fields
from .audit import log_patient_update, log_patient_change
from apps.ph_locations.models import Province, City, Barangay


def convert_psgc_codes_to_names(data):
    """
    Convert PSGC codes to location names.
    
    Args:
        data: Dictionary containing province, city_municipal, barangay codes
    
    Returns:
        Dictionary with codes converted to names
    """
    result = {}
    
    # Convert province code to name
    if 'province' in data and data['province']:
        try:
            province = Province.objects.get(code=data['province'])
            result['province'] = province.name
        except Province.DoesNotExist:
            result['province'] = data['province']  # Keep code if not found
    
    # Convert city code to name
    if 'city_municipal' in data and data['city_municipal']:
        try:
            city = City.objects.get(code=data['city_municipal'])
            result['city_municipal'] = city.name
        except City.DoesNotExist:
            result['city_municipal'] = data['city_municipal']  # Keep code if not found
    
    # Convert barangay code to name
    if 'barangay' in data and data['barangay']:
        try:
            barangay = Barangay.objects.get(code=data['barangay'])
            result['barangay'] = barangay.name
        except Barangay.DoesNotExist:
            result['barangay'] = data['barangay']  # Keep code if not found
    
    return result


class PatientRegistrationView(APIView):
    """
    API endpoint for registering a new patient.
    """
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        try:
            # Get user info for audit trail
            user = request.user
            username = user.username
            fullname = f"{user.firstname} {user.lastname}" if hasattr(user, 'firstname') else username
            role = getattr(user, 'role', 'UNKNOWN')
            subrole = getattr(user, 'subrole', None)
            deployment = getattr(user, 'deployment', None)
            ip_address = request.META.get('REMOTE_ADDR', 'unknown')
            timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            
            # Build trail string conditionally (skip null values)
            trail_parts = [username, fullname, role]
            if subrole:
                trail_parts.append(subrole)
            if deployment:
                trail_parts.append(deployment)
            trail_parts.extend([timestamp, ip_address])
            trail = ' | '.join(trail_parts)
            
            # Parse patient data from request (including address fields)
            patient_data = {
                'lastname': request.data.get('lastname', ''),
                'firstname': request.data.get('firstname', ''),
                'middlename': request.data.get('middlename', ''),
                'ext': request.data.get('ext', ''),
                'birthdate': request.data.get('birthdate', ''),
                'gender': request.data.get('gender', ''),
                'civil_status': request.data.get('civil_status', ''),
                'religion': request.data.get('religion', ''),
                'contact_number': request.data.get('contact_number', ''),
                'purok': request.data.get('purok', ''),
                'barangay': request.data.get('barangay', ''),
                'city_municipal': request.data.get('city_municipal', ''),
                'province': request.data.get('province', ''),
                'current_status': request.data.get('current_status', 'OUTPATIENT'),
                'trail': trail,
                'updated_trail': trail,
            }
            
            # Validate required fields including address
            required_fields = ['lastname', 'firstname', 'birthdate', 'gender', 'civil_status', 'barangay', 'city_municipal', 'province', 'contact_number']
            missing_fields = [field for field in required_fields if not patient_data.get(field)]
            
            if missing_fields:
                return Response({
                    'success': False,
                    'error': f"Missing required fields: {', '.join(missing_fields)}"
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Validate emergency contact required fields
            emergency_required = ['emergency_name', 'emergency_relationship', 'emergency_contact', 
                                  'emergency_province', 'emergency_city', 'emergency_barangay']
            emergency_missing = [field for field in emergency_required if not request.data.get(field)]
            
            if emergency_missing:
                return Response({
                    'success': False,
                    'error': f"Missing emergency contact fields: {', '.join(emergency_missing)}"
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Get photo_url if provided (photo is uploaded separately via /photo/upload/ endpoint)
            photo_url = request.data.get('photo_url', '')
            if photo_url:
                patient_data['photo_url'] = photo_url
                print(f"\n=== PHOTO URL DEBUG ===")
                print(f"Photo URL received: {photo_url}")
            else:
                print(f"\n=== NO PHOTO URL PROVIDED ===")
            
            # Create patient with transaction
            with transaction.atomic():
                # Create patient record
                patient = PatientProfiling.objects.create(**patient_data)
                
                # Generate hospital_id (format: 00-00-XX where XX is patient_id)
                patient.hospital_id = f"00-00-{patient.patient_id:02d}"
                patient.save()
                
                # Create emergency contact record (with address fields)
                emergency_data = {
                    'patient': patient,
                    'contact_name': request.data.get('emergency_name', ''),
                    'relationship': request.data.get('emergency_relationship', ''),
                    'contact_number': request.data.get('emergency_contact', ''),
                    'purok': request.data.get('emergency_purok', ''),
                    'barangay': request.data.get('emergency_barangay', ''),
                    'city_municipal': request.data.get('emergency_city', ''),
                    'province': request.data.get('emergency_province', ''),
                    'trail': trail,
                    'updated_trail': trail,
                    'updated_at': datetime.now(),
                }
                emergency_contact = EmergencyContact.objects.create(**emergency_data)
                
                # Update patient with emergency contact reference
                patient.current_emergency_contact = emergency_contact
                patient.save()
            
            return Response({
                'success': True,
                'message': 'Patient registered successfully',
                'patient_id': patient.patient_id
            }, status=status.HTTP_201_CREATED)
            
        except Exception as e:
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)


class PatientListView(APIView):
    """
    API endpoint for listing all patients with search and filter support.
    GET /api/patients/ - List all patients
    Query parameters:
        - search: Search by hospital_id, patient_id, firstname, lastname
        - status: Filter by status (Outpatient, Inpatient, Emergency)
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        try:
            # Start with all active patients
            queryset = PatientProfiling.objects.filter(is_active=True).order_by('-updated_at')
            
            # Apply search filter
            search_query = request.query_params.get('search', '').strip()
            if search_query:
                from django.db.models import Q
                queryset = queryset.filter(
                    Q(hospital_id__icontains=search_query) |
                    Q(patient_id__icontains=search_query) |
                    Q(firstname__icontains=search_query) |
                    Q(lastname__icontains=search_query)
                )
            
            # Apply status filter
            status_filter = request.query_params.get('status', '').strip()
            if status_filter and status_filter != 'All Status':
                status_map = {
                    'Outpatient': 'OUTPATIENT',
                    'Inpatient': 'INPATIENT',
                    'Emergency': 'EMERGENCY',
                }
                db_status = status_map.get(status_filter)
                if db_status:
                    queryset = queryset.filter(current_status=db_status)
            
            # Serialize data
            serializer = PatientListSerializer(queryset, many=True)
            
            return Response({
                'success': True,
                'count': queryset.count(),
                'results': serializer.data
            })
        except Exception as e:
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def upload_patient_photo(request):
    """
    Upload patient photo temporarily
    Stores photo in MEDIA_ROOT/patient_photos/
    Returns photo URL for use in patient registration
    """
    try:
        if 'photo' not in request.FILES:
            return Response(
                {'error': 'No photo file provided'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        photo = request.FILES['photo']
        
        # Validate file type
        allowed_types = ['image/jpeg', 'image/png', 'image/jpg', 'image/webp', 'image/gif']
        if photo.content_type not in allowed_types:
            return Response(
                {'error': f'Invalid file type: {photo.content_type}. Only JPEG, PNG, WEBP, and GIF images are allowed'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Validate file size (max 5MB)
        if photo.size > 5 * 1024 * 1024:
            return Response(
                {'error': 'File size must be less than 5MB'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Generate unique filename
        ext = photo.name.split('.')[-1] if '.' in photo.name else 'jpg'
        filename = f"patient_{int(timezone.now().timestamp())}.{ext}"
        
        # Save file to media/patient_photos/
        upload_dir = os.path.join(settings.MEDIA_ROOT, 'patient_photos')
        os.makedirs(upload_dir, exist_ok=True)
        
        file_path = os.path.join(upload_dir, filename)
        
        with open(file_path, 'wb+') as destination:
            for chunk in photo.chunks():
                destination.write(chunk)
        
        # Return photo URL
        photo_url = f"{settings.MEDIA_URL}patient_photos/{filename}"
        
        return Response({
            'success': True,
            'message': 'Patient photo uploaded successfully',
            'photo_url': photo_url
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        return Response({
            'error': f'Failed to upload photo: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class PatientUpdateView(APIView):
    """
    API endpoint for updating patient information.
    PUT/PATCH /api/patients/<hospital_id>/
    
    Security features:
    - Role-based permissions (OPD Clerk, Nurse, Admin)
    - Field-level validation
    - Immutable field protection
    - Audit logging of all changes
    - Before/after value tracking
    """
    permission_classes = [IsAuthenticated, CanEditPatientData]
    
    def patch(self, request, hospital_id):
        """
        Partially update patient information.
        Only updates fields provided in request.
        """
        print(f"\n=== PATCH REQUEST DEBUG ===")
        print(f"Hospital ID: {hospital_id}")
        print(f"Request data: {request.data}")
        print(f"User: {request.user}")
        print(f"User role: {getattr(request.user, 'role', 'UNKNOWN')}")
        
        try:
            # Get patient
            try:
                patient = PatientProfiling.objects.get(hospital_id=hospital_id, is_active=True)
                print(f"Patient found: {patient.hospital_id}")
            except PatientProfiling.DoesNotExist:
                return Response({
                    'success': False,
                    'error': f'Patient with hospital ID {hospital_id} not found'
                }, status=status.HTTP_404_NOT_FOUND)
            
            # Check object-level permission
            self.check_object_permissions(request, patient)
            
            # Get user info for audit trail
            user = request.user
            user_role = getattr(user, 'role', 'UNKNOWN')
            
            # Get fields to update
            update_data = request.data.copy()
            
            # Extract emergency contact data if present
            emergency_contact_data = update_data.pop('emergency_contact', None)
            
            fields_to_update = list(update_data.keys())
            
            # Remove metadata fields if present
            metadata_fields = ['reason', 'updated_by']
            for field in metadata_fields:
                if field in fields_to_update:
                    fields_to_update.remove(field)
            
            # Validate field permissions
            print(f"Fields to update: {fields_to_update}")
            print(f"User role: {user_role}")
            is_valid, error_msg = validate_field_permissions(user_role, fields_to_update)
            print(f"Validation result: {is_valid}, {error_msg}")
            if not is_valid:
                print(f"PERMISSION DENIED: {error_msg}")
                return Response({
                    'success': False,
                    'error': error_msg
                }, status=status.HTTP_403_FORBIDDEN)
            
            # Check for immutable fields
            immutable_fields = get_immutable_fields()
            attempted_immutable = [f for f in fields_to_update if f in immutable_fields]
            if attempted_immutable:
                return Response({
                    'success': False,
                    'error': f'Cannot modify immutable fields: {", ".join(attempted_immutable)}'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Track changes for audit log
            changes = {}
            
            # Convert PSGC codes to location names for patient data
            print(f"\n=== BEFORE CONVERSION ===")
            print(f"Patient data: province={update_data.get('province')}, city={update_data.get('city_municipal')}, barangay={update_data.get('barangay')}")
            location_names = convert_psgc_codes_to_names(update_data)
            print(f"Converted names: {location_names}")
            update_data.update(location_names)
            print(f"After update: province={update_data.get('province')}, city={update_data.get('city_municipal')}, barangay={update_data.get('barangay')}")
            
            # Convert PSGC codes to location names for emergency contact data
            if emergency_contact_data:
                print(f"Emergency contact data: province={emergency_contact_data.get('province')}, city={emergency_contact_data.get('city_municipal')}, barangay={emergency_contact_data.get('barangay')}")
                emergency_location_names = convert_psgc_codes_to_names(emergency_contact_data)
                print(f"Emergency converted names: {emergency_location_names}")
                emergency_contact_data.update(emergency_location_names)
            
            # Update patient with transaction
            with transaction.atomic():
                # Build updated trail
                username = user.username
                fullname = f"{user.firstname} {user.lastname}" if hasattr(user, 'firstname') else username
                role = user_role
                subrole = getattr(user, 'subrole', None)
                deployment = getattr(user, 'deployment', None)
                ip_address = request.META.get('REMOTE_ADDR', 'unknown')
                timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                
                trail_parts = [username, fullname, role]
                if subrole:
                    trail_parts.append(subrole)
                if deployment:
                    trail_parts.append(deployment)
                trail_parts.extend([timestamp, ip_address])
                updated_trail = ' | '.join(trail_parts)
                
                # Update each field and track changes
                for field_name in fields_to_update:
                    if hasattr(patient, field_name):
                        old_value = getattr(patient, field_name)
                        new_value = update_data[field_name]
                        
                        # Convert date strings to date objects
                        if field_name == 'birthdate' and isinstance(new_value, str):
                            from datetime import datetime as dt
                            new_value = dt.strptime(new_value, '%Y-%m-%d').date()
                        
                        # Only update if value changed
                        if old_value != new_value:
                            changes[field_name] = (old_value, new_value)
                            setattr(patient, field_name, new_value)
                
                # Update emergency contact if provided
                if emergency_contact_data:
                    emergency_contact = patient.current_emergency_contact
                    if emergency_contact:
                        # Map frontend field names to model field names
                        field_mapping = {
                            'contact_name': 'contact_name',
                            'relationship': 'relationship',
                            'contact_number': 'contact_number',
                            'purok': 'purok',
                            'province': 'province',
                            'city_municipal': 'city_municipal',
                            'barangay': 'barangay',
                        }
                        
                        for frontend_field, model_field in field_mapping.items():
                            if frontend_field in emergency_contact_data:
                                new_value = emergency_contact_data[frontend_field]
                                if hasattr(emergency_contact, model_field):
                                    old_value = getattr(emergency_contact, model_field)
                                    if old_value != new_value:
                                        changes[f'emergency_contact.{model_field}'] = (old_value, new_value)
                                        setattr(emergency_contact, model_field, new_value)
                        
                        emergency_contact.updated_trail = updated_trail
                        emergency_contact.updated_at = datetime.now()
                        emergency_contact.save()
                
                # Update trail
                patient.updated_trail = updated_trail
                patient.updated_at = datetime.now()
                patient.save()
                
                # Log changes to audit trail
                # TODO: Implement audit logging using activity_logs table
                # reason = request.data.get('reason', '')
                # if changes:
                #     log_patient_update(
                #         patient=patient,
                #         user=user,
                #         request=request,
                #         changes_dict=changes,
                #         reason=reason
                #     )
            
            # Return updated patient data
            serializer = PatientListSerializer(patient)
            
            return Response({
                'success': True,
                'message': f'Patient information updated successfully. {len(changes)} field(s) changed.',
                'changes': len(changes),
                'patient': serializer.data
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            import traceback
            print(f"\n=== EXCEPTION OCCURRED IN PATCH ===")
            print(f"Error: {str(e)}")
            print(f"Traceback:\n{traceback.format_exc()}")
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)
    
    def put(self, request, hospital_id):
        """
        Full update of patient information.
        Requires all fields to be provided.
        """
        # For now, redirect to PATCH for partial updates
        # Full PUT can be implemented if needed
        return self.patch(request, hospital_id)


class ServiceScheduleView(APIView):
    """
    API View for OPD Service Schedule.
    GET: Returns list of all active services with their schedules.
    PATCH: Toggle service active_today status.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """Get all active service schedules"""
        try:
            # Import model here to avoid circular imports
            from .models import OpdServiceSchedule
            from .serializers import ServiceScheduleSerializer

            services = OpdServiceSchedule.objects.filter(is_active=True).order_by('id')
            serializer = ServiceScheduleSerializer(services, many=True)

            return Response({
                'success': True,
                'data': serializer.data,
                'current_day_index': self._get_current_day_index(),
            })
        except Exception as e:
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    def patch(self, request):
        """Update service schedule (toggle day, active_today, or per-day hours)"""
        try:
            from .models import OpdServiceSchedule
            from datetime import datetime

            service_id = request.data.get('id')
            field = request.data.get('field')  # 'active_today', 'days_open', or per-day schedule
            value = request.data.get('value')

            service = OpdServiceSchedule.objects.get(id=service_id)

            if field == 'active_today':
                service.active_today = value
            elif field == 'days_open':
                service.days_open = value
            elif field == 'daily_hours':
                # Update per-day schedule
                # value format: {'Mon': {'open': '07:00', 'close': '17:00'}, ...}
                for day_code, hours in value.items():
                    if hours and 'open' in hours and 'close' in hours:
                        open_time = datetime.strptime(hours['open'], '%H:%M').time()
                        close_time = datetime.strptime(hours['close'], '%H:%M').time()
                        service.set_hours_for_day(day_code, open_time, close_time)
                    else:
                        service.set_hours_for_day(day_code, None, None)

            # Also handle active_today if passed alongside other fields
            if 'active_today' in request.data:
                service.active_today = request.data.get('active_today')

            service.save()

            return Response({
                'success': True,
                'message': 'Service schedule updated'
            })
        except OpdServiceSchedule.DoesNotExist:
            return Response({
                'success': False,
                'error': 'Service not found'
            }, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    def _get_current_day_index(self):
        """Get current day index (0=MON, 5=SAT, -1=SUNDAY)"""
        import datetime
        weekday = datetime.datetime.now().weekday()  # 0=MON, 6=SUN
        if weekday == 6:  # Sunday
            return -1
        return weekday


class AvailableServicesView(APIView):
    """Return only services that are currently open for visit scheduling"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        from datetime import datetime

        now = datetime.now()
        current_time = now.time()
        days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
        day_abbr = days[now.weekday()]

        available_services = []

        for service in OpdServiceSchedule.objects.filter(is_active=True):
            # Get per-day hours for today
            open_time, close_time = service.get_hours_for_day(day_abbr)

            # Check if scheduled today (has hours set for today)
            is_scheduled_today = open_time is not None and close_time is not None

            # Check operating hours using per-day schedule
            is_within_hours = False
            if is_scheduled_today:
                is_within_hours = open_time <= current_time <= close_time

            # Service is available if scheduled today AND within hours, OR active_today is True
            if (is_scheduled_today and is_within_hours) or service.active_today:
                available_services.append({
                    'id': service.id,
                    'service': service.service,
                    'service_label': service.service_label,
                })

        return Response({
            'success': True,
            'count': len(available_services),
            'data': available_services
        })
