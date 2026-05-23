import json
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST, require_GET
from django.http import JsonResponse
from .semaphore_sms import send_pn_confirmation, schedule_pn_reminders, _send_sms


@require_GET
def test_sms(request):
    """
    GET /api/billing/sms/test/?number=09XXXXXXXXX
    Test endpoint to verify SMS is working.
    """
    number = request.GET.get('number', '').strip()
    if not number:
        return JsonResponse({'success': False, 'error': 'number parameter required'}, status=400)
    
    # Send test message
    ok, err = _send_sms(number, "This is a test message from Plaridel Community Hospital. Your SMS system is working!")
    
    if ok:
        return JsonResponse({'success': True, 'message': f'Test SMS sent to {number}'})
    else:
        return JsonResponse({'success': False, 'error': err}, status=500)


@csrf_exempt
@require_POST
def send_pn_sms(request):
    """
    POST /api/billing/sms/send-pn/
    Body (JSON):
      {
        "contact":      "09XXXXXXXXX",
        "patient":      "Juan Dela Cruz",
        "total":        25400.00,
        "down_payment": 2000.00,
        "remaining":    23400.00,
        "due_date":     "2026-06-18"
      }
    Sends an immediate confirmation SMS and schedules
    reminders at 3, 7, 15, and 30 days.
    """
    try:
        data = json.loads(request.body)
    except (json.JSONDecodeError, Exception):
        return JsonResponse({'success': False, 'error': 'Invalid JSON body'}, status=400)

    contact      = data.get('contact', '').strip()
    patient      = data.get('patient', 'Patient').strip()
    total        = float(data.get('total', 0))
    down_payment = float(data.get('down_payment', 0))
    remaining    = float(data.get('remaining', 0))
    due_date     = data.get('due_date', '').strip()

    print(f'[PN SMS] Request received: contact={contact}, patient={patient}, total={total}, due={due_date}')

    if not contact or not due_date:
        return JsonResponse({'success': False, 'error': 'contact and due_date are required'}, status=400)

    # 1. Send immediate confirmation SMS to all numbers (blocking — get actual result)
    # Supports comma-separated numbers for multiple recipients
    sms_ok, sms_errors = send_pn_confirmation(contact, patient, total, down_payment, remaining, due_date)
    
    numbers_list = [n.strip() for n in contact.split(',') if n.strip()]
    print(f'[PN SMS] Semaphore result: {"OK" if sms_ok else "PARTIAL/FAIL"} for {len(numbers_list)} number(s)')
    
    if sms_errors:
        for num, err in sms_errors.items():
            print(f'[PN SMS] Failed for {num}: {err}')

    # Partial success - some numbers failed
    if not sms_ok and sms_errors:
        failed_numbers = list(sms_errors.keys())
        successful_numbers = [n for n in numbers_list if n not in failed_numbers]
        
        # Schedule reminders only for successful numbers
        if successful_numbers:
            successful_contact = ','.join(successful_numbers)
            schedule_pn_reminders(successful_contact, patient, remaining, due_date)
        
        return JsonResponse({
            'success': len(successful_numbers) > 0,  # Success if at least one went through
            'partial': True,
            'message': f'Sent to {len(successful_numbers)}/{len(numbers_list)} number(s)',
            'failed': failed_numbers,
            'errors': sms_errors
        })
    
    # Complete failure - all numbers failed
    if not sms_ok:
        return JsonResponse({
            'success': False,
            'error': 'All SMS attempts failed',
            'errors': sms_errors
        }, status=200)

    # 2. Schedule reminders (3 / 7 / 15 / 30 days) in background threads for all successful numbers
    schedule_pn_reminders(contact, patient, remaining, due_date)

    # All succeeded
    return JsonResponse({
        'success': True,
        'message': f'SMS sent to {len(numbers_list)} number(s) and reminders scheduled',
        'recipients': numbers_list
    })
