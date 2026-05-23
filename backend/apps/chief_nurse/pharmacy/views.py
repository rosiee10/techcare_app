"""
Chief Nurse - Pharmacy Views
All pharmacy-related API views for Chief Nurse.
Transferred from main chief_nurse/views.py
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


class PharmacyDashboardView(APIView):
    """
    Dashboard data for chief nurse pharmacy section.
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        """Get pharmacy dashboard stats"""
        try:
            # Reuse the existing stats function
            from .views import get_pharmacy_pr_stats
            return get_pharmacy_pr_stats(request)
        except Exception as e:
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_pharmacy_purchase_requests(request):
    """
    Get all pharmacy purchase requests for Chief Nurse review.
    Fetches from pharmacy_purchase_requests and pharmacy_purchase_request_items tables.
    Includes goods receipt item data for delivered purchase requests.
    """
    try:
        with connection.cursor() as cursor:
            purchase_requests = []
            
            # Get pharmacy purchase requests
            cursor.execute("""
                SELECT 
                    pr.pr_id,
                    pr.pr_no,
                    pr.pr_status,
                    pr.requested_date,
                    pr.purchase_type,
                    pr.expected_arrival_date,
                    pr.cancel_reason
                FROM pharmacy_purchase_requests pr
                ORDER BY pr.requested_date DESC
            """)
            
            columns = [col[0] for col in cursor.description]
            
            for row in cursor.fetchall():
                pr_dict = dict(zip(columns, row))
                pr_dict['source'] = 'pharmacy'
                
                # Get items for this purchase request
                cursor.execute("""
                    SELECT 
                        pri.pr_item_id,
                        pri.qty_requested,
                        pri.unit_snapshot,
                        pri.unit_cost_estimate,
                        pri.line_total_estimate,
                        pri.medicine_name
                    FROM pharmacy_purchase_request_items pri
                    WHERE pri.pr_id = %s
                """, [pr_dict['pr_id']])
                
                item_columns = [col[0] for col in cursor.description]
                items = []
                for item_row in cursor.fetchall():
                    item_dict = dict(zip(item_columns, item_row))
                    
                    # If PR is delivered, fetch goods receipt item data
                    if pr_dict['pr_status'] == 'DELIVERED':
                        cursor.execute("""
                            SELECT 
                                qty_received,
                                unit_cost_actual,
                                line_total_actual
                            FROM pharmacy_goods_receipt_items
                            WHERE pr_item_id = %s
                            LIMIT 1
                        """, [item_dict['pr_item_id']])
                        
                        gri_row = cursor.fetchone()
                        if gri_row:
                            item_dict['goods_receipt_item'] = {
                                'qty_received': float(gri_row[0]) if gri_row[0] is not None else None,
                                'unit_cost_actual': float(gri_row[1]) if gri_row[1] is not None else None,
                                'line_total_actual': float(gri_row[2]) if gri_row[2] is not None else None,
                            }
                        else:
                            item_dict['goods_receipt_item'] = None
                    
                    items.append(item_dict)
                
                pr_dict['items'] = items
                purchase_requests.append(pr_dict)

            return Response({
                'success': True,
                'purchase_requests': purchase_requests
            }, status=status.HTTP_200_OK)
            
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def approve_pharmacy_purchase_request(request, pr_id):
    """
    Approve or reject a pharmacy or medistock purchase request.
    Updates pr_status in the appropriate table.
    Chief Nurse can also edit final quantities before approval.
    """
    try:
        data = request.data
        action = data.get('action', '').upper()  # APPROVED or REJECTED
        remarks = data.get('remarks', '')
        updated_items = data.get('updated_items', [])
        source = data.get('source', '')  # 'pharmacy' or 'medistock'

        if action not in ['APPROVED', 'REJECTED']:
            return Response({
                'success': False,
                'error': 'Invalid action. Must be APPROVED or REJECTED'
            }, status=status.HTTP_400_BAD_REQUEST)

        with connection.cursor() as cursor:
            # Determine which table the PR is in
            is_pharmacy = False
            is_medistock = False
            current_status = None

            if source == 'pharmacy':
                cursor.execute("""
                    SELECT pr_status FROM pharmacy_purchase_requests
                    WHERE pr_id = %s
                """, [pr_id])
                result = cursor.fetchone()
                if result:
                    is_pharmacy = True
                    current_status = result[0]
            elif source == 'medistock':
                cursor.execute("""
                    SELECT pr_status FROM medistock_purchase_requests
                    WHERE pr_id = %s
                """, [pr_id])
                result = cursor.fetchone()
                if result:
                    is_medistock = True
                    current_status = result[0]
            else:
                # Auto-detect: check pharmacy first, then medistock
                cursor.execute("""
                    SELECT pr_status FROM pharmacy_purchase_requests
                    WHERE pr_id = %s
                """, [pr_id])
                result = cursor.fetchone()
                if result:
                    is_pharmacy = True
                    current_status = result[0]
                else:
                    cursor.execute("""
                        SELECT pr_status FROM medistock_purchase_requests
                        WHERE pr_id = %s
                    """, [pr_id])
                    result = cursor.fetchone()
                    if result:
                        is_medistock = True
                        current_status = result[0]

            if not result:
                return Response({
                    'success': False,
                    'error': 'Purchase request not found'
                }, status=status.HTTP_404_NOT_FOUND)

            # Allow approval for SUBMITTED, DRAFT, or FOR_APPROVAL status
            if current_status not in ['SUBMITTED', 'DRAFT', 'FOR_APPROVAL']:
                return Response({
                    'success': False,
                    'error': f'Cannot {action.lower()} PR with status: {current_status}'
                }, status=status.HTTP_400_BAD_REQUEST)

            if is_pharmacy:
                # Update item quantities if provided (for APPROVED)
                if action == 'APPROVED' and updated_items:
                    for item in updated_items:
                        approved_qty = item.get('approved_qty', item.get('qty_requested', 0))
                        unit_cost = item.get('unit_cost_estimate', 0)
                        cursor.execute("""
                            UPDATE pharmacy_purchase_request_items
                            SET qty_requested = %s,
                                line_total_estimate = %s * %s
                            WHERE pr_item_id = %s AND pr_id = %s
                        """, [
                            approved_qty,
                            approved_qty,
                            unit_cost,
                            item['pr_item_id'],
                            pr_id
                        ])

                # Update purchase request status
                cursor.execute("""
                    UPDATE pharmacy_purchase_requests
                    SET pr_status = %s, updated_at = NOW()
                    WHERE pr_id = %s
                """, [action, pr_id])

                # Get updated PR for response (include cancel_reason to check CSD link)
                cursor.execute("""
                    SELECT
                        pr.pr_id,
                        pr.pr_no,
                        pr.pr_status,
                        pr.requested_date,
                        pr.cancel_reason
                    FROM pharmacy_purchase_requests pr
                    WHERE pr.pr_id = %s
                """, [pr_id])

                columns = [col[0] for col in cursor.description]
                updated_pr = dict(zip(columns, cursor.fetchone()))
                updated_pr['source'] = 'pharmacy'

                # If this pharmacy PR is linked to a medistock PR, update medistock too
                cancel_reason = updated_pr.get('cancel_reason') or ''
                if cancel_reason.startswith('CSD_ORIGIN:'):
                    try:
                        medistock_pr_id = int(cancel_reason.split(':')[1])
                        cursor.execute("""
                            UPDATE medistock_purchase_requests
                            SET pr_status = %s, updated_at = NOW()
                            WHERE pr_id = %s
                        """, [action, medistock_pr_id])
                        print(f"DEBUG: Updated medistock PR {medistock_pr_id} status to {action}")
                    except (ValueError, IndexError) as e:
                        print(f"DEBUG: Failed to parse medistock_pr_id from cancel_reason: {cancel_reason}, error: {e}")

            elif is_medistock:
                # Update item quantities if provided (for APPROVED)
                if action == 'APPROVED' and updated_items:
                    for item in updated_items:
                        approved_qty = item.get('approved_qty', item.get('qty_requested', 0))
                        unit_cost = item.get('unit_cost_estimate', 0)
                        cursor.execute("""
                            UPDATE medistock_purchase_request_items
                            SET qty_requested = %s,
                                line_total_estimate = %s * %s
                            WHERE pr_item_id = %s AND purchase_request_id = %s
                        """, [
                            approved_qty,
                            approved_qty,
                            unit_cost,
                            item['pr_item_id'],
                            pr_id
                        ])

                # Update purchase request status
                cursor.execute("""
                    UPDATE medistock_purchase_requests
                    SET pr_status = %s, updated_at = NOW()
                    WHERE pr_id = %s
                """, [action, pr_id])

                # Get updated PR for response
                cursor.execute("""
                    SELECT
                        pr.pr_id,
                        pr.pr_no,
                        pr.pr_status,
                        pr.pr_date as requested_date
                    FROM medistock_purchase_requests pr
                    WHERE pr.pr_id = %s
                """, [pr_id])

                columns = [col[0] for col in cursor.description]
                updated_pr = dict(zip(columns, cursor.fetchone()))
                updated_pr['source'] = 'medistock'

            return Response({
                'success': True,
                'message': f'Purchase request {action.lower()} successfully',
                'purchase_request': updated_pr
            }, status=status.HTTP_200_OK)

    except Exception as e:
        import traceback
        print(traceback.format_exc())
        return Response({
            'success': False,
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_pharmacy_pr_stats(request):
    """
    Get pharmacy purchase request statistics for Chief Nurse dashboard.
    Counts by status: Pending, Approved, On Delivery, Delivered, Rejected.
    """
    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT 
                    COUNT(*) FILTER (WHERE pr_status IN ('SUBMITTED', 'DRAFT')) as pending,
                    COUNT(*) FILTER (WHERE pr_status = 'APPROVED') as approved,
                    COUNT(*) FILTER (WHERE pr_status = 'ON_DELIVERY') as on_delivery,
                    COUNT(*) FILTER (WHERE pr_status = 'DELIVERED') as delivered,
                    COUNT(*) FILTER (WHERE pr_status IN ('CANCELLED', 'REJECTED')) as rejected,
                    COUNT(*) as total
                FROM pharmacy_purchase_requests
            """)
            
            row = cursor.fetchone()
            stats = {
                'pending': row[0] or 0,
                'approved': row[1] or 0,
                'on_delivery': row[2] or 0,
                'delivered': row[3] or 0,
                'rejected': row[4] or 0,
                'total': row[5] or 0,
            }
            
            return Response({
                'success': True,
                'stats': stats
            }, status=status.HTTP_200_OK)
            
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
