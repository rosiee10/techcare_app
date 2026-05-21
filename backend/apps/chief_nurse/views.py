"""
Views for Chief Nurse app - IPD nursing supervision and management.
"""
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import api_view, permission_classes
from django.db import connection


def dict_fetchall(cursor):
    """Return all rows from a cursor as a dict"""
    columns = [col[0] for col in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


def dict_fetchone(cursor):
    """Return one row from a cursor as a dict"""
    columns = [col[0] for col in cursor.description]
    row = cursor.fetchone()
    return dict(zip(columns, row)) if row else None


class WardDashboardView(APIView):
    """
    API endpoint for chief nurse to view ward overview.
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        try:
            with connection.cursor() as cursor:
                # Get all wards with occupancy stats
                cursor.execute("""
                    SELECT 
                        w.ward_id,
                        w.ward_name,
                        w.ward_type,
                        COUNT(DISTINCT b.bed_id) as total_beds,
                        COUNT(DISTINCT CASE WHEN b.status = 'OCCUPIED' THEN b.bed_id END) as occupied_beds,
                        COUNT(DISTINCT CASE WHEN b.status = 'AVAILABLE' THEN b.bed_id END) as available_beds,
                        COUNT(DISTINCT p.patient_id) as current_patients,
                        COUNT(DISTINCT CASE WHEN p.acuity_level = 'CRITICAL' THEN p.patient_id END) as critical_patients
                    FROM pch.wards w
                    LEFT JOIN pch.beds b ON w.ward_id = b.ward_id
                    LEFT JOIN pch.inpatient admissions ia ON b.bed_id = ia.bed_id AND ia.status = 'ADMITTED'
                    LEFT JOIN pch.patient_profiling p ON ia.patient_id = p.patient_id
                    WHERE w.is_active = TRUE
                    GROUP BY w.ward_id, w.ward_name, w.ward_type
                    ORDER BY w.ward_name
                """)
                wards = dict_fetchall(cursor)
            
            return Response({
                'success': True,
                'wards': wards
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class NurseAssignmentsView(APIView):
    """
    API endpoint for chief nurse to view and manage nurse assignments.
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        try:
            with connection.cursor() as cursor:
                # Get all IPD nurses with their assignments
                cursor.execute("""
                    SELECT 
                        u.user_id,
                        u.last_name,
                        u.first_name,
                        u.middle_name,
                        u.employee_id,
                        na.ward_id,
                        w.ward_name,
                        na.assignment_type,
                        na.shift,
                        na.patient_count,
                        na.status as assignment_status
                    FROM pch.users u
                    LEFT JOIN pch.nurse_assignments na ON u.user_id = na.nurse_id AND na.status = 'ACTIVE'
                    LEFT JOIN pch.wards w ON na.ward_id = w.ward_id
                    WHERE u.user_role = 'NURSE' 
                        AND (u.deployment = 'IPD' OR u.deployment = 'BOTH')
                        AND u.is_active = TRUE
                    ORDER BY u.last_name, u.first_name
                """)
                nurses = dict_fetchall(cursor)
            
            return Response({
                'success': True,
                'nurses': nurses
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class PatientStatusView(APIView):
    """
    API endpoint for chief nurse to view patient status overview.
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        try:
            with connection.cursor() as cursor:
                # Get patient status summary
                cursor.execute("""
                    SELECT 
                        p.patient_id,
                        p.hospital_id,
                        p.lastname,
                        p.firstname,
                        p.middlename,
                        p.current_status,
                        ia.admission_id,
                        ia.admission_date,
                        w.ward_name,
                        b.bed_number,
                        pi.acuity_level,
                        pi.vital_signs_status,
                        pi.last_assessment_date,
                        pi.medication_due,
                        u.last_name as assigned_nurse,
                        u.first_name as nurse_first_name
                    FROM pch.patient_profiling p
                    INNER JOIN pch.inpatient admissions ia ON p.patient_id = ia.patient_id
                    INNER JOIN pch.beds b ON ia.bed_id = b.bed_id
                    INNER JOIN pch.wards w ON b.ward_id = w.ward_id
                    LEFT JOIN pch.patient_ipd_info pi ON p.patient_id = pi.patient_id
                    LEFT JOIN pch.nurse_assignments na ON w.ward_id = na.ward_id AND na.status = 'ACTIVE'
                    LEFT JOIN pch.users u ON na.nurse_id = u.user_id
                    WHERE ia.status = 'ADMITTED'
                        AND p.current_status = 'ADMITTED'
                    ORDER BY w.ward_name, b.bed_number
                """)
                patients = dict_fetchall(cursor)
            
            return Response({
                'success': True,
                'patients': patients
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class BedManagementView(APIView):
    """
    API endpoint for chief nurse to manage beds.
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        try:
            ward_id = request.query_params.get('ward_id')
            
            with connection.cursor() as cursor:
                if ward_id:
                    cursor.execute("""
                        SELECT 
                            b.bed_id,
                            b.bed_number,
                            b.bed_type,
                            b.status,
                            w.ward_name,
                            p.hospital_id,
                            p.lastname,
                            p.firstname,
                            ia.admission_date
                        FROM pch.beds b
                        INNER JOIN pch.wards w ON b.ward_id = w.ward_id
                        LEFT JOIN pch.inpatient admissions ia ON b.bed_id = ia.bed_id AND ia.status = 'ADMITTED'
                        LEFT JOIN pch.patient_profiling p ON ia.patient_id = p.patient_id
                        WHERE b.ward_id = %s
                        ORDER BY b.bed_number
                    """, [ward_id])
                else:
                    cursor.execute("""
                        SELECT 
                            b.bed_id,
                            b.bed_number,
                            b.bed_type,
                            b.status,
                            w.ward_name,
                            p.hospital_id,
                            p.lastname,
                            p.firstname,
                            ia.admission_date
                        FROM pch.beds b
                        INNER JOIN pch.wards w ON b.ward_id = w.ward_id
                        LEFT JOIN pch.inpatient admissions ia ON b.bed_id = ia.bed_id AND ia.status = 'ADMITTED'
                        LEFT JOIN pch.patient_profiling p ON ia.patient_id = p.patient_id
                        ORDER BY w.ward_name, b.bed_number
                    """)
                beds = dict_fetchall(cursor)
            
            return Response({
                'success': True,
                'beds': beds
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class NursingScheduleView(APIView):
    """
    API endpoint for chief nurse to view nursing schedule.
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        try:
            date = request.query_params.get('date')
            
            with connection.cursor() as cursor:
                cursor.execute("""
                    SELECT 
                        ns.schedule_id,
                        ns.schedule_date,
                        ns.shift,
                        u.user_id,
                        u.last_name,
                        u.first_name,
                        w.ward_name,
                        ns.status
                    FROM pch.nursing_schedules ns
                    INNER JOIN pch.users u ON ns.nurse_id = u.user_id
                    INNER JOIN pch.wards w ON ns.ward_id = w.ward_id
                    WHERE ns.schedule_date = COALESCE(%s, CURRENT_DATE)
                        AND u.user_role = 'NURSE'
                        AND (u.deployment = 'IPD' OR u.deployment = 'BOTH')
                    ORDER BY ns.shift, w.ward_name, u.last_name
                """, [date])
                schedules = dict_fetchall(cursor)
            
            return Response({
                'success': True,
                'schedules': schedules
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def chief_nurse_dashboard_stats(request):
    """
    Get dashboard statistics for chief nurse.
    """
    try:
        with connection.cursor() as cursor:
            # Total admitted patients
            cursor.execute("""
                SELECT COUNT(*) FROM pch.inpatient admissions ia
                INNER JOIN pch.patient_profiling p ON ia.patient_id = p.patient_id
                WHERE ia.status = 'ADMITTED' AND p.current_status = 'ADMITTED'
            """)
            total_admitted = cursor.fetchone()[0]
            
            # Critical patients
            cursor.execute("""
                SELECT COUNT(*) FROM pch.patient_ipd_info
                WHERE acuity_level = 'CRITICAL'
            """)
            critical_patients = cursor.fetchone()[0]
            
            # Available beds
            cursor.execute("""
                SELECT COUNT(*) FROM pch.beds WHERE status = 'AVAILABLE'
            """)
            available_beds = cursor.fetchone()[0]
            
            # Total IPD nurses on duty
            cursor.execute("""
                SELECT COUNT(DISTINCT nurse_id) FROM pch.nurse_assignments
                WHERE status = 'ACTIVE' AND shift = CURRENT_SHIFT()
            """)
            nurses_on_duty = cursor.fetchone()[0]
            
            # Pending discharges today
            cursor.execute("""
                SELECT COUNT(*) FROM pch.inpatient admissions
                WHERE expected_discharge_date = CURRENT_DATE AND status = 'ADMITTED'
            """)
            pending_discharges = cursor.fetchone()[0]
            
            # Medications due
            cursor.execute("""
                SELECT COUNT(*) FROM pch.medication_schedules
                WHERE scheduled_time <= CURRENT_TIME AND status = 'PENDING'
            """)
            medications_due = cursor.fetchone()[0]
        
        return Response({
            'success': True,
            'stats': {
                'total_admitted': total_admitted,
                'critical_patients': critical_patients,
                'available_beds': available_beds,
                'nurses_on_duty': nurses_on_duty,
                'pending_discharges': pending_discharges,
                'medications_due': medications_due,
            }
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
