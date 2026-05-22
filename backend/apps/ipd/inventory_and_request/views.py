"""
Views for IPD Inventory and Request module
Handles dispensing sheets, cart forms, and patient search for IPD nurses
"""
from rest_framework.views import APIView
from rest_framework.response import Response
from django.utils import timezone
from datetime import datetime
from rest_framework import status, generics
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q
from django.db import connection, transaction

from apps.opd.models import PatientProfiling
from apps.pharmacy.models import PharmacyLocation
from .models import (
    IpdNoticeOfAdmission,
    DispensingSheet,
    DispensingSheetItem,
    CartForm,
    CartFormItem,
    IpdCartInventory
)
from .serializers import (
    PatientProfilingBasicSerializer,
    IpdNoticeOfAdmissionSerializer,
    DispensingSheetListSerializer,
    DispensingSheetDetailSerializer,
    DispensingSheetCreateSerializer,
    CartFormListSerializer,
    CartFormDetailSerializer,
    CartFormCreateSerializer,
    IpdCartInventorySerializer
)


class PharmacyInventoryView(APIView):
    """
    View to search and list medicines available in the Main Pharmacy (Location 1)
    This is used by IPD nurses for selecting medicines in the Dispensing Sheet.
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        query = request.query_params.get('q', '').strip()
        
        # Get the Main Pharmacy location (ID: 1)
        pharmacy_location = PharmacyLocation.objects.filter(location_id=1).first()
        if not pharmacy_location:
            # Fallback if ID 1 isn't found, look by name
            pharmacy_location = PharmacyLocation.objects.filter(location_name__icontains='Pharmacy').first()

        # Filter for Pharmacy Location and group by medicine
        from django.db.models import Sum
        
        # We query PharmacyInventoryBalance directly to get medicines in Location 1
        queryset = IpdCartInventory.objects.filter(location=pharmacy_location, qty_on_hand__gt=0)
        
        if query:
            queryset = queryset.filter(
                Q(medicine__medicine_name__icontains=query) |
                Q(medicine__medicine_code__icontains=query)
            )
            
        results = queryset.values(
            'medicine__medicine_id', 
            'medicine__medicine_name',
            'medicine__medicine_code',
            'medicine__category',
            'medicine__unit',
            'medicine__unit_cost'
        ).annotate(
            total_qty=Sum('qty_on_hand')
        ).order_by('medicine__medicine_name')
        
        inventory_data = []
        for item in results:
            inventory_data.append({
                'medicine_id': item['medicine__medicine_id'],
                'medicine_name': item['medicine__medicine_name'],
                'medicine_code': item['medicine__medicine_code'],
                'category': item['medicine__category'],
                'unit': item['medicine__unit'],
                'unit_cost': float(item['medicine__unit_cost'] or 0),
                'quantity': float(item['total_qty']),
                'display_name': f"{item['medicine__medicine_name']} ({item['medicine__unit']}) - {item['total_qty']} avail"
            })
            
        return Response({
            'success': True,
            'count': len(inventory_data),
            'inventory': inventory_data
        }, status=status.HTTP_200_OK)


class IpdCartInventoryView(APIView):
    """
    View to search and list medicines available in the Cart/Floor Stock (Location 2)
    This is used by IPD nurses for both the Inventory tab and the Cart Form medicine selection.
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        query = request.query_params.get('q', '').strip()
        category = request.query_params.get('category', '').strip()
        
        # Get the Cart location (ID: 2)
        cart_location = PharmacyLocation.objects.filter(location_id=2).first()
        if not cart_location:
            return Response({
                'success': False,
                'error': 'Cart location (ID 2) not found in database.'
            }, status=status.HTTP_404_NOT_FOUND)

        # Filter for Cart Location
        queryset = IpdCartInventory.objects.filter(location=cart_location, qty_on_hand__gt=0)
        
        if query:
            queryset = queryset.filter(
                Q(medicine__medicine_name__icontains=query) |
                Q(medicine__medicine_code__icontains=query)
            )
            
        if category and category != 'All':
            queryset = queryset.filter(medicine__category=category)
            
        # Group by medicine to show total stock available across all batches in the cart
        from django.db.models import Sum, Min
        from django.utils import timezone
        from datetime import timedelta

        # Get threshold for expiry (e.g., 30 days)
        expiry_threshold = timezone.now().date() + timedelta(days=30)
        
        results = queryset.values(
            'medicine__medicine_id', 
            'medicine__medicine_name',
            'medicine__medicine_code',
            'medicine__category',
            'medicine__unit',
            'medicine__reorder_level'
        ).annotate(
            total_qty=Sum('qty_on_hand'),
            earliest_expiry=Min('batch__expiry_date')
        ).order_by('medicine__medicine_name')
        
        # Format results for frontend
        inventory_data = []
        expiry_alert_count = 0
        
        for item in results:
            total_qty = float(item['total_qty'])
            reorder_level = float(item['medicine__reorder_level'] or 0)
            expiry_date = item['earliest_expiry']
            
            # Match UI status logic
            status_text = 'Normal'
            if expiry_date and expiry_date <= timezone.now().date():
                status_text = 'Expired'
                expiry_alert_count += 1
            elif expiry_date and expiry_date <= expiry_threshold:
                status_text = 'Near Expiry'
                expiry_alert_count += 1
            elif total_qty <= 0:
                status_text = 'Out of Stock'
            elif total_qty <= reorder_level:
                status_text = 'Low Stock'

            inventory_data.append({
                'medicine_id': item['medicine__medicine_id'],
                'medicine_name': item['medicine__medicine_name'],
                'medicine_code': item['medicine__medicine_code'],
                'category': item['medicine__category'],
                'unit': item['medicine__unit'],
                'quantity': total_qty,
                'expiry_date': expiry_date.isoformat() if expiry_date else 'N/A',
                'status': status_text
            })
            
        return Response({
            'success': True,
            'total_items': len(inventory_data),
            'normal_stock': len([i for i in inventory_data if i['status'] == 'Normal']),
            'low_stock': len([i for i in inventory_data if i['status'] == 'Low Stock']),
            'expiry_alert': expiry_alert_count,
            'inventory': inventory_data
        }, status=status.HTTP_200_OK)


