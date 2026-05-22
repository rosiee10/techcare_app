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

    def _calculate_active_today(self, service):
        """Calculate if service should be active today based on schedule and time"""
        from datetime import datetime
        
        now = datetime.now()
        current_time = now.time()
        days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
        day_abbr = days[now.weekday()]
        
        # Check if today is in the weekly schedule
        is_scheduled_today = day_abbr in (service.days_open or '')
        
        if not is_scheduled_today:
            return False
        
        # Get operating hours for today
        open_time, close_time = service.get_hours_for_day(day_abbr)
        
        if open_time is None or close_time is None:
            return False
        
        # Check if current time is within operating hours
        return open_time <= current_time <= close_time

    def _was_manually_updated_today(self, service):
        """Check if service was manually updated today"""
        from datetime import datetime
        if service.updated_at:
            now = datetime.now()
            return (service.updated_at.year == now.year and 
                    service.updated_at.month == now.month and 
                    service.updated_at.day == now.day)
        return False

    def get(self, request):
        """Get all active service schedules with auto-updated active_today (respects manual changes)"""
        try:
            # Import model here to avoid circular imports
            from .models import OpdServiceSchedule
            from .serializers import ServiceScheduleSerializer
            from datetime import datetime

            services = OpdServiceSchedule.objects.filter(is_active=True).order_by('id')
            now = datetime.now()
            
            # Auto-update active_today for each service based on schedule
            # BUT skip if manually updated today (respect manual override)
            for service in services:
                # Check if manually updated today
                was_manual = self._was_manually_updated_today(service)
                print(f"DEBUG {service.service}: active_today={service.active_today}, updated_at={service.updated_at}, was_manual={was_manual}", flush=True)
                
                if was_manual:
                    # Skip auto-update - respect manual setting
                    print(f"DEBUG {service.service}: SKIPPING auto-update (manual today)", flush=True)
                    continue
                
                # Auto-calculate based on schedule
                calculated_status = self._calculate_active_today(service)
                print(f"DEBUG {service.service}: calculated={calculated_status}, current={service.active_today}", flush=True)
                if service.active_today != calculated_status:
                    service.active_today = calculated_status
                    service.updated_at = now  # Set timestamp for tracking
                    service.save(update_fields=['active_today', 'updated_at'])
                    print(f"DEBUG {service.service}: UPDATED to {calculated_status}", flush=True)
            
            # Refresh queryset after updates
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
                # value format: {'Mon': {'open': '7:00 AM', 'close': '5:00 PM'}, ...}
                for day_code, hours in value.items():
                    if hours and 'open' in hours and 'close' in hours:
                        try:
                            # Try 12-hour format first (from frontend: "7:00 AM")
                            open_time = datetime.strptime(hours['open'], '%I:%M %p').time()
                            close_time = datetime.strptime(hours['close'], '%I:%M %p').time()
                        except ValueError:
                            try:
                                # Fallback to 24-hour format
                                open_time = datetime.strptime(hours['open'], '%H:%M').time()
                                close_time = datetime.strptime(hours['close'], '%H:%M').time()
                            except ValueError:
                                # Skip if format is invalid
                                continue
                        service.set_hours_for_day(day_code, open_time, close_time)
                    else:
                        service.set_hours_for_day(day_code, None, None)

            # Also handle active_today if passed alongside other fields
            if 'active_today' in request.data:
                service.active_today = request.data.get('active_today')

            # Handle color_theme update
            if 'color_theme' in request.data:
                service.color_theme = request.data.get('color_theme')

            # Update timestamp to track manual changes (prevents auto-override today)
            service.updated_at = datetime.now()
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

    def post(self, request):
        """Dedicated endpoint for toggling active_today with timestamp tracking"""
        try:
            from .models import OpdServiceSchedule
            from datetime import datetime

            service_id = request.data.get('id')
            new_status = request.data.get('active_today')  # True or False

            service = OpdServiceSchedule.objects.get(id=service_id)
            
            # Update active_today
            service.active_today = new_status
            # Set timestamp to NOW to mark as manual change today
            service.updated_at = datetime.now()
            service.save()

            return Response({
                'success': True,
                'message': f'Service {service.service} set to {"Open" if new_status else "Closed"}',
                'active_today': service.active_today,
                'updated_at': service.updated_at.isoformat() if service.updated_at else None
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
        """Return only services that are currently open (active_today=True from database)"""
        available_services = []

        for service in OpdServiceSchedule.objects.filter(is_active=True, active_today=True):
            available_services.append({
                'id': service.id,
                'service': service.service,
                'service_label': service.service_label,
                'is_open_today': True,
                'active_today': service.active_today,
            })

        return Response({
            'success': True,
            'count': len(available_services),
            'data': available_services
        })


class CreateServiceView(APIView):
    """Create a new OPD service schedule"""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        """Create a new service with schedule configuration"""
        try:
            from .models import OpdServiceSchedule
            from datetime import datetime

            # Get data from request
            service_name = request.data.get('service', '').upper()
            service_label = request.data.get('service_label', service_name)
            color_theme = request.data.get('color_theme', '#2196F3')
            open_time = request.data.get('open_time', '07:00')
            close_time = request.data.get('close_time', '17:00')
            days_open = request.data.get('days_open', 'Mon,Tue,Wed,Thu,Fri')

            if not service_name:
                return Response({
                    'success': False,
                    'error': 'Service name is required'
                }, status=status.HTTP_400_BAD_REQUEST)

            # Parse days_open to set individual day fields
            days_list = days_open.split(',') if days_open else []

            # Parse time strings to TimeField format
            from datetime import datetime as dt
            def parse_time(time_str):
                try:
                    return dt.strptime(time_str, '%H:%M').time()
                except:
                    return None

            open_time_obj = parse_time(open_time) if open_time else None
            close_time_obj = parse_time(close_time) if close_time else None

            # Create the service schedule
            service = OpdServiceSchedule.objects.create(
                service=service_name,
                service_label=service_label,
                color_theme=color_theme,
                days_open=days_open,
                # Set hours for selected days only
                mon_open=open_time_obj if 'Mon' in days_list else None,
                mon_close=close_time_obj if 'Mon' in days_list else None,
                tue_open=open_time_obj if 'Tue' in days_list else None,
                tue_close=close_time_obj if 'Tue' in days_list else None,
                wed_open=open_time_obj if 'Wed' in days_list else None,
                wed_close=close_time_obj if 'Wed' in days_list else None,
                thu_open=open_time_obj if 'Thu' in days_list else None,
                thu_close=close_time_obj if 'Thu' in days_list else None,
                fri_open=open_time_obj if 'Fri' in days_list else None,
                fri_close=close_time_obj if 'Fri' in days_list else None,
                sat_open=open_time_obj if 'Sat' in days_list else None,
                sat_close=close_time_obj if 'Sat' in days_list else None,
                is_active=True,
                active_today=False,  # Will be auto-updated by schedule
                updated_at=datetime.now(),
            )

            return Response({
                'success': True,
                'message': f'Service {service_name} created successfully',
                'data': {
                    'id': service.id,
                    'service': service.service,
                    'service_label': service.service_label,
                }
            }, status=status.HTTP_201_CREATED)

        except Exception as e:
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class DeleteServiceView(APIView):
    """Soft-delete (deactivate) an OPD service"""
    permission_classes = [IsAuthenticated]

    def delete(self, request, service_id):
        """Soft-delete service by setting is_active=False"""
        try:
            from .models import OpdServiceSchedule
            from datetime import datetime

            service = OpdServiceSchedule.objects.get(id=service_id)
            
            # Soft delete - set is_active to False
            service.is_active = False
            service.updated_at = datetime.now()
            service.save()

            return Response({
                'success': True,
                'message': f'Service {service.service} deleted successfully'
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

class RoomLocationView(APIView):
    """API View for OPD Room Locations (opd_room_location table)"""
    permission_classes = [IsAuthenticated]
    
    def _get_client_ip(self, request):
        """Get client IP address from request"""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip
    
    def _get_user_info(self, request):
        """Get user info from authenticated request"""
        user = request.user
        try:
            from django.db import connection
            with connection.cursor() as cursor:
                cursor.execute("""
                    SELECT username, firstname, lastname, user_role, deployment
                    FROM pch.users
                    WHERE user_id = %s
                """, [user.id])
                result = cursor.fetchone()
                if result:
                    username, firstname, lastname, user_role, deployment = result
                    fullname = f"{firstname} {lastname}".strip()
                    return {
                        'username': username,
                        'fullname': fullname,
                        'role': user_role,
                        'deployment': deployment
                    }
        except Exception:
            pass
        return {
            'username': user.username,
            'fullname': getattr(user, 'first_name', '') + ' ' + getattr(user, 'last_name', ''),
            'role': 'UNKNOWN',
            'deployment': 'UNKNOWN'
        }
    
    def _generate_trail(self, request):
        """Generate audit trail string: username | fullname | role | deployment | date & time | ip"""
        from datetime import datetime
        user_info = self._get_user_info(request)
        ip = self._get_client_ip(request)
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        
        trail = f"{user_info['username']} | {user_info['fullname']} | {user_info['role']} | {user_info['deployment']} | {timestamp} | {ip}"
        return trail

    def get(self, request):
        """Fetch all active rooms"""
        try:
            from .models import OpdRoomLocation
            from .serializers import RoomLocationSerializer
            from django.db import connection
            import logging
            
            logger = logging.getLogger(__name__)
            # Show all rooms (including inactive) for now to debug
            rooms = OpdRoomLocation.objects.all().order_by('room_location_id')
            
            # Populate doctor_display for rooms that have doctor_id but no doctor_display
            for room in rooms:
                logger.info(f"[DEBUG] Processing room {room.code} - doctor_id: {room.doctor_id}, doctor_display: {room.doctor_display}")
                
                # Check if doctor_id exists (could be int or string)
                doctor_id = room.doctor_id
                if doctor_id and not room.doctor_display:
                    try:
                        # Convert to int if it's a string
                        if isinstance(doctor_id, str):
                            doctor_id = int(doctor_id)
                        
                        logger.info(f"[DEBUG] Looking up doctor_id: {doctor_id}")
                        
                        with connection.cursor() as cursor:
                            cursor.execute("""
                                SELECT firstname, middlename, lastname, name_ext
                                FROM pch.users
                                WHERE user_id = %s
                            """, [doctor_id])
                            result = cursor.fetchone()
                            logger.info(f"[DEBUG] Doctor lookup result: {result}")
                            
                            if result:
                                firstname, middlename, lastname, name_ext = result
                                doctor_display = f"Dr. {firstname}"
                                if middlename:
                                    doctor_display += f" {middlename}"
                                doctor_display += f" {lastname}"
                                if name_ext:
                                    doctor_display += f" {name_ext}"
                                room.doctor_display = doctor_display
                                logger.info(f"[DEBUG] Set doctor_display to: {doctor_display}")
                    except (ValueError, TypeError) as e:
                        logger.error(f"[DEBUG] Error processing doctor_id: {e}")
            
            serializer = RoomLocationSerializer(rooms, many=True)
            return Response({'success': True, 'data': serializer.data, 'count': len(serializer.data)})
        except Exception as e:
            logger.error(f"[DEBUG] Exception in GET: {str(e)}", exc_info=True)
            return Response({'success': False, 'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    def post(self, request):
        """Create a new room"""
        try:
            from .models import OpdRoomLocation
            from .serializers import RoomLocationSerializer
            from datetime import datetime
            from django.db import connection
            import logging
            
            logger = logging.getLogger(__name__)
            logger.info(f"[DEBUG] POST request data: {request.data}")
            
            serializer = RoomLocationSerializer(data=request.data)
            if serializer.is_valid():
                # Get doctor_id and fetch doctor's full name
                doctor_id = None
                doctor_display = None
                
                if request.data.get('doctor'):
                    try:
                        doctor_id = int(request.data.get('doctor'))
                        logger.info(f"[DEBUG] doctor_id: {doctor_id}")
                        
                        with connection.cursor() as cursor:
                            cursor.execute("""
                                SELECT firstname, middlename, lastname, name_ext
                                FROM pch.users
                                WHERE user_id = %s
                            """, [doctor_id])
                            result = cursor.fetchone()
                            logger.info(f"[DEBUG] Doctor lookup result: {result}")
                            
                            if result:
                                firstname, middlename, lastname, name_ext = result
                                doctor_display = f"Dr. {firstname}"
                                if middlename:
                                    doctor_display += f" {middlename}"
                                doctor_display += f" {lastname}"
                                if name_ext:
                                    doctor_display += f" {name_ext}"
                                logger.info(f"[DEBUG] doctor_display formatted: {doctor_display}")
                    except (ValueError, TypeError) as e:
                        logger.error(f"[DEBUG] Error converting doctor_id: {e}")
                
                # Generate audit trail
                trail = self._generate_trail(request)
                logger.info(f"[DEBUG] Generated trail: {trail}")
                
                # Save room with serializer (which handles doctor field mapping)
                room = serializer.save(
                    is_active=True,
                    updated_at=datetime.now(),
                    doctor_display=doctor_display,
                    trail=trail
                )
                logger.info(f"[DEBUG] Room saved - doctor_id: {room.doctor_id}, doctor_display: {room.doctor_display}, trail: {trail}")
                
                return Response({
                    'success': True, 
                    'message': f'Room {room.code} created successfully', 
                    'data': RoomLocationSerializer(room).data
                }, status=status.HTTP_201_CREATED)
            logger.error(f"[DEBUG] Serializer errors: {serializer.errors}")
            return Response({'success': False, 'errors': serializer.errors}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            logger.error(f"[DEBUG] Exception in POST: {str(e)}", exc_info=True)
            return Response({'success': False, 'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    def put(self, request, pk=None):
        """Update a room"""
        try:
            from .models import OpdRoomLocation
            from .serializers import RoomLocationSerializer
            from datetime import datetime
            import logging
            
            logger = logging.getLogger(__name__)
            
            if not pk:
                pk = request.data.get('id')
            
            logger.info(f"[DEBUG] PUT request - pk: {pk}")
            room = OpdRoomLocation.objects.get(room_location_id=pk)
            serializer = RoomLocationSerializer(room, data=request.data, partial=True)
            if serializer.is_valid():
                # Generate updated_trail
                updated_trail = self._generate_trail(request)
                logger.info(f"[DEBUG] Generated updated_trail: {updated_trail}")
                
                serializer.save(updated_at=datetime.now(), updated_trail=updated_trail)
                logger.info(f"[DEBUG] Room updated - updated_trail: {updated_trail}")
                
                return Response({
                    'success': True, 
                    'message': f'Room {room.code} updated successfully', 
                    'data': serializer.data
                })
            return Response({'success': False, 'errors': serializer.errors}, status=status.HTTP_400_BAD_REQUEST)
        except OpdRoomLocation.DoesNotExist:
            logger.error(f"[DEBUG] Room not found with id: {pk}")
            return Response({'success': False, 'error': 'Room not found'}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            logger.error(f"[DEBUG] Exception in PUT: {str(e)}", exc_info=True)
            return Response({'success': False, 'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    def delete(self, request, pk=None):
        """Soft-delete a room"""
        try:
            from .models import OpdRoomLocation
            from django.db import connection
            from datetime import datetime
            import logging
            
            logger = logging.getLogger(__name__)
            logger.info(f"[DEBUG] DELETE request - pk: {pk}")
            
            if not pk:
                pk = request.query_params.get('pk') or request.query_params.get('room_id')
            
            if not pk:
                return Response({'success': False, 'error': 'Room ID not provided'}, status=status.HTTP_400_BAD_REQUEST)
            
            logger.info(f"[DEBUG] Deleting room with id: {pk}")
            
            # First verify room exists
            room = OpdRoomLocation.objects.get(room_location_id=pk)
            room_code = room.code
            logger.info(f"[DEBUG] Found room: {room_code}")
            
            # Generate updated_trail for deletion
            updated_trail = self._generate_trail(request)
            logger.info(f"[DEBUG] Generated updated_trail: {updated_trail}")
            
            # Use raw SQL to update since model is unmanaged
            with connection.cursor() as cursor:
                update_time = datetime.now()
                cursor.execute("""
                    UPDATE opd_room_location
                    SET is_active = %s, updated_at = %s, updated_trail = %s
                    WHERE room_location_id = %s
                """, [False, update_time, updated_trail, pk])
                rows_updated = cursor.rowcount
                logger.info(f"[DEBUG] Updated {rows_updated} rows in opd_room_location")
                logger.info(f"[DEBUG] SQL executed: UPDATE opd_room_location SET is_active = False, updated_at = {update_time}, updated_trail = {updated_trail} WHERE room_location_id = {pk}")
            
            # Commit the transaction to ensure changes are persisted
            connection.commit()
            logger.info(f"[DEBUG] Transaction committed")
            
            logger.info(f"[DEBUG] Room {room_code} marked as inactive with deletion trail")
            return Response({'success': True, 'message': f'Room {room_code} deleted successfully'})
        except OpdRoomLocation.DoesNotExist:
            logger.error(f"[DEBUG] Room not found with id: {pk}")
            return Response({'success': False, 'error': 'Room not found'}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            logger.error(f"[DEBUG] Exception in delete: {str(e)}", exc_info=True)
            return Response({'success': False, 'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class OpdServiceView(APIView):
    """API View for OPD Services (opd_service_schedule table)"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """Fetch all active services with full schedule data"""
        try:
            from .models import OpdServiceSchedule
            from .serializers import OpdServiceSerializer
            services = OpdServiceSchedule.objects.filter(is_active=True).order_by('service')
            
            # Build full service schedule response
            data = []
            for service in services:
                service_data = {
                    'id': service.id,
                    'code': service.service,
                    'name': service.service_label or service.service,
                    'hours': self._get_service_hours(service),
                    'is_open_today': service.active_today,
                    'weekly_schedule': self._get_weekly_schedule(service),
                    'color_hex': service.color_theme or '#2196F3',
                    'is_active': service.is_active,
                    'daily_hours': self._get_daily_hours(service),
                }
                data.append(service_data)
            
            return Response({
                'success': True,
                'data': data,
                'count': len(data),
                'current_day_index': self._get_current_day_index(),
            })
        except Exception as e:
            return Response({'success': False, 'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    def _get_service_hours(self, service):
        """Get service hours as a string"""
        if service.mon_open and service.mon_close:
            return f"{service.mon_open.strftime('%I:%M %p')} - {service.mon_close.strftime('%I:%M %p')}"
        return "Not Set"

    def _get_weekly_schedule(self, service):
        """Get weekly schedule as list of booleans (Mon-Sat)"""
        days_open = (service.days_open or '').split(',')
        days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
        return [day.strip() in days_open for day in days]

    def _get_daily_hours(self, service):
        """Get daily hours for each day"""
        daily_hours = {}
        days = [
            ('Mon', service.mon_open, service.mon_close),
            ('Tue', service.tue_open, service.tue_close),
            ('Wed', service.wed_open, service.wed_close),
            ('Thu', service.thu_open, service.thu_close),
            ('Fri', service.fri_open, service.fri_close),
            ('Sat', service.sat_open, service.sat_close),
        ]
        
        for day_name, open_time, close_time in days:
            if open_time and close_time:
                daily_hours[day_name] = {
                    'open': open_time.strftime('%H:%M'),
                    'close': close_time.strftime('%H:%M'),
                }
        
        return daily_hours

    def _get_current_day_index(self):
        """Get current day index (0=Mon, 5=Sat, -1=Sun)"""
        import datetime
        weekday = datetime.datetime.now().weekday()  # 0=MON, 6=SUN
        return weekday if weekday < 6 else -1

    def post(self, request):
        """Create a new room"""
        try:
            from .serializers import RoomLocationSerializer
            from datetime import datetime
            serializer = RoomLocationSerializer(data=request.data)
            if serializer.is_valid():
                room = serializer.save(
                    is_active=True,
                    updated_at=datetime.now()
                )
                return Response({
                    'success': True, 
                    'message': f'Room {room.code} created successfully', 
                    'data': RoomLocationSerializer(room).data
                }, status=status.HTTP_201_CREATED)
            return Response({'success': False, 'errors': serializer.errors}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({'success': False, 'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    def put(self, request, room_id=None):
        """Update a room"""
        try:
            from .models import OpdRoomLocation
            from .serializers import RoomLocationSerializer
            from datetime import datetime
            if not room_id:
                room_id = request.data.get('id')
            room = OpdRoomLocation.objects.get(room_location_id=room_id)
            serializer = RoomLocationSerializer(room, data=request.data, partial=True)
            if serializer.is_valid():
                serializer.save(updated_at=datetime.now())
                return Response({
                    'success': True, 
                    'message': f'Room {room.code} updated successfully', 
                    'data': serializer.data
                })
            return Response({'success': False, 'errors': serializer.errors}, status=status.HTTP_400_BAD_REQUEST)
        except OpdRoomLocation.DoesNotExist:
            return Response({'success': False, 'error': 'Room not found'}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({'success': False, 'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    def delete(self, request, pk=None):
        """Soft-delete a room"""
        try:
            from .models import OpdRoomLocation
            from datetime import datetime
            import logging
            
            logger = logging.getLogger(__name__)
            logger.info(f"[DEBUG] DELETE request - pk: {pk}")
            
            if not pk:
                pk = request.query_params.get('pk') or request.query_params.get('room_id')
            
            if not pk:
                return Response({'success': False, 'error': 'Room ID not provided'}, status=status.HTTP_400_BAD_REQUEST)
            
            logger.info(f"[DEBUG] Deleting room with id: {pk}")
            room = OpdRoomLocation.objects.get(room_location_id=pk)
            logger.info(f"[DEBUG] Found room: {room.code}")
            
            room.is_active = False
            room.updated_at = datetime.now()
            room.save()
            
            logger.info(f"[DEBUG] Room {room.code} marked as inactive")
            return Response({'success': True, 'message': f'Room {room.code} deleted successfully'})
        except OpdRoomLocation.DoesNotExist:
            logger.error(f"[DEBUG] Room not found with id: {pk}")
            return Response({'success': False, 'error': 'Room not found'}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            logger.error(f"[DEBUG] Exception in delete: {str(e)}", exc_info=True)
            return Response({'success': False, 'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

