"""
Views for Patient Portal app - Patient self-service functionality.
"""
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import api_view, permission_classes
from django.db import connection

from apps.opd.models import PatientProfiling, EmergencyContact
from apps.opd.serializers import PatientProfilingSerializer, EmergencyContactSerializer


def dict_fetchall(cursor):
    """Return all rows from a cursor as a dict"""
    columns = [col[0] for col in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


def dict_fetchone(cursor):
    """Return one row from a cursor as a dict"""
    columns = [col[0] for col in cursor.description]
    row = cursor.fetchone()
    return dict(zip(columns, row)) if row else None


class PatientProfileView(APIView):
    """
    API endpoint for patient to view their own profile.
    Patient users can only access their own linked patient record.
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        try:
            # Get the user's linked patient ID from user profile
            with connection.cursor() as cursor:
                cursor.execute("""
                    SELECT patient_id FROM pch.users 
                    WHERE user_id = %s AND user_role = 'PATIENT'
                """, [request.user.id])
                result = cursor.fetchone()
                
                if not result or not result[0]:
                    return Response({
                        'success': False,
                        'error': 'No patient profile linked to this account'
                    }, status=status.HTTP_404_NOT_FOUND)
                
                patient_id = result[0]
            
            # Get patient details
            patient = PatientProfiling.objects.get(patient_id=patient_id)
            serializer = PatientProfilingSerializer(patient)
            
            # Get emergency contacts
            emergency_contacts = EmergencyContact.objects.filter(patient=patient)
            contacts_serializer = EmergencyContactSerializer(emergency_contacts, many=True)
            
            return Response({
                'success': True,
                'patient': serializer.data,
                'emergency_contacts': contacts_serializer.data
            }, status=status.HTTP_200_OK)
            
        except PatientProfiling.DoesNotExist:
            return Response({
                'success': False,
                'error': 'Patient profile not found'
            }, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class PatientAppointmentsView(APIView):
    """
    API endpoint for patient to view their appointments/history.
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        try:
            # Get the user's linked patient ID
            with connection.cursor() as cursor:
                cursor.execute("""
                    SELECT patient_id FROM pch.users 
                    WHERE user_id = %s AND user_role = 'PATIENT'
                """, [request.user.id])
                result = cursor.fetchone()
                
                if not result or not result[0]:
                    return Response({
                        'success': False,
                        'error': 'No patient profile linked'
                    }, status=status.HTTP_404_NOT_FOUND)
                
                patient_id = result[0]
            
            # Fetch patient appointments/visits from database
            # This is a placeholder - implement based on your actual appointment table
            with connection.cursor() as cursor:
                cursor.execute("""
                    SELECT 
                        visit_id,
                        visit_date,
                        department,
                        doctor_name,
                        chief_complaint,
                        status
                    FROM pch.patient_visits 
                    WHERE patient_id = %s 
                    ORDER BY visit_date DESC
                """, [patient_id])
                visits = dict_fetchall(cursor)
            
            return Response({
                'success': True,
                'appointments': visits
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class PatientLabResultsView(APIView):
    """
    API endpoint for patient to view their lab results.
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        try:
            # Get the user's linked patient ID
            with connection.cursor() as cursor:
                cursor.execute("""
                    SELECT patient_id FROM pch.users 
                    WHERE user_id = %s AND user_role = 'PATIENT'
                """, [request.user.id])
                result = cursor.fetchone()
                
                if not result or not result[0]:
                    return Response({
                        'success': False,
                        'error': 'No patient profile linked'
                    }, status=status.HTTP_404_NOT_FOUND)
                
                patient_id = result[0]
            
            # Fetch lab results
            # Placeholder - implement based on your lab results table
            with connection.cursor() as cursor:
                cursor.execute("""
                    SELECT 
                        lab_result_id,
                        test_name,
                        test_date,
                        result_value,
                        reference_range,
                        status,
                        reviewed_by,
                        reviewed_at
                    FROM pch.lab_results 
                    WHERE patient_id = %s 
                    ORDER BY test_date DESC
                """, [patient_id])
                lab_results = dict_fetchall(cursor)
            
            return Response({
                'success': True,
                'lab_results': lab_results
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class PatientPrescriptionsView(APIView):
    """
    API endpoint for patient to view their prescriptions.
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        try:
            # Get the user's linked patient ID
            with connection.cursor() as cursor:
                cursor.execute("""
                    SELECT patient_id FROM pch.users 
                    WHERE user_id = %s AND user_role = 'PATIENT'
                """, [request.user.id])
                result = cursor.fetchone()
                
                if not result or not result[0]:
                    return Response({
                        'success': False,
                        'error': 'No patient profile linked'
                    }, status=status.HTTP_404_NOT_FOUND)
                
                patient_id = result[0]
            
            # Fetch prescriptions
            # Placeholder - implement based on your prescriptions table
            with connection.cursor() as cursor:
                cursor.execute("""
                    SELECT 
                        prescription_id,
                        prescribed_date,
                        doctor_name,
                        medication_name,
                        dosage,
                        frequency,
                        duration,
                        instructions,
                        status
                    FROM pch.prescriptions 
                    WHERE patient_id = %s 
                    ORDER BY prescribed_date DESC
                """, [patient_id])
                prescriptions = dict_fetchall(cursor)
            
            return Response({
                'success': True,
                'prescriptions': prescriptions
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class UpdatePatientProfileView(APIView):
    """
    API endpoint for patient to update their own profile information.
    Limited fields can be updated by patient (e.g., contact info, address).
    """
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        try:
            # Get the user's linked patient ID
            with connection.cursor() as cursor:
                cursor.execute("""
                    SELECT patient_id FROM pch.users 
                    WHERE user_id = %s AND user_role = 'PATIENT'
                """, [request.user.id])
                result = cursor.fetchone()
                
                if not result or not result[0]:
                    return Response({
                        'success': False,
                        'error': 'No patient profile linked'
                    }, status=status.HTTP_404_NOT_FOUND)
                
                patient_id = result[0]
            
            # Fields that patients are allowed to update
            allowed_fields = [
                'contact_number', 'purok', 'barangay', 
                'city_municipal', 'province', 'religion'
            ]
            
            # Build update data
            update_data = {}
            for field in allowed_fields:
                if field in request.data:
                    update_data[field] = request.data[field]
            
            if not update_data:
                return Response({
                    'success': False,
                    'error': 'No valid fields to update'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Update patient record
            patient = PatientProfiling.objects.get(patient_id=patient_id)
            for field, value in update_data.items():
                setattr(patient, field, value)
            patient.save()
            
            return Response({
                'success': True,
                'message': 'Profile updated successfully'
            }, status=status.HTTP_200_OK)
            
        except PatientProfiling.DoesNotExist:
            return Response({
                'success': False,
                'error': 'Patient profile not found'
            }, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def patient_dashboard_stats(request):
    """
    Get dashboard statistics for patient portal.
    """
    try:
        # Get the user's linked patient ID
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT patient_id FROM pch.users 
                WHERE user_id = %s AND user_role = 'PATIENT'
            """, [request.user.id])
            result = cursor.fetchone()
            
            if not result or not result[0]:
                return Response({
                    'success': False,
                    'error': 'No patient profile linked'
                }, status=status.HTTP_404_NOT_FOUND)
            
            patient_id = result[0]
        
        # Fetch various stats
        with connection.cursor() as cursor:
            # Total visits count
            cursor.execute("""
                SELECT COUNT(*) FROM pch.patient_visits 
                WHERE patient_id = %s
            """, [patient_id])
            total_visits = cursor.fetchone()[0]
            
            # Upcoming appointments count
            cursor.execute("""
                SELECT COUNT(*) FROM pch.appointments 
                WHERE patient_id = %s AND appointment_date >= CURRENT_DATE
            """, [patient_id])
            upcoming_appointments = cursor.fetchone()[0]
            
            # Pending lab results count
            cursor.execute("""
                SELECT COUNT(*) FROM pch.lab_results 
                WHERE patient_id = %s AND status = 'PENDING'
            """, [patient_id])
            pending_lab_results = cursor.fetchone()[0]
            
            # Active prescriptions count
            cursor.execute("""
                SELECT COUNT(*) FROM pch.prescriptions 
                WHERE patient_id = %s AND status = 'ACTIVE'
            """, [patient_id])
            active_prescriptions = cursor.fetchone()[0]
        
        return Response({
            'success': True,
            'stats': {
                'total_visits': total_visits,
                'upcoming_appointments': upcoming_appointments,
                'pending_lab_results': pending_lab_results,
                'active_prescriptions': active_prescriptions,
            }
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