class IpdPatientSearchView(APIView):
    """
    Search for IPD patients (inpatients) by name or hospital_id
    Returns patient info with their current admission details
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        query = request.query_params.get('q', '').strip()
        
        # Search patients with current_status = 'INPATIENT' and is_active = True
        # Note: If no query, return all active inpatients
        queryset = PatientProfiling.objects.filter(
            current_status='INPATIENT',
            is_active=True
        )
        
        if query:
            queryset = queryset.filter(
                Q(lastname__icontains=query) |
                Q(firstname__icontains=query) |
                Q(hospital_id__icontains=query)
            )
        
        try:
            patients = queryset.order_by('lastname', 'firstname')[:50] # Limit results
            
            results = []
            for patient in patients:
                # Get current active admission (Notice of Admission)
                # status can be 'approved' or 'pending' for active inpatients in the new system
                admission = IpdNoticeOfAdmission.objects.filter(
                    patient=patient,
                    status__in=['approved', 'pending']
                ).order_by('-admission_date', '-submitted_date').first()
                
                patient_data = PatientProfilingBasicSerializer(patient).data
                if admission:
                    patient_data['admission'] = IpdNoticeOfAdmissionSerializer(admission).data
                else:
                    patient_data['admission'] = None
                
                results.append(patient_data)
            
            return Response({
                'success': True,
                'count': len(results),
                'patients': results
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class IpdPatientDetailView(APIView):
    """
    Get full patient details with current admission
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request, patient_id):
        try:
            patient = PatientProfiling.objects.get(
                patient_id=patient_id,
                is_active=True
            )
            
            # Get current admission
            admission = IpdNoticeOfAdmission.objects.filter(
                patient=patient,
                status__in=['approved', 'pending']
            ).order_by('-admission_date').first()
            
            patient_data = PatientProfilingBasicSerializer(patient).data
            if admission:
                patient_data['admission'] = IpdNoticeOfAdmissionSerializer(admission).data
            
            return Response({
                'success': True,
                'patient': patient_data
            }, status=status.HTTP_200_OK)
            
        except PatientProfiling.DoesNotExist:
            return Response({
                'success': False,
                'error': 'Patient not found'
            }, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ==================== DISPENSING SHEET VIEWS ====================

class DispensingSheetListView(generics.ListAPIView):
    """
    List all dispensing sheets for the current nurse
    Supports filtering by status and patient
    """
    permission_classes = [IsAuthenticated]
    serializer_class = DispensingSheetListSerializer
    
    def get_queryset(self):
        queryset = DispensingSheet.objects.all()
        
        # Filter by nurse (requested_by)
        user_id = self.request.query_params.get('nurse_id')
        if user_id:
            queryset = queryset.filter(requested_by=user_id)
        
        # Filter by status
        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        # Filter by patient
        patient_id = self.request.query_params.get('patient_id')
        if patient_id:
            queryset = queryset.filter(patient_id=patient_id)
        
        return queryset.order_by('-created_at')


class DispensingSheetCreateView(APIView):
    """
    Create a new dispensing sheet with items
    """
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        try:
            # Add audit trail and user info from request.user
            user = request.user
            # Ensure requested_by and requested_by_name come from the authenticated user
            data = request.data.copy()
            data['requested_by'] = user.id
            
            # Get full name from user profile if available
            fullname = f"{user.firstname} {user.lastname}" if hasattr(user, 'firstname') and user.firstname else user.username
            data['requested_by_name'] = fullname
            
            role = getattr(user, 'role', 'NURSE')
            ip_address = request.META.get('REMOTE_ADDR', 'unknown')
            timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            
            trail = f"{user.username}|{fullname}|{role}|{timestamp}|{ip_address}|CREATED"
            data['trail'] = trail
            
            serializer = DispensingSheetCreateSerializer(data=data)
            if serializer.is_valid():
                dispensing_sheet = serializer.save()
                
                return Response({
                    'success': True,
                    'message': 'Dispensing sheet created successfully',
                    'dispensing_id': dispensing_sheet.dispensing_id,
                    'data': DispensingSheetDetailSerializer(dispensing_sheet).data
                }, status=status.HTTP_201_CREATED)
            
            return Response({
                'success': False,
                'error': serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)
            
        except Exception as e:
            import traceback
            print(f"ERROR: {str(e)}")
            print(traceback.format_exc())
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class DispensingSheetDispenseView(APIView):
    """
    Finalize dispensing: Pharmacist fills in unit, costs, and confirms dispensing.
    Updates the overall status of the sheet to 'DISPENSED'.
    """
    permission_classes = [IsAuthenticated]
    
    def post(self, request, dispensing_id):
        try:
            # REDIRECT TO PHARMACY BACKEND FOR PROCESSING
            # Since this feature belongs to the pharmacist user, we use the pharmacy endpoint
            from apps.pharmacy.views import process_ipd_dispensing
            return process_ipd_dispensing(request._request, dispensing_id)
            
        except Exception as e:
            import traceback
            print(f"IPD REDIRECT ERROR: {str(e)}")
            print(traceback.format_exc())
            return Response({'success': False, 'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            
        except Exception as e:
            return Response({'success': False, 'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class DispensingSheetDetailView(APIView):
    """
    Get detailed view of a dispensing sheet
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request, dispensing_id):
        try:
            dispensing_sheet = DispensingSheet.objects.get(dispensing_id=dispensing_id)
            serializer = DispensingSheetDetailSerializer(dispensing_sheet)
            
            return Response({
                'success': True,
                'data': serializer.data
            }, status=status.HTTP_200_OK)
            
        except DispensingSheet.DoesNotExist:
            return Response({
                'success': False,
                'error': 'Dispensing sheet not found'
            }, status=status.HTTP_404_NOT_FOUND)


class DispensingSheetUpdateStatusView(APIView):
    """
    Update dispensing sheet status (for pharmacists)
    """
    permission_classes = [IsAuthenticated]
    
    def patch(self, request, dispensing_id):
        try:
            dispensing_sheet = DispensingSheet.objects.get(dispensing_id=dispensing_id)
            
            new_status = request.data.get('status')
            if new_status not in ['PENDING', 'APPROVED', 'DISPENSED', 'REJECTED']:
                return Response({
                    'success': False,
                    'error': 'Invalid status'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Update trail
            user = request.user
            username = user.username
            fullname = f"{user.firstname} {user.lastname}" if hasattr(user, 'firstname') else username
            role = getattr(user, 'role', 'UNKNOWN')
            ip_address = request.META.get('REMOTE_ADDR', 'unknown')
            timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            
            trail_entry = f"{username}|{fullname}|{role}|{timestamp}|{ip_address}|STATUS:{new_status}"
            dispensing_sheet.trail = f"{dispensing_sheet.trail or ''}\n{trail_entry}"
            
            dispensing_sheet.status = new_status
            
            # If dispensed, record pharmacist info
            if new_status == 'DISPENSED':
                dispensing_sheet.dispensed_by = user.id
                dispensing_sheet.dispensed_by_name = fullname
                dispensing_sheet.dispensed_date = datetime.now()
            
            dispensing_sheet.save()
            
            return Response({
                'success': True,
                'message': f'Status updated to {new_status}',
                'data': DispensingSheetDetailSerializer(dispensing_sheet).data
            }, status=status.HTTP_200_OK)
            
        except DispensingSheet.DoesNotExist:
            return Response({
                'success': False,
                'error': 'Dispensing sheet not found'
            }, status=status.HTTP_404_NOT_FOUND)


# ==================== CART FORM VIEWS ====================

class CartFormListView(generics.ListAPIView):
    """
    List all cart forms for the current nurse
    """
    permission_classes = [IsAuthenticated]
    serializer_class = CartFormListSerializer
    
    def get_queryset(self):
        queryset = CartForm.objects.all()
        
        # Filter by nurse
        user_id = self.request.query_params.get('nurse_id')
        if user_id:
            queryset = queryset.filter(requested_by=user_id)
        
        # Filter by status
        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        return queryset.order_by('-created_at')


class CartFormCreateView(APIView):
    """
    Create a new cart form with items and automatically deduct from inventory (Location 2)
    """
    permission_classes = [IsAuthenticated]
    
    @transaction.atomic
    def post(self, request):
        try:
            from django.db import connection
            from django.utils import timezone
            import random
            import string
            
            # Add audit trail and user info from request.user
            user = request.user
            data = request.data.copy()
            
            # Auto-populate requested_by information from authenticated user
            data['requested_by'] = user.id
            fullname = f"{user.firstname} {user.lastname}" if hasattr(user, 'firstname') and user.firstname else user.username
            data['requested_by_name'] = fullname
            
            role = getattr(user, 'role', 'NURSE')
            ip_address = request.META.get('REMOTE_ADDR', 'unknown')
            timestamp = timezone.now().strftime('%Y-%m-%d %H:%M:%S')
            
            # 1. Start Audit Trail
            trail = f"{user.username}|{fullname}|{role}|{timestamp}|{ip_address}|CREATED_AND_DISPENSED"
            data['trail'] = trail
            data['status'] = 'VERIFIED' # Automatically verified as it's dispensed immediately
            
            serializer = CartFormCreateSerializer(data=data)
            if serializer.is_valid():
                cart_form = serializer.save()
                
                # 2. Process Automatic Deduction from Inventory Cart (Location 2) using FEFO
                items_data = request.data.get('items', [])
                
                # 3. Create Pharmacy Dispense Receipt (FOR BILLING)
                receipt_no = 'DR-CART-' + ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
                total_sheet_amount = 0
                
                with connection.cursor() as cursor:
                    # 3.1 Insert into pharmacy_dispense_receipts
                    cursor.execute("""
                        INSERT INTO pch.pharmacy_dispense_receipts (
                            receipt_no, ipd_cart_form_id, 
                            patient_id, admission_id, from_location_id, dispensing_date, 
                            total_amount, trail
                        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                        RETURNING receipt_id
                    """, [
                        receipt_no,
                        cart_form.cart_form_id,
                        cart_form.patient_id,
                        cart_form.admission_id,
                        2, # From Location ID: 2 (Cart)
                        timezone.now().date(),
                        0, # Will update after items
                        trail
                    ])
                    receipt_id = cursor.fetchone()[0]

                    for item_data in items_data:
                        medicine_id = item_data.get('medicine_id')
                        quantity = float(item_data.get('quantity', 0))
                        
                        # Find batch from Location 2 (Inventory Cart) following FEFO
                        cursor.execute("""
                            SELECT b.batch_id, i.qty_on_hand, b.unit_cost, b.batch_no
                            FROM pch.pharmacy_inventory_balance i
                            JOIN pch.pharmacy_stock_batches b ON i.batch_id = b.batch_id
                            WHERE i.medicine_id = %s AND i.location_id = 2 AND i.qty_on_hand > 0
                            ORDER BY b.expiry_date ASC, b.received_date ASC
                            LIMIT 1
                        """, [medicine_id])
                        batch_row = cursor.fetchone()
                        
                        if batch_row:
                            batch_id = batch_row[0]
                            unit_cost = float(batch_row[2] or 0)
                            total_cost = unit_cost * quantity
                            total_sheet_amount += total_cost
                            batch_no = batch_row[3]
                            
                            # 3.2 Create Receipt Item (FOR BILLING)
                            cursor.execute("""
                                INSERT INTO pch.pharmacy_dispense_receipt_items (
                                    receipt_id, medicine_id, item_code, 
                                    item_description, quantity, unit, 
                                    unit_cost, total_cost, batch_id, from_location_id, line_status
                                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                            """, [
                                receipt_id, medicine_id, str(medicine_id), 
                                item_data.get('drug_name', 'Cart Medicine'),
                                quantity, '', unit_cost, total_cost, batch_id, 2, 'DISPENSED'
                            ])

                            # Deduct from Inventory Balance (Location 2)
                            cursor.execute("""
                                UPDATE pch.pharmacy_inventory_balance
                                SET qty_on_hand = qty_on_hand - %s
                                WHERE medicine_id = %s AND batch_id = %s AND location_id = 2
                            """, [quantity, medicine_id, batch_id])
                            
                            # Log Transaction (OUT from Location 2)
                            cursor.execute("""
                                INSERT INTO pch.pharmacy_transactions (
                                    transaction_datetime, transaction_type, medicine_id, 
                                    batch_id, from_location_id, qty, reference_type, 
                                    reference_id, service_source, remarks, trail
                                ) VALUES (NOW(), 'OUT', %s, %s, %s, %s, %s, %s, %s, %s, %s)
                            """, [
                                medicine_id, batch_id, 2, quantity, 'IPD_CART_DISPENSE',
                                cart_form.cart_form_id, 'IPD',
                                f"Nurse Dispensed from Cart Form #{cart_form.cart_form_id}", trail
                            ])
                    
                    # 3.3 Update final total in receipt
                    cursor.execute("""
                        UPDATE pch.pharmacy_dispense_receipts 
                        SET total_amount = %s WHERE receipt_id = %s
                    """, [total_sheet_amount, receipt_id])
                
                return Response({
                    'success': True,
                    'message': 'Cart form created and items automatically dispensed from cart inventory.',
                    'cart_form_id': cart_form.cart_form_id,
                    'data': CartFormDetailSerializer(cart_form).data
                }, status=status.HTTP_201_CREATED)
            
            return Response({
                'success': False,
                'error': serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)
            
        except Exception as e:
            import traceback
            print(traceback.format_exc())
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class CartFormVerifyView(APIView):
    """
    Pharmacist verifies medicines taken from the cart.
    Updates the status to 'VERIFIED'.
    """
    permission_classes = [IsAuthenticated]
    
    def post(self, request, cart_form_id):
        try:
            cart_form = CartForm.objects.filter(cart_form_id=cart_form_id).first()
            if not cart_form:
                return Response({'success': False, 'error': 'Cart form not found'}, status=status.HTTP_404_NOT_FOUND)
            
            user = request.user
            cart_form.status = 'VERIFIED'
            
            # Update trail
            fullname = f"{user.firstname} {user.lastname}" if hasattr(user, 'firstname') and user.firstname else user.username
            role = getattr(user, 'role', 'PHARMACIST')
            ip_address = request.META.get('REMOTE_ADDR', 'unknown')
            timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            new_trail = f"{user.username}|{fullname}|{role}|{timestamp}|{ip_address}|VERIFIED"
            cart_form.trail = (cart_form.trail or "") + "\n" + new_trail
            
            cart_form.save()
            
            return Response({
                'success': True,
                'message': 'Cart usage verified successfully',
                'cart_form_id': cart_form_id
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({'success': False, 'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class CartFormDetailView(APIView):
    """
    Get detailed view of a cart form
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request, cart_form_id):
        try:
            cart_form = CartForm.objects.get(cart_form_id=cart_form_id)
            serializer = CartFormDetailSerializer(cart_form)
            
            return Response({
                'success': True,
                'data': serializer.data
            }, status=status.HTTP_200_OK)
            
        except CartForm.DoesNotExist:
            return Response({
                'success': False,
                'error': 'Cart form not found'
            }, status=status.HTTP_404_NOT_FOUND)


class CartFormUpdateStatusView(APIView):
    """
    Update cart form status (for verification/replenishment)
    """
    permission_classes = [IsAuthenticated]
    
    def patch(self, request, cart_form_id):
        try:
            cart_form = CartForm.objects.get(cart_form_id=cart_form_id)
            
            new_status = request.data.get('status')
            if new_status not in ['PENDING', 'VERIFIED', 'REPLENISHED']:
                return Response({
                    'success': False,
                    'error': 'Invalid status'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Update trail
            user = request.user
            username = user.username
            fullname = f"{user.firstname} {user.lastname}" if hasattr(user, 'firstname') else username
            role = getattr(user, 'role', 'UNKNOWN')
            ip_address = request.META.get('REMOTE_ADDR', 'unknown')
            timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            
            trail_entry = f"{username}|{fullname}|{role}|{timestamp}|{ip_address}|STATUS:{new_status}"
            cart_form.trail = f"{cart_form.trail or ''}\n{trail_entry}"
            
            cart_form.status = new_status
            cart_form.save()
            
            return Response({
                'success': True,
                'message': f'Status updated to {new_status}',
                'data': CartFormDetailSerializer(cart_form).data
            }, status=status.HTTP_200_OK)
            
        except CartForm.DoesNotExist:
            return Response({
                'success': False,
                'error': 'Cart form not found'
            }, status=status.HTTP_404_NOT_FOUND)
