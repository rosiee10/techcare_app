from rest_framework import viewsets, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from django.db import models, transaction, connection
from django.db.models import Sum, Q
from datetime import date as date_obj
from .models import (
    MedistockCategory, MedistockUnit, MedistockDepartment, MedistockLocation,
    MedistockSupplyItem, MedistockSupplyBatch, MedistockInventoryBalance,
    MedistockGoodsReceipt, MedistockSupplyRequest, MedistockSupplyRequestItem,
    MedistockTransaction, MedistockReport,
    MedistockPurchaseRequest, MedistockPurchaseRequestItem,
    MedistockVStockSummary, MedistockVLowStock, MedistockVExpiryAlert,
    MedistockVMonthlyConsumption, MedistockVPendingRequest,
    MedistockVCartItem, MedistockVStockCard,
)
from .serializers import (
    MedistockCategorySerializer, MedistockUnitSerializer, MedistockDepartmentSerializer,
    MedistockLocationSerializer, MedistockSupplyItemSerializer, MedistockInventoryBalanceSerializer,
    MedistockGoodsReceiptSerializer,
    MedistockSupplyRequestSerializer, MedistockSupplyRequestListSerializer,
    MedistockSupplyRequestItemSerializer, MedistockTransactionSerializer,
    MedistockReportSerializer,
    MedistockVStockSummarySerializer, MedistockVLowStockSerializer,
    MedistockVExpiryAlertSerializer, MedistockVMonthlyConsumptionSerializer,
    MedistockVPendingRequestSerializer, MedistockVCartItemSerializer,
    MedistockVStockCardSerializer,
    MedistockPRSerializer, MedistockPRListSerializer,
    MedistockSupplyBatchSerializer,
)
from apps.opd.models import PatientProfiling
from apps.pharmacy.models import PharmacyPurchaseRequest, PharmacyPurchaseRequestItem


class MedistockCategoryViewSet(viewsets.ModelViewSet):
    queryset = MedistockCategory.objects.all()
    serializer_class = MedistockCategorySerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['category_name']
    ordering_fields = ['category_name']


class MedistockUnitViewSet(viewsets.ModelViewSet):
    queryset = MedistockUnit.objects.all()
    serializer_class = MedistockUnitSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['unit_name']
    ordering_fields = ['unit_name']


class MedistockDepartmentViewSet(viewsets.ModelViewSet):
    queryset = MedistockDepartment.objects.all()
    serializer_class = MedistockDepartmentSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['department_name']
    ordering_fields = ['department_name']


class MedistockLocationViewSet(viewsets.ModelViewSet):
    queryset = MedistockLocation.objects.select_related('department').all()
    serializer_class = MedistockLocationSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['location_type', 'department']
    search_fields = ['location_name']
    ordering_fields = ['location_name']


