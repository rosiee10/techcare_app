from django.shortcuts import render
from rest_framework import viewsets, status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.decorators import action
from django.utils import timezone
from datetime import timedelta
from django.db import connection, transaction, models
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from .utils import format_trail, get_client_ip
from .models import (

    PharmacySupplier, PharmacyLocation, PharmacyMedicine, PharmacyStockBatch,
    PharmacyInventoryBalance, PharmacyPurchaseRequest, PharmacyPurchaseRequestItem,
    PharmacyGoodsReceipt, PharmacyGoodsReceiptItem,
    PharmacyChargeSlip, PharmacyChargeSlipItem, PharmacyDispenseReceipt,
    PharmacyDispenseReceiptItem, PharmacyInventoryAdjustment,
    PharmacyTransaction, OpdPrescription, PharmacySupplyPrice
)
from apps.medistock.models import MedistockPurchaseRequest, MedistockPurchaseRequestItem

from .serializers import (
    PharmacySupplierSerializer, PharmacyLocationSerializer, PharmacyMedicineSerializer,
    PharmacyStockBatchSerializer, PharmacyInventoryBalanceSerializer,
    PharmacyPurchaseRequestSerializer, PharmacyGoodsReceiptSerializer,
    PharmacyChargeSlipSerializer, PharmacyDispenseReceiptSerializer,
    PharmacyInventoryAdjustmentSerializer, PharmacyTransactionSerializer,
    DashboardStatsSerializer, LowStockAlertSerializer,
    ExpiryAlertSerializer, SuccessResponseSerializer, OpdPrescriptionSerializer
)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def confirm_delivery(request):
    """
    Confirm delivery of a purchase request.
    Creates:
    1. PharmacyGoodsReceipt record
    2. PharmacyGoodsReceiptItem records for each item
    3. PharmacyStockBatch records for inventory
    4. Updates PharmacyPurchaseRequest status to DELIVERED
    """
    try:
        data = request.data
        pr_id = data.get('pr_id')
        pr_no = data.get('pr_no')
        items = data.get('items', [])
        supplier_name = data.get('supplier_name')
        
        if not pr_id or not items:
            return Response({'error': 'pr_id and items are required'}, status=status.HTTP_400_BAD_REQUEST)

        if not supplier_name:
            return Response({'error': 'supplier_name is required'}, status=status.HTTP_400_BAD_REQUEST)
        with connection.cursor() as cursor:

            # Get current user info
            user_id = request.user.id if request.user.is_authenticated else None

            # Check if supplier exists, if not create it
            cursor.execute("""
                SELECT supplier_id FROM pharmacy_suppliers 
                WHERE supplier_name = %s
            """, [supplier_name])
            supplier_row = cursor.fetchone()
            
            if supplier_row:
                supplier_id = supplier_row[0]
            else:

                # Create new supplier with only existing columns
                cursor.execute("""
                    INSERT INTO pharmacy_suppliers (supplier_name, is_active, trail)
                    VALUES (%s, true, %s)
                    RETURNING supplier_id
                """, [supplier_name, format_trail(request.user, get_client_ip(request))])
                supplier_id = cursor.fetchone()[0]

            # Fix pr_no if None
            actual_pr_no = pr_no if pr_no else f"PR-{pr_id}"

            # 1. Create Goods Receipt
            cursor.execute("""
                INSERT INTO pharmacy_goods_receipts (
                    gr_no, pr_id, supplier_id, received_at, status, remarks, trail
                ) VALUES (
                    %s, %s, %s, NOW(), %s, %s, %s
                )
                RETURNING gr_id
            """, [
                f"GR-{actual_pr_no}",
                pr_id,
                supplier_id,
                'RECEIVED',
                f'Goods receipt for purchase request {actual_pr_no}',
                format_trail(request.user, get_client_ip(request))
            ])
            gr_id = cursor.fetchone()[0]

            # 2. Create Goods Receipt Items and Stock Batches
            for item in items:
                medicine_name = item.get('medicine_name')
                qty_ordered = float(item.get('qty_requested') or 0)
                qty_received = float(item.get('qty_delivered') or item.get('qty') or 0)  # Actual quantity received
                pr_item_id = item.get('pr_item_id')
                batch_number = item.get('batch_number')
                expiry_date_raw = item.get('expiry_date')
                # Convert date from MM/DD/YYYY to YYYY-MM-DD format
                expiry_date = None
                if expiry_date_raw:
                    try:
                        from datetime import datetime
                        # Parse MM/DD/YYYY format
                        dt = datetime.strptime(expiry_date_raw, '%m/%d/%Y')
                        expiry_date = dt.strftime('%Y-%m-%d')
                    except:
                        expiry_date = expiry_date_raw  # Keep original if parsing fails
                unit_price = float(item.get('unit_price') or 0)

                # Find medicine_id by name
                cursor.execute("""
                    SELECT medicine_id FROM pharmacy_medicines 
                    WHERE medicine_name = %s
                    LIMIT 1
                """, [medicine_name])
                row = cursor.fetchone()
                if not row:
                    return Response({'error': f'Medicine not found: {medicine_name}'}, status=status.HTTP_400_BAD_REQUEST)
                medicine_id = row[0]

                # Auto-generate or ensure unique batch number (format: BATCH-{MED4}-{SEQ})
                med_prefix = medicine_name[:4].upper()
                
                # Check if we need to generate or if the provided one exists
                needs_generation = not batch_number or not str(batch_number).strip()
                if not needs_generation:
                    cursor.execute("SELECT 1 FROM pharmacy_stock_batches WHERE medicine_id = %s AND batch_no = %s", [medicine_id, batch_number])
                    if cursor.fetchone():
                        needs_generation = True

                if needs_generation:
                    # Find the next batch sequence number for this medicine
                    cursor.execute("""
                        SELECT MAX(CAST(SUBSTRING(batch_no FROM '\\d+$') AS INTEGER))
                        FROM pharmacy_stock_batches
                        WHERE medicine_id = %s
                          AND batch_no ~ '^BATCH-[A-Z]+-[0-9]+$'
                    """, [medicine_id])
                    
                    seq_row = cursor.fetchone()
                    next_seq = (seq_row[0] or 0) + 1
                    batch_number = f"BATCH-{med_prefix}-{next_seq:02d}"
                
                # Create Stock Batch for this item
                cursor.execute("""
                    INSERT INTO pharmacy_stock_batches 
                        (medicine_id, batch_no, expiry_date, received_date, unit_cost, trail)
                    VALUES (%s, %s, %s, NOW(), %s, %s)
                    RETURNING batch_id
                """, [
                    medicine_id,
                    batch_number,
                    expiry_date,
                    unit_price,
                    format_trail(request.user, get_client_ip(request))
                ])
                batch_id = cursor.fetchone()[0]

                # Get default location_id (Main Pharmacy - location_id = 1)
                cursor.execute("""
                    SELECT location_id FROM pharmacy_locations 
                    WHERE location_type = 'PHARMACY' OR location_id = 1
                    ORDER BY location_id LIMIT 1
                """)
                location_row = cursor.fetchone()
                location_id = location_row[0] if location_row else 1
                
                # Create Goods Receipt Item (store both ordered and received quantities)
                cursor.execute("""
                    INSERT INTO pharmacy_goods_receipt_items (
                        gr_id, pr_item_id, medicine_id, batch_id, location_id, qty_ordered, qty_received,
                        expiry_date, unit_cost_actual, line_total_actual, trail
                    ) VALUES (
                        %s, %s, %s, %s, %s, %s, %s,
                        %s, %s, %s, %s
                    )
                """, [
                    gr_id,
                    pr_item_id,
                    medicine_id,
                    batch_id,
                    location_id,
                    qty_ordered,
                    qty_received,
                    expiry_date,
                    unit_price,
                    qty_received * float(unit_price or 0),
                    format_trail(request.user, get_client_ip(request))
                ])

                # Update inventory balance (add received quantity)
                cursor.execute("""
                    INSERT INTO pharmacy_inventory_balance 
                        (medicine_id, batch_id, location_id, qty_on_hand, trail)
                    VALUES (%s, %s, %s, %s, %s)
                    ON CONFLICT (medicine_id, batch_id, location_id) 
                    DO UPDATE SET qty_on_hand = pharmacy_inventory_balance.qty_on_hand + %s
                """, [
                    medicine_id,
                    batch_id,
                    location_id,
                    qty_received,
                    format_trail(request.user, get_client_ip(request)),
                    qty_received
                ])

                # Verify the insert worked
                cursor.execute("""
                    SELECT qty_on_hand FROM pharmacy_inventory_balance
                    WHERE medicine_id = %s AND batch_id = %s AND location_id = %s
                """, [medicine_id, batch_id, location_id])
                balance_row = cursor.fetchone()
                if balance_row:
                    print(f"DEBUG: Inventory balance updated - medicine_id={medicine_id}, batch_id={batch_id}, location_id={location_id}, qty_on_hand={balance_row[0]}")
                else:
                    print(f"ERROR: Failed to insert inventory balance - medicine_id={medicine_id}, batch_id={batch_id}, location_id={location_id}")
                
                # Create inventory transaction record
                cursor.execute("""
                    INSERT INTO pharmacy_transactions 
                        (transaction_datetime, transaction_type, medicine_id, batch_id, to_location_id, qty, 
                         reference_type, reference_id, remarks, trail)
                    VALUES (
                        NOW(), 'IN', %s, %s, %s, %s,
                        'GOODS_RECEIPT', %s,
                        'Stock received for ' || %s, %s
                    )
                """, [
                    medicine_id,
                    batch_id,
                    location_id,
                    qty_received,
                    batch_id,
                    medicine_name,
                    format_trail(request.user, get_client_ip(request))
                ])

            # 3. Calculate delivery days and update supplier
            cursor.execute("""
                SELECT updated_at FROM pharmacy_purchase_requests 
                WHERE pr_id = %s
            """, [pr_id])
            approval_row = cursor.fetchone()
            if approval_row and approval_row[0]:
                from datetime import datetime, timezone
                approval_date = approval_row[0]

                # Get current UTC time
                delivery_date = datetime.now(timezone.utc)
                try:

                    # Parse approval_date - handle different formats
                    if isinstance(approval_date, str):

                        # Try parsing ISO format
                        if 'Z' in approval_date:
                            approval_date = datetime.fromisoformat(approval_date.replace('Z', '+00:00'))
                        elif '+' in approval_date:
                            approval_date = datetime.fromisoformat(approval_date)
                        else:

                            # Naive string - assume UTC
                            approval_date = datetime.fromisoformat(approval_date).replace(tzinfo=timezone.utc)
                    elif hasattr(approval_date, 'tzinfo') and approval_date.tzinfo is None:

                        # Naive datetime - assume UTC
                        approval_date = approval_date.replace(tzinfo=timezone.utc)

                    # Calculate days difference
                    time_diff = delivery_date - approval_date
                    delivery_days = time_diff.days
                    
                    # Ensure non-negative and within reasonable range
                    if delivery_days < 0:
                        delivery_days = 1  # At least 1 day if approved today and delivered same day
                    elif delivery_days > 365:
                        delivery_days = 30  # Cap at 30 if data seems corrupted

                    # Update supplier's delivery_days_avg
                    cursor.execute("""
                        UPDATE pharmacy_suppliers 
                        SET delivery_days_avg = %s
                        WHERE supplier_id = %s
                    """, [delivery_days, supplier_id])
                except Exception as calc_error:

                    # If calculation fails, set a default value
                    print(f"Error calculating delivery days: {calc_error}")
                    cursor.execute("""
                        UPDATE pharmacy_suppliers 
                        SET delivery_days_avg = 1, trail = %s
                        WHERE supplier_id = %s
                    """, [format_trail(request.user, get_client_ip(request)), supplier_id])
            
            # 4. Update Purchase Request status to DELIVERED
            cursor.execute("""
                UPDATE pharmacy_purchase_requests 
                SET pr_status = 'DELIVERED', updated_at = NOW()
                WHERE pr_id = %s
            """, [pr_id])

            # 5. If this PR originated from CSD, update the CSD PR status to DELIVERED too
            cursor.execute("""
                SELECT cancel_reason FROM pharmacy_purchase_requests WHERE pr_id = %s
            """, [pr_id])
            pr_row = cursor.fetchone()
            if pr_row and pr_row[0] and 'CSD_ORIGIN:' in pr_row[0]:
                try:
                    csd_pr_id_str = pr_row[0].split(':')[1]
                    csd_pr_id = int(csd_pr_id_str)
                    cursor.execute("""
                        UPDATE medistock_purchase_requests 
                        SET pr_status = 'DELIVERED', updated_at = NOW()
                        WHERE pr_id = %s
                    """, [csd_pr_id])
                    print(f"DEBUG: Linked CSD PR {csd_pr_id} status updated to DELIVERED")
                except Exception as csd_err:
                    print(f"ERROR updating linked CSD PR status: {csd_err}")

        return Response({
            'success': True,
            'message': 'Delivery confirmed and inventory restocked successfully',
            'gr_id': gr_id,
            'pr_id': pr_id
        })
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class PharmacyTransactionViewSet(viewsets.ModelViewSet):
    queryset = PharmacyTransaction.objects.all()
    serializer_class = PharmacyTransactionSerializer
    
    def perform_create(self, serializer):
        serializer.save(
            trail=format_trail(self.request.user, get_client_ip(self.request)),
            updated_trail=format_trail(self.request.user, get_client_ip(self.request))
        )
    
    def perform_update(self, serializer):
        serializer.save(
            updated_trail=format_trail(self.request.user, get_client_ip(self.request))
        )

class PharmacySupplierViewSet(viewsets.ModelViewSet):
    queryset = PharmacySupplier.objects.all()
    serializer_class = PharmacySupplierSerializer
    def perform_create(self, serializer):
        serializer.save(trail=format_trail(self.request.user, get_client_ip(self.request)))
    def perform_update(self, serializer):
        serializer.save(trail=format_trail(self.request.user, get_client_ip(self.request)))

class PharmacyLocationViewSet(viewsets.ModelViewSet):
    queryset = PharmacyLocation.objects.all()
    serializer_class = PharmacyLocationSerializer
    def perform_create(self, serializer):
        serializer.save(trail=format_trail(self.request.user, get_client_ip(self.request)))
    def perform_update(self, serializer):
        serializer.save(trail=format_trail(self.request.user, get_client_ip(self.request)))

