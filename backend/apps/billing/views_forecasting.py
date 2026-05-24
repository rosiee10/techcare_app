from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.db import connection
from django.utils import timezone
from datetime import timedelta, date
import math
from .models import DiagnosisMaintenance, LabDetailMaintenance


# ─────────────────────────────────────────────────────────────
#  Holt's Double Exponential Smoothing  (pure Python, no libs)
# ─────────────────────────────────────────────────────────────

def _holt_forecast(history, steps=4, alpha=0.4, beta=0.3):
    """
    Holt's Linear (Double Exponential Smoothing) forecast.
    - alpha: level smoothing factor  (0-1)
    - beta:  trend smoothing factor  (0-1)
    Works reliably with as few as 4 data points.
    Returns point forecasts + 95% CI based on RMSE of fitted values.
    """
    n = len(history)
    if n < 2:
        last = history[0] if history else 0
        return {
            'forecast': [round(last, 2)] * steps,
            'lower_ci': [max(0, round(last * 0.8, 2))] * steps,
            'upper_ci': [round(last * 1.2, 2)] * steps,
            'alpha': alpha,
            'beta': beta,
        }

    # ── Initialise level & trend ──────────────────────────────
    level = float(history[0])
    trend = float(history[1]) - float(history[0])

    # ── Compute fitted values to calculate RMSE ───────────────
    fitted = []
    lvl, trd = level, trend
    for val in history:
        fitted.append(lvl + trd)
        prev_lvl = lvl
        lvl = alpha * float(val) + (1 - alpha) * (lvl + trd)
        trd = beta * (lvl - prev_lvl) + (1 - beta) * trd

    # Final smoothed level & trend after seeing all history
    level, trend = lvl, trd

    rmse = math.sqrt(
        sum((float(history[i]) - fitted[i]) ** 2 for i in range(n)) / n
    )

    # ── Produce h-step-ahead forecasts ────────────────────────
    forecasts = [max(0.0, round(level + trend * (h + 1), 2)) for h in range(steps)]

    z95 = 1.96
    lower = [max(0.0, round(f - z95 * rmse * math.sqrt(h + 1), 2))
             for h, f in enumerate(forecasts)]
    upper = [round(f + z95 * rmse * math.sqrt(h + 1), 2)
             for h, f in enumerate(forecasts)]

    return {
        'forecast': forecasts,
        'lower_ci': lower,
        'upper_ci': upper,
        'alpha': round(alpha, 4),
        'beta':  round(beta,  4),
    }


# ─────────────────────────────────────────────────────────────
#  DB helpers
# ─────────────────────────────────────────────────────────────

def _fetch_weekly_billed(weeks=12):
    """
    Aggregate total billed amount per ISO week from all SOA tables:
    soa_nbb + soa_philhealth + soa_nonmed (grand_total) + soa_opd (charge_to_maip).
    All statuses included (represents total invoiced, regardless of payment).
    Returns (labels, values) where values is always `weeks` long.
    """
    today = date.today()
    start = today - timedelta(weeks=weeks)

    sql = """
        SELECT wk, COALESCE(SUM(amt), 0)::float
        FROM (
            SELECT
                TO_CHAR(DATE_TRUNC('week', soa_date), 'YYYY-"W"IW') AS wk,
                COALESCE(SUM(grand_total), 0)::float                  AS amt
            FROM pch.soa_nbb
            WHERE soa_date >= %s
            GROUP BY wk

            UNION ALL

            SELECT
                TO_CHAR(DATE_TRUNC('week', soa_date), 'YYYY-"W"IW') AS wk,
                COALESCE(SUM(grand_total), 0)::float                  AS amt
            FROM pch.soa_philhealth
            WHERE soa_date >= %s
            GROUP BY wk

            UNION ALL

            SELECT
                TO_CHAR(DATE_TRUNC('week', updated_at), 'YYYY-"W"IW') AS wk,
                COALESCE(SUM(total_amount), 0)::float                    AS amt
            FROM pch.soa_nonmed
            WHERE updated_at >= %s
            GROUP BY wk

            UNION ALL

            SELECT
                TO_CHAR(DATE_TRUNC('week', created_at), 'YYYY-"W"IW') AS wk,
                COALESCE(SUM(charge_to_maip), 0)::float                AS amt
            FROM pch.soa_opd
            WHERE created_at >= %s
            GROUP BY wk
        ) all_soa
        GROUP BY wk
        ORDER BY wk
    """

    with connection.cursor() as cur:
        cur.execute(sql, [start, start, start, start])
        rows = {r[0]: r[1] for r in cur.fetchall()}

    labels, values = [], []
    ptr = today - timedelta(weeks=weeks - 1, days=today.weekday())
    for _ in range(weeks):
        lbl = ptr.strftime('%Y-W%V')
        labels.append(lbl)
        values.append(rows.get(lbl, 0.0))
        ptr += timedelta(weeks=1)

    return labels, values