class MedistockSupplyItemViewSet(viewsets.ModelViewSet):
    queryset = MedistockSupplyItem.objects.select_related('category', 'unit').all()
    serializer_class = MedistockSupplyItemSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['category', 'unit', 'is_active']
    search_fields = ['supply_name', 'supply_code']
    ordering_fields = ['supply_name', 'reorder_level']

    @action(detail=False, methods=['post'])
    def add_with_stock(self, request):
        supply_name = request.data.get('supply_name', '').strip()
        category_id = request.data.get('category')
        unit_id = request.data.get('unit')
        reorder_level = request.data.get('reorder_level', 0)
        quantity = int(request.data.get('quantity', 0) or 0)
        expiry_date = request.data.get('expiry_date') or None

        if not supply_name or not category_id:
            return Response({'error': 'supply_name and category are required.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            with transaction.atomic():
                supply = MedistockSupplyItem.objects.create(
                    supply_name=supply_name,
                    category_id=category_id,
                    unit_id=unit_id if unit_id else None,
                    reorder_level=reorder_level,
                    is_active=True,
                )
                location = MedistockLocation.objects.filter(
                    location_name__icontains='central'
                ).first() or MedistockLocation.objects.filter(is_active=True).first()
                if not location:
                    raise ValueError('No active storage location found. Please add a location first.')
                batch = MedistockSupplyBatch.objects.create(
                    supply=supply,
                    batch_no=f'INIT-{supply.supply_id}',
                    expiry_date=expiry_date,
                    received_date=date_obj.today(),
                )
                MedistockInventoryBalance.objects.create(
                    supply=supply,
                    batch=batch,
                    location=location,
                    qty_on_hand=quantity,
                )
            serializer = MedistockSupplyItemSerializer(supply)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


class MedistockSupplyBatchViewSet(viewsets.ReadOnlyModelViewSet):
    """Read-only list of supply batches with expiry dates."""
    serializer_class = MedistockSupplyBatchSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['supply']
    ordering_fields = ['expiry_date', 'batch_id']
    ordering = ['expiry_date']

    def get_queryset(self):
        return MedistockSupplyBatch.objects.select_related('supply').filter(
            expiry_date__isnull=False
        ).order_by('supply_id', 'expiry_date')


class MedistockInventoryBalanceViewSet(viewsets.ModelViewSet):
    queryset = MedistockInventoryBalance.objects.select_related(
        'supply', 'supply__category', 'supply__unit', 'batch', 'location'
    ).all()
    serializer_class = MedistockInventoryBalanceSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['supply', 'location']
    search_fields = ['supply__supply_name', 'location__location_name']
    ordering_fields = ['qty_on_hand']

    def destroy(self, request, pk=None):
        """Delete an inventory balance item (divider restock entry)."""
        try:
            balance = self.get_object()
            item_name = str(balance.supply)
            balance.delete()
            return Response({'success': True, 'message': f'{item_name} deleted successfully.'}, status=status.HTTP_200_OK)
        except MedistockInventoryBalance.DoesNotExist:
            return Response({'error': 'Item not found.'}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['delete'])
    def remove_from_cart(self, request):
        """Remove a supply from a specific cart (deletes all batches of that supply at that location)."""
        supply_id = request.query_params.get('supply_id')
        location_id = request.query_params.get('location_id')
        if not supply_id or not location_id:
            return Response({'error': 'supply_id and location_id are required.'}, status=status.HTTP_400_BAD_REQUEST)
        
        deleted_count, _ = MedistockInventoryBalance.objects.filter(
            supply_id=supply_id,
            location_id=location_id
        ).delete()
        
        return Response({
            'success': True, 
            'message': f'Removed item from cart. {deleted_count} entries deleted.'
        })

    @action(detail=False, methods=['get'])
    def stats(self, request):
        balances = self.get_queryset()
        total_supplies = balances.values('supply_id').distinct().count()
        low_stock = balances.filter(qty_on_hand__lte=models.F('supply__reorder_level')).count()
        total_qty = balances.aggregate(total=Sum('qty_on_hand'))['total'] or 0
        return Response({
            'total_supplies': total_supplies,
            'low_stock_items': low_stock,
            'total_quantity': float(total_qty),
        })

    @action(detail=False, methods=['get'])
    def batches_for_supply(self, request):
        supply_id = request.query_params.get('supply_id')
        exclude_location_id = request.query_params.get('exclude_location_id')
        if not supply_id:
            return Response({'error': 'supply_id is required.'}, status=status.HTTP_400_BAD_REQUEST)
        qs = MedistockInventoryBalance.objects.filter(
            supply_id=supply_id,
            qty_on_hand__gt=0,
        ).select_related('batch', 'location').order_by('batch__expiry_date', 'batch__batch_id')
        if exclude_location_id:
            qs = qs.exclude(location_id=exclude_location_id)
        data = [
            {
                'batch_id': b.batch.batch_id,
                'batch_no': b.batch.batch_no,
                'expiry_date': str(b.batch.expiry_date) if b.batch.expiry_date else None,
                'qty_on_hand': float(b.qty_on_hand),
                'location_name': b.location.location_name,
            }
            for b in qs
        ]
        return Response(data)

    @action(detail=False, methods=['post'])
    def restock_cart(self, request):
        supply_id = request.data.get('supply_id')
        location_id = request.data.get('location_id')
        qty_requested = int(request.data.get('quantity') or 0)
        batch_no = (request.data.get('batch_no') or '').strip() or None

        if not supply_id or not location_id or qty_requested <= 0:
            return Response(
                {'error': 'supply_id, location_id, and quantity are required.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            with transaction.atomic():
                # Build queryset — FEFO order; filter to specific batch if provided
                # Source can be any location except the destination itself
                qs = MedistockInventoryBalance.objects.filter(
                    supply_id=supply_id,
                    qty_on_hand__gt=0,
                ).exclude(
                    location_id=location_id,
                ).select_related('batch', 'location').order_by(
                    'batch__expiry_date', 'batch__batch_id'
                )
                if batch_no:
                    qs = qs.filter(batch__batch_no=batch_no)
                    if not qs.exists():
                        return Response(
                            {'error': f'Batch "{batch_no}" not found in inventory for this supply.'},
                            status=status.HTTP_400_BAD_REQUEST,
                        )

                source_balances = list(qs)
                total_available = sum(b.qty_on_hand for b in source_balances)
                if total_available < qty_requested:
                    return Response(
                        {'error': f'Insufficient stock in {"batch " + batch_no if batch_no else "inventory"}. Available: {float(total_available)}, Requested: {qty_requested}'},
                        status=status.HTTP_400_BAD_REQUEST,
                    )

                remaining = qty_requested
                requested_by = request.user.get_full_name() or request.user.username

                for balance in source_balances:
                    if remaining <= 0:
                        break
                    take = min(balance.qty_on_hand, remaining)

                    # Deduct from source
                    balance.qty_on_hand -= take
                    balance.save()

                    # Add to divider location (upsert by supply+batch+location)
                    dest, _ = MedistockInventoryBalance.objects.get_or_create(
                        supply_id=supply_id,
                        batch=balance.batch,
                        location_id=location_id,
                        defaults={'qty_on_hand': 0},
                    )
                    dest.qty_on_hand += take
                    dest.save()

                    # Sync to medistock_stock_locations for easy cross-module access
                    dest_location = MedistockLocation.objects.get(location_id=location_id)
                    supply_obj = MedistockSupplyItem.objects.select_related('category', 'unit').get(supply_id=supply_id)
                    trail_value = (
                        f"{supply_obj.supply_name} | "
                        f"batch:{balance.batch.batch_no} | "
                        f"qty:{float(dest.qty_on_hand)}"
                    )
                    unit_name = supply_obj.unit.unit_name if supply_obj.unit else None
                    category_name = supply_obj.category.category_name if supply_obj.category else None
                    expiry = balance.batch.expiry_date if balance.batch.expiry_date else None
                    db_cursor = connection.cursor()
                    db_cursor.execute("""
                        INSERT INTO medistock_stock_locations (
                            location_id, location_name, trail,
                            supply_id, supply_name, batch_no, expiry_date,
                            qty, unit, category, restocked_by, restocked_at
                        )
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW())
                        ON CONFLICT (location_id) DO UPDATE
                        SET location_name  = EXCLUDED.location_name,
                            trail          = EXCLUDED.trail,
                            supply_id      = EXCLUDED.supply_id,
                            supply_name    = EXCLUDED.supply_name,
                            batch_no       = EXCLUDED.batch_no,
                            expiry_date    = EXCLUDED.expiry_date,
                            qty            = EXCLUDED.qty,
                            unit           = EXCLUDED.unit,
                            category       = EXCLUDED.category,
                            restocked_by   = EXCLUDED.restocked_by,
                            restocked_at   = NOW()
                    """, [
                        dest_location.location_id, dest_location.location_name, trail_value,
                        supply_obj.supply_id, supply_obj.supply_name,
                        balance.batch.batch_no, expiry,
                        float(dest.qty_on_hand), unit_name, category_name, requested_by,
                    ])

                    # Log the transfer transaction
                    MedistockTransaction.objects.create(
                        transaction_type='CART_RESTOCK',
                        supply_id=supply_id,
                        batch=balance.batch,
                        from_location=balance.location,
                        to_location_id=location_id,
                        qty=take,
                        source_module='MEDISTOCK',
                        requested_by=requested_by,
                    )
                    remaining -= take

            return Response(
                {'success': True, 'message': 'Divider restocked successfully.'},
                status=status.HTTP_201_CREATED,
            )
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


class MedistockGoodsReceiptViewSet(viewsets.ModelViewSet):
    queryset = MedistockGoodsReceipt.objects.select_related('pr').all()
    serializer_class = MedistockGoodsReceiptSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'pr']
    search_fields = ['gr_no', 'supplier_name']
    ordering_fields = ['gr_id', 'received_date']


class MedistockSupplyRequestViewSet(viewsets.ModelViewSet):
    queryset = MedistockSupplyRequest.objects.select_related('source_department').prefetch_related('items').all()
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'source_module', 'source_department']
    search_fields = ['request_no', 'requested_by_name', 'patient_name']
    ordering_fields = ['request_id', 'request_date']

    def get_serializer_class(self):
        if self.action == 'list':
            return MedistockSupplyRequestListSerializer
        return MedistockSupplyRequestSerializer

    @action(detail=False, methods=['get'])
    def stats(self, request):
        qs = self.get_queryset()
        return Response({
            'total': qs.count(),
            'pending': qs.filter(status__iexact='PENDING').count(),
            'approved': qs.filter(status__iexact='APPROVED').count(),
            'dispensed': qs.filter(status__iexact='DISPENSED').count(),
            'cancelled': qs.filter(status__iexact='CANCELLED').count(),
        })


class MedistockSupplyRequestItemViewSet(viewsets.ModelViewSet):
    queryset = MedistockSupplyRequestItem.objects.select_related('request', 'supply', 'unit', 'batch').all()
    serializer_class = MedistockSupplyRequestItemSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['request', 'supply', 'status']
    search_fields = ['item_name', 'supply__supply_name']


class MedistockTransactionViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = MedistockTransaction.objects.select_related(
        'supply', 'batch', 'from_location', 'to_location', 'department'
    ).all()
    serializer_class = MedistockTransactionSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['transaction_type', 'supply', 'source_module']
    search_fields = ['supply__supply_name', 'transaction_type', 'patient_name', 'requested_by']
    ordering_fields = ['transaction_id', 'transaction_datetime', 'qty']

    @action(detail=False, methods=['post'])
    def dispense(self, request):
        """
        Bulk dispense endpoint.
        Expects: { items: [ { supply_id, qty, date, requested_by, patient_name, department_id } ] }
        For each item: deducts from inventory_balance (FEFO), creates a DISPENSE transaction.
        """
        items_data = request.data.get('items', [])
        if not items_data:
            return Response({'error': 'No items provided.'}, status=status.HTTP_400_BAD_REQUEST)

        created_transactions = []
        errors = []

        try:
            with transaction.atomic():
                for idx, item in enumerate(items_data):
                    supply_id = item.get('supply_id')
                    qty_needed = float(item.get('qty', 0) or 0)
                    requested_by = (item.get('requested_by') or '').strip()
                    patient_name = (item.get('patient_name') or '').strip() or None
                    department_id = item.get('department_id') or None
                    tx_date = item.get('date') or None

                    if not supply_id or qty_needed <= 0 or not requested_by:
                        errors.append(f'Row {idx + 1}: supply_id, qty > 0, and requested_by are required.')
                        continue

                    # Validate supply exists
                    try:
                        supply = MedistockSupplyItem.objects.get(supply_id=supply_id, is_active=True)
                    except MedistockSupplyItem.DoesNotExist:
                        errors.append(f'Row {idx + 1}: Supply not found.')
                        continue

                    # Get available balances FEFO (earliest expiry first, non-zero qty)
                    balances = MedistockInventoryBalance.objects.select_related('batch', 'location').filter(
                        supply_id=supply_id,
                        qty_on_hand__gt=0,
                    ).order_by('batch__expiry_date', 'batch_id')

                    total_available = sum(float(b.qty_on_hand) for b in balances)
                    if total_available < qty_needed:
                        errors.append(
                            f'Row {idx + 1}: Insufficient stock for {supply.supply_name}. '
                            f'Available: {total_available}, Requested: {qty_needed}.'
                        )
                        continue

                    # Deduct FEFO
                    remaining = qty_needed
                    for bal in balances:
                        if remaining <= 0:
                            break
                        available = float(bal.qty_on_hand)
                        deduct = min(available, remaining)
                        bal.qty_on_hand = available - deduct
                        bal.save(update_fields=['qty_on_hand'])

                        # Get main/central location for from_location
                        from_location = bal.location

                        tx = MedistockTransaction.objects.create(
                            transaction_type='DISPENSE',
                            supply=supply,
                            batch=bal.batch,
                            from_location=from_location,
                            qty=deduct,
                            reference_type='STOCK_CARD',
                            source_module='MEDISTOCK',
                            patient_name=patient_name,
                            requested_by=requested_by,
                            department_id=department_id,
                            remarks=f'Stock Card dispense',
                        )
                        created_transactions.append(tx.transaction_id)
                        remaining -= deduct

            if errors and not created_transactions:
                return Response({'errors': errors}, status=status.HTTP_400_BAD_REQUEST)

            return Response({
                'success': True,
                'transactions_created': len(created_transactions),
                'transaction_ids': created_transactions,
                'warnings': errors if errors else [],
            }, status=status.HTTP_201_CREATED)

        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


class MedistockReportViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = MedistockReport.objects.all()
    serializer_class = MedistockReportSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['report_type', 'period_type']
    ordering_fields = ['report_id', 'generated_at']


class MedistockPatientSearchViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter]
    search_fields = ['firstname', 'lastname', 'hospital_id']

    def get_queryset(self):
        qs = PatientProfiling.objects.filter(is_active=True)
        q = self.request.query_params.get('q', '')
        if q:
            qs = qs.filter(
                Q(firstname__icontains=q) |
                Q(lastname__icontains=q) |
                Q(hospital_id__icontains=q)
            )
        return qs

    def list(self, request, *args, **kwargs):
        qs = self.get_queryset()[:20]
        data = [
            {
                'patient_id': p.patient_id,
                'hospital_id': p.hospital_id,
                'firstname': p.firstname,
                'lastname': p.lastname,
                'middlename': p.middlename,
                'full_name': f"{p.lastname}, {p.firstname} {p.middlename or ''}".strip(),
            }
            for p in qs
        ]
        return Response(data)


# ── CSD Purchase Requests (→ Pharmacy) ──────────────────────────────────────

class MedistockPurchaseRequestViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['pr_status', 'purchase_type']
    search_fields = ['pr_no']
    ordering_fields = ['pr_id', 'requested_date']
    http_method_names = ['get', 'post', 'patch', 'delete', 'head', 'options']

    def get_queryset(self):
        return MedistockPurchaseRequest.objects.all().prefetch_related('items').order_by('-pr_id')

    def get_serializer_class(self):
        if self.action == 'list':
            return MedistockPRListSerializer
        return MedistockPRSerializer

    @action(detail=False, methods=['get'])
    def stats(self, request):
        qs = self.get_queryset()
        return Response({
            'pending': qs.filter(pr_status='DRAFT').count(),
            'sent_to_pharmacy': qs.filter(pr_status='SUBMITTED').count(),
            'for_approval': qs.filter(pr_status='FOR_APPROVAL').count(),
            'approved': qs.filter(pr_status='APPROVED').count(),
            'completed': qs.filter(pr_status='DELIVERED').count(),
        })

    @action(detail=False, methods=['get'])
    def next_pr_no(self, request):
        last = MedistockPurchaseRequest.objects.all().order_by('-pr_id').first()
        num = (last.pr_id if last else 0) + 1
        return Response({'next_pr_no': f'CS-{str(num).zfill(4)}'})

    def create(self, request, *args, **kwargs):
        pr_no = (request.data.get('pr_no') or '').strip()
        purchase_type = (request.data.get('purchase_type') or 'REGULAR').upper()
        fund = request.data.get('fund', '')
        lgu = request.data.get('lgu', '')
        department_id = request.data.get('department')
        section = request.data.get('section', '')
        items_data = request.data.get('items', [])
        remarks = request.data.get('remarks', '')

        if not pr_no:
            last = MedistockPurchaseRequest.objects.all().order_by('-pr_id').first()
            num = (last.pr_id if last else 0) + 1
            pr_no = f'CS-{str(num).zfill(4)}'

        if not items_data:
            return Response({'error': 'At least one item is required.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            with transaction.atomic():
                pr = MedistockPurchaseRequest.objects.create(
                    pr_no=pr_no,
                    purchase_type=purchase_type,
                    fund=fund,
                    lgu=lgu,
                    department_id=department_id,
                    section=section,
                    pr_status='DRAFT',
                    requested_by=request.user.get_full_name() or request.user.username,
                    remarks=remarks
                )
                total_amount = 0
                for item in items_data:
                    qty = float(item.get('qty_requested', 0) or 0)
                    unit_cost = float(item.get('unit_cost_estimate', 0) or 0)
                    line_total = qty * unit_cost
                    total_amount += line_total
                    MedistockPurchaseRequestItem.objects.create(
                        purchase_request=pr,
                        supply_id=item.get('medistock_item_id') or item.get('supply'),
                        qty_requested=qty,
                        unit_snapshot=item.get('unit_snapshot', ''),
                        unit_cost_estimate=unit_cost,
                        line_total_estimate=line_total,
                        remarks=item.get('remarks', '')
                    )
                pr.total_amount = total_amount
                pr.save()
            serializer = MedistockPRSerializer(pr)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


# ── Read-only View Endpoints ──────────────────────────────────────────────────

class MedistockVStockSummaryViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = MedistockVStockSummary.objects.all()
    serializer_class = MedistockVStockSummarySerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, DjangoFilterBackend]
    filterset_fields = ['stock_status']
    search_fields = ['supply_name', 'category']

    @action(detail=False, methods=['get'])
    def stats(self, request):
        qs = self.get_queryset()
        return Response({
            'total_items': qs.count(),
            'low_stock': qs.filter(stock_status='LOW STOCK').count(),
            'out_of_stock': qs.filter(stock_status='OUT OF STOCK').count(),
            'adequate': qs.filter(stock_status='ADEQUATE').count(),
        })


class MedistockVLowStockViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = MedistockVLowStock.objects.all()
    serializer_class = MedistockVLowStockSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter]
    search_fields = ['supply_name', 'category']


class MedistockVExpiryAlertViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = MedistockVExpiryAlert.objects.all()
    serializer_class = MedistockVExpiryAlertSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['supply_name', 'batch_no']
    ordering_fields = ['days_remaining', 'expiry_date']


class MedistockVMonthlyConsumptionViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = MedistockVMonthlyConsumption.objects.all()
    serializer_class = MedistockVMonthlyConsumptionSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['supply_name', 'category']
    ordering_fields = ['month', 'consumed']


class MedistockVPendingRequestViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = MedistockVPendingRequest.objects.all()
    serializer_class = MedistockVPendingRequestSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['status', 'source_module']
    search_fields = ['request_no', 'patient_name', 'source_department']


class MedistockVCartItemViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = MedistockVCartItem.objects.all()
    serializer_class = MedistockVCartItemSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['location_type']
    search_fields = ['supply_name', 'location_name']


class MedistockVStockCardViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = MedistockVStockCardSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['transaction_type', 'source_module']
    search_fields = ['supply_name', 'patient_name', 'requested_by']
    ordering_fields = ['transaction_id', 'transaction_datetime']

    def get_queryset(self):
        qs = MedistockVStockCard.objects.all()
        date_from = self.request.query_params.get('date_from')
        date_to = self.request.query_params.get('date_to')
        if date_from:
            qs = qs.filter(transaction_datetime__date__gte=date_from)
        if date_to:
            qs = qs.filter(transaction_datetime__date__lte=date_to)
        return qs
