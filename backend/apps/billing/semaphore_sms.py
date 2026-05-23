import threading
import time
import logging
import requests
from concurrent.futures import ThreadPoolExecutor, as_completed

logger = logging.getLogger(__name__)

SEMAPHORE_API_KEY = 'b0c6e04b6f0a25f5e867eee7f399cf64'
SEMAPHORE_API_URL = 'https://api.semaphore.co/api/v4/messages'
SENDER_NAME       = 'PCHBILLING'

# Create a session for connection pooling (faster subsequent requests)
_session = requests.Session()

# Reminder schedule: (delay_in_seconds, day_label)
REMINDER_SCHEDULE = [
    (3  * 24 * 3600, '3 days'),
    (7  * 24 * 3600, '7 days'),
    (15 * 24 * 3600, '15 days'),
    (30 * 24 * 3600, '30 days'),
]


def _normalize_number(contact: str) -> str:
    """Convert 09XXXXXXXXX → 639XXXXXXXXX for Semaphore."""
    number = contact.strip()
    # Remove any non-digit characters
    number = ''.join(c for c in number if c.isdigit())
    if number.startswith('0'):
        number = '63' + number[1:]
    return number


def _send_sms(contact: str, message: str):
    """Send a single SMS via Semaphore API. Returns (True, None) or (False, error_str)."""
    try:
        number = _normalize_number(contact)
        
        print(f'[SMS DEBUG] ========================================')
        print(f'[SMS DEBUG] Sending SMS to: {number}')
        print(f'[SMS DEBUG] Sender: {SENDER_NAME}')
        print(f'[SMS DEBUG] Message: {message[:50]}...')
        print(f'[SMS DEBUG] ========================================')
        
        payload = {
            'apikey':     SEMAPHORE_API_KEY,
            'number':     number,
            'message':    message,
            'sendername': SENDER_NAME,
        }
        
        print(f'[SMS DEBUG] Payload: {payload}')
        
        # Use session for connection pooling (faster)
        response = _session.post(
            SEMAPHORE_API_URL,
            data=payload,
            timeout=10  # Reduced from 15s for faster failure detection
        )
        
        print(f'[SMS DEBUG] Response Status: {response.status_code}')
        print(f'[SMS DEBUG] Response Body: {response.text}')
        
        if response.status_code == 200:
            try:
                result = response.json()
                print(f'[SMS DEBUG] Parsed JSON: {result}')
                
                # Check if message was accepted
                if isinstance(result, list) and len(result) > 0:
                    msg_result = result[0]
                    status = msg_result.get('status', '')
                    
                    if status == 'Pending' or status == 'Sent':
                        logger.info(f'[SMS] Successfully sent to {number}')
                        print(f'[SMS DEBUG] SUCCESS - Message ID: {msg_result.get("message_id", "N/A")}')
                        return True, None
                    else:
                        error_msg = msg_result.get('message', 'Unknown error')
                        print(f'[SMS DEBUG] FAILED - Status: {status}, Error: {error_msg}')
                        return False, f'Semaphore status: {status} - {error_msg}'
                else:
                    # Single message response
                    if result.get('status') in ['Pending', 'Sent', 'success']:
                        logger.info(f'[SMS] Successfully sent to {number}')
                        return True, None
                    else:
                        error_msg = result.get('message', result.get('error', 'Unknown error'))
                        print(f'[SMS DEBUG] FAILED: {error_msg}')
                        return False, str(error_msg)
                        
            except Exception as e:
                print(f'[SMS DEBUG] JSON parse error: {e}')
                # If we got 200, assume success even if JSON parsing failed
                logger.info(f'[SMS] Sent to {number} (status 200)')
                return True, None
        else:
            err = f'Semaphore HTTP {response.status_code}: {response.text}'
            print(f'[SMS DEBUG] HTTP ERROR: {err}')
            return False, err
            
    except requests.exceptions.RequestException as e:
        err = f'Request failed: {str(e)}'
        print(f'[SMS DEBUG] REQUEST EXCEPTION: {err}')
        return False, err
    except Exception as e:
        err = f'Unexpected error: {str(e)}'
        print(f'[SMS DEBUG] EXCEPTION: {err}')
        return False, err


