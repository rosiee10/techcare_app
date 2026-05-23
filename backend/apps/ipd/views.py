from django.shortcuts import render



from rest_framework.decorators import api_view, permission_classes



from rest_framework.permissions import IsAuthenticated



from rest_framework.response import Response



from rest_framework import status



from django.db import connection



from datetime import datetime, timedelta



import json











# ============================================================



# NOTICE OF ADMISSION API



# ============================================================







@api_view(['POST'])



@permission_classes([IsAuthenticated])



def create_notice_of_admission(request):



    """



    Create a new Notice of Admission record.



    POST /api/ipd/notice-of-admission/



    Body: { hospital_id, admission_date, admitting_impression, bp, pr, temp,



            rr, weight, height, o2_sat, admitting_physician, department }



    """



    data = request.data



    hospital_id = data.get('hospital_id', '').strip()







    if not hospital_id:



        return Response({'success': False, 'error': 'hospital_id is required'},



                        status=status.HTTP_400_BAD_REQUEST)







    try:



        with connection.cursor() as cursor:



            # Look up patient_id from hospital_id



            cursor.execute(



                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",



                [hospital_id]



            )



            row = cursor.fetchone()



            if not row:



                return Response({'success': False, 'error': f'Patient {hospital_id} not found'},



                                status=status.HTTP_404_NOT_FOUND)



            patient_id = row[0]







            # Insert notice of admission



            cursor.execute("""



                INSERT INTO pch.ipd_notice_of_admission (



                    patient_id, hospital_id, admission_date, admitting_impression,



                    bp, pr, temp, rr, weight, height, o2_sat,



                    admitting_physician, department, status, patient_condition,



                    submitted_by, submitted_date, created_at, updated_at



                ) VALUES (



                    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,



                    'pending', %s, %s, NOW(), NOW(), NOW()



                ) RETURNING admission_id



            """, [



                patient_id,



                hospital_id,



                data.get('admission_date') or None,



                data.get('admitting_impression', ''),



                data.get('bp', ''),



                data.get('pr', ''),



                data.get('temp', ''),



                data.get('rr', ''),



                data.get('weight', ''),



                data.get('height', ''),



                data.get('o2_sat', ''),



                data.get('admitting_physician', ''),



                data.get('department', 'General Ward'),



                data.get('patient_condition', 'Active'),



                request.user.username if request.user.is_authenticated else 'nurse',



            ])



            admission_id = cursor.fetchone()[0]







            # Update patient_profiling so the doctor's Admission Requests list picks it up



            # PatientListView maps 'Pending' -> 'PENDING' before filtering, so use uppercase



            cursor.execute(



                "UPDATE pch.patient_profiling SET current_status = 'PENDING' WHERE patient_id = %s",



                [patient_id]



            )







        return Response({



            'success': True,



            'admission_id': admission_id,



            'message': 'Notice of admission submitted for doctor approval',



        }, status=status.HTTP_201_CREATED)







    except Exception as e:



        return Response({'success': False, 'error': str(e)},



                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)











@api_view(['GET'])



@permission_classes([IsAuthenticated])



def list_pending_admissions(request):



    """



    List all pending notice of admission records.



    GET /api/ipd/notice-of-admission/pending/



    """



    try:



        with connection.cursor() as cursor:



            cursor.execute("""



                SELECT



                    noa.admission_id,



                    noa.hospital_id,



                    noa.admission_date,



                    noa.admitting_impression,



                    noa.bp, noa.pr, noa.temp, noa.rr,



                    noa.weight, noa.height, noa.o2_sat,



                    noa.admitting_physician,



                    noa.department,



                    noa.status,



                    noa.submitted_by,



                    noa.submitted_date,



                    p.lastname, p.firstname, p.middlename,



                    p.gender, p.address



                FROM pch.ipd_notice_of_admission noa



                JOIN pch.patient_profiling p ON noa.patient_id = p.patient_id



                WHERE noa.status = 'pending'



                ORDER BY noa.submitted_date DESC



            """)



            columns = [col[0] for col in cursor.description]



            rows = [dict(zip(columns, row)) for row in cursor.fetchall()]







        return Response({'success': True, 'admissions': rows}, status=status.HTTP_200_OK)



    except Exception as e:



        return Response({'success': False, 'error': str(e)},



                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)











