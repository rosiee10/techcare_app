import logging
from datetime import datetime, date
from django.db import connection, OperationalError, ProgrammingError
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

logger = logging.getLogger(__name__)


def _dictfetchall(cursor):
    """Return all rows from cursor as a list of dicts."""
    columns = [col[0] for col in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def billing_invoices_list(request):
    """
    Returns all pharmacy dispense receipts joined with patient info,
    admission info, room info, and receipt line items.
    
    Excludes patients that have been sent to social work or cashier.

    Query params:
      - status: filter by received_status (RECEIVED, POSTED, CANCELLED)
      - search: partial match on patient name or hospital number
    """
    status_filter = request.query_params.get('status', None)
    search = request.query_params.get('search', '').strip()

    try:
        # Build WHERE clauses and param list dynamically (avoid .format + %s mixing)
        where_parts = ['1=1']
        params = []

        if status_filter:
            where_parts.append('dr.received_status = %s')
            params.append(status_filter)

        if search:
            where_parts.append(
                "(pp.firstname ILIKE %s OR pp.lastname ILIKE %s OR pp.hospital_id ILIKE %s)"
            )
            params += [f'%{search}%', f'%{search}%', f'%{search}%']

        where_sql = ' AND '.join(where_parts)

        sql = f"""
            SELECT
                dr.receipt_id,
                dr.receipt_no,
                dr.patient_id,
                dr.admission_id,
                dr.dispensing_date,
                dr.charge_slip_no,
                dr.total_amount,
                dr.received_status,
                dr.remarks,
                -- Patient info from patient_profiling (joined on actual patient_id column)
                COALESCE(pp.firstname || ' ' || pp.lastname,
                         'Patient #' || COALESCE(dr.patient_id::text, '?')) AS patient_name,
                COALESCE(pp.hospital_id,
                         CASE WHEN dr.patient_id IS NOT NULL
                              THEN 'IPD-' || dr.patient_id::text
                              ELSE dr.receipt_no
                         END) AS hospital_number,
                -- Age computed from birthdate
                CASE WHEN pp.birthdate IS NOT NULL
                     THEN DATE_PART('year', AGE(pp.birthdate))::integer
                     ELSE NULL
                END AS age,
                pp.gender,
                -- Address built from address fields
                TRIM(BOTH ', ' FROM
                    COALESCE(NULLIF(pp.purok, '') || ', ', '') ||
                    COALESCE(NULLIF(pp.barangay, '') || ', ', '') ||
                    COALESCE(NULLIF(pp.city_municipal, '') || ', ', '') ||
                    COALESCE(NULLIF(pp.province, ''), '')
                ) AS address,
                -- Admission info from ipd_patient_admissions
                ipa.admission_date,
                ipa.status AS admission_status,
                -- Room from ipd_rooms via admission
                COALESCE(ir.room_number || ' - ' || ir.bed_code, 'N/A') AS room
            FROM pch.pharmacy_dispense_receipts dr
            LEFT JOIN pch.patient_profiling pp
                ON pp.patient_id = dr.patient_id
            LEFT JOIN pch.ipd_patient_admissions ipa
                ON ipa.admission_id = dr.admission_id
            LEFT JOIN pch.ipd_rooms ir
                ON ir.room_id = ipa.room_id
            WHERE {where_sql}
            -- Exclude patients already sent to social work or cashier
            AND NOT EXISTS (
                SELECT 1 FROM pch.social_work_referrals swr
                WHERE swr.hospital_no = pp.hospital_id
                AND swr.status IN ('PENDING', 'APPROVED', 'COMPLETED')
            )
            AND NOT EXISTS (
                SELECT 1 FROM pch.soa_nbb snbb
                WHERE snbb.patient_id = dr.patient_id
                AND snbb.soa_status IN ('CASHIER', 'SOCIAL WORK')
            )
            AND NOT EXISTS (
                SELECT 1 FROM pch.soa_philhealth sph
                WHERE sph.patient_id = dr.patient_id
                AND sph.soa_status IN ('CASHIER', 'SOCIAL WORK')
            )
            AND NOT EXISTS (
                SELECT 1 FROM pch.soa_nonmed snm
                WHERE snm.patient_id = dr.patient_id
                AND snm.status IN ('CASHIER', 'SOCIAL WORK')
            )
            AND NOT EXISTS (
                SELECT 1 FROM pch.soa_opd sop
                WHERE sop.hospital_no = pp.hospital_id
                AND sop.status IN ('CASHIER', 'SOCIAL WORK')
            )
            ORDER BY dr.receipt_id DESC
        """

        with connection.cursor() as cursor:
            cursor.execute(sql, params)
            receipts = _dictfetchall(cursor)

    except (OperationalError, ProgrammingError) as e:
        logger.error(f"billing_invoices_list DB error: {e}")
        return Response({'success': False, 'message': f'Database error: {e}'}, status=500)
    except Exception as e:
        logger.error(f"billing_invoices_list unexpected error: {e}")
        return Response({'success': False, 'message': f'Server error: {e}'}, status=500)

    if not receipts:
        return Response({'success': True, 'data': []})

    # Fetch all line items in one query
    receipt_ids = [r['receipt_id'] for r in receipts]
    placeholders = ','.join(['%s'] * len(receipt_ids))

    try:
        with connection.cursor() as cursor:
            cursor.execute(f"""
                SELECT
                    dri.receipt_item_id,
                    dri.receipt_id,
                    dri.item_code,
                    dri.item_description AS description,
                    dri.quantity,
                    dri.unit,
                    dri.unit_cost,
                    dri.total_cost       AS total,
                    dri.line_status,
                    pm.medicine_name
                FROM pch.pharmacy_dispense_receipt_items dri
                LEFT JOIN pch.pharmacy_medicines pm
                    ON pm.medicine_id = dri.medicine_id
                WHERE dri.receipt_id IN ({placeholders})
                ORDER BY dri.receipt_item_id
            """, receipt_ids)
            all_items = _dictfetchall(cursor)
    except Exception as e:
        logger.error(f"billing_invoices_list items query error: {e}")
        all_items = []

    # Group items by receipt_id
    items_by_receipt = {}
    for item in all_items:
        rid = item['receipt_id']
        desc = (
            item.get('description') or
            item.get('medicine_name') or
            item.get('item_code') or
            'Unknown Item'
        )
        items_by_receipt.setdefault(rid, []).append({
            'description': desc,
            'category': 'Pharmacy',
            'quantity': float(item['quantity']) if item['quantity'] else 0,
            'unitPrice': float(item['unit_cost']) if item['unit_cost'] else 0.0,
            'total': float(item['total']) if item['total'] else 0.0,
            'unit': item.get('unit') or '',
        })

    # Build response grouped by patient/admission
    # Items are kept per-receipt so the UI can show itemized purchases by receipt
    patient_invoices = {}
    for r in receipts:
        rid = r['receipt_id']
        patient_key = f"{r['patient_id']}_{r['admission_id']}" if r['patient_id'] else f"receipt_{rid}"

        items = items_by_receipt.get(rid, [])
        receipt_total = sum(i['total'] for i in items) or float(r['total_amount'] or 0)

        # Each receipt becomes a receipt group with its own items
        receipt_group = {
            'receiptId': rid,
            'receiptNo': r['receipt_no'],
            'dispensingDate': str(r['dispensing_date']),
            'chargeSlipNo': r['charge_slip_no'],
            'receiptTotal': receipt_total,
            'items': items.copy(),
        }

        if patient_key not in patient_invoices:
            patient_invoices[patient_key] = {
                'receiptId': rid,
                'receiptNo': r['receipt_no'],
                'name': r['patient_name'],
                'hospitalNo': r['hospital_number'],
                'admissionId': r['admission_id'],
                'age': r['age'],
                'gender': r['gender'],
                'address': r['address'] or '',
                'room': r['room'],
                'admissionDate': str(r['admission_date']) if r['admission_date'] else str(r['dispensing_date']),
                'classification': 'NBB',
                'status': _map_status(r['received_status']),
                'invoiceNo': r['receipt_no'],
                'amount': receipt_total,
                'billingDate': str(r['dispensing_date']),
                'chargeSlipNo': r['charge_slip_no'],
                'admissionStatus': r['admission_status'],
                'receipts': [receipt_group],
                # Flat items list (all receipts combined) for backward compat with print
                'items': items.copy(),
            }
        else:
            patient_invoices[patient_key]['amount'] += receipt_total
            patient_invoices[patient_key]['receipts'].append(receipt_group)
            patient_invoices[patient_key]['items'].extend(items)

    # Format amounts and prepare final list
    data = []
    for inv in patient_invoices.values():
        inv['amount'] = f"₱{inv['amount']:,.2f}"
        data.append(inv)

    return Response({'success': True, 'data': data})


def _map_status(received_status):
    """Map DB received_status to billing UI status."""
    return {
        'RECEIVED': 'READY FOR BILLING',
        'POSTED': 'IN BILLING',
        'CANCELLED': 'CANCELLED',
    }.get(received_status, 'READY FOR BILLING')


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_opd_billing(request):
    """
    Save OPD charge slip to pch.soa_opd and pch.soa_opd_line_items
    when billing staff clicks 'Send to Cashier'.

    Expected JSON body:
    {
        "patient_name":     "Maria Santos",
        "hospital_no":      "OPD-20260301",
        "age":              40,
        "address":          "",
        "doctor":           "Dr. Reyes",
        "department":       "General Medicine",
        "visit_date":       "2026-05-17",
        "discount_type":    "None",
        "discount_amount":  0.00,
        "grand_total":      1350.00,
        "charge_to_maip":   1350.00,
        "prepared_by":      "RETCHEL R. EROY",
        "noted_by":         "DR. JOCELYN L. PALIONAY",
        "items": [
            {"category": "Consultation Fee", "actual_amount": 500.00},
            {"category": "Laboratory Tests", "actual_amount": 700.00},
            {"category": "Medication",        "actual_amount": 150.00}
        ]
    }
    """
    data = request.data
    try:
        patient_name    = data.get('patient_name', '')
        hospital_no     = data.get('hospital_no', '')
        age             = data.get('age') or None
        address         = data.get('address', '')
        visit_date      = data.get('visit_date') or None
        discount_type   = data.get('discount_type', 'None')
        discount_amount = float(data.get('discount_amount') or 0)
        charge_to_maip  = float(data.get('charge_to_maip') or 0)
        prepared_by     = data.get('prepared_by', '')
        noted_by        = data.get('noted_by', '')
        items           = data.get('items', [])

        # Map items to the individual fee columns in soa_opd
        fee_map = {
            'consultation fee':  'consultation_fee',
            'laboratory tests':  'laboratory_fee',
            'laboratory':        'laboratory_fee',
            'medication':        'medication_fee',
            'medicines':         'medication_fee',
        }
        consultation_fee = 0.0
        laboratory_fee   = 0.0
        medication_fee   = 0.0
        other_fee        = 0.0

        for item in items:
            category = (item.get('category') or '').lower()
            amount   = float(item.get('actual_amount') or 0)
            mapped   = fee_map.get(category)
            if mapped == 'consultation_fee':
                consultation_fee += amount
            elif mapped == 'laboratory_fee':
                laboratory_fee += amount
            elif mapped == 'medication_fee':
                medication_fee += amount
            else:
                other_fee += amount

        with connection.cursor() as cursor:
            # Insert SOA header (subtotal & grand_total are GENERATED columns — do NOT insert them)
            cursor.execute("""
                INSERT INTO pch.soa_opd (
                    patient_name, hospital_no, age, address,
                    visit_date, billing_date,
                    consultation_fee, laboratory_fee,
                    medication_fee, other_fee,
                    discount_type, discount_amount,
                    charge_to_maip,
                    status, prepared_by, noted_by,
                    created_at, updated_at
                ) VALUES (
                    %s, %s, %s, %s,
                    %s, CURRENT_DATE,
                    %s, %s, %s, %s,
                    %s, %s,
                    %s,
                    'SENT TO CASHIER', %s, %s,
                    NOW(), NOW()
                ) RETURNING id
            """, [
                patient_name, hospital_no, age, address,
                visit_date,
                consultation_fee, laboratory_fee, medication_fee, other_fee,
                discount_type, discount_amount,
                charge_to_maip,
                prepared_by, noted_by,
            ])
            soa_id = cursor.fetchone()[0]

            # Insert line items
            for item in items:
                cursor.execute("""
                    INSERT INTO pch.soa_opd_line_items (
                        soa_id, category,
                        actual_amount, philhealth_amount,
                        excess_amount, outside_amount,
                        source, created_at
                    ) VALUES (
                        %s, %s,
                        %s, %s,
                        %s, %s,
                        %s, NOW()
                    )
                """, [
                    soa_id,
                    item.get('category', ''),
                    float(item.get('actual_amount') or 0),
                    float(item.get('philhealth_amount') or 0),
                    float(item.get('excess_amount') or 0),
                    float(item.get('outside_amount') or 0),
                    item.get('source', 'manual'),
                ])

        return Response({'success': True, 'soa_id': soa_id})

    except Exception as e:
        logger.error(f"save_opd_billing error: {e}")
        return Response({'success': False, 'message': str(e)}, status=500)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_philhealth_billing(request):
    """
    Save PhilHealth IPD invoice to pch.soa_philhealth + pch.soa_philhealth_line_items
    when billing staff clicks 'Send to Cashier' for a PhilHealth-classified patient.

    Expected JSON body:
    {
        "patient_name":         "Maria Santos",
        "hospital_no":          "H-2026-001",
        "age":                  45,
        "ward":                 "Ward 2 - Bed A",
        "bill_no":              "SOA-00-00-05",
        "classification":       "PhilHealth",
        "admission_date":       "2026-05-01",
        "number_of_days":       10,
        "discount_type":        "None",
        "discount_amount":      0.00,
        "total_bill_amount":    4132.50,
        "amount_after_discount":4132.50,
        "items": [...]
    }
    """
    data = request.data
    try:
        from collections import defaultdict

        patient_name          = data.get('patient_name', '')
        hospital_no           = data.get('hospital_no', '')
        age                   = data.get('age') or None
        ward                  = data.get('ward', '')
        bill_no               = data.get('bill_no', '')
        classification        = data.get('classification', 'PhilHealth')
        admission_date        = data.get('admission_date') or None
        number_of_days        = data.get('number_of_days') or None
        admission_id_from_fe  = data.get('admission_id')  # passed directly from frontend
        discount_type         = data.get('discount_type', 'None')
        discount_amount       = float(data.get('discount_amount') or 0)
        total_bill_amount     = float(data.get('total_bill_amount') or 0)
        amount_after_discount = float(data.get('amount_after_discount') or total_bill_amount)
        items                 = data.get('items', [])

        is_senior  = discount_type == 'Senior'
        is_pwd     = discount_type == 'PWD'
        disc_pct   = 20.00 if (is_senior or is_pwd) else 0.00

        with connection.cursor() as cursor:

            # ── 1. Look up patient_id ──────────────────────────────────────
            cursor.execute("""
                SELECT patient_id FROM pch.patient_profiling
                WHERE hospital_id = %s LIMIT 1
            """, [hospital_no])
            row = cursor.fetchone()
            patient_id = row[0] if row else None

            if patient_id is None:
                return Response(
                    {'success': False, 'message': f'Patient not found: {hospital_no}'},
                    status=404,
                )

            # ── 2. Resolve admission_id (4-step cascade) ──────────────────
            # a) Passed directly from frontend
            admission_id = int(admission_id_from_fe) if admission_id_from_fe else None

            # b) Via receipt_no match in pharmacy_dispense_receipts
            if admission_id is None and bill_no:
                cursor.execute("""
                    SELECT admission_id FROM pch.pharmacy_dispense_receipts
                    WHERE receipt_no = %s AND admission_id IS NOT NULL LIMIT 1
                """, [bill_no])
                adm_row = cursor.fetchone()
                if adm_row:
                    admission_id = adm_row[0]

            # c) Any receipt for this patient that has an admission_id
            if admission_id is None:
                cursor.execute("""
                    SELECT admission_id FROM pch.pharmacy_dispense_receipts
                    WHERE patient_id = %s AND admission_id IS NOT NULL
                    ORDER BY dispensing_date DESC LIMIT 1
                """, [patient_id])
                adm_row = cursor.fetchone()
                if adm_row:
                    admission_id = adm_row[0]

            # d) Most recent admission in ipd_patient_admissions
            if admission_id is None:
                cursor.execute("""
                    SELECT admission_id FROM pch.ipd_patient_admissions
                    WHERE patient_id = %s
                    ORDER BY admission_date DESC LIMIT 1
                """, [patient_id])
                adm_row = cursor.fetchone()
                if adm_row:
                    admission_id = adm_row[0]

            if admission_id is None:
                logger.warning(
                    f"save_philhealth_billing: no admission_id found for "
                    f"hospital_no={hospital_no}; inserting with NULL admission_id."
                )

            # ── 3. Insert soa_philhealth ───────────────────────────────────
            cursor.execute("""
                INSERT INTO pch.soa_philhealth (
                    patient_id, admission_id, bill_no, ward, classification,
                    soa_date, date_of_admission, number_of_days,
                    is_senior_citizen, is_pwd,
                    discount_percent, discount_amount,
                    total_actual, grand_total,
                    soa_status, remarks, updated_at
                ) VALUES (
                    %s, %s, %s, %s, %s,
                    CURRENT_DATE, %s, %s,
                    %s, %s,
                    %s, %s,
                    %s, %s,
                    'SENT TO CASHIER', %s, NOW()
                ) RETURNING soa_id
            """, [
                patient_id, admission_id, bill_no, ward, classification,
                admission_date, number_of_days,
                is_senior, is_pwd,
                disc_pct, discount_amount,
                total_bill_amount, amount_after_discount,
                f'PhilHealth billing — {bill_no}',
            ])
            philhealth_soa_id = cursor.fetchone()[0]

            # ── 4. Insert soa_philhealth_line_items (grouped by category) ──
            # Respects UNIQUE(soa_id, category_id) constraint.
            category_totals = defaultdict(float)
            category_remarks = {}
            for item in items:
                cat = item.get('category', 'Other')
                amt = float(item.get('actual_amount') or item.get('total') or 0)
                category_totals[cat] += amt
                category_remarks.setdefault(cat, item.get('description', cat))

            for cat_name, total_amt in category_totals.items():
                cursor.execute("""
                    INSERT INTO pch.charge_categories
                        (category_name, sort_order, used_in, is_active, updated_at)
                    VALUES (%s, 99, 'BOTH', true, NOW())
                    ON CONFLICT (category_name)
                    DO UPDATE SET updated_at = NOW()
                    RETURNING category_id
                """, [cat_name])
                cat_id = cursor.fetchone()[0]

                cursor.execute("""
                    INSERT INTO pch.soa_philhealth_line_items (
                        soa_id, category_id,
                        actual_amount, philhealth_amount,
                        excess_amount, outside_amount,
                        remarks, updated_at
                    ) VALUES (
                        %s, %s,
                        %s, 0.00,
                        0.00, %s,
                        %s, NOW()
                    )
                """, [
                    philhealth_soa_id, cat_id,
                    total_amt, total_amt,
                    category_remarks.get(cat_name, cat_name),
                ])

        return Response({'success': True, 'philhealth_soa_id': philhealth_soa_id})

    except Exception as e:
        logger.error(f"save_philhealth_billing error: {e}")
        return Response({'success': False, 'message': str(e)}, status=500)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_nonmed_billing(request):
    """
    Save Non-Med IPD invoice to pch.soa_nonmed + pch.soa_nonmed_line_items
    when billing staff clicks 'Send to Cashier' for a Non-Med patient.
    """
    data = request.data
    try:
        from collections import defaultdict

        patient_name          = data.get('patient_name', '')
        hospital_no           = data.get('hospital_no', '')
        age                   = data.get('age') or None
        address               = data.get('address', '')
        ward                  = data.get('ward', '')
        bill_no               = data.get('bill_no', '') or 'PARTIAL BILL'
        classification        = data.get('classification', 'Non-Med')
        admission_date        = data.get('admission_date') or None
        number_of_days        = data.get('number_of_days') or None
        discount_type         = data.get('discount_type', 'None')
        discount_amount       = float(data.get('discount_amount') or 0)
        total_bill_amount     = float(data.get('total_bill_amount') or 0)
        amount_after_discount = float(data.get('amount_after_discount') or total_bill_amount)
        items                 = data.get('items', [])

        is_senior  = discount_type == 'Senior'
        is_pwd     = discount_type == 'PWD'
        disc_rate  = 20.00 if (is_senior or is_pwd) else 0.00

        with connection.cursor() as cursor:

            # ── 1. Look up patient_id ──────────────────────────────────────
            cursor.execute("""
                SELECT patient_id FROM pch.patient_profiling
                WHERE hospital_id = %s LIMIT 1
            """, [hospital_no])
            row = cursor.fetchone()
            patient_id = row[0] if row else None

            if patient_id is None:
                return Response(
                    {'success': False, 'message': f'Patient not found: {hospital_no}'},
                    status=404,
                )

            # ── 2. Insert soa_nonmed ───────────────────────────────────────
            cursor.execute("""
                INSERT INTO pch.soa_nonmed (
                    patient_id, hospital_no, patient_name, patient_address, patient_age,
                    ward, bill_no, classification,
                    admission_date, number_of_days,
                    discount_type, discount_rate, discount_amount,
                    subtotal, grand_total,
                    status, updated_at
                ) VALUES (
                    %s, %s, %s, %s, %s,
                    %s, %s, %s,
                    %s, %s,
                    %s, %s, %s,
                    %s, %s,
                    'SENT TO CASHIER', NOW()
                ) RETURNING id
            """, [
                patient_id, hospital_no, patient_name, address, age,
                ward, bill_no, classification,
                admission_date, number_of_days,
                discount_type, disc_rate, discount_amount,
                total_bill_amount, amount_after_discount,
            ])
            nonmed_soa_id = cursor.fetchone()[0]

            # ── 3. Insert soa_nonmed_line_items (grouped by category) ──────
            category_totals = defaultdict(float)
            for item in items:
                cat = item.get('category', 'Other')
                amt = float(item.get('actual_amount') or item.get('total') or 0)
                category_totals[cat] += amt

            for sort_idx, (cat_name, total_amt) in enumerate(category_totals.items(), start=1):
                cursor.execute("""
                    INSERT INTO pch.soa_nonmed_line_items (
                        soa_id, category,
                        actual_amount, philhealth_amount,
                        excess_amount, outside_amount,
                        sort_order, created_at
                    ) VALUES (
                        %s, %s,
                        %s, 0.00,
                        0.00, %s,
                        %s, NOW()
                    )
                """, [
                    nonmed_soa_id, cat_name,
                    total_amt, total_amt,
                    sort_idx,
                ])

        return Response({'success': True, 'nonmed_soa_id': nonmed_soa_id})

    except Exception as e:
        logger.error(f"save_nonmed_billing error: {e}")
        return Response({'success': False, 'message': str(e)}, status=500)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_nbb_social_work(request):
    """
    Save an NBB IPD referral to pch.social_work_referrals + pch.social_work_referral_items
    when billing staff clicks 'Send to Social Work'.

    Expected JSON body:
    {
        "patient_name":         "Juan Dela Cruz",
        "hospital_no":          "H-2026-001",
        "age":                  50,
        "address":              "Plaridel, Mis. Occ.",
        "doctor":               "Dr. Santos",
        "department":           "Medicine",
        "bill_no":              "SOA-00-00-05",
        "classification":       "NBB",
        "total_bill_amount":    4132.50,
        "discount_type":        "None",
        "discount_amount":      0.00,
        "amount_after_discount":4132.50,
        "items": [
            {
                "category":          "Room and Board",
                "description":       "Ward (10 days)",
                "quantity":          10,
                "unit_price":        400.00,
                "total":             4000.00,
                "actual_amount":     4000.00,
                "philhealth_amount": 0.00,
                "excess_amount":     0.00,
                "outside_amount":    0.00,
                "charge_to_maip":    0.00,
                "source":            "billing"
            }
        ]
    }
    """
    data = request.data
    try:
        from collections import defaultdict

        patient_name          = data.get('patient_name', '')
        hospital_no           = data.get('hospital_no', '')
        age                   = data.get('age') or None
        address               = data.get('address', '')
        doctor                = data.get('doctor', '')
        department            = data.get('department', '')
        bill_no               = data.get('bill_no', '')
        ward                  = data.get('ward', '')
        classification        = data.get('classification', 'NBB')
        visit_date            = data.get('visit_date') or None
        admission_date        = data.get('admission_date') or None
        number_of_days        = data.get('number_of_days') or None
        total_bill_amount     = float(data.get('total_bill_amount') or 0)
        discount_type         = data.get('discount_type', 'None')
        discount_amount       = float(data.get('discount_amount') or 0)
        amount_after_discount = float(data.get('amount_after_discount') or total_bill_amount)
        items                 = data.get('items', [])

        is_senior  = discount_type == 'Senior'
        is_pwd     = discount_type == 'PWD'
        disc_pct   = 20.00 if (is_senior or is_pwd) else 0.00

        # ── Helper: get or create a charge_category by name ───────────────
        def _get_or_create_category(cursor, name):
            cursor.execute("""
                INSERT INTO pch.charge_categories
                    (category_name, sort_order, used_in, is_active, updated_at)
                VALUES (%s, 99, 'BOTH', true, NOW())
                ON CONFLICT (category_name)
                DO UPDATE SET updated_at = NOW()
                RETURNING category_id
            """, [name])
            return cursor.fetchone()[0]

        # ── Helper: group items by category ───────────────────────────────
        def _group_items(items):
            totals  = defaultdict(float)
            remarks = {}
            for item in items:
                cat = item.get('category', 'Other')
                amt = float(item.get('actual_amount') or item.get('total') or 0)
                totals[cat] += amt
                remarks.setdefault(cat, item.get('description', cat))
            return totals, remarks

        with connection.cursor() as cursor:

            # ── 1. Look up patient_id ──────────────────────────────────────
            cursor.execute("""
                SELECT patient_id FROM pch.patient_profiling
                WHERE hospital_id = %s LIMIT 1
            """, [hospital_no])
            row = cursor.fetchone()
            patient_id = row[0] if row else None

            nbb_soa_id         = None
            philhealth_soa_id  = None
            nonmed_soa_id      = None
            soa_opd_id         = None

            if classification == 'PhilHealth':
                # ── 2a. Resolve admission_id (4-step cascade) ─────────────
                admission_id_fe = data.get('admission_id')
                admission_id = int(admission_id_fe) if admission_id_fe else None

                if admission_id is None and bill_no:
                    cursor.execute("""
                        SELECT admission_id FROM pch.pharmacy_dispense_receipts
                        WHERE receipt_no = %s AND admission_id IS NOT NULL LIMIT 1
                    """, [bill_no])
                    adm_row = cursor.fetchone()
                    if adm_row:
                        admission_id = adm_row[0]

                if admission_id is None and patient_id is not None:
                    cursor.execute("""
                        SELECT admission_id FROM pch.pharmacy_dispense_receipts
                        WHERE patient_id = %s AND admission_id IS NOT NULL
                        ORDER BY dispensing_date DESC LIMIT 1
                    """, [patient_id])
                    adm_row = cursor.fetchone()
                    if adm_row:
                        admission_id = adm_row[0]

                if admission_id is None and patient_id is not None:
                    cursor.execute("""
                        SELECT admission_id FROM pch.ipd_patient_admissions
                        WHERE patient_id = %s
                        ORDER BY admission_date DESC LIMIT 1
                    """, [patient_id])
                    adm_row = cursor.fetchone()
                    if adm_row:
                        admission_id = adm_row[0]

                if admission_id is None:
                    logger.warning(
                        f"save_nbb_social_work PhilHealth: no admission_id found for "
                        f"hospital_no={hospital_no}; inserting with NULL."
                    )

                if patient_id is not None:
                    # ── 3a. Insert soa_philhealth (SOCIAL WORK) ────────────
                    cursor.execute("""
                        INSERT INTO pch.soa_philhealth (
                            patient_id, admission_id, bill_no, ward, classification,
                            soa_date, date_of_admission, number_of_days,
                            is_senior_citizen, is_pwd,
                            discount_percent, discount_amount,
                            total_actual, grand_total,
                            soa_status, remarks, updated_at
                        ) VALUES (
                            %s, %s, %s, %s, %s,
                            CURRENT_DATE, %s, %s,
                            %s, %s,
                            %s, %s,
                            %s, %s,
                            'SOCIAL WORK', %s, NOW()
                        ) RETURNING soa_id
                    """, [
                        patient_id, admission_id, bill_no, ward, classification,
                        admission_date, number_of_days,
                        is_senior, is_pwd,
                        disc_pct, discount_amount,
                        total_bill_amount, amount_after_discount,
                        f'Social Work referral — {bill_no}',
                    ])
                    philhealth_soa_id = cursor.fetchone()[0]

                    # ── 4a. Insert soa_philhealth_line_items ───────────────
                    cat_totals, cat_remarks = _group_items(items)
                    for cat_name, total_amt in cat_totals.items():
                        cat_id = _get_or_create_category(cursor, cat_name)
                        cursor.execute("""
                            INSERT INTO pch.soa_philhealth_line_items (
                                soa_id, category_id,
                                actual_amount, philhealth_amount,
                                excess_amount, outside_amount,
                                remarks, updated_at
                            ) VALUES (
                                %s, %s,
                                %s, 0.00,
                                0.00, %s,
                                %s, NOW()
                            )
                        """, [
                            philhealth_soa_id, cat_id,
                            total_amt, total_amt,
                            cat_remarks.get(cat_name, cat_name),
                        ])
                else:
                    logger.warning(
                        f"save_nbb_social_work PhilHealth: patient not found "
                        f"for hospital_no={hospital_no}; skipping soa_philhealth insert."
                    )

            elif classification == 'OPD':
                # ── 2d. Insert soa_opd (SOCIAL WORK) ─────────────────────
                fee_map = {
                    'consultation fee': 'consultation',
                    'laboratory tests': 'laboratory',
                    'laboratory':       'laboratory',
                    'medication':       'medication',
                    'medicines':        'medication',
                }
                consult_fee = lab_fee = med_fee = oth_fee = 0.0
                for item in items:
                    cat    = (item.get('category') or '').lower()
                    amt    = float(item.get('actual_amount') or 0)
                    mapped = fee_map.get(cat)
                    if mapped == 'consultation':
                        consult_fee += amt
                    elif mapped == 'laboratory':
                        lab_fee += amt
                    elif mapped == 'medication':
                        med_fee += amt
                    else:
                        oth_fee += amt

                cursor.execute("""
                    INSERT INTO pch.soa_opd (
                        patient_name, hospital_no, age, address,
                        visit_date, billing_date,
                        consultation_fee, laboratory_fee,
                        medication_fee, other_fee,
                        discount_type, discount_amount,
                        charge_to_maip,
                        status, prepared_by, noted_by,
                        created_at, updated_at
                    ) VALUES (
                        %s, %s, %s, %s,
                        %s, CURRENT_DATE,
                        %s, %s, %s, %s,
                        %s, %s,
                        %s,
                        'SOCIAL WORK', 'RETCHEL R. EROY', '',
                        NOW(), NOW()
                    ) RETURNING id
                """, [
                    patient_name, hospital_no, age, address,
                    visit_date,
                    consult_fee, lab_fee, med_fee, oth_fee,
                    discount_type, discount_amount,
                    total_bill_amount,
                ])
                soa_opd_id = cursor.fetchone()[0]

                # ── 3d. Insert soa_opd_line_items ─────────────────────────
                for item in items:
                    cursor.execute("""
                        INSERT INTO pch.soa_opd_line_items (
                            soa_id, category,
                            actual_amount, philhealth_amount,
                            excess_amount, outside_amount,
                            source, created_at
                        ) VALUES (
                            %s, %s,
                            %s, 0.00,
                            0.00, %s,
                            %s, NOW()
                        )
                    """, [
                        soa_opd_id,
                        item.get('category', ''),
                        float(item.get('actual_amount') or 0),
                        float(item.get('actual_amount') or 0),
                        item.get('source', 'manual'),
                    ])

            elif classification == 'Non-Med':
                # ── 2c. Insert soa_nonmed (SOCIAL WORK) ─────────────────
                if patient_id is not None:
                    cursor.execute("""
                        INSERT INTO pch.soa_nonmed (
                            patient_id, hospital_no, patient_name, patient_address, patient_age,
                            ward, bill_no, classification,
                            admission_date, number_of_days,
                            discount_type, discount_rate, discount_amount,
                            subtotal, grand_total,
                            status, updated_at
                        ) VALUES (
                            %s, %s, %s, %s, %s,
                            %s, %s, %s,
                            %s, %s,
                            %s, %s, %s,
                            %s, %s,
                            'SOCIAL WORK', NOW()
                        ) RETURNING id
                    """, [
                        patient_id, hospital_no, patient_name, address, age,
                        ward, bill_no or 'PARTIAL BILL', classification,
                        admission_date, number_of_days,
                        discount_type, disc_pct, discount_amount,
                        total_bill_amount, amount_after_discount,
                    ])
                    nonmed_soa_id = cursor.fetchone()[0]

                    # ── 3c. Insert soa_nonmed_line_items (grouped by category) ──
                    cat_totals, _ = _group_items(items)
                    for sort_idx, (cat_name, total_amt) in enumerate(cat_totals.items(), start=1):
                        cursor.execute("""
                            INSERT INTO pch.soa_nonmed_line_items (
                                soa_id, category,
                                actual_amount, philhealth_amount,
                                excess_amount, outside_amount,
                                sort_order, created_at
                            ) VALUES (
                                %s, %s,
                                %s, 0.00,
                                0.00, %s,
                                %s, NOW()
                            )
                        """, [
                            nonmed_soa_id, cat_name,
                            total_amt, total_amt,
                            sort_idx,
                        ])
                else:
                    logger.warning(
                        f"save_nbb_social_work Non-Med: patient not found for hospital_no={hospital_no}; "
                        "skipping soa_nonmed insert."
                    )

            else:
                # ── 2b. Insert soa_nbb (SOCIAL WORK) ──────────────────
                if patient_id is not None:
                    cursor.execute("""
                        INSERT INTO pch.soa_nbb (
                            patient_id, soa_date, age,
                            is_senior_citizen, is_pwd,
                            discount_percent, discount_amount,
                            maip_amount, total_actual, grand_total,
                            soa_status, remarks, updated_at
                        ) VALUES (
                            %s, CURRENT_DATE, %s,
                            %s, %s,
                            %s, %s,
                            %s, %s, %s,
                            'SOCIAL WORK', %s, NOW()
                        ) RETURNING soa_id
                    """, [
                        patient_id, age,
                        is_senior, is_pwd,
                        disc_pct, discount_amount,
                        amount_after_discount,
                        total_bill_amount,
                        amount_after_discount,
                        f'Social Work referral — {bill_no}',
                    ])
                    nbb_soa_id = cursor.fetchone()[0]

                    # ── 3b. Insert soa_nbb_line_items (grouped) ────────────
                    cat_totals, cat_remarks = _group_items(items)
                    for cat_name, total_amt in cat_totals.items():
                        cat_id = _get_or_create_category(cursor, cat_name)
                        cursor.execute("""
                            INSERT INTO pch.soa_nbb_line_items (
                                soa_id, category_id,
                                actual_amount, maip_amount,
                                remarks, updated_at
                            ) VALUES (
                                %s, %s,
                                %s, %s,
                                %s, NOW()
                            )
                        """, [
                            nbb_soa_id, cat_id,
                            total_amt, total_amt,
                            cat_remarks.get(cat_name, cat_name),
                        ])
                else:
                    logger.warning(
                        f"save_nbb_social_work: patient not found for hospital_no={hospital_no}; "
                        "skipping soa_nbb insert."
                    )

            # ── 5. Insert social_work_referrals ────────────────────────────────────
            ref_source = 'OPD' if classification == 'OPD' else 'IPD'
            cursor.execute("""
                INSERT INTO pch.social_work_referrals (
                    referral_source, soa_nbb_id, soa_philhealth_id, soa_nonmed_id, soa_opd_id,
                    patient_name, hospital_no, age, address,
                    doctor, department, bill_no, classification,
                    total_bill_amount, discount_type, discount_amount, amount_after_discount,
                    status, referral_date, created_at, updated_at
                ) VALUES (
                    %s, %s, %s, %s, %s,
                    %s, %s, %s, %s,
                    %s, %s, %s, %s,
                    %s, %s, %s, %s,
                    'PENDING', CURRENT_DATE, NOW(), NOW()
                ) RETURNING id
            """, [
                ref_source, nbb_soa_id, philhealth_soa_id, nonmed_soa_id, soa_opd_id,
                patient_name, hospital_no, age, address,
                doctor, department, bill_no, classification,
                total_bill_amount, discount_type, discount_amount, amount_after_discount,
            ])
            referral_id = cursor.fetchone()[0]

            # ── 5. Insert social_work_referral_items (individual rows) ─────
            for item in items:
                total = float(item.get('total') or 0)
                cursor.execute("""
                    INSERT INTO pch.social_work_referral_items (
                        referral_id, category, description, quantity, unit_price, total,
                        actual_amount, philhealth_amount, excess_amount, outside_amount,
                        charge_to_maip, source, created_at
                    ) VALUES (
                        %s, %s, %s, %s, %s, %s,
                        %s, %s, %s, %s,
                        %s, %s, NOW()
                    )
                """, [
                    referral_id,
                    item.get('category', 'Other'),
                    item.get('description', ''),
                    int(item.get('quantity') or 1),
                    float(item.get('unit_price') or 0),
                    total,
                    float(item.get('actual_amount') or total),
                    float(item.get('philhealth_amount') or 0),
                    float(item.get('excess_amount') or 0),
                    float(item.get('outside_amount') or 0),
                    float(item.get('charge_to_maip') or 0),
                    item.get('source', 'billing'),
                ])

        return Response({
            'success':           True,
            'referral_id':       referral_id,
            'nbb_soa_id':        nbb_soa_id,
            'philhealth_soa_id': philhealth_soa_id,
            'nonmed_soa_id':     nonmed_soa_id,
            'soa_opd_id':        soa_opd_id,
        })

    except Exception as e:
        logger.error(f"save_nbb_social_work error: {e}")
        return Response({'success': False, 'message': str(e)}, status=500)


# ══════════════════════════════════════════════════════════════════════════════
# SAVE PROMISSORY NOTE
# ══════════════════════════════════════════════════════════════════════════════
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_promissory_note(request):
    """
    Save a promissory note to pch.promissory_notes.
    Payload fields:
      patient_name, hospital_no, contact_number,
      classification  (NBB | PhilHealth | Non-Med | OPD),
      total_bill_amount, downpayment_amount, due_date,
      department, admission_number, admission_date,
      soa_nbb_id | soa_philhealth_id | soa_nonmed_id | soa_opd_id  (one of these)
    """
    try:
        data = request.data

        hospital_no          = data.get('hospital_no', '')
        classification       = data.get('classification', 'NBB')
        total_bill_amount    = float(data.get('total_bill_amount') or 0)
        downpayment_amount   = min(float(data.get('downpayment_amount') or 0), total_bill_amount)
        downpayment_amount   = max(0.0, downpayment_amount)
        balance_amount       = round(total_bill_amount - downpayment_amount, 2)
        due_date             = data.get('due_date') or None

        # IPD fields - ensure NOT NULL for IPD records (soa_philhealth or soa_nonmed)
        # If empty, provide default values to satisfy database constraint
        raw_department       = data.get('department', '').strip()
        raw_admission_number = data.get('admission_number', '').strip()
        raw_admission_date   = data.get('admission_date', '').strip()

        # Determine if this is an IPD record (has PhilHealth or Non-Med SOA)
        soa_philhealth_id = data.get('soa_philhealth_id')
        soa_nonmed_id = data.get('soa_nonmed_id')
        is_ipd = soa_philhealth_id or soa_nonmed_id

        # For IPD: ensure required fields have values
        if is_ipd:
            department = raw_department if raw_department else 'IPD'
            admission_number = raw_admission_number if raw_admission_number else hospital_no if hospital_no else 'ADM-UNKNOWN'
            admission_date = raw_admission_date if raw_admission_date else datetime.now().strftime('%Y-%m-%d')
        else:
            # OPD can have NULLs
            department = raw_department if raw_department else None
            admission_number = raw_admission_number if raw_admission_number else None
            admission_date = raw_admission_date if raw_admission_date else None

        guarantor_contact    = data.get('contact_number', '')

        # ── Optional SOA links (only one should be set) ──────────────────────
        # Use the same variables already checked for IPD detection
        soa_nbb_id         = data.get('soa_nbb_id') or None
        soa_philhealth_id  = soa_philhealth_id if soa_philhealth_id else None
        soa_nonmed_id      = soa_nonmed_id if soa_nonmed_id else None
        soa_opd_id         = data.get('soa_opd_id') or None

        with connection.cursor() as cursor:
            # ── Resolve patient_id ───────────────────────────────────────────
            # 1. Accept direct patient_id from payload
            patient_id = data.get('patient_id') or None
            if patient_id:
                patient_id = int(patient_id)

            # 2. Look up via patient_profiling.hospital_id
            if patient_id is None and hospital_no:
                cursor.execute("""
                    SELECT patient_id FROM pch.patient_profiling
                    WHERE hospital_id = %s LIMIT 1
                """, [hospital_no])
                row = cursor.fetchone()
                patient_id = row[0] if row else None

            # 3. Fallback: get patient_id from the linked SOA table
            if patient_id is None:
                if soa_nbb_id:
                    cursor.execute("SELECT patient_id FROM pch.soa_nbb WHERE soa_id = %s LIMIT 1", [soa_nbb_id])
                    row = cursor.fetchone()
                    patient_id = row[0] if row else None
                elif soa_philhealth_id:
                    cursor.execute("SELECT patient_id FROM pch.soa_philhealth WHERE soa_id = %s LIMIT 1", [soa_philhealth_id])
                    row = cursor.fetchone()
                    patient_id = row[0] if row else None
                elif soa_nonmed_id:
                    cursor.execute("SELECT patient_id FROM pch.soa_nonmed WHERE id = %s LIMIT 1", [soa_nonmed_id])
                    row = cursor.fetchone()
                    patient_id = row[0] if row else None
                elif soa_opd_id:
                    # soa_opd has no patient_id — look up via hospital_no
                    cursor.execute("SELECT hospital_no FROM pch.soa_opd WHERE id = %s LIMIT 1", [soa_opd_id])
                    opd_row = cursor.fetchone()
                    if opd_row and opd_row[0]:
                        cursor.execute("SELECT patient_id FROM pch.patient_profiling WHERE hospital_id = %s LIMIT 1", [opd_row[0]])
                        row = cursor.fetchone()
                        patient_id = row[0] if row else None

            # 4. Last resort: match by patient name from payload
            if patient_id is None:
                patient_name_payload = data.get('patient_name', '').strip()
                if patient_name_payload:
                    parts = patient_name_payload.split()
                    if len(parts) >= 2:
                        cursor.execute("""
                            SELECT patient_id FROM pch.patient_profiling
                            WHERE LOWER(firstname) = LOWER(%s) AND LOWER(lastname) = LOWER(%s)
                            LIMIT 1
                        """, [parts[0], parts[-1]])
                        row = cursor.fetchone()
                        patient_id = row[0] if row else None

            if patient_id is None:
                logger.warning(f"save_promissory_note: patient_id not resolved | hospital_no={hospital_no} soa_nbb={soa_nbb_id} soa_ph={soa_philhealth_id} soa_nm={soa_nonmed_id} soa_opd={soa_opd_id} — proceeding with NULL")

            # ── Generate unique PN number ─────────────────────────────────────
            now = datetime.now()
            cursor.execute("""
                SELECT COUNT(*) FROM pch.promissory_notes
                WHERE EXTRACT(YEAR FROM pn_date) = %s
            """, [now.year])
            count = cursor.fetchone()[0] + 1
            pn_no = f"PN-{now.year}{str(count).zfill(4)}"

            # ── Insert promissory note ────────────────────────────────────────
            cursor.execute("""
                INSERT INTO pch.promissory_notes (
                    soa_nbb_id, soa_philhealth_id, soa_nonmed_id, soa_opd_id,
                    patient_id,
                    pn_no, pn_date, due_date,
                    admission_number, department, admission_date,
                    total_bill_amount, downpayment_amount, balance_amount,
                    total_paid_amount, remaining_balance,
                    payment_scheme,
                    guarantor_contact,
                    pn_status,
                    updated_at
                ) VALUES (
                    %s, %s, %s, %s,
                    %s,
                    %s, CURRENT_DATE, %s,
                    %s, %s, %s,
                    %s, %s, %s,
                    0.00, %s,
                    'INSTALLMENT',
                    %s,
                    'ACTIVE',
                    NOW()
                ) RETURNING pn_id
            """, [
                soa_nbb_id, soa_philhealth_id, soa_nonmed_id, soa_opd_id,
                patient_id,
                pn_no, due_date,
                admission_number, department, admission_date,
                total_bill_amount, downpayment_amount, balance_amount,
                balance_amount,
                guarantor_contact,
            ])
            pn_id = cursor.fetchone()[0]

            # ── Mark SOA as PROMISSORY NOTE ───────────────────────────────────
            _update_soa_status_row(cursor, soa_nbb_id, soa_philhealth_id,
                                   soa_nonmed_id, soa_opd_id, 'PROMISSORY NOTE')

        return Response({
            'success': True,
            'pn_id':   pn_id,
            'pn_no':   pn_no,
        })

    except Exception as e:
        logger.error(f"save_promissory_note error: {e}")
        return Response({'success': False, 'message': str(e)}, status=500)


# ══════════════════════════════════════════════════════════════════════════════
# SHARED HELPER — update status on one SOA row
# ══════════════════════════════════════════════════════════════════════════════
def _update_soa_status_row(cursor, soa_nbb_id, soa_philhealth_id,
                           soa_nonmed_id, soa_opd_id, new_status):
    """
    Updates the status and payment_status columns on whichever SOA table
    is identified by the supplied id arguments (exactly one should be non-None).
    payment_status is only set to 'PAID' when new_status == 'PAID';
    otherwise it is left untouched.
    """
    pay_st = 'PAID' if new_status == 'PAID' else None

    if soa_nbb_id:
        try:
            if pay_st:
                cursor.execute("""
                    UPDATE pch.soa_nbb
                    SET soa_status = %s, payment_status = %s, updated_at = NOW()
                    WHERE soa_id = %s
                """, [new_status, pay_st, soa_nbb_id])
            else:
                cursor.execute("""
                    UPDATE pch.soa_nbb SET soa_status = %s, updated_at = NOW()
                    WHERE soa_id = %s
                """, [new_status, soa_nbb_id])
        except Exception as e:
            logger.warning(f"_update_soa_status_row soa_nbb {soa_nbb_id}: {e}")

    elif soa_philhealth_id:
        try:
            if pay_st:
                cursor.execute("""
                    UPDATE pch.soa_philhealth
                    SET soa_status = %s, payment_status = %s, updated_at = NOW()
                    WHERE soa_id = %s
                """, [new_status, pay_st, soa_philhealth_id])
            else:
                cursor.execute("""
                    UPDATE pch.soa_philhealth SET soa_status = %s, updated_at = NOW()
                    WHERE soa_id = %s
                """, [new_status, soa_philhealth_id])
        except Exception as e:
            logger.warning(f"_update_soa_status_row soa_philhealth {soa_philhealth_id}: {e}")

    elif soa_nonmed_id:
        try:
            if pay_st:
                cursor.execute("""
                    UPDATE pch.soa_nonmed
                    SET status = %s, payment_status = %s, updated_at = NOW()
                    WHERE id = %s
                """, [new_status, pay_st, soa_nonmed_id])
            else:
                cursor.execute("""
                    UPDATE pch.soa_nonmed SET status = %s, updated_at = NOW()
                    WHERE id = %s
                """, [new_status, soa_nonmed_id])
        except Exception as e:
            logger.warning(f"_update_soa_status_row soa_nonmed {soa_nonmed_id}: {e}")

    elif soa_opd_id:
        try:
            if pay_st:
                cursor.execute("""
                    UPDATE pch.soa_opd
                    SET status = %s, payment_status = %s, updated_at = NOW()
                    WHERE id = %s
                """, [new_status, pay_st, soa_opd_id])
            else:
                cursor.execute("""
                    UPDATE pch.soa_opd SET status = %s, updated_at = NOW()
                    WHERE id = %s
                """, [new_status, soa_opd_id])
        except Exception as e:
            logger.warning(f"_update_soa_status_row soa_opd {soa_opd_id}: {e}")


# ══════════════════════════════════════════════════════════════════════════════
# CASHIER — UPDATE SOA PAYMENT STATUS  (Pay / Mark Paid)
# ══════════════════════════════════════════════════════════════════════════════
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def update_soa_status(request):
    """
    Updates payment status on the appropriate SOA table when the cashier
    confirms payment or marks NBB as paid.
    Body: {
        soa_type: 'nbb' | 'philhealth' | 'nonmed' | 'opd',
        soa_id: int,
        new_status: 'PAID' | 'PROMISSORY NOTE',
        sw_reference: str   (optional, for NBB — stored in remarks)
    }
    """
    try:
        data         = request.data
        soa_type     = (data.get('soa_type') or '').lower()
        soa_id       = data.get('soa_id')
        new_status   = data.get('new_status', 'PAID')
        sw_reference = data.get('sw_reference', '')

        if not soa_type or not soa_id:
            return Response({'success': False, 'message': 'soa_type and soa_id are required'}, status=400)

        # Map type → (table, status_col, pk_col)
        TYPE_MAP = {
            'nbb':        ('pch.soa_nbb',        'soa_status', 'soa_id'),
            'philhealth': ('pch.soa_philhealth',  'soa_status', 'soa_id'),
            'nonmed':     ('pch.soa_nonmed',      'status',     'id'),
            'opd':        ('pch.soa_opd',         'status',     'id'),
        }
        if soa_type not in TYPE_MAP:
            return Response({'success': False, 'message': f'Unknown soa_type: {soa_type}'}, status=400)

        table, status_col, pk_col = TYPE_MAP[soa_type]
        pay_st = 'PAID' if new_status == 'PAID' else None

        with connection.cursor() as cursor:
            if new_status == 'PAID' and soa_type == 'nbb' and sw_reference:
                cursor.execute(f"""
                    UPDATE {table}
                    SET {status_col} = %s, payment_status = %s,
                        remarks = %s, updated_at = NOW()
                    WHERE {pk_col} = %s
                """, [new_status, pay_st, sw_reference, soa_id])
            elif pay_st:
                cursor.execute(f"""
                    UPDATE {table}
                    SET {status_col} = %s, payment_status = %s, updated_at = NOW()
                    WHERE {pk_col} = %s
                """, [new_status, pay_st, soa_id])
            else:
                cursor.execute(f"""
                    UPDATE {table}
                    SET {status_col} = %s, updated_at = NOW()
                    WHERE {pk_col} = %s
                """, [new_status, soa_id])

            rows_updated = cursor.rowcount

        if rows_updated == 0:
            return Response({'success': False, 'message': f'No record found: {soa_type} id={soa_id}'}, status=404)

        return Response({'success': True, 'updated': rows_updated})

    except Exception as e:
        logger.error(f"update_soa_status error: {e}")
        return Response({'success': False, 'message': str(e)}, status=500)


# ══════════════════════════════════════════════════════════════════════════════
# CASHIER – IPD INVOICES  (soa_nbb + soa_philhealth + soa_nonmed)
# ══════════════════════════════════════════════════════════════════════════════
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def cashier_ipd_invoices(request):
    """
    Returns all IPD invoices (NBB + PhilHealth + Non-Med) with status
    'SENT TO CASHIER' or 'PAID', unified into a single list with line items.
    """
    try:
        with connection.cursor() as cursor:

            # ── 1. UNION: all 3 IPD SOA tables ──────────────────────────────
            cursor.execute("""
                SELECT
                    'NBB-' || n.soa_id::text          AS invoice_no,
                    n.soa_id                          AS soa_nbb_id,
                    NULL::integer                     AS soa_philhealth_id,
                    NULL::integer                     AS soa_nonmed_id,
                    COALESCE(pp.firstname || ' ' || pp.lastname,
                             'Patient #' || n.patient_id) AS patient_name,
                    COALESCE(pp.hospital_id, '')       AS hospital_no,
                    'NBB'                             AS classification,
                    COALESCE(n.grand_total, 0)        AS grand_total,
                    n.soa_status                      AS status,
                    n.soa_date                        AS billing_date,
                    NULL::date                        AS admission_date,
                    NULL::text                        AS room,
                    COALESCE(n.age::text, '')         AS age,
                    ''                                AS address,
                    n.updated_at
                FROM pch.soa_nbb n
                LEFT JOIN pch.patient_profiling pp ON pp.patient_id = n.patient_id
                WHERE n.soa_status IN ('SENT TO CASHIER', 'PAID')

                UNION ALL

                SELECT
                    'PH-' || p.soa_id::text           AS invoice_no,
                    NULL::integer                     AS soa_nbb_id,
                    p.soa_id                          AS soa_philhealth_id,
                    NULL::integer                     AS soa_nonmed_id,
                    COALESCE(pp.firstname || ' ' || pp.lastname,
                             'Patient #' || p.patient_id) AS patient_name,
                    COALESCE(pp.hospital_id, '')       AS hospital_no,
                    COALESCE(p.classification, 'PhilHealth') AS classification,
                    COALESCE(p.grand_total, 0)        AS grand_total,
                    p.soa_status                      AS status,
                    p.soa_date                        AS billing_date,
                    p.date_of_admission               AS admission_date,
                    p.ward                            AS room,
                    ''                                AS age,
                    ''                                AS address,
                    p.updated_at
                FROM pch.soa_philhealth p
                LEFT JOIN pch.patient_profiling pp ON pp.patient_id = p.patient_id
                WHERE p.soa_status IN ('SENT TO CASHIER', 'PAID')

                UNION ALL

                SELECT
                    'NM-' || nm.id::text              AS invoice_no,
                    NULL::integer                     AS soa_nbb_id,
                    NULL::integer                     AS soa_philhealth_id,
                    nm.id                             AS soa_nonmed_id,
                    nm.patient_name                   AS patient_name,
                    nm.hospital_no                    AS hospital_no,
                    'Non-Med'                         AS classification,
                    COALESCE(nm.grand_total, 0)       AS grand_total,
                    nm.status                         AS status,
                    nm.updated_at::date               AS billing_date,
                    nm.admission_date                 AS admission_date,
                    nm.ward                           AS room,
                    COALESCE(nm.patient_age::text, '') AS age,
                    COALESCE(nm.patient_address, '')   AS address,
                    nm.updated_at
                FROM pch.soa_nonmed nm
                WHERE nm.status IN ('SENT TO CASHIER', 'PAID')

                ORDER BY updated_at DESC
            """)
            invoices = _dictfetchall(cursor)

            if not invoices:
                return Response({'success': True, 'data': []})

            # ── 2. Fetch line items per SOA type ─────────────────────────────
            nbb_ids = [i['soa_nbb_id'] for i in invoices if i['soa_nbb_id']]
            ph_ids  = [i['soa_philhealth_id'] for i in invoices if i['soa_philhealth_id']]
            nm_ids  = [i['soa_nonmed_id'] for i in invoices if i['soa_nonmed_id']]

            nbb_items_map = {}
            if nbb_ids:
                ph_ = ','.join(['%s'] * len(nbb_ids))
                cursor.execute(f"""
                    SELECT li.soa_id, cc.category_name AS category,
                           li.actual_amount AS total, li.remarks AS description
                    FROM pch.soa_nbb_line_items li
                    JOIN pch.charge_categories cc ON cc.category_id = li.category_id
                    WHERE li.soa_id IN ({ph_})
                """, nbb_ids)
                for row in _dictfetchall(cursor):
                    nbb_items_map.setdefault(row['soa_id'], []).append({
                        'category':    row['category'],
                        'description': row['description'] or row['category'],
                        'total':       float(row['total'] or 0),
                        'quantity':    1,
                    })

            ph_items_map = {}
            if ph_ids:
                ph_ = ','.join(['%s'] * len(ph_ids))
                cursor.execute(f"""
                    SELECT li.soa_id, cc.category_name AS category,
                           li.actual_amount AS total, li.remarks AS description
                    FROM pch.soa_philhealth_line_items li
                    JOIN pch.charge_categories cc ON cc.category_id = li.category_id
                    WHERE li.soa_id IN ({ph_})
                """, ph_ids)
                for row in _dictfetchall(cursor):
                    ph_items_map.setdefault(row['soa_id'], []).append({
                        'category':    row['category'],
                        'description': row['description'] or row['category'],
                        'total':       float(row['total'] or 0),
                        'quantity':    1,
                    })

            nm_items_map = {}
            if nm_ids:
                ph_ = ','.join(['%s'] * len(nm_ids))
                cursor.execute(f"""
                    SELECT soa_id, category, actual_amount AS total, category AS description
                    FROM pch.soa_nonmed_line_items
                    WHERE soa_id IN ({ph_})
                    ORDER BY sort_order
                """, nm_ids)
                for row in _dictfetchall(cursor):
                    nm_items_map.setdefault(row['soa_id'], []).append({
                        'category':    row['category'],
                        'description': row['description'],
                        'total':       float(row['total'] or 0),
                        'quantity':    1,
                    })

            # ── 3. Build response ─────────────────────────────────────────────
            result = []
            for inv in invoices:
                if inv['soa_nbb_id']:
                    items = nbb_items_map.get(inv['soa_nbb_id'], [])
                elif inv['soa_philhealth_id']:
                    items = ph_items_map.get(inv['soa_philhealth_id'], [])
                else:
                    items = nm_items_map.get(inv['soa_nonmed_id'], [])

                result.append({
                    'invoiceNo':        inv['invoice_no'],
                    'patient':          inv['patient_name'],
                    'hospitalNo':       inv['hospital_no'],
                    'classification':   inv['classification'],
                    'amount':           f"₱{float(inv['grand_total']):,.2f}",
                    'status':           inv['status'],
                    'billingDate':      str(inv['billing_date']) if inv['billing_date'] else '',
                    'admissionDate':    str(inv['admission_date']) if inv['admission_date'] else '',
                    'room':             inv['room'] or '',
                    'age':              inv['age'] or '',
                    'address':          inv['address'] or '',
                    'soa_nbb_id':       inv['soa_nbb_id'],
                    'soa_philhealth_id': inv['soa_philhealth_id'],
                    'soa_nonmed_id':    inv['soa_nonmed_id'],
                    'items':            items,
                })

        return Response({'success': True, 'data': result})

    except Exception as e:
        logger.error(f"cashier_ipd_invoices error: {e}")
        return Response({'success': False, 'message': str(e)}, status=500)


# ══════════════════════════════════════════════════════════════════════════════
# CASHIER – OPD INVOICES  (soa_opd)
# ══════════════════════════════════════════════════════════════════════════════
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def cashier_opd_invoices(request):
    """
    Returns all OPD invoices from soa_opd with status 'SENT TO CASHIER' or 'PAID',
    including line items for the invoice modal.
    """
    try:
        with connection.cursor() as cursor:

            cursor.execute("""
                SELECT
                    o.id                           AS soa_opd_id,
                    'OPD-' || o.id::text           AS invoice_no,
                    o.patient_name,
                    COALESCE(o.hospital_no, '')    AS hospital_no,
                    COALESCE(o.age::text, '')      AS age,
                    COALESCE(o.address, '')        AS address,
                    o.visit_date,
                    o.billing_date,
                    COALESCE(o.grand_total, 0)     AS grand_total,
                    o.status,
                    o.created_at
                FROM pch.soa_opd o
                WHERE o.status IN ('SENT TO CASHIER', 'PAID')
                ORDER BY o.created_at DESC
            """)
            invoices = _dictfetchall(cursor)

            if not invoices:
                return Response({'success': True, 'data': []})

            opd_ids      = [i['soa_opd_id'] for i in invoices]
            placeholders = ','.join(['%s'] * len(opd_ids))
            cursor.execute(f"""
                SELECT soa_id, category, actual_amount AS total, source
                FROM pch.soa_opd_line_items
                WHERE soa_id IN ({placeholders})
                ORDER BY soa_id, id
            """, opd_ids)
            items_by_soa = {}
            for row in _dictfetchall(cursor):
                items_by_soa.setdefault(row['soa_id'], []).append({
                    'category':    row['category'],
                    'description': row['category'],
                    'total':       float(row['total'] or 0),
                    'quantity':    1,
                })

            result = []
            for inv in invoices:
                result.append({
                    'invoiceNo':      inv['invoice_no'],
                    'id':             inv['invoice_no'],
                    'patient':        inv['patient_name'],
                    'hospitalNo':     inv['hospital_no'],
                    'opdNo':          inv['hospital_no'],
                    'classification': 'OPD',
                    'amount':         f"₱{float(inv['grand_total']):,.2f}",
                    'status':         inv['status'],
                    'billingDate':    str(inv['billing_date']) if inv['billing_date'] else '',
                    'admissionDate':  str(inv['visit_date']) if inv['visit_date'] else '',
                    'age':            inv['age'],
                    'address':        inv['address'],
                    'department':     'OPD',
                    'type':           'OPD',
                    'soa_opd_id':     inv['soa_opd_id'],
                    'items':          items_by_soa.get(inv['soa_opd_id'], []),
                })

        return Response({'success': True, 'data': result})

    except Exception as e:
        logger.error(f"cashier_opd_invoices error: {e}")
        return Response({'success': False, 'message': str(e)}, status=500)


# ══════════════════════════════════════════════════════════════════════════════
# SOCIAL WORK – REFERRALS LIST
# ══════════════════════════════════════════════════════════════════════════════
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def social_work_referrals_list(request):
    """
    Returns all social work referrals with their line items.
    
    Query params:
      - status: filter by referral status (PENDING, APPROVED, COMPLETED, REJECTED)
      - search: partial match on patient name or hospital number
    """
    status_filter = request.query_params.get('status', None)
    search = request.query_params.get('search', '').strip()

    try:
        where_parts = ['1=1']
        params = []

        if status_filter:
            where_parts.append('swr.status = %s')
            params.append(status_filter)

        if search:
            where_parts.append(
                "(swr.patient_name ILIKE %s OR swr.hospital_no ILIKE %s)"
            )
            params += [f'%{search}%', f'%{search}%']

        where_sql = ' AND '.join(where_parts)

        sql = f"""
            SELECT
                swr.id,
                swr.referral_source,
                swr.soa_nbb_id,
                swr.soa_philhealth_id,
                swr.soa_nonmed_id,
                swr.soa_opd_id,
                swr.patient_name,
                swr.hospital_no,
                swr.age,
                swr.address,
                swr.doctor,
                swr.department,
                swr.bill_no,
                swr.classification,
                swr.total_bill_amount,
                swr.discount_type,
                swr.discount_amount,
                swr.amount_after_discount,
                swr.status,
                swr.referral_date,
                swr.created_at,
                swr.updated_at
            FROM pch.social_work_referrals swr
            WHERE {where_sql}
            ORDER BY swr.id DESC
        """

        with connection.cursor() as cursor:
            cursor.execute(sql, params)
            referrals = _dictfetchall(cursor)

    except (OperationalError, ProgrammingError) as e:
        logger.error(f"social_work_referrals_list DB error: {e}")
        return Response({'success': False, 'message': f'Database error: {e}'}, status=500)
    except Exception as e:
        logger.error(f"social_work_referrals_list unexpected error: {e}")
        return Response({'success': False, 'message': f'Server error: {e}'}, status=500)

    if not referrals:
        return Response({'success': True, 'data': []})

    # Fetch all line items in one query
    referral_ids = [ref['id'] for ref in referrals]
    placeholders = ','.join(['%s'] * len(referral_ids))

    try:
        with connection.cursor() as cursor:
            cursor.execute(f"""
                SELECT
                    swri.id,
                    swri.referral_id,
                    swri.category,
                    swri.description,
                    swri.quantity,
                    swri.unit_price,
                    swri.total,
                    swri.actual_amount,
                    swri.philhealth_amount,
                    swri.excess_amount,
                    swri.outside_amount,
                    swri.charge_to_maip,
                    swri.source,
                    swri.created_at
                FROM pch.social_work_referral_items swri
                WHERE swri.referral_id IN ({placeholders})
                ORDER BY swri.id
            """, referral_ids)
            all_items = _dictfetchall(cursor)
    except Exception as e:
        logger.error(f"social_work_referrals_list items query error: {e}")
        all_items = []

    # Group items by referral_id
    items_by_referral = {}
    for item in all_items:
        ref_id = item['referral_id']
        items_by_referral.setdefault(ref_id, []).append({
            'itemId': item['id'],
            'category': item.get('category') or 'Other',
            'description': item.get('description') or '',
            'quantity': int(item['quantity']) if item['quantity'] else 1,
            'unitPrice': float(item['unit_price']) if item['unit_price'] else 0.0,
            'total': float(item['total']) if item['total'] else 0.0,
            'actualAmount': float(item['actual_amount']) if item['actual_amount'] else 0.0,
            'philhealthAmount': float(item['philhealth_amount']) if item['philhealth_amount'] else 0.0,
            'excessAmount': float(item['excess_amount']) if item['excess_amount'] else 0.0,
            'outsideAmount': float(item['outside_amount']) if item['outside_amount'] else 0.0,
            'chargeToMaip': float(item['charge_to_maip']) if item['charge_to_maip'] else 0.0,
            'source': item.get('source') or 'billing',
        })

    # Build response
    data = []
    for ref in referrals:
        ref_id = ref['id']
        items = items_by_referral.get(ref_id, [])

        data.append({
            'referralId': ref_id,
            'referralSource': ref['referral_source'],
            'soaNbbId': ref['soa_nbb_id'],
            'soaPhilhealthId': ref['soa_philhealth_id'],
            'soaNonmedId': ref['soa_nonmed_id'],
            'soaOpdId': ref['soa_opd_id'],
            'patientName': ref['patient_name'],
            'hospitalNo': ref['hospital_no'],
            'age': ref['age'],
            'address': ref['address'] or '',
            'doctor': ref['doctor'],
            'department': ref['department'],
            'billNo': ref['bill_no'],
            'classification': ref['classification'],
            'totalBillAmount': f"₱{float(ref['total_bill_amount']) if ref['total_bill_amount'] else 0:,.2f}",
            'discountType': ref['discount_type'],
            'discountAmount': f"₱{float(ref['discount_amount']) if ref['discount_amount'] else 0:,.2f}",
            'amountAfterDiscount': f"₱{float(ref['amount_after_discount']) if ref['amount_after_discount'] else 0:,.2f}",
            'status': ref['status'],
            'referralDate': str(ref['referral_date']) if ref['referral_date'] else '',
            'createdAt': str(ref['created_at']) if ref['created_at'] else '',
            'items': items,
        })

    return Response({'success': True, 'data': data})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def cashier_promissory_notes_list(request):
    """
    Return all promissory notes from pch.promissory_notes with patient name
    joined from pch.patient_profiling.
    """
    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT
                    pn.pn_id,
                    pn.pn_no,
                    COALESCE(
                        TRIM(pp.firstname || ' ' || COALESCE(pp.lastname, '')),
                        'Unknown'
                    )                               AS patient_name,
                    COALESCE(pn.guarantor_contact, '')  AS contact,
                    pn.total_bill_amount,
                    pn.downpayment_amount,
                    pn.remaining_balance,
                    pn.due_date,
                    pn.pn_status::text,
                    pn.pn_date
                FROM pch.promissory_notes pn
                LEFT JOIN pch.patient_profiling pp ON pp.patient_id = pn.patient_id
                ORDER BY pn.pn_date DESC, pn.pn_id DESC
            """)
            rows = cursor.fetchall()

        result = []
        for r in rows:
            pn_status = r[8] or 'ACTIVE'
            due_dt    = r[7]
            today     = date.today()

            if pn_status == 'FULLY_PAID':
                display_status = 'Paid'
            elif pn_status == 'CANCELLED':
                display_status = 'Cancelled'
            elif pn_status == 'DEFAULTED':
                display_status = 'Overdue'
            elif due_dt and due_dt < today and pn_status not in ('FULLY_PAID', 'CANCELLED'):
                display_status = 'Overdue'
            else:
                display_status = 'Active'

            result.append({
                'pn_id':          r[0],
                'pn_no':          r[1] or 'N/A',
                'patient':        r[2],
                'contact':        r[3],
                'originalBill':   float(r[4] or 0),
                'initialPayment': float(r[5] or 0),
                'remaining':      float(r[6] or 0),
                'dueDate':        str(due_dt) if due_dt else '—',
                'status':         display_status,
            })

        return Response({'success': True, 'data': result})

    except Exception as e:
        logger.error(f"cashier_promissory_notes_list error: {e}")
        return Response({'success': False, 'message': str(e)}, status=500)