def _send_sms_worker(number: str, message: str):
    """Worker function for concurrent SMS sending. Returns (number, ok, error)."""
    ok, err = _send_sms(number, message)
    return number, ok, err


def send_pn_confirmation(contact: str, patient: str, total: float,
                         down_payment: float, remaining: float, due_date: str):
    """
    Send the immediate confirmation SMS to one or more contacts CONCURRENTLY.
    Supports comma-separated phone numbers.
    Returns (all_ok, errors_dict) where errors_dict maps failed numbers to error messages.
    """
    print(f'[SMS] Starting concurrent send to: {contact}')
    start_time = time.time()
    
    message = (
        f"Dear {patient}, your Promissory Note at Plaridel Community Hospital "
        f"has been registered. Please go back to the hospital. "
        f"Total: P{total:,.2f}, Down Payment: P{down_payment:,.2f}, "
        f"Balance: P{remaining:,.2f}. Due: {due_date}. "
        f"For inquiries, contact our hospital staff. Thank you."
    )
    
    # Handle multiple numbers (comma-separated)
    numbers = [n.strip() for n in contact.split(',') if n.strip()]
    errors = {}
    
    if len(numbers) == 1:
        # Single number - no need for thread pool
        ok, err = _send_sms(numbers[0], message)
        if not ok:
            errors[numbers[0]] = err
    else:
        # Multiple numbers - send concurrently with thread pool
        print(f'[SMS] Sending to {len(numbers)} numbers concurrently...')
        with ThreadPoolExecutor(max_workers=min(len(numbers), 5)) as executor:
            # Submit all tasks
            future_to_number = {
                executor.submit(_send_sms_worker, num, message): num 
                for num in numbers
            }
            
            # Collect results as they complete
            for future in as_completed(future_to_number):
                number, ok, err = future.result()
                if not ok:
                    errors[number] = err
    
    elapsed = time.time() - start_time
    print(f'[SMS] Completed in {elapsed:.2f}s - {len(numbers) - len(errors)}/{len(numbers)} successful')
    
    all_ok = len(errors) == 0
    return all_ok, errors if errors else None


def _reminder_worker(contact: str, patient: str, remaining: float,
                     due_date: str, delay_seconds: int, day_label: str,
                     is_final: bool):
    """Sleep then send one reminder SMS."""
    time.sleep(delay_seconds)
    if is_final:
        message = (
            f"FINAL NOTICE - Dear {patient}, your outstanding balance of "
            f"P{remaining:,.2f} at Plaridel Community Hospital is NOW OVERDUE "
            f"(due {due_date}). Please go back to the hospital immediately "
            f"to settle your account. Contact our hospital staff. Thank you."
        )
    else:
        message = (
            f"Reminder ({day_label}): Dear {patient}, your remaining balance of "
            f"P{remaining:,.2f} at Plaridel Community Hospital is due on {due_date}. "
            f"Please go back to the hospital to settle your account. "
            f"Contact our hospital staff. Thank you."
        )
    ok, err = _send_sms(contact, message)
    if not ok:
        print(f'[SMS DEBUG] Reminder failed for {contact}: {err}')


def schedule_pn_reminders(contact: str, patient: str,
                           remaining: float, due_date: str):
    """
    Schedule SMS reminders at 3, 7, 15, and 30 days after PN generation.
    Supports comma-separated phone numbers - schedules for all numbers.
    Each runs in a background daemon thread so the API response is immediate.
    The 30-day message is marked as the final/overdue notice.
    """
    # Handle multiple numbers (comma-separated)
    numbers = [n.strip() for n in contact.split(',') if n.strip()]
    
    for number in numbers:
        for i, (delay_sec, day_label) in enumerate(REMINDER_SCHEDULE):
            is_final = (i == len(REMINDER_SCHEDULE) - 1)
            t = threading.Thread(
                target=_reminder_worker,
                args=(number, patient, remaining, due_date, delay_sec, day_label, is_final),
                daemon=True,
            )
            t.start()
            logger.info(f'[SMS] Scheduled {day_label} reminder for {number}')