@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_notice_of_admission(request, hospital_id):
    """
    GET /api/ipd/notice-of-admission/<hospital_id>/
    Load the latest Notice of Admission record for a patient.
    """
    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT
                    noa.admission_id, noa.patient_id, noa.hospital_id,
                    noa.admission_date, noa.admitting_impression,
                    noa.bp, noa.pr, noa.temp, noa.rr,
                    noa.weight, noa.height, noa.o2_sat,
                    noa.admitting_physician, noa.department,
                    noa.status, noa.patient_condition,
                    noa.submitted_by, noa.submitted_date,
                    noa.approved_by, noa.approved_date,
                    p.lastname, p.firstname, p.middlename,
                    p.gender, p.birthdate
                FROM pch.ipd_notice_of_admission noa
                JOIN pch.patient_profiling p ON noa.patient_id = p.patient_id
                WHERE noa.hospital_id = %s
                ORDER BY noa.admission_id DESC
                LIMIT 1
            """, [hospital_id])

            row = cursor.fetchone()
            if row:
                columns = [col[0] for col in cursor.description]
                data = dict(zip(columns, row))
                for key, value in data.items():
                    if hasattr(value, 'isoformat'):
                        data[key] = value.isoformat()
                return Response({'success': True, 'data': data}, status=status.HTTP_200_OK)
            else:
                return Response({'success': True, 'data': None}, status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ============================================================



# MATERNITY PATIENT INFO API



# ============================================================



@api_view(['GET'])



@permission_classes([IsAuthenticated])



def get_maternity_patient_info(request, hospital_id):



    """



    GET /api/ipd/maternity-patient-info/<hospital_id>/



    Load existing maternity patient info record for a patient.



    """



    try:



        with connection.cursor() as cursor:



            cursor.execute("""



                SELECT m.* FROM pch.ipd_maternity_patient_info m



                INNER JOIN pch.patient_profiling p ON m.patient_id = p.patient_id



                WHERE p.hospital_id = %s



                ORDER BY m.created_at DESC



                LIMIT 1



            """, [hospital_id])



            row = cursor.fetchone()



            if row:



                columns = [col[0] for col in cursor.description]



                data = dict(zip(columns, row))



                for key, value in data.items():



                    if hasattr(value, 'isoformat'):



                        data[key] = value.isoformat()



                return Response({'success': True, 'data': data}, status=status.HTTP_200_OK)



            else:



                return Response({'success': True, 'data': None}, status=status.HTTP_200_OK)



    except Exception as e:



        return Response({'success': False, 'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)



@api_view(['POST'])



@permission_classes([IsAuthenticated])



def save_maternity_patient_info(request):



    """



    POST /api/ipd/maternity-patient-info/



    Create or update (upsert) maternity patient info record.



    Accepts hospital_id and looks up patient_id + admission_id internally.



    """



    data = request.data



    hospital_id = data.get('hospital_id', '').strip()



    if not hospital_id:



        return Response({'success': False, 'error': 'hospital_id is required'}, status=status.HTTP_400_BAD_REQUEST)



    try:



        with connection.cursor() as cursor:



            cursor.execute("""



                SELECT p.patient_id, noa.admission_id



                FROM pch.patient_profiling p



                LEFT JOIN pch.ipd_notice_of_admission noa ON p.patient_id = noa.patient_id



                WHERE p.hospital_id = %s AND p.is_active = TRUE



                ORDER BY noa.admission_id DESC



                LIMIT 1



            """, [hospital_id])



            row = cursor.fetchone()



            if not row:



                return Response({'success': False, 'error': f'Patient {hospital_id} not found'}, status=status.HTTP_404_NOT_FOUND)



            patient_id, admission_id = row



            fields = [



                'zip_code', 'birthplace', 'nationality', 'civil_status',



                'occupation', 'employer', 'employer_address', 'employer_category',



                'nearest_relative', 'relative_relationship', 'relative_address',



                'fathers_name', 'fathers_address', 'fathers_tel',



                'mothers_name', 'mothers_address', 'mothers_tel',



                'time_admitted', 'date_discharge', 'total_days', 'attending_physician',



                'vital_bp_pr_rr_ht', 'vital_temp_wt_o2sat',



                'admission_type', 'referred_by',



                'social_service_class', 'social_service_agency',



                'food_drug_allergies', 'religious_assistance', 'security_assistance',



                'observe_confidentiality', 'need_special_care',



                'need_statement_of_account', 'need_admission_pack', 'preferred_accommodation',



                'informant_name', 'informant_address',



                'admission_diagnosis', 'admission_icd10',



                'final_diagnosis', 'final_icd10',



                'other_diagnosis', 'other_icd10',



                'complications', 'surgical_procedure', 'pathological_diagnosis', 'transferred_to',



                'disposition_discharged', 'disposition_transferred', 'disposition_dama',



                'disposition_absconded', 'disposition_more_48hrs',



                'result_recovered', 'result_improved', 'result_unimproved', 'result_died',



                'insurance_plan', 'philhealth_type', 'philhealth_options',



                'resident_incharge', 'medical_specialist', 'chief_of_hospital',



            ]



            values = [data.get(f) for f in fields]



            cursor.execute("""



                SELECT maternity_info_id FROM pch.ipd_maternity_patient_info



                WHERE patient_id = %s



            """, [patient_id])



            existing = cursor.fetchone()



            if existing:



                set_clause = ', '.join([f'{f} = %s' for f in fields])



                cursor.execute(f"""



                    UPDATE pch.ipd_maternity_patient_info



                    SET {set_clause}, updated_at = NOW()



                    WHERE patient_id = %s



                """, values + [patient_id])



                maternity_info_id = existing[0]



            else:



                cols = ', '.join(['patient_id', 'admission_id'] + fields)



                placeholders = ', '.join(['%s'] * (2 + len(fields)))



                cursor.execute(f"""



                    INSERT INTO pch.ipd_maternity_patient_info ({cols})



                    VALUES ({placeholders})



                    RETURNING maternity_info_id



                """, [patient_id, admission_id] + values)



                maternity_info_id = cursor.fetchone()[0]



        return Response({'success': True, 'maternity_info_id': maternity_info_id}, status=status.HTTP_200_OK)



    except Exception as e:



        return Response({'success': False, 'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)



# ============================================================



# Sample historical data - In production, this would come from the database



SAMPLE_DISEASE_DATA = {



    'Pneumonia': [



        {'date': '2023-01-01', 'cases': 15},



        {'date': '2023-02-01', 'cases': 18},



        {'date': '2023-03-01', 'cases': 22},



        {'date': '2023-04-01', 'cases': 25},



        {'date': '2023-05-01', 'cases': 28},



        {'date': '2023-06-01', 'cases': 32},



        {'date': '2023-07-01', 'cases': 35},



        {'date': '2023-08-01', 'cases': 38},



        {'date': '2023-09-01', 'cases': 40},



        {'date': '2023-10-01', 'cases': 42},



        {'date': '2023-11-01', 'cases': 45},



        {'date': '2023-12-01', 'cases': 48},



    ],



    'Hypertension': [



        {'date': '2023-01-01', 'cases': 12},



        {'date': '2023-02-01', 'cases': 14},



        {'date': '2023-03-01', 'cases': 16},



        {'date': '2023-04-01', 'cases': 18},



        {'date': '2023-05-01', 'cases': 20},



        {'date': '2023-06-01', 'cases': 22},



        {'date': '2023-07-01', 'cases': 24},



        {'date': '2023-08-01', 'cases': 26},



        {'date': '2023-09-01', 'cases': 28},



        {'date': '2023-10-01', 'cases': 30},



        {'date': '2023-11-01', 'cases': 32},



        {'date': '2023-12-01', 'cases': 34},



    ],



    'Diabetes': [



        {'date': '2023-01-01', 'cases': 10},



        {'date': '2023-02-01', 'cases': 11},



        {'date': '2023-03-01', 'cases': 12},



        {'date': '2023-04-01', 'cases': 12},



        {'date': '2023-05-01', 'cases': 13},



        {'date': '2023-06-01', 'cases': 13},



        {'date': '2023-07-01', 'cases': 14},



        {'date': '2023-08-01', 'cases': 14},



        {'date': '2023-09-01', 'cases': 15},



        {'date': '2023-10-01', 'cases': 15},



        {'date': '2023-11-01', 'cases': 16},



        {'date': '2023-12-01', 'cases': 16},



    ],



    'Pregnancy/Labor': [



        {'date': '2023-01-01', 'cases': 20},



        {'date': '2023-02-01', 'cases': 22},



        {'date': '2023-03-01', 'cases': 25},



        {'date': '2023-04-01', 'cases': 28},



        {'date': '2023-05-01', 'cases': 32},



        {'date': '2023-06-01', 'cases': 36},



        {'date': '2023-07-01', 'cases': 40},



        {'date': '2023-08-01', 'cases': 44},



        {'date': '2023-09-01', 'cases': 48},



        {'date': '2023-10-01', 'cases': 52},



        {'date': '2023-11-01', 'cases': 56},



        {'date': '2023-12-01', 'cases': 58},



    ],



    'Trauma/RTA': [



        {'date': '2023-01-01', 'cases': 18},



        {'date': '2023-02-01', 'cases': 17},



        {'date': '2023-03-01', 'cases': 16},



        {'date': '2023-04-01', 'cases': 15},



        {'date': '2023-05-01', 'cases': 14},



        {'date': '2023-06-01', 'cases': 13},



        {'date': '2023-07-01', 'cases': 12},



        {'date': '2023-08-01', 'cases': 11},



        {'date': '2023-09-01', 'cases': 10},



        {'date': '2023-10-01', 'cases': 9},



        {'date': '2023-11-01', 'cases': 8},



        {'date': '2023-12-01', 'cases': 7},



    ],



}











@api_view(['GET'])



def disease_forecast(request):



    """



    Generate ARIMA forecasts for all diseases.



    



    Query parameters:



    - periods: Number of months to forecast (default: 12)



    - diseases: Comma-separated list of diseases (default: all)



    """



    try:



        from .forecasting import MultiDiseaseForecaster



        



        periods = int(request.query_params.get('periods', 12))



        diseases_param = request.query_params.get('diseases', '')



        



        # Determine which diseases to forecast



        if diseases_param:



            diseases = [d.strip() for d in diseases_param.split(',')]



            disease_data = {k: v for k, v in SAMPLE_DISEASE_DATA.items() if k in diseases}



        else:



            disease_data = SAMPLE_DISEASE_DATA



        



        # Create forecaster and add diseases



        forecaster = MultiDiseaseForecaster()



        for disease_name, historical_data in disease_data.items():



            forecaster.add_disease(disease_name, historical_data)



        



        # Generate forecasts



        results = forecaster.forecast_all(periods=periods)



        



        # Get alerts



        alerts = forecaster.get_alerts(threshold_increase=20)



        



        return Response({



            'status': 'success',



            'forecasts': results,



            'alerts': alerts,



            'forecast_periods': periods,



            'generated_at': datetime.now().isoformat(),



        }, status=status.HTTP_200_OK)



    



    except Exception as e:



        return Response({



            'status': 'error',



            'message': str(e),



        }, status=status.HTTP_400_BAD_REQUEST)











@api_view(['GET'])



def disease_forecast_detail(request, disease_name):



    """



    Get detailed forecast for a specific disease.



    



    Query parameters:



    - periods: Number of months to forecast (default: 12)



    """



    try:



        from .forecasting import MultiDiseaseForecaster



        



        periods = int(request.query_params.get('periods', 12))



        



        if disease_name not in SAMPLE_DISEASE_DATA:



            return Response({



                'status': 'error',



                'message': f'Disease "{disease_name}" not found',



            }, status=status.HTTP_404_NOT_FOUND)



        



        # Create forecaster for single disease



        forecaster = MultiDiseaseForecaster()



        forecaster.add_disease(disease_name, SAMPLE_DISEASE_DATA[disease_name])



        



        # Generate forecast



        results = forecaster.forecast_all(periods=periods)



        



        return Response({



            'status': 'success',



            'disease': disease_name,



            'forecast': results[disease_name],



            'generated_at': datetime.now().isoformat(),



        }, status=status.HTTP_200_OK)



    



    except Exception as e:



        return Response({



            'status': 'error',



            'message': str(e),



        }, status=status.HTTP_400_BAD_REQUEST)











@api_view(['GET'])



def forecast_alerts(request):



    """



    Get alerts for diseases with significant forecast changes.



    



    Query parameters:



    - threshold: Percentage threshold for alerts (default: 20)



    """



    try:



        from .forecasting import MultiDiseaseForecaster



        



        threshold = int(request.query_params.get('threshold', 20))



        



        # Create forecaster for all diseases



        forecaster = MultiDiseaseForecaster()



        for disease_name, historical_data in SAMPLE_DISEASE_DATA.items():



            forecaster.add_disease(disease_name, historical_data)



        



        # Generate forecasts



        forecaster.forecast_all(periods=12)



        



        # Get alerts



        alerts = forecaster.get_alerts(threshold_increase=threshold)



        



        return Response({



            'status': 'success',



            'alerts': alerts,



            'threshold': threshold,



            'alert_count': len(alerts),



            'generated_at': datetime.now().isoformat(),



        }, status=status.HTTP_200_OK)



    



    except Exception as e:



        return Response({



            'status': 'error',



            'message': str(e),



        }, status=status.HTTP_400_BAD_REQUEST)





# ============================================================
# VITAL SIGNS API
# ============================================================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_vital_signs(request):
    """
    Save vital signs sheet for a patient.
    POST /api/ipd/vital-signs/
    Body: { hospital_id, entries: [{datetime_text, bp, pr, rr, temperature, o2_sat}] }
    Entries are ordered: row0-left, row0-right, row1-left, row1-right, ...
    """
    try:
        data = request.data
        hospital_id = data.get('hospital_id', '').strip()
        entries = data.get('entries', [])

        if not hospital_id:
            return Response({'success': False, 'error': 'hospital_id is required'},
                            status=status.HTTP_400_BAD_REQUEST)

        with connection.cursor() as cursor:
            # Resolve patient_id
            cursor.execute(
                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",
                [hospital_id]
            )
            row = cursor.fetchone()
            patient_id = row[0] if row else None

            # Resolve most-recent admission_id
            admission_id = None
            if patient_id:
                cursor.execute(
                    "SELECT admission_id FROM pch.ipd_notice_of_admission WHERE patient_id = %s ORDER BY created_at DESC LIMIT 1",
                    [patient_id]
                )
                adm = cursor.fetchone()
                if adm:
                    admission_id = adm[0]

            # Resolve ward / room
            ward_room = ''
            if admission_id:
                cursor.execute(
                    "SELECT department FROM pch.ipd_notice_of_admission WHERE admission_id = %s",
                    [admission_id]
                )
                wr = cursor.fetchone()
                if wr:
                    ward_room = wr[0] or ''

            # Delete existing rows for this patient so we can do a full re-save
            cursor.execute(
                "DELETE FROM pch.ipd_vital_signs WHERE hospital_id = %s",
                [hospital_id]
            )

            full_name = getattr(request.user, 'get_full_name', None)
            recorded_by = (full_name() if callable(full_name) else None) or getattr(request.user, 'username', 'unknown')
            inserted = 0

            for entry in entries:
                datetime_text = entry.get('datetime_text', '').strip()
                bp          = entry.get('bp', '').strip()
                pr          = entry.get('pr', '').strip()
                rr          = entry.get('rr', '').strip()
                temp_str    = entry.get('temperature', '').strip()
                o2_sat      = entry.get('o2_sat', '').strip()

                if not any([datetime_text, bp, pr, rr, temp_str, o2_sat]):
                    continue

                # Parse datetime_text -> record_date, record_time
                record_date = None
                record_time = None
                if datetime_text:
                    for fmt in ('%Y-%m-%d %H:%M', '%m/%d/%Y %H:%M',
                                '%Y-%m-%d',       '%m/%d/%Y'):
                        try:
                            dt = datetime.strptime(datetime_text, fmt)
                            record_date = dt.date()
                            record_time = dt.time() if ' ' in fmt else None
                            break
                        except ValueError:
                            continue

                # Parse temperature (numeric)
                temperature = None
                if temp_str:
                    try:
                        temperature = float(temp_str)
                    except ValueError:
                        temperature = None

                cursor.execute("""
                    INSERT INTO pch.ipd_vital_signs
                        (patient_id, admission_id, hospital_id, ward_room,
                         record_date, record_time, bp, pr, rr,
                         temperature, o2_sat, recorded_by,
                         created_at, updated_at)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
                """, [
                    patient_id, admission_id, hospital_id, ward_room,
                    record_date, record_time, bp, pr, rr,
                    temperature, o2_sat, recorded_by,
                ])
                inserted += 1

        return Response({'success': True, 'inserted': inserted},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_vital_signs(request, hospital_id):
    """
    Retrieve vital signs for a patient.
    GET /api/ipd/vital-signs/{hospital_id}/
    Returns entries in insertion order (vital_signs_id ASC) so the frontend
    can map them back to cells: row0-left, row0-right, row1-left, ...
    """
    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT vital_signs_id,
                       COALESCE(TO_CHAR(record_date, 'YYYY-MM-DD'), '') AS record_date,
                       COALESCE(TO_CHAR(record_time, 'HH24:MI'), '')    AS record_time,
                       COALESCE(bp, '')          AS bp,
                       COALESCE(pr, '')          AS pr,
                       COALESCE(rr, '')          AS rr,
                       COALESCE(temperature::TEXT, '') AS temperature,
                       COALESCE(o2_sat, '')      AS o2_sat
                FROM pch.ipd_vital_signs
                WHERE hospital_id = %s
                ORDER BY vital_signs_id ASC
            """, [hospital_id])

            columns = [col[0] for col in cursor.description]
            entries = [dict(zip(columns, row)) for row in cursor.fetchall()]

        return Response({'success': True, 'entries': entries},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ============================================================
# DOCTOR'S ORDER API
# ============================================================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_doctors_order(request):
    """
    Save doctor's order for a patient.
    POST /api/ipd/doctors-order/
    Body: { hospital_id, entries: [{order_date, order_time, progress_notes, doctors_order}] }
    """
    try:
        data = request.data
        hospital_id = data.get('hospital_id', '').strip()
        entries = data.get('entries', [])

        if not hospital_id:
            return Response({'success': False, 'error': 'hospital_id is required'},
                            status=status.HTTP_400_BAD_REQUEST)

        with connection.cursor() as cursor:
            # Resolve patient_id
            cursor.execute(
                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",
                [hospital_id]
            )
            row = cursor.fetchone()
            patient_id = row[0] if row else None

            if not patient_id:
                return Response({'success': False, 'error': f'Patient {hospital_id} not found'},
                                status=status.HTTP_404_NOT_FOUND)

            # Resolve most-recent admission_id
            admission_id = None
            cursor.execute(
                "SELECT admission_id FROM pch.ipd_notice_of_admission WHERE patient_id = %s ORDER BY created_at DESC LIMIT 1",
                [patient_id]
            )
            adm = cursor.fetchone()
            if adm:
                admission_id = adm[0]

            # Resolve ward / room
            ward_room = ''
            if admission_id:
                cursor.execute(
                    "SELECT department FROM pch.ipd_notice_of_admission WHERE admission_id = %s",
                    [admission_id]
                )
                wr = cursor.fetchone()
                if wr:
                    ward_room = wr[0] or ''

            # Get doctor's name
            full_name = getattr(request.user, 'get_full_name', None)
            ordered_by = (full_name() if callable(full_name) else None) or getattr(request.user, 'username', 'unknown')

            # Delete existing orders for this patient
            cursor.execute(
                "DELETE FROM pch.ipd_doctors_order WHERE hospital_id = %s",
                [hospital_id]
            )

            inserted = 0
            for entry in entries:
                order_date = entry.get('order_date')
                order_time = entry.get('order_time')
                progress_notes = entry.get('progress_notes', '').strip()
                doctors_order = entry.get('doctors_order', '').strip()

                if not any([progress_notes, doctors_order]):
                    continue

                cursor.execute("""
                    INSERT INTO pch.ipd_doctors_order
                        (patient_id, admission_id, hospital_id, ward_room,
                         order_date, order_time, progress_notes, doctors_order,
                         ordered_by, created_at, updated_at)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
                """, [
                    patient_id, admission_id, hospital_id, ward_room,
                    order_date, order_time, progress_notes, doctors_order,
                    ordered_by
                ])
                inserted += 1

        return Response({'success': True, 'inserted': inserted},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_doctors_order(request, hospital_id):
    """
    Retrieve doctor's orders for a patient.
    GET /api/ipd/doctors-order/{hospital_id}/
    """
    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT order_id,
                       COALESCE(TO_CHAR(order_date, 'YYYY-MM-DD'), '') AS order_date,
                       COALESCE(TO_CHAR(order_time, 'HH24:MI'), '') AS order_time,
                       COALESCE(progress_notes, '') AS progress_notes,
                       COALESCE(doctors_order, '') AS doctors_order,
                       COALESCE(ordered_by, '') AS ordered_by
                FROM pch.ipd_doctors_order
                WHERE hospital_id = %s
                ORDER BY order_id ASC
            """, [hospital_id])

            columns = [col[0] for col in cursor.description]
            entries = [dict(zip(columns, row)) for row in cursor.fetchall()]

        return Response({'success': True, 'entries': entries},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_doctors_order(request, hospital_id):
    """
    Retrieve doctor's orders for a patient.
    GET /api/ipd/doctors-order/{hospital_id}/
    Returns all orders for the patient ordered by date/time
    """
    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT order_id,
                       COALESCE(TO_CHAR(order_date, 'YYYY-MM-DD'), '') AS order_date,
                       COALESCE(TO_CHAR(order_time, 'HH24:MI'), '')    AS order_time,
                       COALESCE(progress_notes, '') AS progress_notes,
                       COALESCE(doctors_order, '')  AS doctors_order,
                       COALESCE(ordered_by, '')     AS ordered_by,
                       COALESCE(TO_CHAR(created_at, 'YYYY-MM-DD HH24:MI:SS'), '') AS created_at
                FROM pch.ipd_doctors_order
                WHERE hospital_id = %s
                ORDER BY order_date DESC, order_time DESC, order_id DESC
            """, [hospital_id])

            columns = [col[0] for col in cursor.description]
            entries = [dict(zip(columns, row)) for row in cursor.fetchall()]

        return Response({'success': True, 'entries': entries},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_doctors_order(request, order_id):
    """
    Delete a specific doctor's order.
    DELETE /api/ipd/doctors-order/{order_id}/
    """
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "DELETE FROM pch.ipd_doctors_order WHERE order_id = %s",
                [order_id]
            )
            if cursor.rowcount == 0:
                return Response({'success': False, 'error': 'Order not found'},
                                status=status.HTTP_404_NOT_FOUND)

        return Response({'success': True, 'message': 'Order deleted successfully'},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ============================================================
# IVF SHEET API
# ============================================================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_ivf_sheet(request):
    """
    Save IVF (Intravenous Fluid) sheet for a patient.
    POST /api/ipd/ivf-sheet/
    Body: { hospital_id, entries: [{date, shift, bottle_no, kind_of_solution, volume, rate, time_started, remarks, nurse_signature}] }
    """
    try:
        data = request.data
        hospital_id = data.get('hospital_id', '').strip()
        entries = data.get('entries', [])

        if not hospital_id:
            return Response({'success': False, 'error': 'hospital_id is required'},
                            status=status.HTTP_400_BAD_REQUEST)

        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",
                [hospital_id]
            )
            row = cursor.fetchone()
            patient_id = row[0] if row else None

            admission_id = None
            if patient_id:
                cursor.execute(
                    "SELECT admission_id FROM pch.ipd_notice_of_admission WHERE patient_id = %s ORDER BY created_at DESC LIMIT 1",
                    [patient_id]
                )
                adm = cursor.fetchone()
                if adm:
                    admission_id = adm[0]

            ward_room = ''
            if admission_id:
                cursor.execute(
                    "SELECT department FROM pch.ipd_notice_of_admission WHERE admission_id = %s",
                    [admission_id]
                )
                wr = cursor.fetchone()
                if wr:
                    ward_room = wr[0] or ''

            cursor.execute(
                "DELETE FROM pch.ipd_ivf_sheet WHERE hospital_id = %s",
                [hospital_id]
            )

            full_name = getattr(request.user, 'get_full_name', None)
            recorded_by = (full_name() if callable(full_name) else None) or getattr(request.user, 'username', 'unknown')
            inserted = 0

            for entry in entries:
                date_str   = entry.get('date', '').strip()
                shift      = entry.get('shift', '').strip()
                bottle_no  = entry.get('bottle_no', '').strip()
                solution   = entry.get('kind_of_solution', '').strip()
                volume_str = entry.get('volume', '').strip()
                rate_str   = entry.get('rate', '').strip()
                time_start = entry.get('time_started', '').strip()
                remarks    = entry.get('remarks', '').strip()
                nurse_sig  = entry.get('nurse_signature', '').strip()

                if not any([date_str, shift, bottle_no, solution, volume_str, rate_str, time_start, remarks, nurse_sig]):
                    continue

                infusion_date = None
                if date_str:
                    for fmt in ('%Y-%m-%d', '%m/%d/%Y', '%m/%d/%y'):
                        try:
                            from datetime import datetime as _dt
                            infusion_date = _dt.strptime(date_str, fmt).date()
                            break
                        except ValueError:
                            continue

                # Parse volume and rate as numeric
                volume_ml = None
                if volume_str:
                    try:
                        volume_ml = float(volume_str)
                    except ValueError:
                        pass

                rate_ml_hr = None
                if rate_str:
                    try:
                        rate_ml_hr = float(rate_str)
                    except ValueError:
                        pass

                # Parse time_started
                time_started_obj = None
                if time_start:
                    for fmt in ('%H:%M', '%H:%M:%S', '%I:%M %p'):
                        try:
                            from datetime import datetime as _dt
                            time_started_obj = _dt.strptime(time_start, fmt).time()
                            break
                        except ValueError:
                            continue

                cursor.execute("""
                    INSERT INTO pch.ipd_ivf_sheet
                        (patient_id, admission_id, hospital_id, ward_room,
                         infusion_date, shift, bottle_no, kind_of_solution,
                         volume_ml, rate_ml_hr, time_started, remarks, nurse_signature,
                         created_at, updated_at)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
                """, [
                    patient_id, admission_id, hospital_id, ward_room,
                    infusion_date, shift, bottle_no, solution,
                    volume_ml, rate_ml_hr, time_started_obj, remarks, nurse_sig,
                ])
                inserted += 1

        return Response({'success': True, 'inserted': inserted},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_ivf_sheet(request, hospital_id):
    """
    Retrieve IVF sheet entries for a patient.
    GET /api/ipd/ivf-sheet/{hospital_id}/
    """
    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT ivf_id,
                       COALESCE(TO_CHAR(infusion_date, 'YYYY-MM-DD'), '') AS date,
                       COALESCE(shift, '')             AS shift,
                       COALESCE(bottle_no, '')         AS bottle_no,
                       COALESCE(kind_of_solution, '')  AS kind_of_solution,
                       COALESCE(volume_ml::TEXT, '')   AS volume,
                       COALESCE(rate_ml_hr::TEXT, '')  AS rate,
                       COALESCE(TO_CHAR(time_started, 'HH24:MI'), '') AS time_started,
                       COALESCE(remarks, '')           AS remarks,
                       COALESCE(nurse_signature, '')   AS nurse_signature
                FROM pch.ipd_ivf_sheet
                WHERE hospital_id = %s
                ORDER BY ivf_id ASC
            """, [hospital_id])

            columns = [col[0] for col in cursor.description]
            entries = [dict(zip(columns, row)) for row in cursor.fetchall()]

        return Response({'success': True, 'entries': entries},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ============================================================
# WEEKLY STATISTICS API
# ============================================================

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def weekly_stats(request):
    """
    Return weekly/daily admission, discharge, diagnosis statistics.
    GET /api/ipd/weekly-stats/
    """
    try:
        today      = datetime.now().date()
        week_start = today - timedelta(days=today.weekday())
        week_end   = week_start + timedelta(days=6)
        seven_ago  = today - timedelta(days=6)

        # ── Admissions & Diagnoses ────────────────────────────────
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT COUNT(*) FROM pch.ipd_notice_of_admission WHERE admission_date >= %s AND admission_date <= %s",
                [week_start, week_end])
            admissions_week = cursor.fetchone()[0] or 0

            cursor.execute(
                "SELECT COUNT(*) FROM pch.ipd_notice_of_admission WHERE admission_date = %s",
                [today])
            admissions_today = cursor.fetchone()[0] or 0

            cursor.execute("""
                SELECT admission_date::TEXT, COUNT(*) FROM pch.ipd_notice_of_admission
                WHERE admission_date >= %s AND admission_date <= %s
                GROUP BY admission_date ORDER BY admission_date
            """, [seven_ago, today])
            admissions_per_day = {r[0]: r[1] for r in cursor.fetchall()}

            cursor.execute("""
                SELECT COUNT(*) AS total, COUNT(DISTINCT admission_date) AS days
                FROM pch.ipd_notice_of_admission
                WHERE admission_date >= %s AND admission_date <= %s
            """, [week_start, today])
            row = cursor.fetchone()
            avg_daily = round((row[0] or 0) / max(row[1] or 1, 1), 1)

            cursor.execute("""
                SELECT TRIM(admitting_impression), COUNT(*) AS cnt
                FROM pch.ipd_notice_of_admission
                WHERE admission_date >= %s AND admission_date <= %s
                  AND admitting_impression IS NOT NULL AND TRIM(admitting_impression) <> ''
                GROUP BY TRIM(admitting_impression)
                ORDER BY cnt DESC LIMIT 5
            """, [week_start, week_end])
            diagnoses_week = [{'diagnosis': r[0], 'count': r[1]} for r in cursor.fetchall()]

            cursor.execute("""
                SELECT TRIM(admitting_impression), COUNT(*) AS cnt
                FROM pch.ipd_notice_of_admission
                WHERE admission_date = %s
                  AND admitting_impression IS NOT NULL AND TRIM(admitting_impression) <> ''
                GROUP BY TRIM(admitting_impression)
                ORDER BY cnt DESC LIMIT 5
            """, [today])
            diagnoses_today = [{'diagnosis': r[0], 'count': r[1]} for r in cursor.fetchall()]

        # ── Discharges (table may not exist yet) ──────────────────
        discharges_week   = 0
        discharges_today  = 0
        discharges_per_day = {}
        try:
            with connection.cursor() as cursor:
                cursor.execute(
                    "SELECT COUNT(*) FROM pch.ipd_discharge_slip WHERE discharge_date >= %s AND discharge_date <= %s",
                    [week_start, week_end])
                discharges_week = cursor.fetchone()[0] or 0

                cursor.execute(
                    "SELECT COUNT(*) FROM pch.ipd_discharge_slip WHERE discharge_date = %s",
                    [today])
                discharges_today = cursor.fetchone()[0] or 0

                cursor.execute("""
                    SELECT discharge_date::TEXT, COUNT(*) FROM pch.ipd_discharge_slip
                    WHERE discharge_date >= %s AND discharge_date <= %s
                    GROUP BY discharge_date ORDER BY discharge_date
                """, [seven_ago, today])
                discharges_per_day = {r[0]: r[1] for r in cursor.fetchall()}
        except Exception:
            pass  # table not yet created; return zeros

        day_labels = [(seven_ago + timedelta(days=i)).isoformat() for i in range(7)]

        return Response({
            'success':    True,
            'today':      today.isoformat(),
            'week_start': week_start.isoformat(),
            'week_end':   week_end.isoformat(),
            'admissions': {
                'this_week': admissions_week,
                'today':     admissions_today,
                'avg_daily': avg_daily,
                'per_day':   admissions_per_day,
            },
            'discharges': {
                'this_week': discharges_week,
                'today':     discharges_today,
                'per_day':   discharges_per_day,
            },
            'diagnoses': {
                'this_week': diagnoses_week,
                'today':     diagnoses_today,
            },
            'day_labels': day_labels,
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ============================================================
# WEEKLY FORECAST API  (ARIMA on real DB data)
# ============================================================

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def weekly_forecast(request):
    """
    Forecast weekly admissions & discharges using ARIMA on real DB data.
    GET /api/ipd/weekly-forecast/?weeks=4&history=26
    """
    try:
        from .forecasting import DiseaseForecaster
        import numpy as np

        forecast_weeks = int(request.query_params.get('weeks', 4))
        history_weeks  = int(request.query_params.get('history', 26))
        today          = datetime.now().date()
        history_start  = today - timedelta(weeks=history_weeks)

        # ── Weekly admission history ─────────────────────────────
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT DATE_TRUNC('week', admission_date)::DATE AS wk,
                       COUNT(*) AS cnt
                FROM pch.ipd_notice_of_admission
                WHERE admission_date >= %s AND admission_date <= %s
                GROUP BY DATE_TRUNC('week', admission_date)
                ORDER BY wk
            """, [history_start, today])
            adm_rows = cursor.fetchall()

        adm_history = [{'date': r[0].isoformat(), 'cases': int(r[1])} for r in adm_rows]

        # ── Weekly discharge history (graceful fallback) ─────────
        dis_history = []
        try:
            with connection.cursor() as cursor:
                cursor.execute("""
                    SELECT DATE_TRUNC('week', discharge_date)::DATE AS wk,
                           COUNT(*) AS cnt
                    FROM pch.ipd_discharge_slip
                    WHERE discharge_date >= %s AND discharge_date <= %s
                    GROUP BY DATE_TRUNC('week', discharge_date)
                    ORDER BY wk
                """, [history_start, today])
                dis_rows = cursor.fetchall()
            dis_history = [{'date': r[0].isoformat(), 'cases': int(r[1])} for r in dis_rows]
        except Exception:
            pass

        # ── ARIMA forecast helper ────────────────────────────────
        def run_forecast(history, label, periods):
            def _moving_avg_result(avg, last_dt):
                fl = []
                for i in range(periods):
                    fd = last_dt + timedelta(weeks=i + 1)
                    fl.append({
                        'date':      fd.strftime('%Y-%m-%d'),
                        'forecast':  avg,
                        'lower_ci':  max(0.0, round(avg * 0.8, 1)),
                        'upper_ci':  round(avg * 1.2, 1),
                    })
                return fl

            if len(history) < 4:
                avg     = round(sum(h['cases'] for h in history) / len(history), 1) if history else 0.0
                last_dt = datetime.strptime(history[-1]['date'], '%Y-%m-%d') if history else datetime.now()
                return {
                    'forecast': _moving_avg_result(avg, last_dt),
                    'trend': 'Stable', 'avg_forecast': avg,
                    'model': 'moving_average', 'note': 'Min 4 weeks required for ARIMA.',
                }

            try:
                forecaster = DiseaseForecaster(label, history)
                forecaster.fit_model(order=(1, 1, 0))
                fc_result = forecaster.fitted_model.get_forecast(steps=periods)
                fc_df     = fc_result.summary_frame()
                ts        = forecaster.prepare_data()
                last_dt   = ts.index[-1]

                fl = []
                for i in range(periods):
                    fd  = last_dt + timedelta(weeks=i + 1)
                    val = max(0.0, round(float(fc_df['mean'].iloc[i]), 1))
                    fl.append({
                        'date':      fd.strftime('%Y-%m-%d'),
                        'forecast':  val,
                        'lower_ci':  max(0.0, round(float(fc_df['mean_ci_lower'].iloc[i]), 1)),
                        'upper_ci':  round(float(fc_df['mean_ci_upper'].iloc[i]), 1),
                    })

                vals  = [f['forecast'] for f in fl]
                trend = ('Rising'  if vals[-1] > vals[0] * 1.05 else
                         'Falling' if vals[-1] < vals[0] * 0.95 else 'Stable')
                return {
                    'forecast': fl, 'trend': trend,
                    'avg_forecast': round(float(np.mean(vals)), 1),
                    'model': 'ARIMA(1,1,0)',
                    'note': f'Based on last {len(history)} weeks of data.',
                }

            except Exception as err:
                vals    = [h['cases'] for h in history[-8:]]
                avg     = round(sum(vals) / len(vals), 1) if vals else 0.0
                last_dt = datetime.strptime(history[-1]['date'], '%Y-%m-%d')
                return {
                    'forecast': _moving_avg_result(avg, last_dt),
                    'trend': 'Stable', 'avg_forecast': avg,
                    'model': 'moving_average',
                    'note': f'ARIMA failed: {str(err)[:80]}',
                }

        no_data = {'forecast': [], 'trend': 'No data', 'avg_forecast': 0.0, 'model': 'none', 'note': ''}
        adm_fc = run_forecast(adm_history, 'Admissions', forecast_weeks) if adm_history else no_data
        dis_fc = run_forecast(dis_history, 'Discharges', forecast_weeks) if dis_history else {**no_data, 'note': 'No discharge records.'}

        return Response({
            'success':        True,
            'forecast_weeks': forecast_weeks,
            'admissions':     adm_fc,
            'discharges':     dis_fc,
            'history': {
                'admissions': adm_history,
                'discharges': dis_history,
            },
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ============================================================
# MEDICATION SHEET API
# ============================================================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_medication_sheet(request):
    """
    Save medication sheet for a patient.
    POST /api/ipd/medication-sheet/
    Body: { hospital_id, entries: [{medication_name, dosage, frequency, route, administration_date, administration_time, administered_by, remarks}] }
    """
    try:
        data = request.data
        hospital_id = data.get('hospital_id', '').strip()
        entries = data.get('entries', [])

        if not hospital_id:
            return Response({'success': False, 'error': 'hospital_id is required'},
                            status=status.HTTP_400_BAD_REQUEST)

        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",
                [hospital_id]
            )
            row = cursor.fetchone()
            patient_id = row[0] if row else None

            if not patient_id:
                return Response({'success': False, 'error': f'Patient {hospital_id} not found'},
                                status=status.HTTP_404_NOT_FOUND)

            admission_id = None
            cursor.execute(
                "SELECT admission_id FROM pch.ipd_notice_of_admission WHERE patient_id = %s ORDER BY created_at DESC LIMIT 1",
                [patient_id]
            )
            adm = cursor.fetchone()
            if adm:
                admission_id = adm[0]

            ward_room = ''
            if admission_id:
                cursor.execute(
                    "SELECT department FROM pch.ipd_notice_of_admission WHERE admission_id = %s",
                    [admission_id]
                )
                wr = cursor.fetchone()
                if wr:
                    ward_room = wr[0] or ''

            cursor.execute(
                "DELETE FROM pch.ipd_medication_sheet WHERE hospital_id = %s",
                [hospital_id]
            )

            full_name = getattr(request.user, 'get_full_name', None)
            administered_by = (full_name() if callable(full_name) else None) or getattr(request.user, 'username', 'unknown')
            inserted = 0

            for entry in entries:
                medication_name = entry.get('medication_name', '').strip()
                dosage = entry.get('dosage', '').strip()
                frequency = entry.get('frequency', '').strip()
                route = entry.get('route', '').strip()
                admin_date_str = entry.get('administration_date', '').strip()
                admin_time_str = entry.get('administration_time', '').strip()
                remarks = entry.get('remarks', '').strip()

                if not any([medication_name, dosage, frequency, route, admin_date_str, admin_time_str, remarks]):
                    continue

                administration_date = None
                if admin_date_str:
                    for fmt in ('%Y-%m-%d', '%m/%d/%Y', '%d/%m/%Y', '%m/%d/%y', '%d/%m/%y'):
                        try:
                            administration_date = datetime.strptime(admin_date_str, fmt).date()
                            break
                        except ValueError:
                            continue

                administration_time = None
                if admin_time_str:
                    for fmt in ('%H:%M', '%H:%M:%S', '%I:%M %p'):
                        try:
                            administration_time = datetime.strptime(admin_time_str, fmt).time()
                            break
                        except ValueError:
                            continue

                cursor.execute("""
                    INSERT INTO pch.ipd_medication_sheet
                        (patient_id, admission_id, hospital_id, ward_room,
                         medication_name, dosage, frequency, route,
                         administration_date, administration_time, administered_by, remarks,
                         created_at, updated_at)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
                """, [
                    patient_id, admission_id, hospital_id, ward_room,
                    medication_name, dosage, frequency, route,
                    administration_date, administration_time, administered_by, remarks
                ])
                inserted += 1

        return Response({'success': True, 'inserted': inserted},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_medication_sheet(request, hospital_id):
    """
    Retrieve medication sheet entries for a patient.
    GET /api/ipd/medication-sheet/{hospital_id}/
    """
    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT medication_id,
                       COALESCE(medication_name, '') AS medication_name,
                       COALESCE(dosage, '') AS dosage,
                       COALESCE(frequency, '') AS frequency,
                       COALESCE(route, '') AS route,
                       COALESCE(TO_CHAR(administration_date, 'YYYY-MM-DD'), '') AS administration_date,
                       COALESCE(TO_CHAR(administration_time, 'HH24:MI'), '') AS administration_time,
                       COALESCE(administered_by, '') AS administered_by,
                       COALESCE(remarks, '') AS remarks
                FROM pch.ipd_medication_sheet
                WHERE hospital_id = %s
                ORDER BY medication_id ASC
            """, [hospital_id])

            columns = [col[0] for col in cursor.description]
            entries = [dict(zip(columns, row)) for row in cursor.fetchall()]

        return Response({'success': True, 'entries': entries},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ============================================================
# MEDICATION STAT & PRN API
# ============================================================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_medication_stat_prn(request):
    """
    Save medication STAT & PRN sheet for a patient.
    POST /api/ipd/medication-stat-prn/
    Body: { hospital_id, entries: [{order_type, medication_name, dosage, frequency, route, administration_date, administration_time, administered_by, remarks}] }
    """
    try:
        data = request.data
        hospital_id = data.get('hospital_id', '').strip()
        entries = data.get('entries', [])

        if not hospital_id:
            return Response({'success': False, 'error': 'hospital_id is required'},
                            status=status.HTTP_400_BAD_REQUEST)

        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",
                [hospital_id]
            )
            row = cursor.fetchone()
            patient_id = row[0] if row else None

            if not patient_id:
                return Response({'success': False, 'error': f'Patient {hospital_id} not found'},
                                status=status.HTTP_404_NOT_FOUND)

            admission_id = None
            cursor.execute(
                "SELECT admission_id FROM pch.ipd_notice_of_admission WHERE patient_id = %s ORDER BY created_at DESC LIMIT 1",
                [patient_id]
            )
            adm = cursor.fetchone()
            if adm:
                admission_id = adm[0]

            ward_room = ''
            if admission_id:
                cursor.execute(
                    "SELECT department FROM pch.ipd_notice_of_admission WHERE admission_id = %s",
                    [admission_id]
                )
                wr = cursor.fetchone()
                if wr:
                    ward_room = wr[0] or ''

            cursor.execute(
                "DELETE FROM pch.ipd_medication_stat_prn WHERE hospital_id = %s",
                [hospital_id]
            )

            full_name = getattr(request.user, 'get_full_name', None)
            administered_by = (full_name() if callable(full_name) else None) or getattr(request.user, 'username', 'unknown')
            inserted = 0

            for entry in entries:
                order_type = entry.get('order_type', '').strip()
                medication_name = entry.get('medication_name', '').strip()
                dosage = entry.get('dosage', '').strip()
                frequency = entry.get('frequency', '').strip()
                route = entry.get('route', '').strip()
                admin_date_str = entry.get('administration_date', '').strip()
                admin_time_str = entry.get('administration_time', '').strip()
                remarks = entry.get('remarks', '').strip()

                if not any([order_type, medication_name, dosage, frequency, route, admin_date_str, admin_time_str, remarks]):
                    continue

                administration_date = None
                if admin_date_str:
                    for fmt in ('%Y-%m-%d', '%m/%d/%Y', '%d/%m/%Y', '%m/%d/%y', '%d/%m/%y'):
                        try:
                            administration_date = datetime.strptime(admin_date_str, fmt).date()
                            break
                        except ValueError:
                            continue

                administration_time = None
                if admin_time_str:
                    for fmt in ('%H:%M', '%H:%M:%S', '%I:%M %p'):
                        try:
                            administration_time = datetime.strptime(admin_time_str, fmt).time()
                            break
                        except ValueError:
                            continue

                cursor.execute("""
                    INSERT INTO pch.ipd_medication_stat_prn
                        (patient_id, admission_id, hospital_id, ward_room,
                         order_type, medication_name, dosage, frequency, route,
                         administration_date, administration_time, administered_by, remarks,
                         created_at, updated_at)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
                """, [
                    patient_id, admission_id, hospital_id, ward_room,
                    order_type, medication_name, dosage, frequency, route,
                    administration_date, administration_time, administered_by, remarks
                ])
                inserted += 1

        return Response({'success': True, 'inserted': inserted},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_medication_stat_prn(request, hospital_id):
    """
    Retrieve medication STAT & PRN entries for a patient.
    GET /api/ipd/medication-stat-prn/{hospital_id}/
    """
    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT stat_prn_id,
                       COALESCE(order_type, '') AS order_type,
                       COALESCE(medication_name, '') AS medication_name,
                       COALESCE(dosage, '') AS dosage,
                       COALESCE(frequency, '') AS frequency,
                       COALESCE(route, '') AS route,
                       COALESCE(TO_CHAR(administration_date, 'YYYY-MM-DD'), '') AS administration_date,
                       COALESCE(TO_CHAR(administration_time, 'HH24:MI'), '') AS administration_time,
                       COALESCE(administered_by, '') AS administered_by,
                       COALESCE(remarks, '') AS remarks
                FROM pch.ipd_medication_stat_prn
                WHERE hospital_id = %s
                ORDER BY stat_prn_id ASC
            """, [hospital_id])

            columns = [col[0] for col in cursor.description]
            entries = [dict(zip(columns, row)) for row in cursor.fetchall()]

        return Response({'success': True, 'entries': entries},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ============================================================
# NURSES NOTES API
# ============================================================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_nurses_notes(request):
    """
    Save nurses notes for a patient.
    POST /api/ipd/nurses-notes/
    Body: { hospital_id, entries: [{note_date, shift, note_time, notes, nurse_signature}] }
    """
    try:
        data = request.data
        hospital_id = data.get('hospital_id', '').strip()
        entries = data.get('entries', [])

        if not hospital_id:
            return Response({'success': False, 'error': 'hospital_id is required'},
                            status=status.HTTP_400_BAD_REQUEST)

        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",
                [hospital_id]
            )
            row = cursor.fetchone()
            patient_id = row[0] if row else None

            if not patient_id:
                return Response({'success': False, 'error': f'Patient {hospital_id} not found'},
                                status=status.HTTP_404_NOT_FOUND)

            admission_id = None
            cursor.execute(
                "SELECT admission_id FROM pch.ipd_notice_of_admission WHERE patient_id = %s ORDER BY created_at DESC LIMIT 1",
                [patient_id]
            )
            adm = cursor.fetchone()
            if adm:
                admission_id = adm[0]

            ward_room = ''
            if admission_id:
                cursor.execute(
                    "SELECT department FROM pch.ipd_notice_of_admission WHERE admission_id = %s",
                    [admission_id]
                )
                wr = cursor.fetchone()
                if wr:
                    ward_room = wr[0] or ''

            cursor.execute(
                "DELETE FROM pch.ipd_nurses_notes WHERE hospital_id = %s",
                [hospital_id]
            )

            full_name = getattr(request.user, 'get_full_name', None)
            nurse_signature = (full_name() if callable(full_name) else None) or getattr(request.user, 'username', 'unknown')
            inserted = 0

            for entry in entries:
                note_date_str = entry.get('note_date', '').strip()
                shift = entry.get('shift', '').strip()
                note_time_str = entry.get('note_time', '').strip()
                notes = entry.get('notes', '').strip()

                if not any([note_date_str, shift, note_time_str, notes]):
                    continue

                note_date = None
                if note_date_str:
                    for fmt in ('%Y-%m-%d', '%m/%d/%Y', '%d/%m/%Y'):
                        try:
                            note_date = datetime.strptime(note_date_str, fmt).date()
                            break
                        except ValueError:
                            continue

                note_time = None
                if note_time_str:
                    for fmt in ('%H:%M', '%H:%M:%S', '%I:%M %p'):
                        try:
                            note_time = datetime.strptime(note_time_str, fmt).time()
                            break
                        except ValueError:
                            continue

                cursor.execute("""
                    INSERT INTO pch.ipd_nurses_notes
                        (patient_id, admission_id, hospital_id, ward_room,
                         note_date, shift, note_time, notes, nurse_signature,
                         created_at, updated_at)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
                """, [
                    patient_id, admission_id, hospital_id, ward_room,
                    note_date, shift, note_time, notes, nurse_signature
                ])
                inserted += 1

        return Response({'success': True, 'inserted': inserted},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_nurses_notes(request, hospital_id):
    """
    Retrieve nurses notes for a patient.
    GET /api/ipd/nurses-notes/{hospital_id}/
    """
    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT note_id,
                       COALESCE(TO_CHAR(note_date, 'YYYY-MM-DD'), '') AS note_date,
                       COALESCE(shift, '') AS shift,
                       COALESCE(TO_CHAR(note_time, 'HH24:MI'), '') AS note_time,
                       COALESCE(notes, '') AS notes,
                       COALESCE(nurse_signature, '') AS nurse_signature
                FROM pch.ipd_nurses_notes
                WHERE hospital_id = %s
                ORDER BY note_id ASC
            """, [hospital_id])

            columns = [col[0] for col in cursor.description]
            entries = [dict(zip(columns, row)) for row in cursor.fetchall()]

        return Response({'success': True, 'entries': entries},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ============================================================
# TPR SHEET API
# ============================================================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_tpr_sheet(request):
    """
    Save TPR (Temperature/Pulse/Respiration) sheet for a patient.
    POST /api/ipd/tpr-sheet/
    Body: { hospital_id, entries: [{record_date, day_of_month, day_of_diagnosis, days_in_hospital, weight_kg, time_period, respiration, pulse, temperature, urine_7_3, urine_3_11, urine_11_7, stool_7_3, stool_3_11, stool_11_7}] }
    """
    try:
        data = request.data
        hospital_id = data.get('hospital_id', '').strip()
        case_no = data.get('case_no', '').strip()
        bed_no = data.get('bed_no', '').strip()
        doctor = data.get('doctor', '').strip()
        entries = data.get('entries', [])

        if not hospital_id:
            return Response({'success': False, 'error': 'hospital_id is required'},
                            status=status.HTTP_400_BAD_REQUEST)

        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",
                [hospital_id]
            )
            row = cursor.fetchone()
            patient_id = row[0] if row else None

            if not patient_id:
                return Response({'success': False, 'error': f'Patient {hospital_id} not found'},
                                status=status.HTTP_404_NOT_FOUND)

            admission_id = None
            cursor.execute(
                "SELECT admission_id FROM pch.ipd_notice_of_admission WHERE patient_id = %s ORDER BY created_at DESC LIMIT 1",
                [patient_id]
            )
            adm = cursor.fetchone()
            if adm:
                admission_id = adm[0]

            cursor.execute(
                "DELETE FROM pch.ipd_tpr_sheet WHERE patient_id = %s",
                [patient_id]
            )

            inserted = 0
            for entry in entries:
                record_date_str = entry.get('record_date', '').strip()
                day_of_month_str = entry.get('day_of_month', '').strip()
                day_of_diagnosis_str = entry.get('day_of_diagnosis', '').strip()
                days_in_hospital_str = entry.get('days_in_hospital', '').strip()
                weight_kg_str = entry.get('weight_kg', '').strip()
                time_period = entry.get('time_period', '').strip()
                respiration_str = entry.get('respiration', '').strip()
                pulse_str = entry.get('pulse', '').strip()
                temperature_str = entry.get('temperature', '').strip()
                urine_7_3_str = entry.get('urine_7_3', '').strip()
                urine_3_11_str = entry.get('urine_3_11', '').strip()
                urine_11_7_str = entry.get('urine_11_7', '').strip()
                stool_7_3 = entry.get('stool_7_3', '').strip()
                stool_3_11 = entry.get('stool_3_11', '').strip()
                stool_11_7 = entry.get('stool_11_7', '').strip()

                if not any([record_date_str, time_period, respiration_str, pulse_str, temperature_str]):
                    continue

                record_date = None
                if record_date_str:
                    for fmt in ('%Y-%m-%d', '%m/%d/%Y', '%d/%m/%Y'):
                        try:
                            record_date = datetime.strptime(record_date_str, fmt).date()
                            break
                        except ValueError:
                            continue

                # Parse numeric fields
                day_of_month = int(day_of_month_str) if day_of_month_str and day_of_month_str.isdigit() else None
                day_of_diagnosis = int(day_of_diagnosis_str) if day_of_diagnosis_str and day_of_diagnosis_str.isdigit() else None
                days_in_hospital = int(days_in_hospital_str) if days_in_hospital_str and days_in_hospital_str.isdigit() else None
                weight_kg = float(weight_kg_str) if weight_kg_str else None
                respiration = int(respiration_str) if respiration_str and respiration_str.isdigit() else None
                pulse = int(pulse_str) if pulse_str and pulse_str.isdigit() else None
                temperature = float(temperature_str) if temperature_str else None
                urine_7_3 = float(urine_7_3_str) if urine_7_3_str else None
                urine_3_11 = float(urine_3_11_str) if urine_3_11_str else None
                urine_11_7 = float(urine_11_7_str) if urine_11_7_str else None

                cursor.execute("""
                    INSERT INTO pch.ipd_tpr_sheet
                        (patient_id, admission_id, case_no, bed_no, doctor,
                         record_date, day_of_month, day_of_diagnosis, days_in_hospital, weight_kg,
                         time_period, respiration, pulse, temperature,
                         urine_7_3, urine_3_11, urine_11_7,
                         stool_7_3, stool_3_11, stool_11_7,
                         created_at, updated_at)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
                """, [
                    patient_id, admission_id, case_no, bed_no, doctor,
                    record_date, day_of_month, day_of_diagnosis, days_in_hospital, weight_kg,
                    time_period, respiration, pulse, temperature,
                    urine_7_3, urine_3_11, urine_11_7,
                    stool_7_3, stool_3_11, stool_11_7
                ])
                inserted += 1

        return Response({'success': True, 'inserted': inserted},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_tpr_sheet(request, hospital_id):
    """
    Retrieve TPR sheet entries for a patient.
    GET /api/ipd/tpr-sheet/{hospital_id}/
    """
    try:
        with connection.cursor() as cursor:
            # First get patient_id
            cursor.execute(
                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",
                [hospital_id]
            )
            row = cursor.fetchone()
            if not row:
                return Response({'success': False, 'error': f'Patient {hospital_id} not found'},
                                status=status.HTTP_404_NOT_FOUND)
            patient_id = row[0]

            cursor.execute("""
                SELECT tpr_id,
                       COALESCE(case_no, '') AS case_no,
                       COALESCE(bed_no, '') AS bed_no,
                       COALESCE(doctor, '') AS doctor,
                       COALESCE(TO_CHAR(record_date, 'YYYY-MM-DD'), '') AS record_date,
                       COALESCE(day_of_month::TEXT, '') AS day_of_month,
                       COALESCE(day_of_diagnosis::TEXT, '') AS day_of_diagnosis,
                       COALESCE(days_in_hospital::TEXT, '') AS days_in_hospital,
                       COALESCE(weight_kg::TEXT, '') AS weight_kg,
                       COALESCE(time_period, '') AS time_period,
                       COALESCE(respiration::TEXT, '') AS respiration,
                       COALESCE(pulse::TEXT, '') AS pulse,
                       COALESCE(temperature::TEXT, '') AS temperature,
                       COALESCE(urine_7_3::TEXT, '') AS urine_7_3,
                       COALESCE(urine_3_11::TEXT, '') AS urine_3_11,
                       COALESCE(urine_11_7::TEXT, '') AS urine_11_7,
                       COALESCE(stool_7_3, '') AS stool_7_3,
                       COALESCE(stool_3_11, '') AS stool_3_11,
                       COALESCE(stool_11_7, '') AS stool_11_7
                FROM pch.ipd_tpr_sheet
                WHERE patient_id = %s
                ORDER BY tpr_id ASC
            """, [patient_id])

            columns = [col[0] for col in cursor.description]
            entries = [dict(zip(columns, row)) for row in cursor.fetchall()]

        return Response({'success': True, 'entries': entries},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ============================================================
# I&O MONITORING API
# ============================================================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_io_monitoring(request):
    """
    Save I&O (Intake & Output) monitoring sheet for a patient.
    POST /api/ipd/io-monitoring/
    Body: { hospital_id, entries: [{monitoring_date, shift, intake_oral, intake_ivf, output_urine, output_others, total_intake, total_output, nurse_signature}] }
    """
    try:
        data = request.data
        hospital_id = data.get('hospital_id', '').strip()
        entries = data.get('entries', [])

        if not hospital_id:
            return Response({'success': False, 'error': 'hospital_id is required'},
                            status=status.HTTP_400_BAD_REQUEST)

        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",
                [hospital_id]
            )
            row = cursor.fetchone()
            patient_id = row[0] if row else None

            if not patient_id:
                return Response({'success': False, 'error': f'Patient {hospital_id} not found'},
                                status=status.HTTP_404_NOT_FOUND)

            admission_id = None
            cursor.execute(
                "SELECT admission_id FROM pch.ipd_notice_of_admission WHERE patient_id = %s ORDER BY created_at DESC LIMIT 1",
                [patient_id]
            )
            adm = cursor.fetchone()
            if adm:
                admission_id = adm[0]

            cursor.execute(
                "DELETE FROM pch.ipd_io_monitoring WHERE patient_id = %s",
                [patient_id]
            )

            full_name = getattr(request.user, 'get_full_name', None)
            nurse_signature = (full_name() if callable(full_name) else None) or getattr(request.user, 'username', 'unknown')
            inserted = 0

            for entry in entries:
                monitoring_date_str = entry.get('monitoring_date', '').strip()
                shift = entry.get('shift', '').strip()
                intake_oral_str = entry.get('intake_oral', '').strip()
                intake_ivf_str = entry.get('intake_ivf', '').strip()
                output_urine_str = entry.get('output_urine', '').strip()
                output_others_str = entry.get('output_others', '').strip()
                total_intake_str = entry.get('total_intake', '').strip()
                total_output_str = entry.get('total_output', '').strip()

                if not any([monitoring_date_str, shift, intake_oral_str, intake_ivf_str, output_urine_str, output_others_str]):
                    continue

                monitoring_date = None
                if monitoring_date_str:
                    for fmt in ('%Y-%m-%d', '%m/%d/%Y', '%d/%m/%Y'):
                        try:
                            monitoring_date = datetime.strptime(monitoring_date_str, fmt).date()
                            break
                        except ValueError:
                            continue

                intake_oral = float(intake_oral_str) if intake_oral_str else None
                intake_ivf = float(intake_ivf_str) if intake_ivf_str else None
                output_urine = float(output_urine_str) if output_urine_str else None
                output_others = float(output_others_str) if output_others_str else None
                total_intake = float(total_intake_str) if total_intake_str else None
                total_output = float(total_output_str) if total_output_str else None

                cursor.execute("""
                    INSERT INTO pch.ipd_io_monitoring
                        (patient_id, admission_id, monitoring_date, shift,
                         intake_oral, intake_ivf, output_urine, output_others,
                         total_intake, total_output, nurse_signature,
                         created_at, updated_at)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
                """, [
                    patient_id, admission_id, monitoring_date, shift,
                    intake_oral, intake_ivf, output_urine, output_others,
                    total_intake, total_output, nurse_signature
                ])
                inserted += 1

        return Response({'success': True, 'inserted': inserted},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_io_monitoring(request, hospital_id):
    """
    Retrieve I&O monitoring entries for a patient.
    GET /api/ipd/io-monitoring/{hospital_id}/
    """
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",
                [hospital_id]
            )
            row = cursor.fetchone()
            if not row:
                return Response({'success': False, 'error': f'Patient {hospital_id} not found'},
                                status=status.HTTP_404_NOT_FOUND)
            patient_id = row[0]

            cursor.execute("""
                SELECT io_id,
                       COALESCE(TO_CHAR(monitoring_date, 'YYYY-MM-DD'), '') AS monitoring_date,
                       COALESCE(shift, '') AS shift,
                       COALESCE(intake_oral::TEXT, '') AS intake_oral,
                       COALESCE(intake_ivf::TEXT, '') AS intake_ivf,
                       COALESCE(output_urine::TEXT, '') AS output_urine,
                       COALESCE(output_others::TEXT, '') AS output_others,
                       COALESCE(total_intake::TEXT, '') AS total_intake,
                       COALESCE(total_output::TEXT, '') AS total_output,
                       COALESCE(nurse_signature, '') AS nurse_signature
                FROM pch.ipd_io_monitoring
                WHERE patient_id = %s
                ORDER BY io_id ASC
            """, [patient_id])

            columns = [col[0] for col in cursor.description]
            entries = [dict(zip(columns, row)) for row in cursor.fetchall()]

        return Response({'success': True, 'entries': entries},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ============================================================
# CONSENT FORM API
# ============================================================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_consent_form(request):
    """
    Save consent form for a patient.
    POST /api/ipd/consent-form/
    Body: { hospital_id, patient_name, patient_age, civil_status_married, civil_status_single, civil_status_widowed, civil_status_text, consent_date, consent_text, witness_name, witness_signature, patient_signature, representative_name, representative_signature }
    """
    try:
        data = request.data
        hospital_id = data.get('hospital_id', '').strip()

        if not hospital_id:
            return Response({'success': False, 'error': 'hospital_id is required'},
                            status=status.HTTP_400_BAD_REQUEST)

        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",
                [hospital_id]
            )
            row = cursor.fetchone()
            patient_id = row[0] if row else None

            if not patient_id:
                return Response({'success': False, 'error': f'Patient {hospital_id} not found'},
                                status=status.HTTP_404_NOT_FOUND)

            admission_id = None
            cursor.execute(
                "SELECT admission_id FROM pch.ipd_notice_of_admission WHERE patient_id = %s ORDER BY created_at DESC LIMIT 1",
                [patient_id]
            )
            adm = cursor.fetchone()
            if adm:
                admission_id = adm[0]

            # Parse consent_date
            consent_date_str = data.get('consent_date', '').strip()
            consent_date = None
            if consent_date_str:
                for fmt in ('%Y-%m-%d', '%m/%d/%Y', '%d/%m/%Y'):
                    try:
                        consent_date = datetime.strptime(consent_date_str, fmt).date()
                        break
                    except ValueError:
                        continue

            # Check if record exists
            cursor.execute(
                "SELECT consent_id FROM pch.ipd_consent_form WHERE patient_id = %s",
                [patient_id]
            )
            existing = cursor.fetchone()

            if existing:
                cursor.execute("""
                    UPDATE pch.ipd_consent_form
                    SET hospital_id = %s, patient_name = %s, patient_age = %s,
                        civil_status_married = %s, civil_status_single = %s, civil_status_widowed = %s, civil_status_text = %s,
                        consent_date = %s, consent_text = %s, witness_name = %s, witness_signature = %s,
                        patient_signature = %s, representative_name = %s, representative_signature = %s,
                        updated_at = NOW()
                    WHERE patient_id = %s
                """, [
                    hospital_id, data.get('patient_name', ''), data.get('patient_age'),
                    data.get('civil_status_married', False), data.get('civil_status_single', False),
                    data.get('civil_status_widowed', False), data.get('civil_status_text', ''),
                    consent_date, data.get('consent_text', ''), data.get('witness_name', ''),
                    data.get('witness_signature', ''), data.get('patient_signature', ''),
                    data.get('representative_name', ''), data.get('representative_signature', ''),
                    patient_id
                ])
                consent_id = existing[0]
            else:
                cursor.execute("""
                    INSERT INTO pch.ipd_consent_form
                        (patient_id, admission_id, hospital_id, patient_name, patient_age,
                         civil_status_married, civil_status_single, civil_status_widowed, civil_status_text,
                         consent_date, consent_text, witness_name, witness_signature,
                         patient_signature, representative_name, representative_signature,
                         created_at, updated_at)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
                    RETURNING consent_id
                """, [
                    patient_id, admission_id, hospital_id, data.get('patient_name', ''), data.get('patient_age'),
                    data.get('civil_status_married', False), data.get('civil_status_single', False),
                    data.get('civil_status_widowed', False), data.get('civil_status_text', ''),
                    consent_date, data.get('consent_text', ''), data.get('witness_name', ''),
                    data.get('witness_signature', ''), data.get('patient_signature', ''),
                    data.get('representative_name', ''), data.get('representative_signature', '')
                ])
                consent_id = cursor.fetchone()[0]

        return Response({'success': True, 'consent_id': consent_id},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_consent_form(request, hospital_id):
    """
    Retrieve consent form for a patient.
    GET /api/ipd/consent-form/{hospital_id}/
    """
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",
                [hospital_id]
            )
            row = cursor.fetchone()
            if not row:
                return Response({'success': False, 'error': f'Patient {hospital_id} not found'},
                                status=status.HTTP_404_NOT_FOUND)
            patient_id = row[0]

            cursor.execute("""
                SELECT consent_id, hospital_id,
                       COALESCE(patient_name, '') AS patient_name,
                       COALESCE(patient_age::TEXT, '') AS patient_age,
                       COALESCE(civil_status_married, FALSE) AS civil_status_married,
                       COALESCE(civil_status_single, FALSE) AS civil_status_single,
                       COALESCE(civil_status_widowed, FALSE) AS civil_status_widowed,
                       COALESCE(civil_status_text, '') AS civil_status_text,
                       COALESCE(TO_CHAR(consent_date, 'YYYY-MM-DD'), '') AS consent_date,
                       COALESCE(consent_text, '') AS consent_text,
                       COALESCE(witness_name, '') AS witness_name,
                       COALESCE(witness_signature, '') AS witness_signature,
                       COALESCE(patient_signature, '') AS patient_signature,
                       COALESCE(representative_name, '') AS representative_name,
                       COALESCE(representative_signature, '') AS representative_signature
                FROM pch.ipd_consent_form
                WHERE patient_id = %s
                LIMIT 1
            """, [patient_id])

            columns = [col[0] for col in cursor.description]
            row = cursor.fetchone()
            data = dict(zip(columns, row)) if row else None

        return Response({'success': True, 'data': data},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ============================================================
# CLINICAL HISTORY API
# ============================================================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_clinical_history(request):
    """
    Save clinical history & physical examination for a patient.
    POST /api/ipd/clinical-history/
    """
    try:
        data = request.data
        hospital_id = data.get('hospital_id', '').strip()

        if not hospital_id:
            return Response({'success': False, 'error': 'hospital_id is required'},
                            status=status.HTTP_400_BAD_REQUEST)

        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",
                [hospital_id]
            )
            row = cursor.fetchone()
            patient_id = row[0] if row else None

            if not patient_id:
                return Response({'success': False, 'error': f'Patient {hospital_id} not found'},
                                status=status.HTTP_404_NOT_FOUND)

            admission_id = None
            cursor.execute(
                "SELECT admission_id FROM pch.ipd_notice_of_admission WHERE patient_id = %s ORDER BY created_at DESC LIMIT 1",
                [patient_id]
            )
            adm = cursor.fetchone()
            if adm:
                admission_id = adm[0]

            # Check if record exists
            cursor.execute(
                "SELECT clinical_history_id FROM pch.ipd_clinical_history WHERE patient_id = %s",
                [patient_id]
            )
            existing = cursor.fetchone()

            fields = [
                'pfn', 'chief_complaint', 'admitting_diagnosis', 'discharge_diagnosis', 'religion',
                'case_code_1', 'case_code_2', 'time_admitted_am', 'time_admitted_pm',
                'time_discharged_am', 'time_discharged_pm', 'history_present_illness',
                'past_medical_surgical_social_history', 'ob_gyn_gravida', 'ob_gyn_parity',
                'ob_gyn_lmp', 'ob_gyn_na', 'ros_altered_mental_sensorium', 'ros_abdominal_cramp_pain',
                'ros_anorexia', 'ros_arthralgia', 'ros_body_weakness', 'ros_blurring_of_vision',
                'ros_chest_discomfort', 'ros_constipation', 'ros_cough', 'ros_diarrhea',
                'ros_dizziness', 'ros_dysphagia', 'ros_dyspnea', 'ros_dysuria', 'ros_epistaxis',
                'ros_frequency_urination', 'ros_headache', 'ros_hematesis', 'ros_hematuria',
                'ros_hemolysis', 'ros_irritability', 'ros_jaundice', 'ros_lower_extremity_edema',
                'ros_myalgia', 'ros_osteopenea', 'ros_palpitations', 'ros_skin_rashes',
                'ros_sweating', 'ros_urgency', 'ros_weight_loss', 'ros_others',
                'referred_from_hci', 'referred_reason', 'originating_hci',
                'pe_awake_alert', 'pe_altered_sensorium', 'pe_bp', 'pe_hr', 'pe_rr', 'pe_temp',
                'pe_heent_normal', 'pe_pale_conjunctivae', 'pe_abnormal_pupillary',
                'pe_cervical_lymphadenopathy', 'pe_dry_mucous_membrane', 'pe_sunken_fontanelle',
                'pe_heent_others'
            ]

            # Parse date fields
            ob_gyn_lmp = data.get('ob_gyn_lmp', '').strip()
            if ob_gyn_lmp:
                for fmt in ('%Y-%m-%d', '%m/%d/%Y', '%d/%m/%Y'):
                    try:
                        ob_gyn_lmp = datetime.strptime(ob_gyn_lmp, fmt).date()
                        break
                    except ValueError:
                        continue
            else:
                ob_gyn_lmp = None

            values = []
            for f in fields:
                if f == 'ob_gyn_lmp':
                    values.append(ob_gyn_lmp)
                else:
                    values.append(data.get(f))

            if existing:
                set_clause = ', '.join([f'{f} = %s' for f in fields])
                cursor.execute(f"""
                    UPDATE pch.ipd_clinical_history
                    SET {set_clause}, updated_at = NOW()
                    WHERE patient_id = %s
                """, values + [patient_id])
                clinical_history_id = existing[0]
            else:
                cols = ', '.join(['patient_id', 'admission_id', 'hospital_id'] + fields)
                placeholders = ', '.join(['%s'] * (3 + len(fields)))
                cursor.execute(f"""
                    INSERT INTO pch.ipd_clinical_history ({cols})
                    VALUES ({placeholders})
                    RETURNING clinical_history_id
                """, [patient_id, admission_id, hospital_id] + values)
                clinical_history_id = cursor.fetchone()[0]

        return Response({'success': True, 'clinical_history_id': clinical_history_id},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_clinical_history(request, hospital_id):
    """
    Retrieve clinical history for a patient.
    GET /api/ipd/clinical-history/{hospital_id}/
    """
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",
                [hospital_id]
            )
            row = cursor.fetchone()
            if not row:
                return Response({'success': False, 'error': f'Patient {hospital_id} not found'},
                                status=status.HTTP_404_NOT_FOUND)
            patient_id = row[0]

            cursor.execute("""
                SELECT * FROM pch.ipd_clinical_history
                WHERE patient_id = %s
                LIMIT 1
            """, [patient_id])

            row = cursor.fetchone()
            if row:
                columns = [col[0] for col in cursor.description]
                data = dict(zip(columns, row))
                # Convert dates to strings
                for key, value in data.items():
                    if hasattr(value, 'isoformat'):
                        data[key] = value.isoformat()
            else:
                data = None

        return Response({'success': True, 'data': data},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ============================================================
# PHYSICAL EXAM CONTINUED API
# ============================================================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_physical_exam_continued(request):
    """
    Save physical examination continued for a patient.
    POST /api/ipd/physical-exam-continued/
    """
    try:
        data = request.data
        hospital_id = data.get('hospital_id', '').strip()

        if not hospital_id:
            return Response({'success': False, 'error': 'hospital_id is required'},
                            status=status.HTTP_400_BAD_REQUEST)

        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",
                [hospital_id]
            )
            row = cursor.fetchone()
            patient_id = row[0] if row else None

            if not patient_id:
                return Response({'success': False, 'error': f'Patient {hospital_id} not found'},
                                status=status.HTTP_404_NOT_FOUND)

            admission_id = None
            cursor.execute(
                "SELECT admission_id FROM pch.ipd_notice_of_admission WHERE patient_id = %s ORDER BY created_at DESC LIMIT 1",
                [patient_id]
            )
            adm = cursor.fetchone()
            if adm:
                admission_id = adm[0]

            cursor.execute(
                "SELECT phys_exam_id FROM pch.ipd_physical_exam_continued WHERE patient_id = %s",
                [patient_id]
            )
            existing = cursor.fetchone()

            fields = [
                'chest_normal', 'chest_asymmetrical_expansion', 'chest_decreased_breath_sounds',
                'chest_wheezes', 'chest_lumps_breast', 'chest_rales_crackles_rhonchi',
                'chest_intercostal_retraction', 'chest_others',
                'cvs_normal', 'cvs_displaced_apex_beat', 'cvs_heaves_thrills',
                'cvs_pericardial_bulge', 'cvs_irregular_rhythm', 'cvs_muffled_heart_sounds',
                'cvs_murmur', 'cvs_tachycardia', 'cvs_others',
                'abd_normal', 'abd_rigidity', 'abd_hyperactive_bowel', 'abd_palpable_mass',
                'abd_tympanitic_dull', 'abd_uterine_contraction', 'abd_tenderness', 'abd_others',
                'gu_normal', 'gu_blood_stained', 'gu_cervical_dilation', 'gu_abnormal_discharge', 'gu_others',
                'skin_normal', 'skin_clubbing', 'skin_cold_clammy', 'skin_cyanosis',
                'skin_edema_swelling', 'skin_decreased_mobility', 'skin_pale_nailbeds',
                'skin_poor_skin_turgor', 'skin_rashes_petechiae', 'skin_weak_pulses', 'skin_others',
                'neuro_cerebral', 'neuro_cerebellar', 'neuro_cranial_nerves', 'neuro_motor',
                'neuro_sensory', 'neuro_dtr', 'admitting_impression', 'physician_signature'
            ]

            values = [data.get(f) for f in fields]

            if existing:
                set_clause = ', '.join([f'{f} = %s' for f in fields])
                cursor.execute(f"""
                    UPDATE pch.ipd_physical_exam_continued
                    SET {set_clause}, updated_at = NOW()
                    WHERE patient_id = %s
                """, values + [patient_id])
                phys_exam_id = existing[0]
            else:
                cols = ', '.join(['patient_id', 'admission_id'] + fields)
                placeholders = ', '.join(['%s'] * (2 + len(fields)))
                cursor.execute(f"""
                    INSERT INTO pch.ipd_physical_exam_continued ({cols})
                    VALUES ({placeholders})
                    RETURNING phys_exam_id
                """, [patient_id, admission_id] + values)
                phys_exam_id = cursor.fetchone()[0]

        return Response({'success': True, 'phys_exam_id': phys_exam_id},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_physical_exam_continued(request, hospital_id):
    """
    Retrieve physical exam continued for a patient.
    GET /api/ipd/physical-exam-continued/{hospital_id}/
    """
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",
                [hospital_id]
            )
            row = cursor.fetchone()
            if not row:
                return Response({'success': False, 'error': f'Patient {hospital_id} not found'},
                                status=status.HTTP_404_NOT_FOUND)
            patient_id = row[0]

            cursor.execute("""
                SELECT * FROM pch.ipd_physical_exam_continued
                WHERE patient_id = %s
                LIMIT 1
            """, [patient_id])

            row = cursor.fetchone()
            if row:
                columns = [col[0] for col in cursor.description]
                data = dict(zip(columns, row))
                for key, value in data.items():
                    if hasattr(value, 'isoformat'):
                        data[key] = value.isoformat()
            else:
                data = None

        return Response({'success': True, 'data': data},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ============================================================
# CLINICAL ABSTRACT API
# ============================================================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_clinical_abstract(request):
    """
    Save clinical abstract & discharge summary for a patient.
    POST /api/ipd/clinical-abstract/
    """
    try:
        data = request.data
        hospital_id = data.get('hospital_id', '').strip()

        if not hospital_id:
            return Response({'success': False, 'error': 'hospital_id is required'},
                            status=status.HTTP_400_BAD_REQUEST)

        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",
                [hospital_id]
            )
            row = cursor.fetchone()
            patient_id = row[0] if row else None

            if not patient_id:
                return Response({'success': False, 'error': f'Patient {hospital_id} not found'},
                                status=status.HTTP_404_NOT_FOUND)

            admission_id = None
            cursor.execute(
                "SELECT admission_id FROM pch.ipd_notice_of_admission WHERE patient_id = %s ORDER BY created_at DESC LIMIT 1",
                [patient_id]
            )
            adm = cursor.fetchone()
            if adm:
                admission_id = adm[0]

            cursor.execute(
                "SELECT abstract_id FROM pch.ipd_clinical_abstract WHERE patient_id = %s",
                [patient_id]
            )
            existing = cursor.fetchone()

            fields = [
                'clinical_abstract', 'admitting_diagnosis', 'course_in_ward', 'final_diagnosis',
                'disposition', 'attending_physician', 'discharge_date'
            ]

            # Parse discharge_date
            discharge_date_str = data.get('discharge_date', '').strip()
            discharge_date = None
            if discharge_date_str:
                for fmt in ('%Y-%m-%d', '%m/%d/%Y', '%d/%m/%Y'):
                    try:
                        discharge_date = datetime.strptime(discharge_date_str, fmt).date()
                        break
                    except ValueError:
                        continue

            values = []
            for f in fields:
                if f == 'discharge_date':
                    values.append(discharge_date)
                else:
                    values.append(data.get(f))

            if existing:
                set_clause = ', '.join([f'{f} = %s' for f in fields])
                cursor.execute(f"""
                    UPDATE pch.ipd_clinical_abstract
                    SET {set_clause}, updated_at = NOW()
                    WHERE patient_id = %s
                """, values + [patient_id])
                abstract_id = existing[0]
            else:
                cols = ', '.join(['patient_id', 'admission_id', 'hospital_id'] + fields)
                placeholders = ', '.join(['%s'] * (3 + len(fields)))
                cursor.execute(f"""
                    INSERT INTO pch.ipd_clinical_abstract ({cols})
                    VALUES ({placeholders})
                    RETURNING abstract_id
                """, [patient_id, admission_id, hospital_id] + values)
                abstract_id = cursor.fetchone()[0]

        return Response({'success': True, 'abstract_id': abstract_id},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_clinical_abstract(request, hospital_id):
    """
    Retrieve clinical abstract for a patient.
    GET /api/ipd/clinical-abstract/{hospital_id}/
    """
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",
                [hospital_id]
            )
            row = cursor.fetchone()
            if not row:
                return Response({'success': False, 'error': f'Patient {hospital_id} not found'},
                                status=status.HTTP_404_NOT_FOUND)
            patient_id = row[0]

            cursor.execute("""
                SELECT * FROM pch.ipd_clinical_abstract
                WHERE patient_id = %s
                LIMIT 1
            """, [patient_id])

            row = cursor.fetchone()
            if row:
                columns = [col[0] for col in cursor.description]
                data = dict(zip(columns, row))
                for key, value in data.items():
                    if hasattr(value, 'isoformat'):
                        data[key] = value.isoformat()
            else:
                data = None

        return Response({'success': True, 'data': data},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ============================================================
# DISCHARGE PLAN API
# ============================================================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_discharge_plan(request):
    """
    Save discharge plan for a patient.
    POST /api/ipd/discharge-plan/
    """
    try:
        data = request.data
        hospital_id = data.get('hospital_id', '').strip()

        if not hospital_id:
            return Response({'success': False, 'error': 'hospital_id is required'},
                            status=status.HTTP_400_BAD_REQUEST)

        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",
                [hospital_id]
            )
            row = cursor.fetchone()
            patient_id = row[0] if row else None

            if not patient_id:
                return Response({'success': False, 'error': f'Patient {hospital_id} not found'},
                                status=status.HTTP_404_NOT_FOUND)

            admission_id = None
            cursor.execute(
                "SELECT admission_id FROM pch.ipd_notice_of_admission WHERE patient_id = %s ORDER BY created_at DESC LIMIT 1",
                [patient_id]
            )
            adm = cursor.fetchone()
            if adm:
                admission_id = adm[0]

            cursor.execute(
                "SELECT discharge_plan_id FROM pch.ipd_discharge_plan WHERE patient_id = %s",
                [patient_id]
            )
            existing = cursor.fetchone()

            fields = [
                'discharge_instructions', 'medications', 'follow_up_date', 'follow_up_location',
                'diet_instructions', 'activity_restrictions', 'warning_signs',
                'prepared_by', 'preparation_date'
            ]

            # Parse dates
            follow_up_date_str = data.get('follow_up_date', '').strip()
            follow_up_date = None
            if follow_up_date_str:
                for fmt in ('%Y-%m-%d', '%m/%d/%Y', '%d/%m/%Y'):
                    try:
                        follow_up_date = datetime.strptime(follow_up_date_str, fmt).date()
                        break
                    except ValueError:
                        continue

            preparation_date_str = data.get('preparation_date', '').strip()
            preparation_date = None
            if preparation_date_str:
                for fmt in ('%Y-%m-%d', '%m/%d/%Y', '%d/%m/%Y'):
                    try:
                        preparation_date = datetime.strptime(preparation_date_str, fmt).date()
                        break
                    except ValueError:
                        continue

            values = []
            for f in fields:
                if f == 'follow_up_date':
                    values.append(follow_up_date)
                elif f == 'preparation_date':
                    values.append(preparation_date)
                else:
                    values.append(data.get(f))

            if existing:
                set_clause = ', '.join([f'{f} = %s' for f in fields])
                cursor.execute(f"""
                    UPDATE pch.ipd_discharge_plan
                    SET {set_clause}, updated_at = NOW()
                    WHERE patient_id = %s
                """, values + [patient_id])
                discharge_plan_id = existing[0]
            else:
                cols = ', '.join(['patient_id', 'admission_id', 'hospital_id'] + fields)
                placeholders = ', '.join(['%s'] * (3 + len(fields)))
                cursor.execute(f"""
                    INSERT INTO pch.ipd_discharge_plan ({cols})
                    VALUES ({placeholders})
                    RETURNING discharge_plan_id
                """, [patient_id, admission_id, hospital_id] + values)
                discharge_plan_id = cursor.fetchone()[0]

        return Response({'success': True, 'discharge_plan_id': discharge_plan_id},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_discharge_plan(request, hospital_id):
    """
    Retrieve discharge plan for a patient.
    GET /api/ipd/discharge-plan/{hospital_id}/
    """
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",
                [hospital_id]
            )
            row = cursor.fetchone()
            if not row:
                return Response({'success': False, 'error': f'Patient {hospital_id} not found'},
                                status=status.HTTP_404_NOT_FOUND)
            patient_id = row[0]

            cursor.execute("""
                SELECT * FROM pch.ipd_discharge_plan
                WHERE patient_id = %s
                LIMIT 1
            """, [patient_id])

            row = cursor.fetchone()
            if row:
                columns = [col[0] for col in cursor.description]
                data = dict(zip(columns, row))
                for key, value in data.items():
                    if hasattr(value, 'isoformat'):
                        data[key] = value.isoformat()
            else:
                data = None

        return Response({'success': True, 'data': data},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ============================================================
# DISCHARGE NOTICE API
# ============================================================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_discharge_notice(request):
    """
    Save discharge notice & clearance for a patient.
    POST /api/ipd/discharge-notice/
    """
    try:
        data = request.data
        hospital_id = data.get('hospital_id', '').strip()

        if not hospital_id:
            return Response({'success': False, 'error': 'hospital_id is required'},
                            status=status.HTTP_400_BAD_REQUEST)

        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",
                [hospital_id]
            )
            row = cursor.fetchone()
            patient_id = row[0] if row else None

            if not patient_id:
                return Response({'success': False, 'error': f'Patient {hospital_id} not found'},
                                status=status.HTTP_404_NOT_FOUND)

            admission_id = None
            cursor.execute(
                "SELECT admission_id FROM pch.ipd_notice_of_admission WHERE patient_id = %s ORDER BY created_at DESC LIMIT 1",
                [patient_id]
            )
            adm = cursor.fetchone()
            if adm:
                admission_id = adm[0]

            cursor.execute(
                "SELECT discharge_notice_id FROM pch.ipd_discharge_notice WHERE patient_id = %s",
                [patient_id]
            )
            existing = cursor.fetchone()

            fields = [
                'ward_room', 'discharge_date', 'discharge_time', 'phic_classification',
                'non_phic_classification', 'final_diagnosis', 'operation_procedure',
                'pharmacy_cleared_by', 'pharmacy_cleared_date', 'billing_cleared_by', 'billing_cleared_date',
                'cashier_cleared_by', 'cashier_cleared_date', 'philhealth_cleared_by', 'philhealth_cleared_date',
                'mswd_cleared_by', 'mswd_cleared_date', 'laboratory_cleared_by', 'laboratory_cleared_date',
                'linen_cleared_by', 'linen_cleared_date', 'central_supply_cleared_by', 'central_supply_cleared_date',
                'security_cleared_by', 'security_cleared_date', 'nurse_station_cleared_by', 'nurse_station_cleared_date'
            ]

            # Parse dates and times
            discharge_date_str = data.get('discharge_date', '').strip()
            discharge_date = None
            if discharge_date_str:
                for fmt in ('%Y-%m-%d', '%m/%d/%Y', '%d/%m/%Y'):
                    try:
                        discharge_date = datetime.strptime(discharge_date_str, fmt).date()
                        break
                    except ValueError:
                        continue

            discharge_time_str = data.get('discharge_time', '').strip()
            discharge_time = None
            if discharge_time_str:
                for fmt in ('%H:%M', '%H:%M:%S', '%I:%M %p'):
                    try:
                        discharge_time = datetime.strptime(discharge_time_str, fmt).time()
                        break
                    except ValueError:
                        continue

            # Parse clearance dates
            date_fields = ['pharmacy_cleared_date', 'billing_cleared_date', 'cashier_cleared_date',
                          'philhealth_cleared_date', 'mswd_cleared_date', 'laboratory_cleared_date',
                          'linen_cleared_date', 'central_supply_cleared_date', 'security_cleared_date',
                          'nurse_station_cleared_date']

            values = []
            for f in fields:
                if f == 'discharge_date':
                    values.append(discharge_date)
                elif f == 'discharge_time':
                    values.append(discharge_time)
                elif f in date_fields:
                    date_str = data.get(f, '').strip()
                    parsed_date = None
                    if date_str:
                        for fmt in ('%Y-%m-%d', '%m/%d/%Y', '%d/%m/%Y'):
                            try:
                                parsed_date = datetime.strptime(date_str, fmt).date()
                                break
                            except ValueError:
                                continue
                    values.append(parsed_date)
                else:
                    values.append(data.get(f))

            if existing:
                set_clause = ', '.join([f'{f} = %s' for f in fields])
                cursor.execute(f"""
                    UPDATE pch.ipd_discharge_notice
                    SET {set_clause}, updated_at = NOW()
                    WHERE patient_id = %s
                """, values + [patient_id])
                discharge_notice_id = existing[0]
            else:
                cols = ', '.join(['patient_id', 'admission_id', 'hospital_id'] + fields)
                placeholders = ', '.join(['%s'] * (3 + len(fields)))
                cursor.execute(f"""
                    INSERT INTO pch.ipd_discharge_notice ({cols})
                    VALUES ({placeholders})
                    RETURNING discharge_notice_id
                """, [patient_id, admission_id, hospital_id] + values)
                discharge_notice_id = cursor.fetchone()[0]

        return Response({'success': True, 'discharge_notice_id': discharge_notice_id},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_discharge_notice(request, hospital_id):
    """
    Retrieve discharge notice for a patient.
    GET /api/ipd/discharge-notice/{hospital_id}/
    """
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",
                [hospital_id]
            )
            row = cursor.fetchone()
            if not row:
                return Response({'success': False, 'error': f'Patient {hospital_id} not found'},
                                status=status.HTTP_404_NOT_FOUND)
            patient_id = row[0]

            cursor.execute("""
                SELECT * FROM pch.ipd_discharge_notice
                WHERE patient_id = %s
                LIMIT 1
            """, [patient_id])

            row = cursor.fetchone()
            if row:
                columns = [col[0] for col in cursor.description]
                data = dict(zip(columns, row))
                for key, value in data.items():
                    if hasattr(value, 'isoformat'):
                        data[key] = value.isoformat()
            else:
                data = None

        return Response({'success': True, 'data': data},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ============================================================
# CLINICAL REFERRAL FORM API
# ============================================================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_clinical_referral(request):
    """
    Save clinical referral form for a patient.
    POST /api/ipd/clinical-referral/
    """
    try:
        data = request.data
        hospital_id = data.get('hospital_id', '').strip()

        if not hospital_id:
            return Response({'success': False, 'error': 'hospital_id is required'},
                            status=status.HTTP_400_BAD_REQUEST)

        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",
                [hospital_id]
            )
            row = cursor.fetchone()
            patient_id = row[0] if row else None

            if not patient_id:
                return Response({'success': False, 'error': f'Patient {hospital_id} not found'},
                                status=status.HTTP_404_NOT_FOUND)

            admission_id = None
            cursor.execute(
                "SELECT admission_id FROM pch.ipd_notice_of_admission WHERE patient_id = %s ORDER BY created_at DESC LIMIT 1",
                [patient_id]
            )
            adm = cursor.fetchone()
            if adm:
                admission_id = adm[0]

            cursor.execute(
                "SELECT referral_id FROM pch.ipd_clinical_referral_form WHERE patient_id = %s",
                [patient_id]
            )
            existing = cursor.fetchone()

            fields = [
                'referral_type_emergency', 'referral_type_ambulatory', 'referral_type_medico_legal',
                'referred_to', 'referral_date', 'referral_time', 'chief_complaint_diagnosis',
                'surgical_operations_no', 'surgical_operations_yes', 'surgical_procedure',
                'drug_allergy_no', 'drug_allergy_yes', 'drug_allergy_details',
                'pe_bp', 'pe_pr', 'pe_rr', 'pe_temp', 'pe_weight', 'pe_o2_sat', 'pe_findings',
                'actions_taken', 'reason_hospital_capability', 'reason_lack_specialist',
                'reason_financial_constraint', 'reason_others',
                'referred_by_name', 'referred_by_license',
                'referring_facility_name', 'referring_facility_address',
                'receiving_physician', 'receiving_contact_no', 'receiving_address', 'receiving_license_no',
                'driver_name', 'plate_no', 'time_departure', 'time_arrival'
            ]

            # Parse dates and times
            referral_date_str = data.get('referral_date', '').strip()
            referral_date = None
            if referral_date_str:
                for fmt in ('%Y-%m-%d', '%m/%d/%Y', '%d/%m/%Y'):
                    try:
                        referral_date = datetime.strptime(referral_date_str, fmt).date()
                        break
                    except ValueError:
                        continue

            time_fields = ['referral_time', 'time_departure', 'time_arrival']
            parsed_times = {}
            for tf in time_fields:
                time_str = data.get(tf, '').strip()
                parsed_time = None
                if time_str:
                    for fmt in ('%H:%M', '%H:%M:%S', '%I:%M %p'):
                        try:
                            parsed_time = datetime.strptime(time_str, fmt).time()
                            break
                        except ValueError:
                            continue
                parsed_times[tf] = parsed_time

            values = []
            for f in fields:
                if f == 'referral_date':
                    values.append(referral_date)
                elif f in time_fields:
                    values.append(parsed_times[f])
                else:
                    values.append(data.get(f))

            if existing:
                set_clause = ', '.join([f'{f} = %s' for f in fields])
                cursor.execute(f"""
                    UPDATE pch.ipd_clinical_referral_form
                    SET {set_clause}, updated_at = NOW()
                    WHERE patient_id = %s
                """, values + [patient_id])
                referral_id = existing[0]
            else:
                cols = ', '.join(['patient_id', 'admission_id', 'hospital_id'] + fields)
                placeholders = ', '.join(['%s'] * (3 + len(fields)))
                cursor.execute(f"""
                    INSERT INTO pch.ipd_clinical_referral_form ({cols})
                    VALUES ({placeholders})
                    RETURNING referral_id
                """, [patient_id, admission_id, hospital_id] + values)
                referral_id = cursor.fetchone()[0]

        return Response({'success': True, 'referral_id': referral_id},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_clinical_referral(request, hospital_id):
    """
    Retrieve clinical referral form for a patient.
    GET /api/ipd/clinical-referral/{hospital_id}/
    """
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",
                [hospital_id]
            )
            row = cursor.fetchone()
            if not row:
                return Response({'success': False, 'error': f'Patient {hospital_id} not found'},
                                status=status.HTTP_404_NOT_FOUND)
            patient_id = row[0]

            cursor.execute("""
                SELECT * FROM pch.ipd_clinical_referral_form
                WHERE patient_id = %s
                LIMIT 1
            """, [patient_id])

            row = cursor.fetchone()
            if row:
                columns = [col[0] for col in cursor.description]
                data = dict(zip(columns, row))
                for key, value in data.items():
                    if hasattr(value, 'isoformat'):
                        data[key] = value.isoformat()
            else:
                data = None

        return Response({'success': True, 'data': data},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ============================================================
# INFORMED CONSENT FOR SURGERY API
# ============================================================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_informed_consent_surgery(request):
    """
    Save informed consent for surgery/anesthesia for a patient.
    POST /api/ipd/informed-consent-surgery/
    """
    try:
        data = request.data
        hospital_id = data.get('hospital_id', '').strip()

        if not hospital_id:
            return Response({'success': False, 'error': 'hospital_id is required'},
                            status=status.HTTP_400_BAD_REQUEST)

        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",
                [hospital_id]
            )
            row = cursor.fetchone()
            patient_id = row[0] if row else None

            if not patient_id:
                return Response({'success': False, 'error': f'Patient {hospital_id} not found'},
                                status=status.HTTP_404_NOT_FOUND)

            admission_id = None
            cursor.execute(
                "SELECT admission_id FROM pch.ipd_notice_of_admission WHERE patient_id = %s ORDER BY created_at DESC LIMIT 1",
                [patient_id]
            )
            adm = cursor.fetchone()
            if adm:
                admission_id = adm[0]

            cursor.execute(
                "SELECT surgery_consent_id FROM pch.ipd_informed_consent_surgery WHERE patient_id = %s",
                [patient_id]
            )
            existing = cursor.fetchone()

            fields = [
                'patient_name', 'patient_age', 'civil_status', 'relationship_to_patient',
                'procedure_1', 'procedure_2', 'procedure_3', 'procedure_4',
                'explained_by_1', 'explained_by_2', 'explained_by_3', 'explained_by_4',
                'consent_tissue_disposal', 'consent_photographs',
                'patient_signature', 'signature_date', 'thumb_mark',
                'witness_1_name', 'witness_1_address', 'witness_2_name', 'witness_2_address',
                'physician_midwife', 'physician_date'
            ]

            # Parse dates
            signature_date_str = data.get('signature_date', '').strip()
            signature_date = None
            if signature_date_str:
                for fmt in ('%Y-%m-%d', '%m/%d/%Y', '%d/%m/%Y'):
                    try:
                        signature_date = datetime.strptime(signature_date_str, fmt).date()
                        break
                    except ValueError:
                        continue

            physician_date_str = data.get('physician_date', '').strip()
            physician_date = None
            if physician_date_str:
                for fmt in ('%Y-%m-%d', '%m/%d/%Y', '%d/%m/%Y'):
                    try:
                        physician_date = datetime.strptime(physician_date_str, fmt).date()
                        break
                    except ValueError:
                        continue

            values = []
            for f in fields:
                if f == 'signature_date':
                    values.append(signature_date)
                elif f == 'physician_date':
                    values.append(physician_date)
                else:
                    values.append(data.get(f))

            if existing:
                set_clause = ', '.join([f'{f} = %s' for f in fields])
                cursor.execute(f"""
                    UPDATE pch.ipd_informed_consent_surgery
                    SET {set_clause}, updated_at = NOW()
                    WHERE patient_id = %s
                """, values + [patient_id])
                surgery_consent_id = existing[0]
            else:
                cols = ', '.join(['patient_id', 'admission_id', 'hospital_id'] + fields)
                placeholders = ', '.join(['%s'] * (3 + len(fields)))
                cursor.execute(f"""
                    INSERT INTO pch.ipd_informed_consent_surgery ({cols})
                    VALUES ({placeholders})
                    RETURNING surgery_consent_id
                """, [patient_id, admission_id, hospital_id] + values)
                surgery_consent_id = cursor.fetchone()[0]

        return Response({'success': True, 'surgery_consent_id': surgery_consent_id},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_informed_consent_surgery(request, hospital_id):
    """
    Retrieve informed consent for surgery for a patient.
    GET /api/ipd/informed-consent-surgery/{hospital_id}/
    """
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",
                [hospital_id]
            )
            row = cursor.fetchone()
            if not row:
                return Response({'success': False, 'error': f'Patient {hospital_id} not found'},
                                status=status.HTTP_404_NOT_FOUND)
            patient_id = row[0]

            cursor.execute("""
                SELECT * FROM pch.ipd_informed_consent_surgery
                WHERE patient_id = %s
                LIMIT 1
            """, [patient_id])

            row = cursor.fetchone()
            if row:
                columns = [col[0] for col in cursor.description]
                data = dict(zip(columns, row))
                for key, value in data.items():
                    if hasattr(value, 'isoformat'):
                        data[key] = value.isoformat()
            else:
                data = None

        return Response({'success': True, 'data': data},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ============================================================
# REFUSAL OF TREATMENT API
# ============================================================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_refusal_of_treatment(request):
    """
    Save refusal of treatment form for a patient.
    POST /api/ipd/refusal-of-treatment/
    """
    try:
        data = request.data
        hospital_id = data.get('hospital_id', '').strip()

        if not hospital_id:
            return Response({'success': False, 'error': 'hospital_id is required'},
                            status=status.HTTP_400_BAD_REQUEST)

        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",
                [hospital_id]
            )
            row = cursor.fetchone()
            patient_id = row[0] if row else None

            if not patient_id:
                return Response({'success': False, 'error': f'Patient {hospital_id} not found'},
                                status=status.HTTP_404_NOT_FOUND)

            admission_id = None
            cursor.execute(
                "SELECT admission_id FROM pch.ipd_notice_of_admission WHERE patient_id = %s ORDER BY created_at DESC LIMIT 1",
                [patient_id]
            )
            adm = cursor.fetchone()
            if adm:
                admission_id = adm[0]

            cursor.execute(
                "SELECT refusal_id FROM pch.ipd_refusal_of_treatment WHERE patient_id = %s",
                [patient_id]
            )
            existing = cursor.fetchone()

            fields = [
                'patient_name', 'patient_age', 'patient_status',
                'refused_medication', 'refused_ivf_therapy', 'refused_blood_transfusion',
                'refused_surgery', 'refused_diagnostic_procedure', 'refused_others',
                'reason_for_refusal', 'patient_signature', 'signature_date',
                'witness_name', 'witness_date', 'physician_midwife', 'physician_date'
            ]

            # Parse dates
            date_fields = ['signature_date', 'witness_date', 'physician_date']
            parsed_dates = {}
            for df in date_fields:
                date_str = data.get(df, '').strip()
                parsed_date = None
                if date_str:
                    for fmt in ('%Y-%m-%d', '%m/%d/%Y', '%d/%m/%Y'):
                        try:
                            parsed_date = datetime.strptime(date_str, fmt).date()
                            break
                        except ValueError:
                            continue
                parsed_dates[df] = parsed_date

            values = []
            for f in fields:
                if f in date_fields:
                    values.append(parsed_dates[f])
                else:
                    values.append(data.get(f))

            if existing:
                set_clause = ', '.join([f'{f} = %s' for f in fields])
                cursor.execute(f"""
                    UPDATE pch.ipd_refusal_of_treatment
                    SET {set_clause}, updated_at = NOW()
                    WHERE patient_id = %s
                """, values + [patient_id])
                refusal_id = existing[0]
            else:
                cols = ', '.join(['patient_id', 'admission_id', 'hospital_id'] + fields)
                placeholders = ', '.join(['%s'] * (3 + len(fields)))
                cursor.execute(f"""
                    INSERT INTO pch.ipd_refusal_of_treatment ({cols})
                    VALUES ({placeholders})
                    RETURNING refusal_id
                """, [patient_id, admission_id, hospital_id] + values)
                refusal_id = cursor.fetchone()[0]

        return Response({'success': True, 'refusal_id': refusal_id},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_refusal_of_treatment(request, hospital_id):
    """
    Retrieve refusal of treatment form for a patient.
    GET /api/ipd/refusal-of-treatment/{hospital_id}/
    """
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",
                [hospital_id]
            )
            row = cursor.fetchone()
            if not row:
                return Response({'success': False, 'error': f'Patient {hospital_id} not found'},
                                status=status.HTTP_404_NOT_FOUND)
            patient_id = row[0]

            cursor.execute("""
                SELECT * FROM pch.ipd_refusal_of_treatment
                WHERE patient_id = %s
                LIMIT 1
            """, [patient_id])

            row = cursor.fetchone()
            if row:
                columns = [col[0] for col in cursor.description]
                data = dict(zip(columns, row))
                for key, value in data.items():
                    if hasattr(value, 'isoformat'):
                        data[key] = value.isoformat()
            else:
                data = None

        return Response({'success': True, 'data': data},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ============================================================
# DISCHARGE SLIP API
# ============================================================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_discharge_slip(request):
    """
    Save discharge slip for a patient.
    POST /api/ipd/discharge-slip/
    """
    try:
        data = request.data
        hospital_id = data.get('hospital_id', '').strip()

        if not hospital_id:
            return Response({'success': False, 'error': 'hospital_id is required'},
                            status=status.HTTP_400_BAD_REQUEST)

        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",
                [hospital_id]
            )
            row = cursor.fetchone()
            patient_id = row[0] if row else None

            if not patient_id:
                return Response({'success': False, 'error': f'Patient {hospital_id} not found'},
                                status=status.HTTP_404_NOT_FOUND)

            admission_id = None
            cursor.execute(
                "SELECT admission_id FROM pch.ipd_notice_of_admission WHERE patient_id = %s ORDER BY created_at DESC LIMIT 1",
                [patient_id]
            )
            adm = cursor.fetchone()
            if adm:
                admission_id = adm[0]

            cursor.execute(
                "SELECT discharge_slip_id FROM pch.ipd_discharge_slip WHERE patient_id = %s",
                [patient_id]
            )
            existing = cursor.fetchone()

            fields = [
                'ward_room', 'discharge_date', 'discharge_time',
                'all_departments_cleared', 'authorized_by', 'authorization_date', 'notes'
            ]

            # Parse dates and times
            discharge_date_str = data.get('discharge_date', '').strip()
            discharge_date = None
            if discharge_date_str:
                for fmt in ('%Y-%m-%d', '%m/%d/%Y', '%d/%m/%Y'):
                    try:
                        discharge_date = datetime.strptime(discharge_date_str, fmt).date()
                        break
                    except ValueError:
                        continue

            discharge_time_str = data.get('discharge_time', '').strip()
            discharge_time = None
            if discharge_time_str:
                for fmt in ('%H:%M', '%H:%M:%S', '%I:%M %p'):
                    try:
                        discharge_time = datetime.strptime(discharge_time_str, fmt).time()
                        break
                    except ValueError:
                        continue

            authorization_date_str = data.get('authorization_date', '').strip()
            authorization_date = None
            if authorization_date_str:
                for fmt in ('%Y-%m-%d', '%m/%d/%Y', '%d/%m/%Y'):
                    try:
                        authorization_date = datetime.strptime(authorization_date_str, fmt).date()
                        break
                    except ValueError:
                        continue

            values = []
            for f in fields:
                if f == 'discharge_date':
                    values.append(discharge_date)
                elif f == 'discharge_time':
                    values.append(discharge_time)
                elif f == 'authorization_date':
                    values.append(authorization_date)
                else:
                    values.append(data.get(f))

            if existing:
                set_clause = ', '.join([f'{f} = %s' for f in fields])
                cursor.execute(f"""
                    UPDATE pch.ipd_discharge_slip
                    SET {set_clause}, updated_at = NOW()
                    WHERE patient_id = %s
                """, values + [patient_id])
                discharge_slip_id = existing[0]
            else:
                cols = ', '.join(['patient_id', 'admission_id', 'hospital_id'] + fields)
                placeholders = ', '.join(['%s'] * (3 + len(fields)))
                cursor.execute(f"""
                    INSERT INTO pch.ipd_discharge_slip ({cols})
                    VALUES ({placeholders})
                    RETURNING discharge_slip_id
                """, [patient_id, admission_id, hospital_id] + values)
                discharge_slip_id = cursor.fetchone()[0]

        return Response({'success': True, 'discharge_slip_id': discharge_slip_id},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_discharge_slip(request, hospital_id):
    """
    Retrieve discharge slip for a patient.
    GET /api/ipd/discharge-slip/{hospital_id}/
    """
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",
                [hospital_id]
            )
            row = cursor.fetchone()
            if not row:
                return Response({'success': False, 'error': f'Patient {hospital_id} not found'},
                                status=status.HTTP_404_NOT_FOUND)
            patient_id = row[0]

            cursor.execute("""
                SELECT * FROM pch.ipd_discharge_slip
                WHERE patient_id = %s
                LIMIT 1
            """, [patient_id])

            row = cursor.fetchone()
            if row:
                columns = [col[0] for col in cursor.description]
                data = dict(zip(columns, row))
                for key, value in data.items():
                    if hasattr(value, 'isoformat'):
                        data[key] = value.isoformat()
            else:
                data = None

        return Response({'success': True, 'data': data},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_diet_list(request):
    """
    Save diet list for a patient.
    POST /api/ipd/diet-list/
    Body: { hospital_id, ward, diet_date, diet_breakfast, diet_lunch, diet_supper, remarks }
    """
    try:
        data = request.data
        hospital_id = data.get('hospital_id', '').strip()
        ward = data.get('ward', '').strip()
        diet_date = data.get('diet_date')
        diet_breakfast = data.get('diet_breakfast', '').strip()
        diet_lunch = data.get('diet_lunch', '').strip()
        diet_supper = data.get('diet_supper', '').strip()
        remarks = data.get('remarks', '').strip()

        if not hospital_id:
            return Response({'success': False, 'error': 'hospital_id is required'},
                            status=status.HTTP_400_BAD_REQUEST)

        with connection.cursor() as cursor:
            # Resolve patient_id
            cursor.execute(
                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",
                [hospital_id]
            )
            row = cursor.fetchone()
            patient_id = row[0] if row else None

            # Resolve most-recent admission_id
            admission_id = None
            if patient_id:
                cursor.execute(
                    "SELECT admission_id FROM pch.ipd_notice_of_admission WHERE patient_id = %s ORDER BY created_at DESC LIMIT 1",
                    [patient_id]
                )
                adm = cursor.fetchone()
                if adm:
                    admission_id = adm[0]

            # Parse diet_date
            parsed_date = None
            if diet_date:
                for fmt in ('%Y-%m-%d', '%m/%d/%Y'):
                    try:
                        parsed_date = datetime.strptime(diet_date, fmt).date()
                        break
                    except ValueError:
                        continue

            full_name = getattr(request.user, 'get_full_name', None)
            ordered_by = (full_name() if callable(full_name) else None) or getattr(request.user, 'username', 'unknown')

            cursor.execute("""
                INSERT INTO pch.ipd_diet_list
                    (patient_id, admission_id, ward, diet_date, diet_breakfast, diet_lunch, diet_supper, remarks, ordered_by, created_at, updated_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
                RETURNING diet_id
            """, [patient_id, admission_id, ward, parsed_date, diet_breakfast, diet_lunch, diet_supper, remarks, ordered_by])
            diet_id = cursor.fetchone()[0]

        return Response({'success': True, 'diet_id': diet_id},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_diet_list(request, hospital_id):
    """
    Retrieve diet list for a patient.
    GET /api/ipd/diet-list/{hospital_id}/
    """
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",
                [hospital_id]
            )
            row = cursor.fetchone()
            if not row:
                return Response({'success': False, 'error': f'Patient {hospital_id} not found'},
                                status=status.HTTP_404_NOT_FOUND)
            patient_id = row[0]

            cursor.execute("""
                SELECT * FROM pch.ipd_diet_list
                WHERE patient_id = %s
                ORDER BY created_at DESC
                LIMIT 1
            """, [patient_id])

            row = cursor.fetchone()
            if row:
                columns = [col[0] for col in cursor.description]
                data = dict(zip(columns, row))
                for key, value in data.items():
                    if hasattr(value, 'isoformat'):
                        data[key] = value.isoformat()
            else:
                data = None

        return Response({'success': True, 'data': data},
                        status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def update_patient_bed_assignment(request):
    """
    Update patient's department and room when bed is assigned.
    POST /api/ipd/update-bed-assignment/
    Body: { hospital_id, room_name, bed_number }
    """
    try:
        data = request.data
        hospital_id = data.get('hospital_id', '').strip()
        room_name = data.get('room_name', '').strip()
        bed_number = data.get('bed_number')

        if not hospital_id or not room_name or bed_number is None:
            return Response({'success': False, 'error': 'hospital_id, room_name, and bed_number are required'},
                            status=status.HTTP_400_BAD_REQUEST)

        with connection.cursor() as cursor:
            # Get patient_id from hospital_id
            cursor.execute(
                "SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s AND is_active = TRUE",
                [hospital_id]
            )
            row = cursor.fetchone()
            if not row:
                return Response({'success': False, 'error': f'Patient {hospital_id} not found'},
                                status=status.HTTP_404_NOT_FOUND)
            patient_id = row[0]

            # Map room name to department
            department_mapping = {
                'Female Ward': 'Femaleward',
                'Male Ward': 'Maleward',
                'Pediatric Ward 1': 'PDEA1',
                'Pediatric Ward 2': 'PDEA2',
                'Room 1': 'Room1',
                'Room 2': 'Room2',
                'Room 3': 'Room3',
                'Isolation-In': 'IsoIn',
                'Isolation-Out 1': 'IsoOut1',
                'Isolation-Out 2': 'IsoOut2',
                'Private 2': 'Private2',
                'Private 3': 'Private3',
                'Private 4': 'Private4',
            }
            department = department_mapping.get(room_name, room_name)

            # Update patient_profiling with department and room
            cursor.execute("""
                UPDATE pch.patient_profiling
                SET department = %s, room = %s
                WHERE patient_id = %s
            """, [department, f'{room_name} - Bed {bed_number}', patient_id])

        return Response({
            'success': True,
            'message': f'Patient assigned to {room_name} Bed {bed_number}',
            'department': department
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'error': str(e)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)