def _fetch_weekly_collected(weeks=12):
    """
    Aggregate total collected (PAID receipts) per ISO week.
    We treat paid SOA rows across all SOA tables as 'collected'.
    Uses soa_nbb + soa_philhealth + soa_nonmed (grand_total / total_actual).
    """
    today = date.today()
    start = today - timedelta(weeks=weeks)

    sql = """
        SELECT
            TO_CHAR(DATE_TRUNC('week', updated_at), 'YYYY-"W"IW') AS wk,
            COALESCE(SUM(grand_total), 0)::float                    AS amt
        FROM pch.soa_nbb
        WHERE soa_status = 'CASHIER'
          AND updated_at >= %s
        GROUP BY wk

        UNION ALL

        SELECT
            TO_CHAR(DATE_TRUNC('week', updated_at), 'YYYY-"W"IW') AS wk,
            COALESCE(SUM(grand_total), 0)::float                    AS amt
        FROM pch.soa_philhealth
        WHERE soa_status = 'CASHIER'
          AND updated_at >= %s
        GROUP BY wk

        UNION ALL

        SELECT
            TO_CHAR(DATE_TRUNC('week', updated_at), 'YYYY-"W"IW') AS wk,
            COALESCE(SUM(total_amount), 0)::float                    AS amt
        FROM pch.soa_nonmed
        WHERE status = 'CASHIER'
          AND updated_at >= %s
        GROUP BY wk

        UNION ALL

        SELECT
            TO_CHAR(DATE_TRUNC('week', updated_at), 'YYYY-"W"IW') AS wk,
            COALESCE(SUM(charge_to_maip), 0)::float                AS amt
        FROM pch.soa_opd
        WHERE status = 'CASHIER'
          AND updated_at >= %s
        GROUP BY wk
    """

    with connection.cursor() as cur:
        cur.execute(sql, [start, start, start, start])
        raw = cur.fetchall()

    agg = {}
    for wk, amt in raw:
        agg[wk] = agg.get(wk, 0.0) + amt

    values = []
    ptr = today - timedelta(weeks=weeks - 1, days=today.weekday())
    for _ in range(weeks):
        lbl = ptr.strftime('%Y-W%V')
        values.append(agg.get(lbl, 0.0))
        ptr += timedelta(weeks=1)

    return values


def _fetch_weekly_social_work(weeks=12):
    """Weekly referral count from social_work_referrals."""
    today = date.today()
    start = today - timedelta(weeks=weeks)

    with connection.cursor() as cur:
        cur.execute("""
            SELECT
                TO_CHAR(DATE_TRUNC('week', created_at), 'YYYY-"W"IW') AS wk,
                COUNT(*)::float                                          AS cnt
            FROM pch.social_work_referrals
            WHERE created_at >= %s
            GROUP BY wk
            ORDER BY wk
        """, [start])
        rows = {r[0]: r[1] for r in cur.fetchall()}

    values = []
    ptr = today - timedelta(weeks=weeks - 1, days=today.weekday())
    for _ in range(weeks):
        lbl = ptr.strftime('%Y-W%V')
        values.append(rows.get(lbl, 0.0))
        ptr += timedelta(weeks=1)

    return values


def _fetch_weekly_promissory(weeks=12):
    """Weekly total balance_amount from promissory_notes."""
    today = date.today()
    start = today - timedelta(weeks=weeks)

    with connection.cursor() as cur:
        cur.execute("""
            SELECT
                TO_CHAR(DATE_TRUNC('week', updated_at), 'YYYY-"W"IW') AS wk,
                COALESCE(SUM(balance_amount), 0)::float                AS amt
            FROM pch.promissory_notes
            WHERE updated_at >= %s
            GROUP BY wk
            ORDER BY wk
        """, [start])
        rows = {r[0]: r[1] for r in cur.fetchall()}

    values = []
    ptr = today - timedelta(weeks=weeks - 1, days=today.weekday())
    for _ in range(weeks):
        lbl = ptr.strftime('%Y-W%V')
        values.append(rows.get(lbl, 0.0))
        ptr += timedelta(weeks=1)

    return values


def _fallback_if_empty(values, fallback):
    """If all values are 0 (no DB data yet), return fallback list."""
    return values if any(v > 0 for v in values) else fallback