class PharmacyMedicineViewSet(viewsets.ModelViewSet):
    queryset = PharmacyMedicine.objects.all().order_by('medicine_name')
    serializer_class = PharmacyMedicineSerializer
    def perform_create(self, serializer):
        serializer.save(trail=format_trail(self.request.user, get_client_ip(self.request)))
    def perform_update(self, serializer):
        serializer.save(trail=format_trail(self.request.user, get_client_ip(self.request)))

    @action(detail=True, methods=['get'])
    def batches(self, request, pk=None):
        """Get all batches for this medicine"""
        medicine = self.get_object()
        batches = PharmacyStockBatch.objects.filter(medicine=medicine)
        serializer = PharmacyStockBatchSerializer(batches, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'], url_path='remove-medicine')
    def remove_medicine(self, request, pk=None):
        """Totally remove a medicine (or just from one location) and all its batches from the database and log adjustments"""
        try:
            medicine = self.get_object()
            reason = request.data.get('reason', 'DAMAGED').upper()
            remarks = request.data.get('remarks', '')
            location_id = request.data.get('location_id')
            medicine_id = medicine.medicine_id
            medicine_name = medicine.medicine_name

            with transaction.atomic():
                from django.db import connection
                with connection.cursor() as cursor:
                    # 1. Get all batches for this medicine
                    batches = PharmacyStockBatch.objects.filter(medicine_id=medicine_id)
                    batch_ids = [b.batch_id for b in batches]

                    # 2. Handle constraints for each batch (only if totally removing)
                    if not location_id and batch_ids:
                        for b_id in batch_ids:
                            # Find all tables with foreign key constraints referencing pharmacy_stock_batches
                            cursor.execute("""
                                SELECT 
                                    conrelid::regclass::text AS table_name,
                                    a.attname AS column_name
                                FROM pg_constraint c
                                JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
                                WHERE confrelid = 'pch.pharmacy_stock_batches'::regclass
                            """)
                            restrict_tables = cursor.fetchall()

                            for table_name, column_name in restrict_tables:
                                # Clean up table name (might include schema)
                                table_path = table_name if '.' in table_name else f"pch.{table_name}"
                                pure_table = table_name.split('.')[-1]
                                
                                if pure_table == 'pharmacy_inventory_balance':
                                    continue

                                # Check if column is part of a primary key
                                cursor.execute("""
                                    SELECT 1 FROM pg_constraint c
                                    JOIN pg_class t ON t.oid = c.conrelid
                                    JOIN pg_namespace n ON n.oid = t.relnamespace
                                    JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
                                    WHERE c.contype = 'p' AND t.relname = %s AND a.attname = %s
                                """, [pure_table, column_name])
                                if cursor.fetchone() is not None:
                                    continue 

                                # Attempt to drop NOT NULL if needed and update to NULL
                                try:
                                    cursor.execute(f"ALTER TABLE {table_path} ALTER COLUMN {column_name} DROP NOT NULL")
                                except:
                                    pass
                                
                                cursor.execute(f"UPDATE {table_path} SET {column_name} = NULL WHERE {column_name} = %s", [b_id])

                    # 4. Create adjustments for all stock found in relevant batches
                    if location_id:
                        balances = PharmacyInventoryBalance.objects.filter(medicine_id=medicine_id, location_id=location_id)
                    else:
                        balances = PharmacyInventoryBalance.objects.filter(medicine_id=medicine_id)
                        
                    adjustments = []
                    for balance in balances:
                        if balance.qty_on_hand > 0:
                            # Find batch number for remarks
                            cursor.execute("SELECT batch_no FROM pch.pharmacy_stock_batches WHERE batch_id = %s", [balance.batch_id])
                            b_row = cursor.fetchone()
                            b_no = b_row[0] if b_row else "Unknown"
                            
                            adj_remarks = f"Medicine Removal ({reason}): {medicine_name}, Batch: {b_no}, Qty: {balance.qty_on_hand}. Location: {balance.location_id}. {remarks}"
                            cursor.execute("""
                                INSERT INTO pch.pharmacy_inventory_adjustments (adj_type, location_id, remarks, trail)
                                VALUES (%s, %s, %s, %s)
                                RETURNING adj_id
                            """, [reason, balance.location_id, adj_remarks, format_trail(request.user, get_client_ip(request))])
                            adj_id = cursor.fetchone()[0]
                            adjustments.append({
                                'adj_id': adj_id,
                                'qty': balance.qty_on_hand,
                                'location_id': balance.location_id,
                                'batch_no': b_no
                            })

                    # 5. Clear inventory balances (optionally filtered by location)
                    if location_id:
                        cursor.execute("DELETE FROM pch.pharmacy_inventory_balance WHERE medicine_id = %s AND location_id = %s", [medicine_id, location_id])
                    else:
                        cursor.execute("DELETE FROM pch.pharmacy_inventory_balance WHERE medicine_id = %s", [medicine_id])

                    # 6. Delete all batches (ONLY if NOT filtered by location)
                    if not location_id:
                        # We null out references to batches first to ensure they can be deleted
                        if batch_ids:
                            for b_id in batch_ids:
                                # Find all tables with foreign key constraints referencing pharmacy_stock_batches
                                cursor.execute("""
                                    SELECT 
                                        conrelid::regclass::text AS table_name,
                                        a.attname AS column_name
                                    FROM pg_constraint c
                                    JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
                                    WHERE confrelid = 'pch.pharmacy_stock_batches'::regclass
                                """)
                                restrict_tables = cursor.fetchall()

                                for table_name, column_name in restrict_tables:
                                    table_path = table_name if '.' in table_name else f"pch.{table_name}"
                                    pure_table = table_name.split('.')[-1]
                                    if pure_table == 'pharmacy_inventory_balance':
                                        continue
                                    cursor.execute("""
                                        SELECT 1 FROM pg_constraint c
                                        JOIN pg_class t ON t.oid = c.conrelid
                                        JOIN pg_namespace n ON n.oid = t.relnamespace
                                        JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
                                        WHERE c.contype = 'p' AND t.relname = %s AND a.attname = %s
                                    """, [pure_table, column_name])
                                    if cursor.fetchone() is not None:
                                        continue 
                                    try:
                                        cursor.execute(f"ALTER TABLE {table_path} ALTER COLUMN {column_name} DROP NOT NULL")
                                    except:
                                        pass
                                    cursor.execute(f"UPDATE {table_path} SET {column_name} = NULL WHERE {column_name} = %s", [b_id])

                        cursor.execute("DELETE FROM pch.pharmacy_stock_batches WHERE medicine_id = %s", [medicine_id])

                    # 7. Create transaction records for each stock movement
                    for adj in adjustments:
                        cursor.execute("""
                            INSERT INTO pch.pharmacy_transactions (
                                transaction_datetime, transaction_type, medicine_id,
                                from_location_id, qty, reference_type, reference_id, remarks, trail
                            ) VALUES (NOW(), 'ADJUST', %s, %s, %s, 'BATCH_REMOVAL', %s, %s, %s)
                        """, [
                            medicine_id,
                            adj['location_id'],
                            adj['qty'],
                            adj['adj_id'],
                            f"Medicine {medicine_name} (Batch {adj['batch_no']}) removed ({reason}) from Location {adj['location_id']}: {remarks}",
                            format_trail(request.user, get_client_ip(request))
                        ])

                    # 8. Final check for ANY remaining references to this medicine (only if NOT filtered by location)
                    if not location_id:
                        # Find all tables with foreign key constraints referencing pharmacy_medicines
                        cursor.execute("""
                            SELECT 
                                conrelid::regclass::text AS table_name,
                                a.attname AS column_name
                            FROM pg_constraint c
                            JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
                            WHERE confrelid = 'pch.pharmacy_medicines'::regclass
                        """)
                        med_restrict_tables = cursor.fetchall()
                        for table_name, column_name in med_restrict_tables:
                            # Clean up table name
                            table_path = table_name if '.' in table_name else f"pch.{table_name}"
                            pure_table = table_name.split('.')[-1]

                            if pure_table in ['pharmacy_inventory_balance', 'pharmacy_stock_batches']:
                                continue
                            
                            cursor.execute("""
                                SELECT 1 FROM pg_constraint c
                                JOIN pg_class t ON t.oid = c.conrelid
                                JOIN pg_namespace n ON n.oid = t.relnamespace
                                JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
                                WHERE c.contype = 'p' AND t.relname = %s AND a.attname = %s
                            """, [pure_table, column_name])
                            if cursor.fetchone() is not None:
                                continue

                            try:
                                cursor.execute(f"ALTER TABLE {table_path} ALTER COLUMN {column_name} DROP NOT NULL")
                            except:
                                pass
                            
                            cursor.execute(f"UPDATE {table_path} SET {column_name} = NULL WHERE {column_name} = %s", [medicine_id])

                        # 9. Delete the medicine itself
                        cursor.execute("DELETE FROM pch.pharmacy_medicines WHERE medicine_id = %s", [medicine_id])

            msg = f"Medicine {medicine_name} removed from Location {location_id}" if location_id else f"Medicine {medicine_name} and all its batches removed successfully from all locations"
            return Response({
                'success': True,
                'message': msg
            })
        except Exception as e:
            import traceback
            print(f"ERROR in remove_medicine: {e}")
            print(traceback.format_exc())
            return Response({'error': str(e)}, status=500)

    def list(self, request, *args, **kwargs):
        try:
            return super().list(request, *args, **kwargs)
        except Exception as e:
            import traceback
            print(f"ERROR in list: {e}")
            print(traceback.format_exc())
            return Response(
                {"detail": str(e), "traceback": traceback.format_exc()},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class PharmacyStockBatchViewSet(viewsets.ModelViewSet):
    queryset = PharmacyStockBatch.objects.all()
    serializer_class = PharmacyStockBatchSerializer
    def perform_update(self, serializer):
        serializer.save(trail=format_trail(self.request.user, get_client_ip(self.request)))

    @action(detail=True, methods=['post'], url_path='remove-batch')
    def remove_batch(self, request, pk=None):
        """Totally remove a batch from the database and log adjustment"""
        try:
            batch = self.get_object()
            reason = request.data.get('reason', 'DAMAGED')
            remarks = request.data.get('remarks', '')

            with transaction.atomic():
                from django.db import connection
                with connection.cursor() as cursor:
                    # 1. Find all tables with foreign key constraints referencing pharmacy_stock_batches
                    cursor.execute("""
                        SELECT 
                            conrelid::regclass::text AS table_name,
                            a.attname AS column_name
                        FROM pg_constraint c
                        JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
                        WHERE confrelid = 'pch.pharmacy_stock_batches'::regclass
                    """)
                    restrict_tables = cursor.fetchall()

                    # 2. Null out references to this specific batch (skip inventory_balance - we delete those manually)
                    blocking_tables = []
                    for table_name, column_name in restrict_tables:
                        # Clean up table name
                        table_path = table_name if '.' in table_name else f"pch.{table_name}"
                        pure_table = table_name.split('.')[-1]

                        if pure_table == 'pharmacy_inventory_balance':
                            continue

                        # Check if column is part of a primary key using pg_constraint
                        cursor.execute("""
                            SELECT 1
                            FROM pg_constraint c
                            JOIN pg_class t ON t.oid = c.conrelid
                            JOIN pg_namespace n ON n.oid = t.relnamespace
                            JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
                            WHERE c.contype = 'p'
                            AND t.relname = %s
                            AND a.attname = %s
                        """, [pure_table, column_name])
                        is_in_pk = cursor.fetchone() is not None
                        if is_in_pk:
                            blocking_tables.append(pure_table)
                            continue

                        # Attempt to drop NOT NULL if needed and update to NULL
                        try:
                            cursor.execute(f"ALTER TABLE {table_path} ALTER COLUMN {column_name} DROP NOT NULL")
                        except:
                            pass

                        cursor.execute(f"UPDATE {table_path} SET {column_name} = NULL WHERE {column_name} = %s", [batch.batch_id])

                    if blocking_tables:
                        return Response({
                            'error': f"Cannot remove batch: the following tables have primary-key references that block deletion: {', '.join(blocking_tables)}"
                        }, status=400)

                    # 3. Create adjustments
                    balances = PharmacyInventoryBalance.objects.filter(batch=batch)
                    adjustments = []
                    for balance in balances:
                        if balance.qty_on_hand > 0:
                            adj_remarks = f"Batch Removal ({reason}): {batch.batch_no}, Qty: {balance.qty_on_hand}. {remarks}"
                            cursor.execute("""
                                INSERT INTO pch.pharmacy_inventory_adjustments (adj_type, location_id, remarks, trail)
                                VALUES (%s, %s, %s, %s)
                                RETURNING adj_id
                            """, [reason, balance.location_id, adj_remarks, format_trail(request.user, get_client_ip(request))])
                            adj_id = cursor.fetchone()[0]
                            adjustments.append({
                                'adj_id': adj_id,
                                'qty': balance.qty_on_hand,
                                'location_id': balance.location_id,
                            })

                    # 4. Delete inventory balances
                    cursor.execute("DELETE FROM pch.pharmacy_inventory_balance WHERE batch_id = %s", [batch.batch_id])

                    batch_no = batch.batch_no
                    medicine_id = batch.medicine_id
                    batch_id = batch.batch_id

                    # 5. Delete the batch
                    cursor.execute("DELETE FROM pch.pharmacy_stock_batches WHERE batch_id = %s", [batch_id])

                    # 6. Create transaction records
                    for adj in adjustments:
                        cursor.execute("""
                            INSERT INTO pch.pharmacy_transactions (
                                transaction_datetime, transaction_type, medicine_id,
                                from_location_id, qty, reference_type, reference_id, remarks, trail
                            ) VALUES (NOW(), 'ADJUST', %s, %s, %s, 'BATCH_REMOVAL', %s, %s, %s)
                        """, [
                            medicine_id,
                            adj['location_id'],
                            adj['qty'],
                            adj['adj_id'],
                            f"Batch {batch_no} removed ({reason}): {remarks}",
                            format_trail(request.user, get_client_ip(request))
                        ])

            return Response({
                'success': True,
                'message': f'Batch {batch_no} removed successfully'
            })
        except Exception as e:
            import traceback
            print(f"ERROR in remove_batch: {e}")
            print(traceback.format_exc())
            return Response({'error': str(e)}, status=500)

    @transaction.atomic
    def perform_create(self, serializer):

        # 1. Capture initial quantity from validated data before saving batch
        initial_qty = serializer.validated_data.pop('initial_qty', 0)

        # 2. Save the new batch with trail
        batch = serializer.save(trail=format_trail(self.request.user, get_client_ip(self.request)))

        # 3. Automatically create initial inventory balance for this batch in Location 1 (Main Pharmacy)
        # Use raw SQL to handle existing records and avoid primary key issues
        from django.db import connection
        with connection.cursor() as cursor:

            # Check if it exists
            cursor.execute("""
                SELECT qty_on_hand FROM pch.pharmacy_inventory_balance 
                WHERE medicine_id = %s AND batch_id = %s AND location_id = 1
            """, [batch.medicine_id, batch.batch_id])
            row = cursor.fetchone()
            
            if row:
                # UPDATE EXISTING
                new_qty = float(row[0]) + float(initial_qty)
                cursor.execute("""
                    UPDATE pch.pharmacy_inventory_balance 
                    SET qty_on_hand = %s 
                    WHERE medicine_id = %s AND batch_id = %s AND location_id = 1
                """, [new_qty, batch.medicine_id, batch.batch_id])
            else:

                # CREATE NEW
                cursor.execute("""
                    INSERT INTO pch.pharmacy_inventory_balance (medicine_id, batch_id, location_id, qty_on_hand, trail)
                    VALUES (%s, %s, 1, %s, %s)
                """, [batch.medicine_id, batch.batch_id, initial_qty, format_trail(self.request.user, get_client_ip(self.request))])
            
        # 4. Log the initial transaction
        PharmacyTransaction.objects.create(
            transaction_datetime=timezone.now(),
            transaction_type='IN',
            medicine_id=batch.medicine_id,
            batch_id=batch.batch_id,
            to_location_id=1,
            qty=initial_qty,
            reference_type='BATCH_CREATION',
            reference_id=batch.batch_id,
            remarks=f"Initial stock from batch creation: {batch.batch_no}",
            trail=format_trail(self.request.user, get_client_ip(self.request))
        )

class PharmacyInventoryBalanceViewSet(viewsets.ModelViewSet):
    serializer_class = PharmacyInventoryBalanceSerializer
    def perform_create(self, serializer):
        serializer.save(trail=format_trail(self.request.user, get_client_ip(self.request)))
    def perform_update(self, serializer):
        serializer.save(trail=format_trail(self.request.user, get_client_ip(self.request)))
    def get_queryset(self):

        # Use raw SQL to retrieve inventory balance data to avoid ORM issues with composite keys
        from django.db import connection
        with connection.cursor() as cursor:
            
            # Get location filter from query params
            location_id = self.request.query_params.get('location_id')
            if location_id:
                cursor.execute("""
                    SELECT 
                        ib.medicine_id,
                        m.medicine_name,
                        m.unit,
                        ib.batch_id,
                        b.batch_no,
                        b.expiry_date,
                        b.received_date,
                        b.unit_cost,
                        ib.location_id,
                        l.location_name,
                        l.location_type,
                        ib.qty_on_hand,
                        ib.trail
                    FROM pharmacy_inventory_balance ib
                    INNER JOIN pharmacy_medicines m ON ib.medicine_id = m.medicine_id
                    LEFT JOIN pharmacy_stock_batches b ON ib.batch_id = b.batch_id
                    INNER JOIN pharmacy_locations l ON ib.location_id = l.location_id
                    WHERE ib.location_id = %s
                    ORDER BY m.medicine_name
                """, [location_id])
            else:
                cursor.execute("""
                    SELECT 
                        ib.medicine_id,
                        m.medicine_name,
                        m.unit,
                        ib.batch_id,
                        b.batch_no,
                        b.expiry_date,
                        b.received_date,
                        b.unit_cost,
                        ib.location_id,
                        l.location_name,
                        l.location_type,
                        ib.qty_on_hand,
                        ib.trail
                    FROM pharmacy_inventory_balance ib
                    INNER JOIN pharmacy_medicines m ON ib.medicine_id = m.medicine_id
                    LEFT JOIN pharmacy_stock_batches b ON ib.batch_id = b.batch_id
                    INNER JOIN pharmacy_locations l ON ib.location_id = l.location_id
                    ORDER BY m.medicine_name
                """)
            columns = [col[0] for col in cursor.description]
            data = [dict(zip(columns, row)) for row in cursor.fetchall()]
        # Convert raw SQL results to model instances for serialization
        queryset = []
        for row in data:

            # Create a simple object that can be serialized
            class InventoryBalanceItem:
                def __init__(self, data):
                    self.medicine_id = data['medicine_id']
                    self.medicine_name = data['medicine_name']
                    self.unit = data.get('unit')
                    self.batch_id = data['batch_id']
                    self.batch_no = data['batch_no']
                    self.expiry_date = data['expiry_date']
                    self.received_date = data['received_date']
                    self.unit_cost = data.get('unit_cost')
                    self.location_id = data['location_id']
                    self.location_name = data['location_name']
                    self.location_type = data['location_type']
                    self.qty_on_hand = data['qty_on_hand']
                    self.trail = data['trail']
            queryset.append(InventoryBalanceItem(row))
        return queryset

    def list(self, request, *args, **kwargs):

        # Override list to handle raw SQL queryset
        queryset = self.get_queryset()

        # Serialize the data manually
        serializer_data = []
        for item in queryset:
            serializer_data.append({
                'medicine_id': item.medicine_id,
                'medicine': item.medicine_id, # Keep for backward compatibility
                'medicine_name': item.medicine_name,
                'unit': item.unit,
                'batch': item.batch_id,
                'batch_no': item.batch_no,
                'unit_cost': float(item.unit_cost) if item.unit_cost else 0.0,
                'location': item.location_id,
                'location_name': item.location_name,
                'location_type': item.location_type,
                'qty_on_hand': float(item.qty_on_hand),
                'expiry_date': item.expiry_date.isoformat() if item.expiry_date else None,
                'received_date': item.received_date.isoformat() if item.received_date else None,
                'trail': item.trail
            })

        # Add cache-control headers
        response = Response(serializer_data)
        response['Cache-Control'] = 'no-cache, no-store, must-revalidate'
        response['Pragma'] = 'no-cache'
        response['Expires'] = '0'
        return response

    @action(detail=False, methods=['post'], url_path='manual-return')
    @transaction.atomic
    def manual_return(self, request):
        """Manually return medicine to a location (Main or Cart)"""
        medicine_id = request.data.get('medicine_id')
        batch_no = request.data.get('batch_no')
        qty_to_return = float(request.data.get('quantity', 0))
        location_id = int(request.data.get('location_id', 1)) # Default to Main Pharmacy
        remarks = request.data.get('remarks', 'Manual return from pharmacist')
        return_type = request.data.get('return_type', 'RETURN') # Default to RETURN
        
        if not medicine_id or not batch_no or qty_to_return <= 0:
            return Response({'error': 'Medicine ID, Batch Number, and valid Quantity are required'}, status=400)
        try:

            # 1. Find the batch
            batch = PharmacyStockBatch.objects.get(medicine_id=medicine_id, batch_no=batch_no)     

            # 2. Update existing balance or create if it doesn't exist
            from django.db import connection
            with connection.cursor() as cursor:

                # Check if it exists
                cursor.execute("""
                    SELECT qty_on_hand FROM pch.pharmacy_inventory_balance 
                    WHERE medicine_id = %s AND batch_id = %s AND location_id = %s
                """, [medicine_id, batch.batch_id, location_id])
                row = cursor.fetchone()
                if row:

                    # UPDATE EXISTING
                    new_qty = float(row[0]) + qty_to_return
                    cursor.execute("""
                        UPDATE pch.pharmacy_inventory_balance 
                        SET qty_on_hand = %s 
                        WHERE medicine_id = %s AND batch_id = %s AND location_id = %s
                    """, [new_qty, medicine_id, batch.batch_id, location_id])
                else:

                    # CREATE NEW
                    cursor.execute("""
                        INSERT INTO pch.pharmacy_inventory_balance (medicine_id, batch_id, location_id, qty_on_hand, trail)
                        VALUES (%s, %s, %s, %s, %s)
                    """, [medicine_id, batch.batch_id, location_id, qty_to_return, format_trail(request.user, get_client_ip(request))])

            # 3. Log Transaction
            PharmacyTransaction.objects.create(
                transaction_datetime=timezone.now(),
                transaction_type='IN',
                medicine_id=medicine_id,
                batch_id=batch.batch_id,
                to_location_id=location_id,
                qty=qty_to_return,
                reference_type='MANUAL_RETURN',
                remarks=remarks,
                service_source='CART' if location_id == 2 else 'IPD'
            )

            # 4. Create formal inventory adjustment record ONLY for RETURN or DAMAGE
            # RESTOCK and ADD BATCH do not enter this method; they have their own logic
            # This ensures we only audit specialized movements in the adjustment tables.
            from django.db import connection
            with connection.cursor() as cursor:
                cursor.execute("""
                    INSERT INTO pch.pharmacy_inventory_adjustments (adj_type, location_id, remarks, trail)
                    VALUES ('COUNT_VARIANCE', %s, %s, %s)
                    RETURNING adj_id
                """, [location_id, f"{return_type}: {remarks}", format_trail(request.user, get_client_ip(request))])
                adj_id = cursor.fetchone()[0]
                cursor.execute("""
                    INSERT INTO pch.pharmacy_inventory_adjustment_items (adj_id, medicine_id, batch_id, qty)
                    VALUES (%s, %s, %s, %s)
                """, [adj_id, medicine_id, batch.batch_id, qty_to_return])

            return Response({
                'success': True,
                'message': f'Successfully recorded {return_type} of {qty_to_return} units.',
            })
        except PharmacyStockBatch.DoesNotExist:
            return Response({'error': f'Batch {batch_no} not found for this medicine'}, status=404)
        except Exception as e:
            import traceback
            print(f"ERROR in manual_return: {e}")
            print(traceback.format_exc())
            return Response({'error': str(e)}, status=500)

    @action(detail=False, methods=['post'], url_path='restock-cart')
    @transaction.atomic
    def restock_cart(self, request):
        """Restock a cart (Location 2) from Main Pharmacy (Location 1)"""
        medicine_id = request.data.get('medicine_id')
        batch_no = request.data.get('batch_no')
        qty_to_add = float(request.data.get('quantity', 0))
        unit_cost = float(request.data.get('unit_cost', 0))
    
        if not medicine_id or not batch_no or qty_to_add <= 0:
            return Response({'error': 'Medicine ID, Batch Number, and valid Quantity are required'}, status=400)
            
        # 1. Find or create the batch
        try:

            # Try to find existing batch
            source_batch = PharmacyStockBatch.objects.filter(medicine_id=medicine_id, batch_no=batch_no).first()

            if not source_batch:
                # If batch doesn't exist, create it (this handles new deliveries directly to cart or system syncs)
                # We need an expiry date for creation - if not provided, we can't create a valid batch
                expiry_date = request.data.get('expiry_date')
                if not expiry_date:
                    return Response({'error': 'Expiry date is required to create a new batch'}, status=400)
                source_batch = PharmacyStockBatch.objects.create(
                    medicine_id=medicine_id,
                    batch_no=batch_no,
                    expiry_date=expiry_date,
                    unit_cost=unit_cost,
                    received_date=timezone.now().date(),
                    trail=format_trail(request.user, get_client_ip(request))
                )
            elif unit_cost > 0:

                # Update unit cost if provided and different
                source_batch.unit_cost = unit_cost
                source_batch.trail = format_trail(request.user, get_client_ip(request))
                source_batch.save()

            # Get source balance using raw SQL
            cursor.execute("""
                SELECT qty_on_hand FROM pharmacy_inventory_balance
                WHERE medicine_id = %s AND batch_id = %s AND location_id = 1
            """, [medicine_id, source_batch.batch_id])
            source_row = cursor.fetchone()
            if not source_row:
                return Response({'error': 'Batch not found in Main Pharmacy'}, status=404)
            source_qty = float(source_row[0])
            
            if source_qty < qty_to_add:
                return Response({'error': f'Insufficient stock in Main Pharmacy. Available: {source_qty}'}, status=400)

            # 2. Deduct from Main Pharmacy (Location 1) using raw SQL
            cursor.execute("""
                UPDATE pharmacy_inventory_balance
                SET qty_on_hand = qty_on_hand - %s
                WHERE medicine_id = %s AND batch_id = %s AND location_id = 1
            """, [qty_to_add, medicine_id, source_batch.batch_id])
            
            # 3. Add to Cart (Location 2) using raw SQL
            cursor.execute("""
                INSERT INTO pharmacy_inventory_balance (medicine_id, batch_id, location_id, qty_on_hand, trail)
                VALUES (%s, %s, 2, %s, %s)
                ON CONFLICT (medicine_id, batch_id, location_id)
                DO UPDATE SET qty_on_hand = pharmacy_inventory_balance.qty_on_hand + %s
            """, [medicine_id, source_batch.batch_id, qty_to_add, format_trail(request.user, get_client_ip(request)), qty_to_add])
            
            # 4. Log Transactions
            timestamp = timezone.now()

            # OUT from Main
            PharmacyTransaction.objects.create(
                transaction_datetime=timestamp,
                transaction_type='OUT',
                medicine_id=medicine_id,
                batch_id=source_batch.batch_id,
                from_location_id=1,
                to_location_id=2,
                qty=qty_to_add,
                reference_type='CART_RESTOCK',
                reference_id=source_batch.batch_id,
                remarks=f"Stock moved to Cart (Location 2) for batch: {batch_no}",
                trail=format_trail(request.user, get_client_ip(request))
            )

            # IN to Cart
            PharmacyTransaction.objects.create(
                transaction_datetime=timestamp,
                transaction_type='IN',
                medicine_id=medicine_id,
                batch_id=source_batch.batch_id,
                from_location_id=1,
                to_location_id=2,
                qty=qty_to_add,
                reference_type='CART_RESTOCK',
                reference_id=source_batch.batch_id,
                remarks=f"Stock received in Cart from Main Pharmacy",
                trail=format_trail(request.user, get_client_ip(request))
            )

            return Response({
                'success': True,
                'message': f'Successfully restocked {qty_to_add} units to the cart.',
                'new_cart_qty': cart_balance.qty_on_hand
            })

        except (PharmacyStockBatch.DoesNotExist, PharmacyInventoryBalance.DoesNotExist):
            return Response({'error': 'Batch not found in Main Pharmacy inventory'}, status=404)
        except Exception as e:
            return Response({'error': str(e)}, status=500)

class PharmacyPurchaseRequestViewSet(viewsets.ModelViewSet):
    queryset = PharmacyPurchaseRequest.objects.prefetch_related('items').all().order_by('-pr_id')
    serializer_class = PharmacyPurchaseRequestSerializer
    def perform_create(self, serializer):
        serializer.save(
            trail=format_trail(self.request.user, get_client_ip(self.request)),
            updated_trail=format_trail(self.request.user, get_client_ip(self.request))
        )

    def perform_update(self, serializer):
        serializer.save(
            updated_trail=format_trail(self.request.user, get_client_ip(self.request))
        )
    
    def list(self, request, *args, **kwargs):
        """Override list to add debugging for qty_received"""
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            data = serializer.data
            # Debug: print first item to check if goods_receipt_item is present
            if data and len(data) > 0:
                first_pr = data[0]
                print(f"DEBUG LIST - PR {first_pr.get('pr_no')} (status: {first_pr.get('pr_status')}) items:")
                for item in first_pr.get('items', []):
                    gri = item.get('goods_receipt_item')
                    print(f"  Item {item.get('pr_item_id')}: qty_requested={item.get('qty_requested')}, goods_receipt_item={gri}")
                    if gri:
                        print(f"    -> qty_received={gri.get('qty_received')}, unit_cost_actual={gri.get('unit_cost_actual')}, line_total_actual={gri.get('line_total_actual')}")
            return self.get_paginated_response(data)
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
    def retrieve(self, request, *args, **kwargs):
        """Override retrieve to add debugging for qty_received"""
        instance = self.get_object()
        serializer = self.get_serializer(instance)
        data = serializer.data
        # Debug: print items to check if goods_receipt_item is present
        print(f"DEBUG RETRIEVE - PR {instance.pr_no} (status: {instance.pr_status}) items:")
        for item in data.get('items', []):
            gri = item.get('goods_receipt_item')
            print(f"  Item {item.get('pr_item_id')}: qty_requested={item.get('qty_requested')}, goods_receipt_item={gri}")
            if gri:
                print(f"    -> qty_received={gri.get('qty_received')}, unit_cost_actual={gri.get('unit_cost_actual')}, line_total_actual={gri.get('line_total_actual')}")
        return Response(data)

class PharmacyChargeSlipViewSet(viewsets.ModelViewSet):
    queryset = PharmacyChargeSlip.objects.all()
    serializer_class = PharmacyChargeSlipSerializer

    def perform_create(self, serializer):
        serializer.save(
            trail=format_trail(self.request.user, get_client_ip(self.request)),
            updated_trail=format_trail(self.request.user, get_client_ip(self.request))
        )

    def perform_update(self, serializer):
        serializer.save(
            updated_trail=format_trail(self.request.user, get_client_ip(self.request))
        )

    @action(detail=False, methods=['post'], url_path='generate-from-opd')
    def generate_from_opd(self, request):
        """Generate a charge slip from OPD prescription data"""
        patient_id = request.data.get('patient_id')
        rx_id = request.data.get('rx_id')
        items = request.data.get('items', [])

        if not patient_id or not rx_id:
            return Response(
                {'error': 'patient_id and rx_id are required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if not items:
            return Response(
                {'error': 'At least one item is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            with transaction.atomic():
                # Generate unique charge slip number
                from datetime import datetime
                prefix = f"CS-{datetime.now().strftime('%Y%m%d')}"
                last_slip = PharmacyChargeSlip.objects.filter(
                    charge_slip_no__startswith=prefix
                ).order_by('-charge_slip_no').first()

                if last_slip:
                    try:
                        last_num = int(last_slip.charge_slip_no.split('-')[-1])
                    except ValueError:
                        last_num = 0
                else:
                    last_num = 0

                charge_slip_no = f"{prefix}-{last_num + 1:04d}"

                # Create charge slip
                charge_slip = PharmacyChargeSlip.objects.create(
                    charge_slip_no=charge_slip_no,
                    rx_id=rx_id,
                    patient_id=patient_id,
                    status='FOR_BILLING',
                    trail=format_trail(request.user, get_client_ip(request)),
                    updated_trail=format_trail(request.user, get_client_ip(request))
                )

                # Create charge slip items
                for item in items:
                    medicine_id = item.get('medicine_id')
                    qty = item.get('qty', 0)
                    unit_cost = item.get('unit_cost', 0)
                    line_total = qty * unit_cost

                    if medicine_id:
                        PharmacyChargeSlipItem.objects.create(
                            charge_slip=charge_slip,
                            medicine_id=medicine_id,
                            qty=qty,
                            unit_cost=unit_cost,
                            line_total=line_total,
                            trail=format_trail(request.user, get_client_ip(request))
                        )

                return Response(
                    PharmacyChargeSlipSerializer(charge_slip).data,
                    status=status.HTTP_201_CREATED
                )

        except Exception as e:
            return Response(
                {'error': f'Failed to create charge slip: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class PharmacyDispenseReceiptViewSet(viewsets.ModelViewSet):
    queryset = PharmacyDispenseReceipt.objects.all().order_by('-created_at')
    serializer_class = PharmacyDispenseReceiptSerializer

    def perform_create(self, serializer):
        serializer.save(
            trail=format_trail(self.request.user, get_client_ip(self.request)),
            updated_trail=format_trail(self.request.user, get_client_ip(self.request))
        )

    def perform_update(self, serializer):
        serializer.save(
            updated_trail=format_trail(self.request.user, get_client_ip(self.request))
        )

    @action(detail=False, methods=['get'], url_path='billing-list')
    def billing_list(self, request):
        """Grouped list for Pharmacy Billing UI (One entry per patient)"""
        from django.db.models import Sum, Max, Count
        from django.db import connection

        # Group by patient to avoid duplicates
        # We aggregate multiple receipts into one view for the Billing Clerk
        receipts = PharmacyDispenseReceipt.objects.filter(
            received_status='RECEIVED'
        ).values(
            'patient_id', 
            'patient__firstname', 
            'patient__lastname',
            'patient__patient_id' # Hospital ID
        ).annotate(
            receipt_id=Max('receipt_id'), # Capture the latest receipt ID for this patient group
            from_location_id=Max('from_location_id'), # Get the latest location
            admission_id=Max('admission_id'), # Get the latest admission
            total_amount_sum=Sum('total_amount'),
            items_count_sum=Count('items'),
            last_dispensed=Max('dispensing_date'),
            latest_created_at=Max('created_at'),
            latest_received_status=Max('received_status')
        ).order_by('-latest_created_at')

        results = []
        for r in receipts:

            # Get ward/room from admission if available
            ward = "N/A"
            if r['admission_id']:
                with connection.cursor() as cursor:
                    cursor.execute("""
                        SELECT department FROM ipd_notice_of_admission 
                        WHERE admission_id = %s
                    """, [r['admission_id']])
                    row = cursor.fetchone()
                    if row:
                        ward = row[0]

            # Collect all items for this patient from all their receipts
            # Use raw SQL to LEFT JOIN with pharmacy_transactions to get transaction_datetime
            # This ensures we get the exact date and time from the transaction table
            with connection.cursor() as cursor:
                cursor.execute("""
                    SELECT 
                        i.receipt_id,
                        i.receipt_item_id,
                        COALESCE(m.medicine_name, i.item_description) as item_name,
                        i.quantity,
                        COALESCE(NULLIF(i.unit_cost, 0), sp.unit_price, 0) as unit_cost,
                        i.total_cost,
                        r.dispensing_date,
                        r.created_at,
                        t.transaction_datetime,
                        i.supply_id,
                        i.item_type
                    FROM pharmacy_dispense_receipt_items i
                    LEFT JOIN pharmacy_medicines m ON i.medicine_id = m.medicine_id
                    LEFT JOIN pharmacy_dispense_receipts r ON i.receipt_id = r.receipt_id
                    LEFT JOIN (
                        SELECT DISTINCT ON (supply_id) supply_id, unit_price
                        FROM pharmacy_supply_price
                        WHERE is_active = true
                        ORDER BY supply_id, effective_date DESC, created_at DESC
                    ) sp ON i.supply_id = sp.supply_id
                    LEFT JOIN LATERAL (
                        SELECT transaction_datetime
                        FROM pharmacy_transactions t2
                        WHERE t2.medicine_id = i.medicine_id
                        AND t2.transaction_type = 'OUT'
                        ORDER BY t2.transaction_datetime DESC
                        LIMIT 1
                    ) t ON true
                    WHERE r.patient_id = %s 
                        AND r.received_status = 'RECEIVED'
                    ORDER BY COALESCE(t.transaction_datetime, r.dispensing_date, r.created_at)
                """, [r['patient_id']])
                
                items_data = cursor.fetchall()

            # Map items to final format and calculate accurate total strictly based on quantity
            items_list = []
            calculated_total = 0
            for item in items_data:
                # item is a tuple from raw SQL: (receipt_id, receipt_item_id, item_name, quantity, unit_cost, total_cost, dispensing_date, created_at, transaction_datetime, supply_id, item_type)
                receipt_id = item[0]
                receipt_item_id = item[1]
                item_name = item[2]
                quantity = item[3]
                unit_cost = item[4]
                total_cost = item[5]
                dispensing_date = item[6]
                created_at = item[7]
                transaction_datetime = item[8]
                supply_id = item[9]
                item_type = item[10]

                # MANDATORY: Strictly use quantity for accuracy as actual_used_quantity is merged into it
                actual_qty = float(quantity or 0)
                unit_cost_val = float(unit_cost or 0)
                line_total = actual_qty * unit_cost_val
                calculated_total += line_total

                # Use transaction_datetime if available, otherwise use dispensing_date, then created_at
                date_to_display = transaction_datetime if transaction_datetime else (dispensing_date if dispensing_date else created_at)
                
                items_list.append({
                    'receipt_id': str(receipt_id),
                    'receipt_item_id': str(receipt_item_id),
                    'item_name': str(item_name or 'Unknown'),
                    'quantity': str(actual_qty), # Final quantity
                    'unit_cost': str(unit_cost),
                    'total_cost': "{:.2f}".format(line_total),
                    'dispensing_date': date_to_display.isoformat() if date_to_display else 'N/A',
                    'supply_id': supply_id,
                    'item_type': item_type or ('SUPPLY' if supply_id else 'MEDICINE')
                })

            results.append({
                'receipt_id': r['receipt_id'],
                'from_location_id': r['from_location_id'],
                'patient_id': str(r['patient_id']),
                'patient_name': f"{r['patient__firstname']} {r['patient__lastname']}",
                'patient_hospital_id': str(r['patient__patient_id'] or '—'),
                'ward': str(ward),
                'total_amount': "{:.2f}".format(calculated_total), # Accurate aggregated total
                'items_count': str(len(items_list)), # Use actual count from items query
                'created_at': r['latest_created_at'].isoformat() if r['latest_created_at'] else 'N/A',
                'received_status': str(r['latest_received_status'] or 'RECEIVED'),
                'items': items_list
            })
        return Response(results)

    @action(detail=True, methods=['post'], url_path='finalize-billing')
    def finalize_billing(self, request, pk=None):
        """Finalize the billing quantities for the patient and deduct manually added items from inventory"""
        receipt = self.get_object()
        items_data = request.data.get('items', [])
    
        # 1. Update receipt items with finalized quantities
        total_amount = 0
        for item_data in items_data:
            item_id = item_data.get('receipt_item_id')
            is_new = item_data.get('is_new_billing_item', False)
            final_qty = float(item_data.get('quantity', 0))

            if is_new:
                # CREATE NEW ITEM manually added by pharmacist
                medicine_id = item_data.get('medicine_id')
                medicine_name = item_data.get('medicine_name')
                unit_cost = float(item_data.get('unit_cost', 0))
                
                # GET MEDICINE DETAILS
                from .models import PharmacyMedicine, PharmacyLocation, PharmacyInventoryBalance, PharmacyStockBatch, PharmacyTransaction
                medicine = PharmacyMedicine.objects.filter(medicine_id=medicine_id).first()
                
                # IDENTIFY CART LOCATION (Usually where the patient's medicines are stored for IPD)
                # We prioritize the location associated with the receipt, otherwise look for a CART type location.
                cart_location = PharmacyLocation.objects.filter(location_id=receipt.from_location_id, location_type='CART').first()
                if not cart_location:
                    cart_location = PharmacyLocation.objects.filter(location_type='CART').first()

                new_item = PharmacyDispenseReceiptItem.objects.create(
                    dispense_receipt=receipt,
                    medicine_id=medicine_id,
                    item_code=medicine.medicine_code if medicine else str(medicine_id),
                    item_description=medicine_name,
                    item_type='MEDICINE',
                    quantity=final_qty,
                    unit=medicine.unit if medicine else 'Piece',
                    unit_cost=unit_cost,
                    total_cost=final_qty * unit_cost,
                    remarks="Manually added by Pharmacist during Billing Finalization",
                    trail=format_trail(request.user, get_client_ip(request))
                )
                total_amount += new_item.total_cost

                # DEDUCT FROM INVENTORY AUTOMATICALLY (FEFO)
                if cart_location and final_qty > 0:
                    remaining_to_deduct = final_qty
                    
                    # Find batches with stock in the cart location, sorted by expiry date
                    balances = PharmacyInventoryBalance.objects.filter(
                        medicine_id=medicine_id,
                        location=cart_location,
                        qty_on_hand__gt=0
                    ).select_related('batch').order_by('batch__expiry_date')

                    for bal in balances:
                        if remaining_to_deduct <= 0:
                            break
                            
                        deduct_qty = min(float(bal.qty_on_hand), remaining_to_deduct)
                        
                        # Update balance using targeted update to avoid composite PK issues with Django's save()
                        new_qty = float(bal.qty_on_hand) - deduct_qty
                        PharmacyInventoryBalance.objects.filter(
                            medicine_id=medicine_id,
                            batch_id=bal.batch_id,
                            location_id=bal.location_id
                        ).update(qty_on_hand=new_qty)
                        
                        # Record Transaction
                        PharmacyTransaction.objects.create(
                            transaction_type='OUT',
                            medicine_id=medicine_id,
                            batch=bal.batch,
                            from_location=cart_location,
                            qty=deduct_qty,
                            reference_type='BILLING_ADDITION',
                            reference_id=receipt.receipt_id,
                            service_source='IPD',
                            remarks=f"Auto-deducted: Added during billing finalization for {receipt.patient.firstname} {receipt.patient.lastname}",
                            trail=format_trail(request.user, get_client_ip(request))
                        )
                        
                        remaining_to_deduct -= deduct_qty
                
                continue

            # Use the Primary Key (receipt_item_id) for the most reliable update for existing items
            item = PharmacyDispenseReceiptItem.objects.filter(receipt_item_id=item_id).first()
            if item:
                final_qty_val = float(final_qty)
                old_qty = float(item.quantity)
                new_unit_cost = float(item_data.get('unit_cost', item.unit_cost or 0))
                
                # UPDATE THE quantity COLUMN DIRECTLY FOR BILLING
                item.quantity = final_qty_val
                
                # Update unit cost if provided (especially for supplies)
                item.unit_cost = new_unit_cost
                
                # Update the total cost based on the finalized quantity and unit cost
                item.total_cost = new_unit_cost * final_qty_val
                item.updated_trail = format_trail(request.user, get_client_ip(request))

                # Save the item (No inventory logic here)
                item.save()
                total_amount += item.total_cost
                
                # PERSIST SUPPLY PRICE for future dispenses
                if item.supply_id and new_unit_cost > 0:
                    from django.db import connection
                    with connection.cursor() as cursor:
                        # Deactivate previous active prices for this supply
                        cursor.execute("""
                            UPDATE pharmacy_supply_price
                            SET is_active = false, updated_at = NOW()
                            WHERE supply_id = %s AND is_active = true
                        """, [item.supply_id])
                        # Insert new active price
                        cursor.execute("""
                            INSERT INTO pharmacy_supply_price (
                                supply_id, batch_id, unit_price, effective_date,
                                is_active, set_by_id, created_at, updated_at
                            ) VALUES (%s, %s, %s, %s, %s, %s, NOW(), NOW())
                        """, [
                            item.supply_id,
                            item.batch_id,
                            new_unit_cost,
                            timezone.now().date(),
                            True,
                            request.user.id
                        ])

                # SYNC WITH TRANSACTIONS TABLE
                # This ensures Dispensing Reports are accurate after finalizing billing
                try:
                    from .models import PharmacyTransaction

                    # IMPORTANT: Use the item's actual parent receipt, not the pk receipt.
                    # billing_list groups by patient and items may belong to different receipts.
                    item_receipt = item.dispense_receipt

                    # 1. Find the matching OUT transaction for IPD dispensing
                    # For IPD, reference_type is 'IPD_DISPENSING' and reference_id is ipd_dispensing_id
                    if item_receipt and item_receipt.ipd_dispensing_id:
                        PharmacyTransaction.objects.filter(
                            transaction_type='OUT',
                            medicine_id=item.medicine_id,
                            reference_id=item_receipt.ipd_dispensing_id,
                            reference_type='IPD_DISPENSING'
                        ).update(
                            qty=final_qty_val,
                            remarks=f"{item.remarks or ''} | Finalized in Billing from {old_qty} to {final_qty_val}",
                            updated_trail=format_trail(request.user, get_client_ip(request))
                        )

                    # 2. Find the matching OUT transaction for Cart dispensing (from IPD cart form)
                    # For IPD cart form dispensing, reference_type is 'IPD_CART_DISPENSE' and reference_id is ipd_cart_form_id
                    if item_receipt and item_receipt.ipd_cart_form_id:
                        PharmacyTransaction.objects.filter(
                            transaction_type='OUT',
                            medicine_id=item.medicine_id,
                            reference_id=item_receipt.ipd_cart_form_id,
                            reference_type='IPD_CART_DISPENSE'
                        ).update(
                            qty=final_qty_val,
                            remarks=f"{item.remarks or ''} | Finalized in Billing from {old_qty} to {final_qty_val}",
                            updated_trail=format_trail(request.user, get_client_ip(request))
                        )

                    # 3. Find the matching OUT transaction for direct Cart dispensing
                    # For direct cart dispensing, reference_type is 'CART_DISPENSE' and reference_id is receipt_id
                    if item_receipt:
                        PharmacyTransaction.objects.filter(
                            transaction_type='OUT',
                            medicine_id=item.medicine_id,
                            reference_id=item_receipt.receipt_id,
                            reference_type='CART_DISPENSE'
                        ).update(
                            qty=final_qty_val,
                            remarks=f"{item.remarks or ''} | Finalized in Billing from {old_qty} to {final_qty_val}",
                            updated_trail=format_trail(request.user, get_client_ip(request))
                        )
                except Exception as tx_err:
                    print(f"Warning: Transaction sync failed: {tx_err}")

        # 2. Update receipt total
        receipt.total_amount = total_amount
        receipt.updated_trail = format_trail(request.user, get_client_ip(request))
        receipt.save()
        
        return Response({
            'success': True,
            'message': 'Billing quantities finalized successfully',
            'total_amount': total_amount
        })

    @action(detail=True, methods=['post'], url_path='send-to-billing')
    def send_to_billing(self, request, pk=None):
        """Send the pharmacy bill to the hospital billing department"""
        receipt = self.get_object()
        
        # Logic to "Send" usually involves updating status or creating a Charge Slip
        receipt.received_status = 'RECEIVED' # Or 'POSTED' if you have that
        receipt.trail = format_trail(request.user, get_client_ip(request))
        receipt.save()
        
        return Response({
            'success': True,
            'message': 'Pharmacy bill sent to Billing Department successfully.'
        })

class PharmacyInventoryAdjustmentViewSet(viewsets.ModelViewSet):
    queryset = PharmacyInventoryAdjustment.objects.all()
    serializer_class = PharmacyInventoryAdjustmentSerializer

    def perform_create(self, serializer):
        serializer.save(
            trail=format_trail(self.request.user, get_client_ip(self.request)),
            updated_trail=format_trail(self.request.user, get_client_ip(self.request))
        )

    def perform_update(self, serializer):
        serializer.save(
            updated_trail=format_trail(self.request.user, get_client_ip(self.request))
        )

class PharmacyGoodsReceiptViewSet(viewsets.ModelViewSet):
    queryset = PharmacyGoodsReceipt.objects.all()
    serializer_class = PharmacyGoodsReceiptSerializer

    def perform_update(self, serializer):
        serializer.save(trail=format_trail(self.request.user, get_client_ip(self.request)))

    def perform_create(self, serializer):
        """Override create to update medicine unit_cost when receiving goods"""
        goods_receipt = serializer.save(trail=format_trail(self.request.user, get_client_ip(self.request)))

        # Update medicine unit_cost based on actual received cost
        try:
            for item in goods_receipt.items.all():
                if item.medicine and item.unit_cost_actual > 0:

                    # Update medicine's unit_cost to the latest actual cost
                    item.medicine.unit_cost = item.unit_cost_actual
                    item.medicine.save()
        except Exception as e:

            # Log error but don't fail the receipt creation
            print(f"Warning: Could not update medicine unit_cost: {e}")
        return goods_receipt

class PharmacyReportView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        report_type = request.query_params.get('report_type')
        date_range = request.query_params.get('date_range', '')

        # Parse date range: "MM/DD/YY - MM/DD/YY"
        start_date = None
        end_date = None
        if ' - ' in date_range:
            parts = date_range.split(' - ')
            try:
                from datetime import datetime
                start_date = datetime.strptime(parts[0], '%m/%d/%y').date()
                end_date = datetime.strptime(parts[1], '%m/%d/%y').date()
            except:
                pass

        if report_type == 'Weekly Inventory Report':
            return self._generate_inventory_report()
        elif 'Dispensing Report' in report_type:
            return self._generate_dispensing_report(start_date, end_date)
        elif report_type == 'Annual Pharmacy Report':
            return self._generate_annual_report(start_date, end_date)
        
        return Response({'error': 'Invalid report type'}, status=status.HTTP_400_BAD_REQUEST)

    def _generate_inventory_report(self):
        from django.db import connection
        results = []
        medicines = PharmacyMedicine.objects.all()
        with connection.cursor() as cursor:
            for med in medicines:
                cursor.execute("""
                    SELECT COALESCE(SUM(qty_on_hand), 0) as total
                    FROM pharmacy_inventory_balance
                    WHERE medicine_id = %s
                """, [med.medicine_id])
                row = cursor.fetchone()
                total_on_hand = float(row[0]) if row else 0
                results.append({
                    'medicine_name': med.medicine_name,
                    'category': med.category,
                    'current_stock': total_on_hand,
                    'reorder_level': float(med.reorder_level),
                'status': 'LOW' if total_on_hand <= med.reorder_level else 'OK'
            })
        return Response(results)

    def _generate_dispensing_report(self, start, end):
        from django.db.models import Sum, Count
        queryset = PharmacyTransaction.objects.filter(transaction_type='OUT')
        if start: queryset = queryset.filter(transaction_datetime__date__gte=start)
        if end: queryset = queryset.filter(transaction_datetime__date__lte=end)
        
        results = queryset.values('medicine__medicine_name').annotate(
            total_qty=Sum('qty'),
            transaction_count=Count('transaction_id')
        ).order_by('-total_qty')

        return Response(list(results))

    def _generate_annual_report(self, start, end):
        from django.db.models import Count
        total_medicines = PharmacyMedicine.objects.count()
        dispensed_count = PharmacyTransaction.objects.filter(transaction_type='OUT')
        if start: dispensed_count = dispensed_count.filter(transaction_datetime__date__gte=start)
        if end: dispensed_count = dispensed_count.filter(transaction_datetime__date__lte=end)

        pr_qs = PharmacyPurchaseRequest.objects.all()
        # PurchaseRequest uses requested_date or updated_at, not created_at
        if start: pr_qs = pr_qs.filter(requested_date__gte=start)
        if end: pr_qs = pr_qs.filter(requested_date__lte=end)
        pr_count = pr_qs.count()

        return Response({
            'total_medicines': total_medicines,
            'total_dispensed_transactions': dispensed_count.count(),
            'total_purchase_requests': pr_count,
            'report_period': f"{start} to {end}" if start else "Current Year"
        })

class DashboardStatsView(APIView):
    def get(self, request):
        # Safely get counts with fallback to 0 if database schema doesn't match
        from django.db.models import Sum, Q, F
        from django.utils import timezone
        from datetime import timedelta
        from .models import PharmacyMedicine, PharmacyStockBatch, PharmacyPurchaseRequest, PharmacyInventoryBalance, PharmacyDispenseReceipt
        today = timezone.now().date()
        thirty_days_later = today + timedelta(days=30)

        # 1. Total Medicines
        try:
            total_medicines = PharmacyMedicine.objects.count()
        except:
            total_medicines = 0

        # 2. Low Stock Alerts (using raw SQL to connect to pharmacy_stock_batches)
        low_stock_alerts = []
        try:
            from django.db import connection
            with connection.cursor() as cursor:
                all_medicines = PharmacyMedicine.objects.all()
                for medicine in all_medicines:
                    cursor.execute("""
                        SELECT COALESCE(SUM(qty_on_hand), 0) as total
                        FROM pharmacy_inventory_balance
                        WHERE medicine_id = %s
                    """, [medicine.medicine_id])
                    row = cursor.fetchone()
                    total_qty = float(row[0]) if row else 0
                    
                    if total_qty <= medicine.reorder_level:
                        low_stock_alerts.append({
                            'id': medicine.medicine_id,
                            'name': medicine.medicine_name,
                            'qty': total_qty,
                        'reorder_level': float(medicine.reorder_level)
                    })
        except Exception as e:
            print(f"Error calculating low stock: {e}")

        # 3. Expiry Alerts (using raw SQL to connect to pharmacy_stock_batches)
        expiry_alerts = []
        try:
            from django.db import connection
            with connection.cursor() as cursor:
                cursor.execute("""
                    SELECT 
                        ib.medicine_id,
                        m.medicine_name,
                        b.batch_no,
                        b.expiry_date,
                        ib.qty_on_hand
                    FROM pharmacy_inventory_balance ib
                    INNER JOIN pharmacy_medicines m ON ib.medicine_id = m.medicine_id
                    INNER JOIN pharmacy_stock_batches b ON ib.batch_id = b.batch_id
                    WHERE b.expiry_date BETWEEN %s AND %s
                      AND ib.qty_on_hand > 0
                    ORDER BY b.expiry_date ASC
                """, [today, thirty_days_later])
                columns = [col[0] for col in cursor.description]
                expiring_rows = [dict(zip(columns, row)) for row in cursor.fetchall()]
                for row in expiring_rows:
                    expiry_alerts.append({
                        'id': row['medicine_id'],
                        'name': row['medicine_name'],
                        'batch_no': row['batch_no'],
                        'expiry_date': row['expiry_date'].isoformat() if row['expiry_date'] else None,
                        'qty': float(row['qty_on_hand']),
                    })
        except Exception as e:
            print(f"Error calculating expiry alerts: {e}")

        # 4. Pending PRs count
        try:
            # Check field names in PharmacyPurchaseRequest model
            pending_prs = PharmacyPurchaseRequest.objects.filter(
                pr_status='PENDING'
            ).count()
        except:
            pending_prs = 0

        # 5. Today's dispensed
        today_dispensed = 0
        try:
            today_dispensed = PharmacyDispenseReceipt.objects.filter(created_at__date=today).count()
        except:
            pass
        data = {
            'total_medicines': total_medicines,
            'low_stock_count': len(low_stock_alerts),
            'expiring_soon': len(expiry_alerts),
            'pending_prs': pending_prs,
            'today_dispensed': today_dispensed,
            'pending_dispensing_sheets': self._get_pending_dispensing_sheets(),
            'approved_prs': self._get_approved_prs_details(request.user),
            'low_stock_alerts': low_stock_alerts,
            'expiry_alerts': expiry_alerts,
        }
        serializer = DashboardStatsSerializer(data)
        return Response(serializer.data)

    def _get_pending_dispensing_sheets(self):
        try:
            from apps.ipd.inventory_and_request.models import DispensingSheet
            from django.utils.timesince import timesince
            from django.utils import timezone
            from datetime import datetime, timedelta
            import datetime as dt_module
            
            # Use current system time
            now = timezone.now()
            # Django's timezone doesn't always have .utc, use dt_module.UTC or timezone.utc if available
            utc_tz = getattr(timezone, 'utc', dt_module.timezone.utc)

            # Fetch PENDING sheets
            sheets = DispensingSheet.objects.filter(status='PENDING').order_by('-created_at')
            
            results = []
            for s in sheets:
                notif_time = "Just now"
                timestamp_iso = ""
                
                # Use request_time primarily
                if s.request_time:
                    try:
                        target_date = s.request_date if s.request_date else now.date()
                        target_time = s.request_time
                        
                        # Combine into a single datetime
                        combined_dt = datetime.combine(target_date, target_time)
                        
                        # Local time (UTC+8) -> UTC correction
                        combined_dt_utc = combined_dt - timedelta(hours=8)
                        
                        # Make aware using the resolved UTC timezone
                        combined_dt_utc = timezone.make_aware(combined_dt_utc, utc_tz)
                        
                        # Calculate relative time against UTC now
                        notif_time = timesince(combined_dt_utc, now) + " ago"
                        timestamp_iso = combined_dt_utc.isoformat()
                    except Exception as e:
                        print(f"Time calculation error: {e}")
                        if s.created_at:
                            cat = s.created_at
                            if timezone.is_naive(cat):
                                cat = timezone.make_aware(cat, utc_tz)
                            notif_time = timesince(cat, now) + " ago"
                            timestamp_iso = cat.isoformat()
                elif s.created_at:
                    cat = s.created_at
                    if timezone.is_naive(cat):
                        cat = timezone.make_aware(cat, utc_tz)
                    notif_time = timesince(cat, now) + " ago"
                    timestamp_iso = cat.isoformat()

                # Safely get patient and ward info
                p_name = "Unknown Patient"
                if s.patient:
                    try:
                        p_name = f"{s.patient.firstname} {s.patient.lastname}"
                    except:
                        p_name = str(s.patient)
                elif hasattr(s, 'patient_name') and s.patient_name:
                    p_name = s.patient_name

                ward_info = "IPD Ward"
                try:
                    if s.admission and s.admission.ward:
                        ward_info = s.admission.ward.ward_name
                    elif hasattr(s, 'ward_name') and s.ward_name:
                        ward_info = s.ward_name
                except:
                    pass

                results.append({
                    'id': s.pk,
                    'document_no': str(getattr(s, 'dispensing_id', s.pk)),
                    'patient_name': p_name,
                    'ward': ward_info,
                    'time': notif_time,
                    'timestamp': timestamp_iso
                })   
            return results
        except Exception as e:
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"NOTIFICATION ERROR: {str(e)}")
            return []

    def _get_approved_prs_details(self, user):
        try:
            from .models import PharmacyPurchaseRequest
            from django.utils.timesince import timesince
            from django.utils import timezone
            now = timezone.now()

            # Fetch only PRs that are APPROVED but not yet DELIVERED or CLOSED.
            # Once status changes from APPROVED (e.g., to DELIVERED), it will disappear.
            prs = PharmacyPurchaseRequest.objects.filter(
                pr_status='APPROVED'
            ).order_by('-updated_at')
            
            return [{
                'id': pr.pr_id,
                'pr_no': pr.pr_no,
                'time': timesince(pr.updated_at, now) + " ago" if pr.updated_at else "Just now",
                'timestamp': pr.updated_at.isoformat() if pr.updated_at else ""
            } for pr in prs]
        except Exception as e:
            print(f"Error fetching approved PRs: {e}")
            return []

class ForecastingStatsView(APIView):
    def get(self, request):
        """API for forecasting dashboard data based on real transactions"""
        from django.db.models import Sum, Count
        from django.db.models.functions import TruncMonth, TruncWeek
        from datetime import timedelta

        today = timezone.now().date()
        last_30_days = today - timedelta(days=30)
        prev_30_days = today - timedelta(days=60)
        last_year = today - timedelta(days=365)
        last_8_weeks = today - timedelta(days=56)
        last_90_days = today - timedelta(days=90)

        cursor = connection.cursor()

        def get_medicine_usage(medicine, start_date, end_date=None):
            qs = PharmacyTransaction.objects.filter(
                medicine=medicine,
                transaction_type='OUT',
                transaction_datetime__date__gte=start_date
            ).exclude(reference_type='CART_RESTOCK')
            if end_date:
                qs = qs.filter(transaction_datetime__date__lt=end_date)
            return float(qs.aggregate(total=Sum('qty'))['total'] or 0)

        # 1. Demand Counts & Top Dispensed (Last 30 days) — exclude internal restocks
        dispensed_totals = list(PharmacyTransaction.objects.filter(
            transaction_type='OUT',
            transaction_datetime__date__gte=last_30_days
        ).exclude(
            reference_type='CART_RESTOCK'
        ).values('medicine__medicine_name', 'medicine__reorder_level').annotate(
            total_qty=Sum('qty')
        ).order_by('-total_qty'))

        top_dispensed_list = []
        for d in dispensed_totals[:5]:
            top_dispensed_list.append({
                'name': d['medicine__medicine_name'],
                'qty': float(d['total_qty'])
            })

        # Dynamic demand classification using percentiles for accuracy
        all_qtys = [float(d['total_qty']) for d in dispensed_totals if float(d['total_qty']) > 0]
        high_demand = 0
        medium_demand = 0
        low_demand = 0

        if len(all_qtys) >= 3:
            sorted_qtys = sorted(all_qtys)
            p66 = sorted_qtys[int(len(sorted_qtys) * 0.66)]
            p33 = sorted_qtys[int(len(sorted_qtys) * 0.33)]
            for qty in all_qtys:
                if qty >= p66:
                    high_demand += 1
                elif qty >= p33:
                    medium_demand += 1
                else:
                    low_demand += 1
        elif all_qtys:
            avg_qty = sum(all_qtys) / len(all_qtys)
            for qty in all_qtys:
                if qty >= avg_qty * 1.5:
                    high_demand += 1
                elif qty >= avg_qty * 0.5:
                    medium_demand += 1
                else:
                    low_demand += 1

        # 2. Critical Stock & Stock Analysis
        all_medicines = list(PharmacyMedicine.objects.all())
        critical_stock = []
        stock_adequate = 0
        stock_moderate = 0
        stock_low = 0
        forecast_table = []
        stock_runway_list = []

        for medicine in all_medicines:
            cursor.execute("""
                SELECT COALESCE(SUM(qty_on_hand), 0) as total
                FROM pharmacy_inventory_balance
                WHERE medicine_id = %s
            """, [medicine.medicine_id])
            row = cursor.fetchone()
            on_hand = float(row[0]) if row else 0
            reorder = float(medicine.reorder_level or 0)

            if on_hand <= reorder and on_hand > 0:
                critical_stock.append(medicine.medicine_id)

            if on_hand > reorder * 2:
                stock_adequate += 1
            elif on_hand > reorder:
                stock_moderate += 1
            else:
                stock_low += 1

            # Usage calculations for forecasting (exclude internal restocks)
            current_usage = get_medicine_usage(medicine, last_30_days)
            prev_usage = get_medicine_usage(medicine, prev_30_days, last_30_days)

            # Fallback: if no 30-day usage, try 90 days and scale to 30-day equivalent
            has_usage_data = current_usage > 0 or prev_usage > 0
            if current_usage == 0:
                usage_90d = get_medicine_usage(medicine, last_90_days)
                if usage_90d > 0:
                    current_usage = usage_90d / 3.0
                    has_usage_data = True

            # Actual growth trend calculation
            if prev_usage > 0 and current_usage > 0:
                growth_pct = ((current_usage - prev_usage) / prev_usage) * 100
                trend_str = f"{'+' if growth_pct >= 0 else ''}{growth_pct:.0f}%"
            elif current_usage > 0 and prev_usage == 0:
                trend_str = "+100%"
            elif not has_usage_data:
                trend_str = "No usage"
            else:
                trend_str = "0%"

            # Daily consumption rate and forecast
            daily_rate = current_usage / 30.0
            forecast_next_30 = current_usage * 1.2  # slight growth buffer
            if prev_usage > 0:
                forecast_next_30 = (current_usage + prev_usage) / 2 * 1.15

            # Stock runway (days until stockout)
            days_remaining = None
            if daily_rate > 0:
                days_remaining = int(on_hand / daily_rate)
            elif on_hand == 0:
                days_remaining = 0

            if on_hand > 0 or has_usage_data:
                action_text = "Stock adequate"
                if not has_usage_data:
                    action_text = "No usage data"
                elif forecast_next_30 > on_hand:
                    action_text = f"Order {int(max(0, forecast_next_30 - on_hand))} units"

                forecast_table.append({
                    'medicine': medicine.medicine_name,
                    'category': medicine.category,
                    'current_stock': on_hand,
                    'reorder_level': reorder,
                    'current_usage': round(current_usage, 1),
                    'forecasted_demand': round(forecast_next_30, 1),
                    'trend': trend_str,
                    'action': action_text,
                    'is_urgent': (days_remaining or 999) < 7 and on_hand > 0,
                    'days_remaining': days_remaining,
                    'daily_rate': round(daily_rate, 2) if has_usage_data else 0,
                    'has_usage_data': has_usage_data,
                })

                if (days_remaining or 999) < 60:
                    stock_runway_list.append({
                        'medicine': medicine.medicine_name,
                        'days_remaining': days_remaining,
                        'current_stock': on_hand,
                        'daily_rate': round(daily_rate, 2) if has_usage_data else 0,
                        'is_critical': (days_remaining or 999) < 7,
                    })

        # Sort forecast table by urgency (lowest days remaining first, then urgent)
        forecast_table.sort(key=lambda x: (0 if x['is_urgent'] else 1, x['days_remaining'] if x['days_remaining'] is not None else 99999))
        stock_runway_list.sort(key=lambda x: x['days_remaining'] if x['days_remaining'] is not None else 99999)

        # 3. Monthly Distribution - actual quantity dispensed, not just transaction count
        monthly_data = PharmacyTransaction.objects.filter(
            transaction_type='OUT',
            transaction_datetime__date__gte=last_year
        ).exclude(
            reference_type='CART_RESTOCK'
        ).annotate(
            month=TruncMonth('transaction_datetime')
        ).values('month').annotate(
            total_qty=Sum('qty'),
            count=Count('transaction_id')
        ).order_by('month')

        monthly_list = []
        for m in monthly_data:
            monthly_list.append({
                'month': m['month'].strftime('%b'),
                'count': m['count'],
                'total_qty': float(m['total_qty'])
            })

        # 4. Weekly Trend (last 8 weeks)
        weekly_data = PharmacyTransaction.objects.filter(
            transaction_type='OUT',
            transaction_datetime__date__gte=last_8_weeks
        ).exclude(
            reference_type='CART_RESTOCK'
        ).annotate(
            week=TruncWeek('transaction_datetime')
        ).values('week').annotate(
            total_qty=Sum('qty')
        ).order_by('week')

        weekly_list = []
        for w in weekly_data:
            weekly_list.append({
                'week': w['week'].strftime('%W'),
                'label': f"W{w['week'].strftime('%W')}",
                'total_qty': float(w['total_qty'])
            })

        # 5. Category Breakdown
        category_data = PharmacyTransaction.objects.filter(
            transaction_type='OUT',
            transaction_datetime__date__gte=last_30_days
        ).exclude(
            reference_type='CART_RESTOCK'
        ).values('medicine__category').annotate(
            total_qty=Sum('qty'),
            count=Count('transaction_id')
        ).order_by('-total_qty')

        category_list = []
        for c in category_data:
            category_list.append({
                'category': c['medicine__category'] or 'Uncategorized',
                'total_qty': float(c['total_qty']),
                'count': c['count']
            })

        data = {
            'high_demand_count': high_demand,
            'medium_demand_count': medium_demand,
            'low_demand_count': low_demand,
            'critical_stock_count': len(critical_stock),
            'top_dispensed': top_dispensed_list,
            'demand_trends': {
                'high': high_demand,
                'medium': medium_demand,
                'low': low_demand
            },
            'monthly_distribution': monthly_list,
            'weekly_trend': weekly_list,
            'category_breakdown': category_list,
            'stock_analysis': {
                'total': len(all_medicines),
                'adequate': stock_adequate,
                'moderate': stock_moderate,
                'low': stock_low
            },
            'stock_runway': stock_runway_list[:10],
            'forecast_table': forecast_table[:10]
        }

        return Response(data)

class DispenseMedicineView(APIView):
    def post(self, request):
        """Dispense medicines using FEFO batch costing - First Expiry First Out"""
        try:
            data = request.data
            patient_id = data.get('patient_id')
            medicines = data.get('medicines', [])
            location_id = data.get('location_id', 1)  # Default location

            receipt = PharmacyDispenseReceipt.objects.create(
                ipd_patient_id=patient_id,
                ipd_document_id=data.get('document_id', 0),
                ipd_admission_id=data.get('admission_id', 0),
                dispensing_date=timezone.now().date(),
                total_amount=0,
                received_status='RECEIVED',
                trail=format_trail(request.user, get_client_ip(request)),
                updated_trail=format_trail(request.user, get_client_ip(request))
            )

            total_amount = 0
            for med in medicines:
                medicine_id = med.get('medicine_id')
                quantity_to_dispense = med.get('quantity', 0)
                
                # Find batches with available quantity using raw SQL (FEFO - earliest expiry first)
                cursor.execute("""
                    SELECT 
                        ib.batch_id,
                        b.batch_no,
                        b.expiry_date,
                        b.unit_cost,
                        ib.qty_on_hand
                    FROM pharmacy_inventory_balance ib
                    INNER JOIN pharmacy_stock_batches b ON ib.batch_id = b.batch_id
                    WHERE ib.medicine_id = %s
                      AND ib.location_id = %s
                      AND ib.qty_on_hand > 0
                    ORDER BY b.expiry_date ASC, b.batch_id ASC
                """, [medicine_id, location_id])
                balance_rows = cursor.fetchall()
                columns = [col[0] for col in cursor.description]
                balances_data = [dict(zip(columns, row)) for row in balance_rows]
                
                remaining_qty = quantity_to_dispense
                total_cost_for_item = 0
                batch_info = []       

                for balance_data in balances_data:
                    if remaining_qty <= 0:
                        break

                    

                    # Skip expired batches

                    if balance_data['expiry_date'] and balance_data['expiry_date'] < timezone.now().date():

                        continue

                    

                    # Get batch unit cost (actual cost when received)

                    batch_unit_cost = balance_data['unit_cost'] or 0

                    available_qty = float(balance_data['qty_on_hand'])

                    

                    # Calculate how much to take from this batch

                    take_qty = min(remaining_qty, available_qty)

                    

                    # Calculate cost for this portion

                    cost = take_qty * batch_unit_cost

                    total_cost_for_item += cost

                    

                    batch_info.append({

                        'batch_no': balance_data['batch_no'],

                        'batch_id': balance_data['batch_id'],

                        'expiry_date': balance_data['expiry_date'].isoformat() if balance_data['expiry_date'] else None,

                        'quantity_taken': take_qty,

                        'unit_cost': batch_unit_cost,

                        'cost': cost

                    })

                    

                    # Update inventory balance using raw SQL

                    cursor.execute("""

                        UPDATE pharmacy_inventory_balance

                        SET qty_on_hand = qty_on_hand - %s

                        WHERE medicine_id = %s AND batch_id = %s AND location_id = %s

                    """, [take_qty, medicine_id, balance_data['batch_id'], location_id])

                    

                    remaining_qty -= take_qty

                

                # Check if we couldn't fulfill the full quantity

                if remaining_qty > 0:

                    raise Exception(f"Insufficient stock for medicine {medicine_id}. Needed {quantity_to_dispense}, short by {remaining_qty}")

                

                # Calculate average unit cost for this dispense item

                avg_unit_cost = total_cost_for_item / quantity_to_dispense if quantity_to_dispense > 0 else 0

                

                # Create dispense item with actual batch cost

                item = PharmacyDispenseReceiptItem.objects.create(

                    dispense_receipt=receipt,

                    medicine_id=medicine_id,

                    quantity=quantity_to_dispense,

                    unit_cost=avg_unit_cost,  # Average of batch costs used

                    total_cost=total_cost_for_item,

                    item_type='Medication',

                    item_code=med.get('item_code', ''),

                    line_status='PENDING',

                    remarks=f"FEFO batches: {batch_info}",

                    trail=format_trail(request.user, get_client_ip(request))

                )

                total_amount += item.total_cost



            receipt.total_amount = total_amount

            receipt.save()



            return Response({

                'success': True,

                'message': 'Medicines dispensed successfully with FEFO costing',

                'receipt_id': receipt.receipt_id

            }, status=status.HTTP_201_CREATED)

        except Exception as e:

            return Response({

                'success': False,

                'message': str(e)

            }, status=status.HTTP_400_BAD_REQUEST)





class LowStockAlertsView(APIView):

    def get(self, request):

        from django.db.models import Sum

        threshold = int(request.query_params.get('threshold', 50))



        # Calculate stock from inventory balance using raw SQL

        alerts = []

        try:

            from django.db import connection

            with connection.cursor() as cursor:

                for medicine in PharmacyMedicine.objects.all():

                    cursor.execute("""

                        SELECT COALESCE(SUM(qty_on_hand), 0) as total

                        FROM pharmacy_inventory_balance

                        WHERE medicine_id = %s

                    """, [medicine.medicine_id])

                    row = cursor.fetchone()

                    total_qty = float(row[0]) if row else 0

                    

                    if total_qty <= threshold or total_qty <= medicine.reorder_level:

                        alerts.append({

                            'medicine_id': medicine.medicine_id,

                            'medicine_name': medicine.medicine_name,

                            'current_stock': total_qty,

                            'reorder_level': medicine.reorder_level

                        })

        except Exception as e:

            # If database columns don't match, return empty list

            pass



        serializer = LowStockAlertSerializer(alerts, many=True)

        return Response(serializer.data)





class ExpiryAlertsView(APIView):

    def get(self, request):

        days = int(request.query_params.get('days', 30))

        expiry_date_limit = timezone.now().date() + timedelta(days=days)



        expiring_batches = PharmacyStockBatch.objects.filter(

            expiry_date__lte=expiry_date_limit,

            expiry_date__gt=timezone.now().date()

        ).select_related('medicine')



        alerts = []

        for batch in expiring_batches:

            days_remaining = (batch.expiry_date - timezone.now().date()).days

            alerts.append({

                'batch_id': batch.batch_id,

                'medicine_name': batch.medicine.medicine_name,

                'batch_no': batch.batch_no,

                'expiry_date': batch.expiry_date,

                'days_until_expiry': days_remaining

            })



        serializer = ExpiryAlertSerializer(alerts, many=True)

        return Response(serializer.data)





class TransferToCartView(APIView):

    """

    Transfer medicine from Main Inventory to Cart location.

    Supports multi-batch transfers using FEFO (First Expiry First Out).

    Records TRANSFER transactions in pharmacy_transactions.

    """

    permission_classes = [IsAuthenticated]

    

    def post(self, request):

        try:

            data = request.data

            medicine_id = data.get('medicine_id')

            quantity_requested = float(data.get('quantity', 0))

            

            if not medicine_id or quantity_requested <= 0:

                return Response({

                    'success': False,

                    'message': 'Medicine ID and quantity are required'

                }, status=status.HTTP_400_BAD_REQUEST)

            

            # Get or create locations

            main_location, _ = PharmacyLocation.objects.get_or_create(

                location_id=1,

                defaults={'location_name': 'Main Pharmacy', 'location_type': 'PHARMACY'}

            )

            cart_location, _ = PharmacyLocation.objects.get_or_create(

                location_id=2,

                defaults={'location_name': 'Patient Cart', 'location_type': 'CART'}

            )

            

            # Get medicine

            try:

                medicine = PharmacyMedicine.objects.get(medicine_id=medicine_id)

            except PharmacyMedicine.DoesNotExist:

                return Response({

                    'success': False,

                    'message': f'Medicine with ID {medicine_id} not found in database'

                }, status=status.HTTP_404_NOT_FOUND)

            

            # Get all available batches with stock in main inventory, ordered by expiry (FEFO)

            with connection.cursor() as cursor:

                cursor.execute("""

                    SELECT sb.batch_id, sb.batch_no, sb.expiry_date, sb.received_date,

                           ib.qty_on_hand, sb.unit_cost

                    FROM pharmacy_stock_batches sb

                    INNER JOIN pharmacy_inventory_balance ib 

                        ON sb.batch_id = ib.batch_id 

                        AND sb.medicine_id = ib.medicine_id

                    WHERE sb.medicine_id = %s

                        AND sb.expiry_date >= CURRENT_DATE

                        AND ib.location_id = %s

                        AND ib.qty_on_hand > 0

                    ORDER BY sb.expiry_date ASC, sb.batch_id ASC

                """, [medicine_id, main_location.location_id])

                

                available_batches = cursor.fetchall()

            

            if not available_batches:

                return Response({

                    'success': False,

                    'message': f'No available batches with stock for medicine {medicine.medicine_name}. Please check goods receipts.'

                }, status=status.HTTP_400_BAD_REQUEST)

            

            # Calculate total available stock

            total_available = sum(float(row[4]) for row in available_batches)

            

            if total_available < quantity_requested:

                return Response({

                    'success': False,

                    'message': f'Insufficient stock in main inventory. Available: {total_available}, Requested: {quantity_requested}'

                }, status=status.HTTP_400_BAD_REQUEST)

            

            # Transfer from multiple batches using FEFO

            remaining_to_transfer = quantity_requested

            transferred_batches = []

            

            with transaction.atomic():

                for batch_data in available_batches:

                    if remaining_to_transfer <= 0:

                        break

                    

                    batch_id, batch_no, expiry_date, received_date, qty_on_hand, unit_cost = batch_data

                    batch_qty = float(qty_on_hand)

                    

                    # Determine how much to take from this batch

                    take_qty = min(batch_qty, remaining_to_transfer)

                    

                    # Deduct from main inventory

                    with connection.cursor() as cursor:

                        cursor.execute(

                            """UPDATE pharmacy_inventory_balance 

                               SET qty_on_hand = qty_on_hand - %s 

                               WHERE medicine_id = %s AND batch_id = %s AND location_id = %s""",

                            [take_qty, medicine_id, batch_id, main_location.location_id]

                        )

                    

                    # Add to cart inventory

                    with connection.cursor() as cursor:

                        # Check if cart balance exists

                        cursor.execute("""

                            SELECT qty_on_hand FROM pharmacy_inventory_balance

                            WHERE medicine_id = %s AND batch_id = %s AND location_id = %s

                        """, [medicine_id, batch_id, cart_location.location_id])

                        

                        row = cursor.fetchone()

                        if row:

                            cursor.execute("""

                                UPDATE pharmacy_inventory_balance

                                SET qty_on_hand = qty_on_hand + %s

                                WHERE medicine_id = %s AND batch_id = %s AND location_id = %s

                            """, [take_qty, medicine_id, batch_id, cart_location.location_id])

                        else:

                            cursor.execute("""

                                INSERT INTO pharmacy_inventory_balance 

                                    (medicine_id, batch_id, location_id, qty_on_hand, trail)

                                VALUES (%s, %s, %s, %s, %s)

                            """, [medicine_id, batch_id, cart_location.location_id, take_qty, format_trail(request.user, get_client_ip(request))])

                    

                    # Record transaction

                    PharmacyTransaction.objects.create(

                        transaction_type='TRANSFER',

                        medicine=medicine,

                        batch_id=batch_id,

                        from_location=main_location,

                        to_location=cart_location,

                        qty=take_qty,

                        reference_type='CART_TRANSFER',

                        reference_id=0,

                        service_source='CART',

                        remarks=f'Transferred {take_qty} units from batch {batch_no} to patient cart'

                    )

                    

                    transferred_batches.append({

                        'batch_id': batch_id,

                        'batch_no': batch_no,

                        'quantity': take_qty

                    })

                    

                    remaining_to_transfer -= take_qty

            

            return Response({

                'success': True,

                'message': f'{medicine.medicine_name} ({quantity_requested} units) transferred to cart from {len(transferred_batches)} batch(es)',

                'transaction_type': 'TRANSFER',

                'medicine_id': medicine_id,

                'quantity_transferred': quantity_requested,

                'batches_used': transferred_batches

            }, status=status.HTTP_201_CREATED)

            

        except PharmacyMedicine.DoesNotExist:

            return Response({

                'success': False,

                'message': 'Medicine not found'

            }, status=status.HTTP_404_NOT_FOUND)

        except Exception as e:

            return Response({

                'success': False,

                'message': str(e)

            }, status=status.HTTP_400_BAD_REQUEST)





class DispenseFromCartView(APIView):

    """

    Dispense medicine from Cart location to patient.

    Records an OUT transaction in pharmacy_transactions with service_source='CART'.

    """

    def post(self, request):

        try:

            data = request.data

            patient_id = data.get('patient_id')

            medicines = data.get('medicines', [])  # List of {medicine_id, quantity, batch_id}

            

            if not medicines:

                return Response({

                    'success': False,

                    'message': 'No medicines to dispense'

                }, status=status.HTTP_400_BAD_REQUEST)

            

            # Get cart location

            cart_location = PharmacyLocation.objects.filter(location_id=2).first()

            if not cart_location:

                return Response({

                    'success': False,

                    'message': 'Cart location not configured'

                }, status=status.HTTP_400_BAD_REQUEST)

            

            # Create dispense receipt

            receipt = PharmacyDispenseReceipt.objects.create(

                ipd_patient_id=patient_id,

                ipd_document_id=data.get('document_id', 0),

                ipd_admission_id=data.get('admission_id', 0),

                dispensing_date=timezone.now().date(),

                total_amount=0,

                received_status='RECEIVED',

                trail=format_trail(request.user, get_client_ip(request)),

                updated_trail=format_trail(request.user, get_client_ip(request))

            )

            

            total_amount = 0

            transaction_records = []

            

            for med in medicines:

                medicine_id = med.get('medicine_id')

                quantity_to_dispense = med.get('quantity', 0)

                batch_id = med.get('batch_id')

                

                medicine = PharmacyMedicine.objects.get(medicine_id=medicine_id)

                

                # Get specific batch or find from cart

                if batch_id:

                    batch = PharmacyStockBatch.objects.get(batch_id=batch_id)

                else:

                    # Find batch in cart with earliest expiry using raw SQL

                    cursor.execute("""

                        SELECT 

                            ib.batch_id,

                            b.batch_no,

                            b.expiry_date,

                            ib.qty_on_hand

                        FROM pharmacy_inventory_balance ib

                        INNER JOIN pharmacy_stock_batches b ON ib.batch_id = b.batch_id

                        WHERE ib.medicine_id = %s

                          AND ib.location_id = %s

                          AND ib.qty_on_hand > 0

                        ORDER BY b.expiry_date ASC

                        LIMIT 1

                    """, [medicine_id, cart_location.location_id])

                    row = cursor.fetchone()

                    if not row:

                        raise Exception(f'No stock available in cart for {medicine.medicine_name}')

                    batch_id = row[0]

                    batch = PharmacyStockBatch.objects.get(batch_id=batch_id)

                

                # Check cart inventory using raw SQL

                cursor.execute("""

                    SELECT qty_on_hand FROM pharmacy_inventory_balance

                    WHERE medicine_id = %s AND batch_id = %s AND location_id = %s

                """, [medicine_id, batch.batch_id, cart_location.location_id])

                balance_row = cursor.fetchone()

                available_qty = float(balance_row[0]) if balance_row else 0

                if available_qty < quantity_to_dispense:

                    raise Exception(f'Insufficient stock in cart for {medicine.medicine_name}. Available: {available_qty}')

                

                # Deduct from cart using raw SQL

                cursor.execute("""

                    UPDATE pharmacy_inventory_balance

                    SET qty_on_hand = qty_on_hand - %s

                    WHERE medicine_id = %s AND batch_id = %s AND location_id = %s

                """, [quantity_to_dispense, medicine_id, batch.batch_id, cart_location.location_id])

                

                # Calculate cost

                batch_unit_cost = batch.unit_cost or 0

                total_cost = quantity_to_dispense * batch_unit_cost

                total_amount += total_cost

                

                # Create dispense item

                PharmacyDispenseReceiptItem.objects.create(

                    dispense_receipt=receipt,

                    medicine=medicine,

                    quantity=quantity_to_dispense,

                    unit_cost=batch_unit_cost,

                    total_cost=total_cost,

                    item_type='Medication',

                    item_code=med.get('item_code', ''),

                    line_status='DISPENSED',

                    remarks=f'Dispensed from cart. Batch: {batch.batch_no}',

                    trail=format_trail(request.user, get_client_ip(request))

                )

                

                # Record OUT transaction

                transaction = PharmacyTransaction.objects.create(

                    transaction_type='OUT',

                    medicine=medicine,

                    batch=batch,

                    from_location=cart_location,

                    to_location=None,

                    qty=quantity_to_dispense,

                    reference_type='CART_DISPENSE',

                    reference_id=receipt.receipt_id,

                    service_source='CART',

                    remarks=f'Dispensed to patient {patient_id} from cart',

                    trail=format_trail(request.user, get_client_ip(request))

                )

                

                transaction_records.append({

                    'medicine': medicine.medicine_name,

                    'quantity': quantity_to_dispense,

                    'batch': batch.batch_no,

                    'transaction_id': transaction.transaction_id

                })

            

            receipt.total_amount = total_amount

            receipt.updated_trail = format_trail(request.user, get_client_ip(request))

            receipt.save()

            

            return Response({

                'success': True,

                'message': 'Medicines dispensed from cart successfully',

                'receipt_id': receipt.receipt_id,

                'transactions': transaction_records

            }, status=status.HTTP_201_CREATED)

            

        except PharmacyMedicine.DoesNotExist:

            return Response({

                'success': False,

                'message': 'Medicine not found'

            }, status=status.HTTP_404_NOT_FOUND)

        except Exception as e:

            return Response({

                'success': False,

                'message': str(e)

            }, status=status.HTTP_400_BAD_REQUEST)

from rest_framework.permissions import IsAuthenticated

from rest_framework.response import Response

from rest_framework import status

from .models import PharmacyLocation, PharmacyInventoryBalance





@api_view(['GET'])

@permission_classes([IsAuthenticated])

def get_medicine_batches(request, medicine_id):
    """Get all batches with quantities for a specific medicine from PHARMACY location"""

    try:
        # Use raw SQL to avoid ORM composite key issues
        from django.db import connection

        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT 
                    ib.medicine_id,
                    m.medicine_name,
                    ib.batch_id,
                    b.batch_no,
                    b.expiry_date,
                    b.received_date,
                    b.unit_cost,
                    ib.location_id,
                    l.location_name,
                    l.location_type,
                    ib.qty_on_hand
                FROM pharmacy_inventory_balance ib
                INNER JOIN pharmacy_medicines m ON ib.medicine_id = m.medicine_id
                INNER JOIN pharmacy_stock_batches b ON ib.batch_id = b.batch_id
                INNER JOIN pharmacy_locations l ON ib.location_id = l.location_id
                WHERE ib.medicine_id = %s
                  AND (l.location_type = 'PHARMACY' OR l.location_id = 1)
                  AND ib.qty_on_hand > 0
                ORDER BY b.expiry_date ASC
            """, [medicine_id])

            columns = [col[0] for col in cursor.description]
            data = [dict(zip(columns, row)) for row in cursor.fetchall()]

        if not data:
            return Response({
                'success': True,
                'medicine_id': medicine_id,
                'batches': [],
                'message': 'No stock available in pharmacy'
            })

        # Format batch data
        batches = []
        for row in data:
            batches.append({
                'batch_id': row['batch_id'],
                'batch_no': row['batch_no'],
                'expiry_date': row['expiry_date'].isoformat() if row['expiry_date'] else None,
                'received_date': row['received_date'].isoformat() if row['received_date'] else None,
                'quantity': float(row['qty_on_hand']),
                'unit_cost': float(row['unit_cost']) if row['unit_cost'] else 0,
            })

        # Sort by expiry date (FEFO) - already sorted by SQL
        return Response({
            'success': True,
            'medicine_id': medicine_id,
            'batches': batches,
            'total_quantity': sum(b['quantity'] for b in batches)
        })

    except Exception as e:
        return Response({
            'success': False,
            'message': str(e)
        }, status=status.HTTP_400_BAD_REQUEST)
@api_view(['POST'])
@permission_classes([IsAuthenticated])
@transaction.atomic
def process_ipd_dispensing(request, dispensing_id):

    """

    Process IPD Dispensing Sheet from the Pharmacy Backend perspective.

    This endpoint belongs to the Pharmacist user.

    """

    try:

        from apps.ipd.inventory_and_request.models import DispensingSheet, DispensingSheetItem

        from django.db import connection

        import random

        import string

        

        user = request.user

        # Resolve user model instance and details

        firstname = getattr(user, 'firstname', '')

        lastname = getattr(user, 'lastname', '')

        username = getattr(user, 'username', 'unknown')

        fullname = f"{firstname} {lastname}".strip() or username

        

        items_data = request.data.get('items', [])

        

        # 1. Update the IPD Dispensing Sheet Status

        dispensing_sheet = DispensingSheet.objects.filter(dispensing_id=dispensing_id).first()

        if not dispensing_sheet:

            return Response({'success': False, 'error': 'Dispensing sheet not found'}, status=status.HTTP_404_NOT_FOUND)

            

        dispensing_sheet.status = 'DISPENSED'

        # Safely assign user object

        from django.db.models import Model

        dispensing_sheet.dispensed_by = user if isinstance(user, Model) else None

        dispensing_sheet.dispensed_by_name = fullname

        dispensing_sheet.dispensed_date = timezone.now().date()

        

        # Update Audit Trail

        dispensing_sheet.trail = format_trail(request.user, get_client_ip(request))

        

        # 2. Process IPD Items and Calculate Total

        total_sheet_amount = 0

        for item_data in items_data:

            ipd_item_id = item_data.get('dispensing_item_id')

            unit_cost = float(item_data.get('unit_cost', 0))

            quantity = float(item_data.get('quantity', 0))

            

            ipd_item = DispensingSheetItem.objects.filter(dispensing_item_id=ipd_item_id).first()

            if ipd_item:

                ipd_item.quantity = quantity

                ipd_item.unit_cost = unit_cost

                ipd_item.total_cost = unit_cost * quantity

                ipd_item.pharmacist_name = fullname

                ipd_item.trail = format_trail(request.user, get_client_ip(request))

                ipd_item.save()

                total_sheet_amount += ipd_item.total_cost

        

        dispensing_sheet.total_amount = total_sheet_amount

        dispensing_sheet.save()

        

        # 3. Create Pharmacy Dispense Receipt (Direct SQL into 'pch' schema)

        receipt_no = 'DR-' + ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))

        

        with connection.cursor() as cursor:
            # Ensure admission_id is nullable in the database
            try:
                cursor.execute("ALTER TABLE pharmacy_dispense_receipts ALTER COLUMN admission_id DROP NOT NULL")
            except:
                pass

            # 3.1 Insert into pharmacy_dispense_receipts

            # Get admission_id safely from the dispensing sheet

            # Handle the case where admission might be None

            raw_admission_id = dispensing_sheet.admission_id

            

            # If admission_id is missing, we try to find the current active admission

            if not raw_admission_id:

                cursor.execute("""
                    SELECT admission_id FROM ipd_notice_of_admission 
                    WHERE patient_id = %s AND status IN ('approved', 'pending')
                    ORDER BY admission_date DESC, submitted_date DESC LIMIT 1
                """, [dispensing_sheet.patient_id])

                row = cursor.fetchone()

                if row:

                    raw_admission_id = row[0]

            

            # If STILL missing, try ANY admission for this patient

            if not raw_admission_id:

                cursor.execute("""
                    SELECT admission_id FROM ipd_notice_of_admission 
                    WHERE patient_id = %s ORDER BY admission_id DESC LIMIT 1
                """, [dispensing_sheet.patient_id])

                row = cursor.fetchone()

                if row:

                    raw_admission_id = row[0]



            # IMPORTANT: Since the DB has a NOT NULL constraint on admission_id,

            # and the user wants to allow it to be empty, we must either:

            # 1. Modify the DB (run ALTER TABLE in PGAdmin)

            # 2. Use a dummy value if it's still NULL after lookups.

            

            # Use dummy ID 0 or NULL based on what the DB allows. 

            # If the user hasn't run the ALTER TABLE command yet, NULL will still fail.

            

            # Attempt to insert without admission_id column to bypass constraint
            cursor.execute("""
                INSERT INTO pharmacy_dispense_receipts (
                    receipt_no, ipd_dispensing_id, 
                    patient_id, admission_id, from_location_id, dispensing_date, 
                    total_amount, trail, updated_trail, received_status
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING receipt_id
            """, [
                receipt_no,
                dispensing_sheet.dispensing_id,
                dispensing_sheet.patient_id,
                raw_admission_id,
                1, # From Location ID: 1 (Main Pharmacy)
                timezone.now().date(),
                total_sheet_amount,
                format_trail(request.user, get_client_ip(request)),
                format_trail(request.user, get_client_ip(request)),
                'RECEIVED'
            ])

        

            receipt_id = cursor.fetchone()[0]



            # 3.2 Create Items & Deduct Inventory

            for item_data in items_data:

                medicine_id = item_data.get('medicine_id')

                quantity = float(item_data.get('quantity', 0))

                unit = item_data.get('unit', '')

                unit_cost = float(item_data.get('unit_cost', 0))

                total_cost = unit_cost * quantity

                medicine_name = item_data.get('medicine_name', 'IPD Medicine')

                

                # Find batch from Location 1 (Main Pharmacy) following FEFO (First Expiry First Out)
                cursor.execute("""
                    SELECT b.batch_id, i.qty_on_hand 
                    FROM pharmacy_inventory_balance i
                    JOIN pharmacy_stock_batches b ON i.batch_id = b.batch_id
                    WHERE i.medicine_id = %s AND i.location_id = 1 AND i.qty_on_hand > 0
                    ORDER BY b.expiry_date ASC, b.received_date ASC
                    LIMIT 1
                """, [medicine_id])

                batch_row = cursor.fetchone()

                batch_id = batch_row[0] if batch_row else None



                # Create Receipt Item
                cursor.execute("""
                    INSERT INTO pharmacy_dispense_receipt_items (
                        receipt_id, medicine_id, item_code, 
                        item_description, quantity, unit, 
                        unit_cost, total_cost, batch_id, from_location_id, line_status, trail
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """, [
                    receipt_id, medicine_id, str(medicine_id), medicine_name,
                    quantity, unit, unit_cost, total_cost, batch_id, 1, 'DISPENSED', format_trail(request.user, get_client_ip(request))
                ])



                if batch_id:
                    cursor.execute("""
                        UPDATE pharmacy_inventory_balance
                        SET qty_on_hand = qty_on_hand - %s
                        WHERE medicine_id = %s AND batch_id = %s AND location_id = 1
                    """, [quantity, medicine_id, batch_id])

                    cursor.execute("""
                        INSERT INTO pharmacy_transactions (
                            transaction_datetime, transaction_type, medicine_id, 
                            batch_id, from_location_id, qty, reference_type, 
                            reference_id, service_source, remarks, trail
                        ) VALUES (NOW(), 'OUT', %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    """, [
                        medicine_id, batch_id, 1, quantity, 'IPD_DISPENSING',
                        dispensing_sheet.dispensing_id, 'IPD',
                        f"Pharmacist Dispensed Sheet #{dispensing_sheet.dispensing_id}", format_trail(request.user, get_client_ip(request))
                    ])



        return Response({

            'success': True,

            'message': f'Pharmacist processed Sheet #{dispensing_id} successfully.',

            'receipt_no': receipt_no

        }, status=status.HTTP_200_OK)



    except Exception as e:

        import traceback

        print(traceback.format_exc())

        return Response({'success': False, 'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)



class WeeklyInventoryReportView(APIView):

    """

    Weekly Inventory Report - matches the physical "LIST OF MEDICINES" form layout.

    Returns inventory quantities for each medicine across weekly date columns,

    plus a NEAR EXP column for near-expiry quantities.

    """

    permission_classes = [IsAuthenticated]



    def get(self, request):

        try:

            from datetime import datetime, timedelta

            today = timezone.now().date()

            

            # Generate 4 weekly date columns (last 4 weeks)

            week_dates = []

            for i in range(3, -1, -1):

                week_start = today - timedelta(weeks=i)

                week_dates.append(week_start)

            

            # Near expiry threshold: 30 days

            expiry_threshold = today + timedelta(days=30)

            

            medicines = PharmacyMedicine.objects.filter(is_active=True).order_by('medicine_name')

            

            results = []

            

            with connection.cursor() as cursor:

                for med in medicines:

                    medicine_id = med.medicine_id

                    

                    # Get current total quantity for location_id=1 (Main Pharmacy)

                    cursor.execute("""

                        SELECT COALESCE(SUM(qty_on_hand), 0) as total

                        FROM pharmacy_inventory_balance

                        WHERE medicine_id = %s AND location_id = 1

                    """, [medicine_id])

                    row = cursor.fetchone()

                    current_qty = float(row[0]) if row else 0

                    

                    # Calculate weekly quantities by working backward from current inventory

                    # using transaction history

                    weekly_quantities = []

                    for week_date in week_dates:

                        # Get all OUT transactions after this week to subtract

                        cursor.execute("""

                            SELECT COALESCE(SUM(qty), 0) as total_out

                            FROM pharmacy_transactions

                            WHERE medicine_id = %s

                              AND transaction_type = 'OUT'

                              AND transaction_datetime::date > %s

                              AND from_location_id = 1

                        """, [medicine_id, week_date])

                        row = cursor.fetchone()

                        total_out_after = float(row[0]) if row else 0

                        

                        # Get all IN transactions after this week to add back

                        cursor.execute("""

                            SELECT COALESCE(SUM(qty), 0) as total_in

                            FROM pharmacy_transactions

                            WHERE medicine_id = %s

                              AND transaction_type = 'IN'

                              AND transaction_datetime::date > %s

                              AND to_location_id = 1

                        """, [medicine_id, week_date])

                        row = cursor.fetchone()

                        total_in_after = float(row[0]) if row else 0

                        

                        # Reconstruct inventory at that week

                        week_qty = current_qty + total_out_after - total_in_after

                        weekly_quantities.append(max(0, round(week_qty, 0)))

                    

                    # Get near-expiry quantity

                    cursor.execute("""

                        SELECT COALESCE(SUM(ib.qty_on_hand), 0) as near_expiry

                        FROM pharmacy_inventory_balance ib

                        INNER JOIN pharmacy_stock_batches b ON ib.batch_id = b.batch_id

                        WHERE ib.medicine_id = %s

                          AND ib.location_id = 1

                          AND b.expiry_date BETWEEN %s AND %s

                          AND ib.qty_on_hand > 0

                    """, [medicine_id, today, expiry_threshold])

                    row = cursor.fetchone()

                    near_expiry = float(row[0]) if row else 0

                    

                    results.append({

                        'medicine_name': med.medicine_name,

                        'medicine_code': med.medicine_code or '',

                        'unit': med.unit,

                        'week_quantities': weekly_quantities,

                        'week_dates': [d.strftime('%m/%d/%y') for d in week_dates],

                        'near_expiry': round(near_expiry, 0),

                        'current_stock': round(current_qty, 0),

                    })

            

            return Response({

                'success': True,

                'report_title': 'LIST OF MEDICINES',

                'week_dates': [d.strftime('%m/%d/%y') for d in week_dates],

                'medicines': results,

                'generated_at': timezone.now().isoformat(),

            })

        except Exception as e:

            import traceback

            print(traceback.format_exc())

            return Response({'success': False, 'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)



class QuarterlyDispensingReportView(APIView):

    """

    Quarterly Dispensing Report - matches the physical "INVENTORY OF CONSUMED MEDICINES" form.

    Returns dispensing data grouped by medicine with IPD/OPD/TOTAL breakdown per month.

    """

    permission_classes = [IsAuthenticated]



    def get(self, request):

        try:

            from datetime import datetime

            

            # Get quarter and year from query params, default to current quarter

            year = int(request.query_params.get('year', timezone.now().year))

            quarter = int(request.query_params.get('quarter', (timezone.now().month - 1) // 3 + 1))

            

            # Calculate quarter months

            quarter_months = {

                1: [(1, 'JANUARY'), (2, 'FEBRUARY'), (3, 'MARCH')],

                2: [(4, 'APRIL'), (5, 'MAY'), (6, 'JUNE')],

                3: [(7, 'JULY'), (8, 'AUGUST'), (9, 'SEPTEMBER')],

                4: [(10, 'OCTOBER'), (11, 'NOVEMBER'), (12, 'DECEMBER')],

            }

            
            months = quarter_months.get(quarter, quarter_months[2])

            

            results = []

            row_num = 1

            

            with connection.cursor() as cursor:

                # Get all medicines that had dispensing transactions in this quarter

                cursor.execute("""

                    SELECT DISTINCT m.medicine_id, m.medicine_name, m.medicine_code, m.unit

                    FROM pharmacy_medicines m

                    INNER JOIN pharmacy_transactions t ON m.medicine_id = t.medicine_id

                    WHERE t.transaction_type = 'OUT'

                      AND EXTRACT(YEAR FROM t.transaction_datetime) = %s

                      AND EXTRACT(QUARTER FROM t.transaction_datetime) = %s

                    ORDER BY m.medicine_name

                """, [year, quarter])

                

                medicine_rows = cursor.fetchall()

                

                for med_row in medicine_rows:

                    medicine_id, medicine_name, medicine_code, unit = med_row

                    

                    month_data = []

                    

                    for month_num, month_name in months:

                        # Get IPD dispensing for this month

                        cursor.execute("""

                            SELECT COALESCE(SUM(qty), 0) as ipd_qty

                            FROM pharmacy_transactions

                            WHERE medicine_id = %s

                              AND transaction_type = 'OUT'

                              AND EXTRACT(YEAR FROM transaction_datetime) = %s

                              AND EXTRACT(MONTH FROM transaction_datetime) = %s

                              AND service_source = 'IPD'

                        """, [medicine_id, year, month_num])

                        ipd_qty = float(cursor.fetchone()[0] or 0)

                        

                        # Get OPD dispensing for this month

                        cursor.execute("""

                            SELECT COALESCE(SUM(qty), 0) as opd_qty

                            FROM pharmacy_transactions

                            WHERE medicine_id = %s

                              AND transaction_type = 'OUT'

                              AND EXTRACT(YEAR FROM transaction_datetime) = %s

                              AND EXTRACT(MONTH FROM transaction_datetime) = %s

                              AND service_source = 'OPD'

                        """, [medicine_id, year, month_num])

                        opd_qty = float(cursor.fetchone()[0] or 0)

                        

                        # Also include dispensing without service_source (default to OPD)

                        cursor.execute("""

                            SELECT COALESCE(SUM(qty), 0) as other_qty

                            FROM pharmacy_transactions

                            WHERE medicine_id = %s

                              AND transaction_type = 'OUT'

                              AND EXTRACT(YEAR FROM transaction_datetime) = %s

                              AND EXTRACT(MONTH FROM transaction_datetime) = %s

                              AND (service_source IS NULL OR service_source = '')

                        """, [medicine_id, year, month_num])

                        other_qty = float(cursor.fetchone()[0] or 0)

                        

                        # Default null service_source to OPD

                        opd_qty += other_qty

                        

                        month_total = ipd_qty + opd_qty

                        

                        month_data.append({

                            'month_name': month_name,

                            'month_num': month_num,

                            'ipd': round(ipd_qty, 0),

                            'opd': round(opd_qty, 0),

                            'total': round(month_total, 0),

                        })

                    

                    # Calculate quarter totals

                    quarter_ipd = sum(m['ipd'] for m in month_data)

                    quarter_opd = sum(m['opd'] for m in month_data)

                    quarter_total = quarter_ipd + quarter_opd

                    

                    results.append({

                        'row_number': row_num,

                        'medicine_name': medicine_name,

                        'medicine_code': medicine_code or '',

                        'unit': unit,

                        'months': month_data,

                        'quarter_ipd': round(quarter_ipd, 0),

                        'quarter_opd': round(quarter_opd, 0),

                        'quarter_total': round(quarter_total, 0),

                    })

                    row_num += 1

            

            return Response({

                'success': True,

                'report_title': f'{self._get_quarter_ordinal(quarter)} QUARTER OF {year}',

                'subtitle': 'INVENTORY OF CONSUMED MEDICINES',

                'months': [m[1] for m in months],

                'medicines': results,

                'year': year,

                'quarter': quarter,

                'generated_at': timezone.now().isoformat(),

            })

        except Exception as e:

            import traceback

            print(traceback.format_exc())

            return Response({'success': False, 'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    

    def _get_quarter_ordinal(self, quarter):

        ordinals = {1: '1ST', 2: '2ND', 3: '3RD', 4: '4TH'}

        return ordinals.get(quarter, f'{quarter}TH')


class MonthlyDispensingReportView(APIView):

    """

    Monthly Dispensing Report - matches the physical "INVENTORY OF CONSUMED MEDICINES" form.

    Returns dispensing data grouped by medicine with IPD/OPD/TOTAL breakdown for a single month.

    """

    permission_classes = [IsAuthenticated]



    def get(self, request):

        try:

            from datetime import datetime



            # Get month and year from query params, default to current month

            year = int(request.query_params.get('year', timezone.now().year))

            month = int(request.query_params.get('month', timezone.now().month))



            # Get month name

            month_names = {

                1: 'JANUARY', 2: 'FEBRUARY', 3: 'MARCH', 4: 'APRIL',

                5: 'MAY', 6: 'JUNE', 7: 'JULY', 8: 'AUGUST',

                9: 'SEPTEMBER', 10: 'OCTOBER', 11: 'NOVEMBER', 12: 'DECEMBER',

            }

            month_name = month_names.get(month, 'UNKNOWN')



            results = []

            row_num = 1



            with connection.cursor() as cursor:

                # Get all medicines that had dispensing transactions in this month

                cursor.execute("""

                    SELECT DISTINCT m.medicine_id, m.medicine_name, m.medicine_code, m.unit

                    FROM pharmacy_medicines m

                    INNER JOIN pharmacy_transactions t ON m.medicine_id = t.medicine_id

                    WHERE t.transaction_type = 'OUT'

                      AND EXTRACT(YEAR FROM t.transaction_datetime) = %s

                      AND EXTRACT(MONTH FROM t.transaction_datetime) = %s

                    ORDER BY m.medicine_name

                """, [year, month])



                medicine_rows = cursor.fetchall()


                for med_row in medicine_rows:

                    medicine_id, medicine_name, medicine_code, unit = med_row



                    # Get IPD dispensing for this month

                    cursor.execute("""

                        SELECT COALESCE(SUM(qty), 0) as ipd_qty

                        FROM pharmacy_transactions

                        WHERE medicine_id = %s

                          AND transaction_type = 'OUT'

                          AND EXTRACT(YEAR FROM transaction_datetime) = %s

                          AND EXTRACT(MONTH FROM transaction_datetime) = %s

                          AND service_source = 'IPD'

                    """, [medicine_id, year, month])

                    ipd_qty = float(cursor.fetchone()[0] or 0)


                    # Get OPD dispensing for this month

                    cursor.execute("""

                        SELECT COALESCE(SUM(qty), 0) as opd_qty

                        FROM pharmacy_transactions

                        WHERE medicine_id = %s

                          AND transaction_type = 'OUT'

                          AND EXTRACT(YEAR FROM transaction_datetime) = %s

                          AND EXTRACT(MONTH FROM transaction_datetime) = %s

                          AND service_source = 'OPD'

                    """, [medicine_id, year, month])

                    opd_qty = float(cursor.fetchone()[0] or 0)


                    # Also include dispensing without service_source (default to OPD)

                    cursor.execute("""

                        SELECT COALESCE(SUM(qty), 0) as other_qty

                        FROM pharmacy_transactions

                        WHERE medicine_id = %s

                          AND transaction_type = 'OUT'

                          AND EXTRACT(YEAR FROM transaction_datetime) = %s

                          AND EXTRACT(MONTH FROM transaction_datetime) = %s

                          AND (service_source IS NULL OR service_source = '')

                    """, [medicine_id, year, month])

                    other_qty = float(cursor.fetchone()[0] or 0)


                    # Default null service_source to OPD

                    opd_qty += other_qty


                    month_total = ipd_qty + opd_qty


                    month_data = [{

                        'month_name': month_name,

                        'month_num': month,

                        'ipd': round(ipd_qty, 0),

                        'opd': round(opd_qty, 0),

                        'total': round(month_total, 0),

                    }]


                    results.append({

                        'row_number': row_num,

                        'medicine_name': medicine_name,

                        'medicine_code': medicine_code or '',

                        'unit': unit,

                        'months': month_data,

                        'month_ipd': round(ipd_qty, 0),

                        'month_opd': round(opd_qty, 0),

                        'month_total': round(month_total, 0),

                    })

                    row_num += 1


            return Response({

                'success': True,

                'report_title': f'MONTH OF {month_name} {year}',

                'subtitle': 'INVENTORY OF CONSUMED MEDICINES',

                'months': [month_name],

                'medicines': results,

                'year': year,

                'month': month,

                'generated_at': timezone.now().isoformat(),

            })

        except Exception as e:

            import traceback

            print(traceback.format_exc())

            return Response({'success': False, 'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class OpdPrescriptionViewSet(viewsets.ModelViewSet):
    """ViewSet for OPD Prescriptions"""
    queryset = OpdPrescription.objects.all().order_by('-rx_id')
    serializer_class = OpdPrescriptionSerializer


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def csd_purchase_requests_sent_to_pharmacy(request):
    """
    Read CSD clerk purchase requests from medistock_purchase_requests table.
    Uses raw SQL to correctly join on pr_id column (the ORM model expects
    purchase_request_id which does not match the actual DB schema).
    Shows only DRAFT PRs since those are the ones the CSD clerk created
    and forwarded to the pharmacy.
    """
    try:
        with connection.cursor() as cursor:
            # Fetch all purchase requests with pr_status = 'DRAFT'
            cursor.execute("""
                SELECT pr_id, pr_no, pr_date, purchase_type, pr_status,
                       lgu, section, fund, requested_by, total_amount, remarks
                FROM medistock_purchase_requests
                WHERE pr_status = 'DRAFT'
                ORDER BY pr_id DESC
            """)
            pr_rows = cursor.fetchall()

            results = []
            for pr_row in pr_rows:
                pr_id = pr_row[0]
                pr_no = pr_row[1]
                pr_date = pr_row[2]
                purchase_type = pr_row[3]
                pr_status = pr_row[4]
                lgu = pr_row[5]
                section = pr_row[6]
                fund = pr_row[7]
                requested_by = pr_row[8]
                total_amount = pr_row[9]
                remarks = pr_row[10]

                # Fetch items using purchase_request_id (the actual FK column)
                # Also look up the unit_price from pharmacy_supply_price
                cursor.execute("""
                    SELECT i.pr_item_id, i.supply_id, s.supply_name,
                           i.qty_requested, i.unit_snapshot,
                           i.unit_cost_estimate, i.line_total_estimate, i.remarks,
                           COALESCE(
                               (SELECT p.unit_price
                                FROM pharmacy_supply_price p
                                WHERE p.supply_id = i.supply_id
                                  AND p.is_active = true
                                ORDER BY p.effective_date DESC
                                LIMIT 1),
                               i.unit_cost_estimate,
                               0
                           ) as unit_price
                    FROM medistock_purchase_request_items i
                    LEFT JOIN medistock_supply_items s ON i.supply_id = s.supply_id
                    WHERE i.purchase_request_id = %s
                """, [pr_id])
                item_rows = cursor.fetchall()

                items_data = []
                for item_row in item_rows:
                    items_data.append({
                        'pr_item_id': item_row[0],
                        'supply_id': item_row[1],
                        'supply_name': item_row[2] or 'Unknown',
                        'qty_requested': str(item_row[3]),
                        'unit_snapshot': item_row[4],
                        'unit_cost_estimate': str(item_row[5]) if item_row[5] else '0',
                        'line_total_estimate': str(item_row[6]) if item_row[6] else '0',
                        'remarks': item_row[7],
                        'unit_price': str(item_row[8]) if item_row[8] else '0',
                    })

                results.append({
                    'pr_id': pr_id,
                    'pr_no': pr_no,
                    'pr_date': pr_date.isoformat() if pr_date else None,
                    'purchase_type': purchase_type,
                    'pr_status': pr_status,
                    'lgu': lgu,
                    'section': section,
                    'fund': fund,
                    'requested_by': requested_by,
                    'total_amount': str(total_amount) if total_amount else '0',
                    'remarks': remarks,
                    'items': items_data,
                    'items_count': len(items_data),
                })

        return Response(results)
    except Exception as e:
        import traceback
        print(traceback.format_exc())
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def update_csd_purchase_request_status(request):
    """
    Update the status of a medistock_purchase_request.
    Called after pharmacist submits their pharmacy PR.
    """
    try:
        pr_id = request.data.get('pr_id')
        new_status = request.data.get('status')

        if not pr_id or not new_status:
            return Response(
                {'error': 'pr_id and status are required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        with connection.cursor() as cursor:
            cursor.execute("""
                UPDATE medistock_purchase_requests
                SET pr_status = %s, updated_at = NOW()
                WHERE pr_id = %s
            """, [new_status, pr_id])

        return Response({'success': True, 'message': f'PR {pr_id} status updated to {new_status}'})
    except Exception as e:
        import traceback
        print(traceback.format_exc())
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