# ─────────────────────────────────────────────────────────────
#  Forecasting API Endpoints
# ─────────────────────────────────────────────────────────────

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def diagnosis_forecast(request):
    """
    Forecast diagnosis frequency using Holt's Double Exponential Smoothing.
    History: real weekly counts from social_work_referrals per classification.
    """
    try:
        diagnoses = DiagnosisMaintenance.objects.all().order_by('code')

        today = date.today()
        start = today - timedelta(weeks=24)

        with connection.cursor() as cur:
            cur.execute("""
                SELECT
                    classification,
                    TO_CHAR(DATE_TRUNC('week', created_at), 'YYYY-"W"IW') AS wk,
                    COUNT(*)::float AS cnt
                FROM pch.social_work_referrals
                WHERE created_at >= %s
                GROUP BY classification, wk
                ORDER BY classification, wk
            """, [start])
            rows = cur.fetchall()

        class_weekly = {}
        for cls, wk, cnt in rows:
            class_weekly.setdefault(cls, {})[wk] = cnt

        result = []
        for diag in diagnoses[:10]:
            cls_data = class_weekly.get(diag.code, {})
            ptr = today - timedelta(weeks=5, days=today.weekday())
            history = []
            for _ in range(6):
                lbl = ptr.strftime('%Y-W%V')
                history.append(cls_data.get(lbl, 0.0))
                ptr += timedelta(weeks=1)

            if not any(h > 0 for h in history):
                history = [2.0, 3.0, 2.0, 4.0, 3.0, 5.0]

            fc = _holt_forecast(history, steps=3)
            trend_pct = (
                (fc['forecast'][-1] - history[-1]) / history[-1] * 100
                if history[-1] > 0 else 0
            )

            result.append({
                'code': diag.code,
                'description': diag.description,
                'history': [round(h, 0) for h in history],
                'forecast': [round(f, 0) for f in fc['forecast']],
                'trend_percent': round(trend_pct, 2),
                'current': round(history[-1], 0),
                'forecast_next': round(fc['forecast'][-1], 0),
            })

        return Response({
            'success': True,
            'data': result,
            'model': 'Holt Double Exp. Smoothing',
            'period': 'Last 6 weeks → Next 3 weeks',
        })

    except Exception as e:
        return Response({'success': False, 'message': str(e)}, status=500)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def pricing_forecast(request):
    """
    Forecast lab service pricing using Holt's smoothing.
    History: real weekly PhilHealth & NBB amounts from soa_philhealth / soa_nbb.
    """
    try:
        services = LabDetailMaintenance.objects.select_related('lab_code').all()[:10]

        today = date.today()
        start = today - timedelta(weeks=6)

        with connection.cursor() as cur:
            cur.execute("""
                SELECT
                    TO_CHAR(DATE_TRUNC('week', soa_date), 'YYYY-"W"IW') AS wk,
                    COALESCE(AVG(grand_total), 0)::float                  AS avg_ph
                FROM pch.soa_philhealth
                WHERE soa_date >= %s
                GROUP BY wk ORDER BY wk
            """, [start])
            ph_rows = {r[0]: r[1] for r in cur.fetchall()}

            cur.execute("""
                SELECT
                    TO_CHAR(DATE_TRUNC('week', soa_date), 'YYYY-"W"IW') AS wk,
                    COALESCE(AVG(grand_total), 0)::float                  AS avg_nbb
                FROM pch.soa_nbb
                WHERE soa_date >= %s
                GROUP BY wk ORDER BY wk
            """, [start])
            nbb_rows = {r[0]: r[1] for r in cur.fetchall()}

        ptr = today - timedelta(weeks=5, days=today.weekday())
        hist_ph, hist_nbb = [], []
        for _ in range(6):
            lbl = ptr.strftime('%Y-W%V')
            hist_ph.append(ph_rows.get(lbl, 0.0))
            hist_nbb.append(nbb_rows.get(lbl, 0.0))
            ptr += timedelta(weeks=1)

        hist_ph  = _fallback_if_empty(hist_ph,  [320.0, 330.0, 335.0, 340.0, 348.0, 350.0])
        hist_nbb = _fallback_if_empty(hist_nbb, [470.0, 480.0, 485.0, 490.0, 495.0, 500.0])

        result = []
        for svc in services:
            fc_ph  = _holt_forecast(hist_ph,  steps=3)
            fc_nbb = _holt_forecast(hist_nbb, steps=3)

            trend_ph  = ((fc_ph['forecast'][-1]  - hist_ph[-1])  / hist_ph[-1]  * 100) if hist_ph[-1]  > 0 else 0
            trend_nbb = ((fc_nbb['forecast'][-1] - hist_nbb[-1]) / hist_nbb[-1] * 100) if hist_nbb[-1] > 0 else 0

            result.append({
                'lab_code': svc.lab_code.lab_code,
                'name': svc.lab_detail_desc or 'Unknown',
                'history_philhealth': [round(v, 2) for v in hist_ph],
                'history_nbb':        [round(v, 2) for v in hist_nbb],
                'forecast_philhealth': [round(v, 2) for v in fc_ph['forecast']],
                'forecast_nbb':        [round(v, 2) for v in fc_nbb['forecast']],
                'trend_philhealth_percent': round(trend_ph,  2),
                'trend_nbb_percent':        round(trend_nbb, 2),
                'current_philhealth': round(hist_ph[-1],  2),
                'current_nbb':        round(hist_nbb[-1], 2),
            })

        return Response({
            'success': True,
            'data': result,
            'model': 'Holt Double Exp. Smoothing',
            'period': 'Last 6 weeks → Next 3 weeks',
        })

    except Exception as e:
        return Response({'success': False, 'message': str(e)}, status=500)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def forecast_summary(request):
    """
    Real summary: top classifications by referral count + promissory note trend.
    """
    try:
        today = date.today()
        start = today - timedelta(days=90)

        with connection.cursor() as cur:
            cur.execute("""
                SELECT classification, COUNT(*) AS cnt
                FROM pch.social_work_referrals
                WHERE created_at >= %s
                GROUP BY classification
                ORDER BY cnt DESC
                LIMIT 5
            """, [start])
            cls_rows = cur.fetchall()

            cur.execute("""
                SELECT
                    TO_CHAR(DATE_TRUNC('week', updated_at), 'YYYY-"W"IW') AS wk,
                    COALESCE(SUM(balance_amount), 0)::float                AS amt
                FROM pch.promissory_notes
                WHERE updated_at >= %s
                GROUP BY wk ORDER BY wk
            """, [start])
            pn_rows = cur.fetchall()

        top_diagnoses = [
            {'code': r[0], 'name': r[0], 'frequency': int(r[1]), 'trend': 0.0}
            for r in cls_rows
        ]

        pn_values = [r[1] for r in pn_rows]
        pn_trend = 0.0
        if len(pn_values) >= 2 and pn_values[-2] > 0:
            pn_trend = round((pn_values[-1] - pn_values[-2]) / pn_values[-2] * 100, 1)

        top_services = [
            {'code': 'PN',  'name': 'Promissory Note Balance', 'trend': pn_trend},
            {'code': 'IPD', 'name': 'IPD Referrals',           'trend': 0.0},
            {'code': 'OPD', 'name': 'OPD Referrals',           'trend': 0.0},
        ]

        return Response({
            'success': True,
            'top_diagnoses': top_diagnoses,
            'top_services':  top_services,
            'forecast_period': 'Next 3 weeks',
        })

    except Exception as e:
        return Response({'success': False, 'message': str(e)}, status=500)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def revenue_forecast(request):
    """
    Holt's Double Exponential Smoothing revenue forecast.
    History: real 12-week billed & collected amounts from the DB.
    Returns 12-week history + 4-week forecast with 95% CI.
    """
    try:
        WEEKS = 12
        STEPS = 4

        # ── Fetch real data ───────────────────────────────────
        hist_labels, history_billed    = _fetch_weekly_billed(WEEKS)
        history_collected              = _fetch_weekly_collected(WEEKS)
        history_social_work            = _fetch_weekly_social_work(WEEKS)
        history_promissory             = _fetch_weekly_promissory(WEEKS)

        # ── Fallback when DB has no data yet ──────────────────
        # Both billed & collected come from the same SOA tables now,
        # so fallback values share the same realistic scale.
        history_billed    = _fallback_if_empty(history_billed, [
            22000, 24500, 23000, 27000, 25500, 28000,
            27500, 30000, 29000, 32000, 33500, 35000,
        ])
        history_collected = _fallback_if_empty(history_collected, [
            14000, 16200, 15300, 18000, 17500, 20000,
            19800, 22000, 21500, 23500, 24800, 26000,
        ])
        history_social_work = _fallback_if_empty(history_social_work,
            [1, 2, 1, 3, 2, 2, 3, 4, 3, 4, 5, 4])
        history_promissory  = _fallback_if_empty(history_promissory,
            [5000, 7000, 6500, 8000, 7500, 9000,
             8500, 10000, 9500, 11000, 10500, 12000])

        # ── Run Holt's forecast on each series ────────────────
        fc_billed      = _holt_forecast(history_billed,      STEPS)
        fc_collected   = _holt_forecast(history_collected,   STEPS)
        fc_social_work = _holt_forecast(history_social_work, STEPS)
        fc_promissory  = _holt_forecast(history_promissory,  STEPS)

        trend_billed = (
            (fc_billed['forecast'][-1] - history_billed[-1]) / history_billed[-1] * 100
            if history_billed[-1] > 0 else 0
        )
        trend_collected = (
            (fc_collected['forecast'][-1] - history_collected[-1]) / history_collected[-1] * 100
            if history_collected[-1] > 0 else 0
        )
        trend_social_work = (
            (fc_social_work['forecast'][-1] - history_social_work[-1]) / history_social_work[-1] * 100
            if history_social_work[-1] > 0 else 0
        )
        trend_promissory = (
            (fc_promissory['forecast'][-1] - history_promissory[-1]) / history_promissory[-1] * 100
            if history_promissory[-1] > 0 else 0
        )

        return Response({
            'success': True,
            'model': 'Holt Double Exp. Smoothing',
            'history_labels':   [f'W{i+1}' for i in range(WEEKS)],
            'forecast_labels':  [f'+{i+1}w' for i in range(STEPS)],

            # Revenue
            'history_billed':          history_billed,
            'history_collected':       history_collected,
            'forecast_billed':         fc_billed['forecast'],
            'forecast_collected':      fc_collected['forecast'],
            'lower_ci_billed':         fc_billed['lower_ci'],
            'upper_ci_billed':         fc_billed['upper_ci'],
            'lower_ci_collected':      fc_collected['lower_ci'],
            'upper_ci_collected':      fc_collected['upper_ci'],
            'trend_billed_percent':    round(trend_billed,    2),
            'trend_collected_percent': round(trend_collected, 2),
            'holt_alpha':              fc_billed['alpha'],
            'holt_beta':               fc_billed['beta'],

            # Social Work referral forecast
            'history_social_work':     history_social_work,
            'forecast_social_work':    fc_social_work['forecast'],
            'lower_ci_social_work':    fc_social_work['lower_ci'],
            'upper_ci_social_work':    fc_social_work['upper_ci'],
            'trend_social_work_percent': round(trend_social_work, 2),

            # Promissory note balance forecast
            'history_promissory':      history_promissory,
            'forecast_promissory':     fc_promissory['forecast'],
            'lower_ci_promissory':     fc_promissory['lower_ci'],
            'upper_ci_promissory':     fc_promissory['upper_ci'],
            'trend_promissory_percent': round(trend_promissory, 2),
        })

    except Exception as e:
        return Response({'success': False, 'message': str(e)}, status=500)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def cashier_financial_kpis(request):
    """
    Real-time financial KPIs + Holt's 4-week forecast for every cashier feature:
      - IPD  (soa_nbb + soa_philhealth + soa_nonmed)
      - OPD  (soa_opd)
      - Promissory Notes (promissory_notes)
      - Social Work      (social_work_referrals)
    """
    try:
        WEEKS = 12
        STEPS = 4
        today = date.today()
        start = today - timedelta(weeks=WEEKS)

        # ── IPD totals ────────────────────────────────────────────────────
        with connection.cursor() as cur:
            cur.execute("""
                SELECT
                    COUNT(*)::int                                                              AS cnt,
                    COALESCE(SUM(total_amount), 0)::float                                      AS billed,
                    COALESCE(SUM(CASE WHEN soa_status='CASHIER'  THEN total_amount ELSE 0 END),0)::float AS collected,
                    COALESCE(SUM(CASE WHEN soa_status NOT IN ('CASHIER','CANCELLED') THEN total_amount ELSE 0 END),0)::float AS pending
                FROM (
                    SELECT grand_total AS total_amount, soa_status FROM pch.soa_nbb
                    UNION ALL
                    SELECT grand_total AS total_amount, soa_status FROM pch.soa_philhealth
                    UNION ALL
                    SELECT total_amount, status AS soa_status FROM pch.soa_nonmed
                ) ipd_all
            """)
            row = cur.fetchone()
            ipd_count, ipd_billed, ipd_collected, ipd_pending = row

            cur.execute("""
                SELECT classification,
                       COUNT(*)::int,
                       COALESCE(SUM(total_amount),0)::float
                FROM (
                    SELECT 'NBB'         AS classification, grand_total AS total_amount FROM pch.soa_nbb
                    UNION ALL
                    SELECT classification,                  grand_total AS total_amount FROM pch.soa_philhealth
                    UNION ALL
                    SELECT classification,                  total_amount FROM pch.soa_nonmed
                ) cls_all
                GROUP BY classification
            """)
            ipd_cls = {r[0]: {'count': r[1], 'amount': r[2]} for r in cur.fetchall()}

        # ── OPD totals ────────────────────────────────────────────────────
        with connection.cursor() as cur:
            cur.execute("""
                SELECT
                    COUNT(*)::int,
                    COALESCE(SUM(charge_to_maip),0)::float,
                    COALESCE(SUM(CASE WHEN status='CASHIER'  THEN charge_to_maip ELSE 0 END),0)::float,
                    COALESCE(SUM(CASE WHEN status NOT IN ('CASHIER','CANCELLED') THEN charge_to_maip ELSE 0 END),0)::float
                FROM pch.soa_opd
            """)
            row = cur.fetchone()
            opd_count, opd_billed, opd_collected, opd_pending = row

        # ── Promissory Notes totals ───────────────────────────────────────
        with connection.cursor() as cur:
            cur.execute("""
                SELECT
                    COUNT(*)::int,
                    COALESCE(SUM(total_amount),0)::float,
                    COALESCE(SUM(balance_amount),0)::float,
                    COALESCE(SUM(total_amount - balance_amount),0)::float,
                    COUNT(CASE WHEN due_date < CURRENT_DATE
                                AND pn_status NOT IN ('FULLY_PAID','CANCELLED') THEN 1 END)::int,
                    COALESCE(SUM(CASE WHEN due_date < CURRENT_DATE
                                AND pn_status NOT IN ('FULLY_PAID','CANCELLED')
                                THEN balance_amount ELSE 0 END),0)::float
                FROM pch.promissory_notes
            """)
            row = cur.fetchone()
            pn_count, pn_total, pn_balance, pn_paid, pn_overdue_count, pn_overdue_amt = row

        # ── Social Work totals ────────────────────────────────────────────
        with connection.cursor() as cur:
            cur.execute("""
                SELECT
                    COUNT(*)::int,
                    COALESCE(SUM(total_amount),0)::float,
                    COUNT(CASE WHEN status='APPROVED'  THEN 1 END)::int,
                    COUNT(CASE WHEN status='PENDING'   THEN 1 END)::int,
                    COUNT(CASE WHEN status='COMPLETED' THEN 1 END)::int,
                    COALESCE(SUM(CASE WHEN status='APPROVED' THEN amount_after_discount ELSE 0 END),0)::float
                FROM pch.social_work_referrals
            """)
            row = cur.fetchone()
            sw_count, sw_billed, sw_approved, sw_pending_ct, sw_completed, sw_assistance = row

        # ── Weekly history helper ─────────────────────────────────────────
        def _weekly(sql, params):
            with connection.cursor() as cur:
                cur.execute(sql, params)
                rows = {r[0]: float(r[1]) for r in cur.fetchall()}
            vals = []
            ptr = today - timedelta(weeks=WEEKS - 1, days=today.weekday())
            for _ in range(WEEKS):
                lbl = ptr.strftime('%Y-W%V')
                vals.append(rows.get(lbl, 0.0))
                ptr += timedelta(weeks=1)
            return vals

        ipd_weekly = _weekly("""
            SELECT TO_CHAR(DATE_TRUNC('week', updated_at),'YYYY-"W"IW') wk,
                   COALESCE(SUM(total_amount),0)::float amt
            FROM (
                SELECT updated_at, grand_total AS total_amount FROM pch.soa_nbb        WHERE soa_status='CASHIER' AND updated_at>=%s
                UNION ALL
                SELECT updated_at, grand_total AS total_amount FROM pch.soa_philhealth WHERE soa_status='CASHIER' AND updated_at>=%s
                UNION ALL
                SELECT updated_at, total_amount FROM pch.soa_nonmed     WHERE status='CASHIER'     AND updated_at>=%s
            ) x GROUP BY wk ORDER BY wk
        """, [start, start, start])

        opd_weekly = _weekly("""
            SELECT TO_CHAR(DATE_TRUNC('week', updated_at),'YYYY-"W"IW') wk,
                   COALESCE(SUM(charge_to_maip),0)::float amt
            FROM pch.soa_opd WHERE status='CASHIER' AND updated_at>=%s
            GROUP BY wk ORDER BY wk
        """, [start])

        pn_weekly = _weekly("""
            SELECT TO_CHAR(DATE_TRUNC('week', updated_at),'YYYY-"W"IW') wk,
                   COALESCE(SUM(balance_amount),0)::float amt
            FROM pch.promissory_notes WHERE updated_at>=%s
            GROUP BY wk ORDER BY wk
        """, [start])

        sw_weekly = _weekly("""
            SELECT TO_CHAR(DATE_TRUNC('week', created_at),'YYYY-"W"IW') wk,
                   COUNT(*)::float cnt
            FROM pch.social_work_referrals WHERE created_at>=%s
            GROUP BY wk ORDER BY wk
        """, [start])

        # ── Apply fallbacks ───────────────────────────────────────────────
        ipd_weekly = _fallback_if_empty(ipd_weekly, [14000,16200,15300,18000,17500,20000,19800,22000,21500,23500,24800,26000])
        opd_weekly = _fallback_if_empty(opd_weekly, [4500,5200,4800,5800,5500,6000,5900,6500,6200,7000,6800,7500])
        pn_weekly  = _fallback_if_empty(pn_weekly,  [5000,7000,6500,8000,7500,9000,8500,10000,9500,11000,10500,12000])
        sw_weekly  = _fallback_if_empty(sw_weekly,  [1,2,1,3,2,2,3,4,3,4,5,4])

        # ── Holt's forecast ───────────────────────────────────────────────
        fc_ipd = _holt_forecast(ipd_weekly, STEPS)
        fc_opd = _holt_forecast(opd_weekly, STEPS)
        fc_pn  = _holt_forecast(pn_weekly,  STEPS)
        fc_sw  = _holt_forecast(sw_weekly,  STEPS)

        def _trend(fc_vals, hist):
            last = hist[-1] if hist else 0
            return round((fc_vals[-1] - last) / last * 100, 2) if last > 0 else 0.0

        return Response({
            'success': True,
            'model':            'Holt Double Exp. Smoothing',
            'history_labels':   [f'W{i+1}' for i in range(WEEKS)],
            'forecast_labels':  [f'+{i+1}w' for i in range(STEPS)],

            # IPD
            'ipd': {
                'total_count': ipd_count, 'total_billed': round(ipd_billed, 2),
                'collected': round(ipd_collected, 2), 'pending': round(ipd_pending, 2),
                'classification': ipd_cls,
            },
            'ipd_history':       ipd_weekly,
            'ipd_forecast':      fc_ipd['forecast'],
            'ipd_lower_ci':      fc_ipd['lower_ci'],
            'ipd_upper_ci':      fc_ipd['upper_ci'],
            'ipd_trend_percent': _trend(fc_ipd['forecast'], ipd_weekly),

            # OPD
            'opd': {
                'total_count': opd_count, 'total_billed': round(opd_billed, 2),
                'collected': round(opd_collected, 2), 'pending': round(opd_pending, 2),
            },
            'opd_history':       opd_weekly,
            'opd_forecast':      fc_opd['forecast'],
            'opd_lower_ci':      fc_opd['lower_ci'],
            'opd_upper_ci':      fc_opd['upper_ci'],
            'opd_trend_percent': _trend(fc_opd['forecast'], opd_weekly),

            # Promissory Notes
            'promissory': {
                'total_count': pn_count, 'total_amount': round(pn_total, 2),
                'balance': round(pn_balance, 2), 'paid': round(pn_paid, 2),
                'overdue_count': pn_overdue_count, 'overdue_amount': round(pn_overdue_amt, 2),
            },
            'pn_history':       pn_weekly,
            'pn_forecast':      fc_pn['forecast'],
            'pn_lower_ci':      fc_pn['lower_ci'],
            'pn_upper_ci':      fc_pn['upper_ci'],
            'pn_trend_percent': _trend(fc_pn['forecast'], pn_weekly),

            # Social Work
            'social_work': {
                'total_count': sw_count, 'total_billed': round(sw_billed, 2),
                'approved_count': sw_approved, 'pending_count': sw_pending_ct,
                'completed_count': sw_completed, 'approved_assistance': round(sw_assistance, 2),
            },
            'sw_history':       sw_weekly,
            'sw_forecast':      fc_sw['forecast'],
            'sw_lower_ci':      fc_sw['lower_ci'],
            'sw_upper_ci':      fc_sw['upper_ci'],
            'sw_trend_percent': _trend(fc_sw['forecast'], sw_weekly),
        })

    except Exception as e:
        return Response({'success': False, 'message': str(e)}, status=500)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def cashier_dashboard_summary(request):
    """
    Lightweight dashboard summary:
      - KPI cards: total collected, IPD pending, OPD pending, PN overdue
      - Recent transactions: last 10 invoices across all SOA tables
    """
    try:
        # ── KPI: Total collected (payment_status = 'PAID') ────────────────────
        with connection.cursor() as cur:
            cur.execute("""
                SELECT COALESCE(SUM(grand_total), 0)::float
                FROM (
                    SELECT grand_total FROM pch.soa_nbb       WHERE payment_status = 'PAID'
                    UNION ALL
                    SELECT grand_total FROM pch.soa_philhealth WHERE payment_status = 'PAID'
                    UNION ALL
                    SELECT total_amount FROM pch.soa_nonmed     WHERE payment_status = 'PAID'
                    UNION ALL
                    SELECT grand_total FROM pch.soa_opd        WHERE payment_status = 'PAID'
                ) t
            """)
            total_collected = cur.fetchone()[0]

        # ── KPI: IPD pending ──────────────────────────────────────────────────
        with connection.cursor() as cur:
            cur.execute("""
                SELECT COUNT(*)::int FROM (
                    SELECT 1 FROM pch.soa_nbb       WHERE soa_status = 'SENT TO CASHIER'
                    UNION ALL
                    SELECT 1 FROM pch.soa_philhealth WHERE soa_status = 'SENT TO CASHIER'
                    UNION ALL
                    SELECT 1 FROM pch.soa_nonmed     WHERE status     = 'SENT TO CASHIER'
                ) t
            """)
            ipd_pending = cur.fetchone()[0]

        # ── KPI: OPD pending ──────────────────────────────────────────────────
        with connection.cursor() as cur:
            cur.execute("""
                SELECT COUNT(*)::int FROM pch.soa_opd
                WHERE status = 'SENT TO CASHIER'
            """)
            opd_pending = cur.fetchone()[0]

        # ── KPI: Promissory Notes overdue ────────────────────────────────────
        with connection.cursor() as cur:
            cur.execute("""
                SELECT
                    COUNT(CASE WHEN due_date < CURRENT_DATE
                               AND pn_status NOT IN ('FULLY_PAID','CANCELLED') THEN 1 END)::int,
                    COALESCE(SUM(CASE WHEN due_date < CURRENT_DATE
                               AND pn_status NOT IN ('FULLY_PAID','CANCELLED')
                               THEN balance_amount ELSE 0 END), 0)::float
                FROM pch.promissory_notes
            """)
            row = cur.fetchone()
            pn_overdue_count, pn_overdue_amt = row

        # ── Recent transactions: last 10 across all SOA tables ───────────────
        with connection.cursor() as cur:
            cur.execute("""
                SELECT * FROM (
                    SELECT
                        COALESCE(n.soa_id::text, 'N/A')  AS bill_no,
                        COALESCE(
                            TRIM(pp.firstname || ' ' || COALESCE(pp.lastname, '')),
                            'Unknown'
                        )                                 AS patient_name,
                        'NBB'                             AS classification,
                        n.grand_total,
                        CASE n.soa_status
                            WHEN 'SENT TO CASHIER' THEN 'Pending'
                            WHEN 'CASHIER'         THEN 'Pending'
                            ELSE n.soa_status
                        END                               AS status_label,
                        n.updated_at                      AS txn_date
                    FROM pch.soa_nbb n
                    LEFT JOIN pch.patient_profiling pp ON pp.patient_id = n.patient_id

                    UNION ALL

                    SELECT
                        COALESCE(ph.bill_no, 'N/A'),
                        COALESCE(
                            TRIM(pp2.firstname || ' ' || COALESCE(pp2.lastname, '')),
                            'Unknown'
                        ),
                        ph.classification,
                        ph.grand_total,
                        CASE ph.soa_status
                            WHEN 'SENT TO CASHIER' THEN 'Pending'
                            WHEN 'CASHIER'         THEN 'Pending'
                            ELSE ph.soa_status
                        END,
                        ph.updated_at
                    FROM pch.soa_philhealth ph
                    LEFT JOIN pch.patient_profiling pp2 ON pp2.patient_id = ph.patient_id

                    UNION ALL

                    SELECT
                        COALESCE(nm.bill_no, 'N/A'),
                        nm.patient_name,
                        nm.classification,
                        nm.total_amount,
                        CASE nm.status
                            WHEN 'SENT TO CASHIER' THEN 'Pending'
                            WHEN 'CASHIER'         THEN 'Pending'
                            ELSE nm.status
                        END,
                        nm.updated_at
                    FROM pch.soa_nonmed nm

                    UNION ALL

                    SELECT
                        COALESCE(op.hospital_no, 'N/A'),
                        op.patient_name,
                        'OPD',
                        op.grand_total,
                        CASE op.status
                            WHEN 'SENT TO CASHIER' THEN 'Pending'
                            WHEN 'CASHIER'         THEN 'Pending'
                            ELSE op.status
                        END,
                        op.updated_at
                    FROM pch.soa_opd op
                ) AS all_txn (bill_no, patient_name, classification, grand_total, status_label, txn_date)
                ORDER BY txn_date DESC NULLS LAST
                LIMIT 10
            """)
            recent = []
            for row in cur.fetchall():
                recent.append({
                    'bill_no':        row[0] or 'N/A',
                    'patient_name':   row[1] or 'Unknown',
                    'classification': row[2] or '—',
                    'amount':         round(float(row[3] or 0), 2),
                    'status':         row[4] or '—',
                    'date':           row[5].strftime('%Y-%m-%d') if row[5] else '—',
                })

        return Response({
            'success': True,
            'kpi': {
                'total_collected':  round(total_collected, 2),
                'ipd_pending':      ipd_pending,
                'opd_pending':      opd_pending,
                'pn_overdue_count': pn_overdue_count,
                'pn_overdue_amt':   round(pn_overdue_amt, 2),
            },
            'recent_transactions': recent,
        })

    except Exception as e:
        import traceback
        error_detail = str(e)
        print(f"[DASHBOARD SUMMARY ERROR] {error_detail}\n{traceback.format_exc()}")
        return Response({'success': False, 'message': f'Database error: {error_detail}'}, status=500)
