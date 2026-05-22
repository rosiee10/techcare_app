import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/card_container.dart';
import '../services/pharmacy_service.dart';
import '../widgets/purchase_request/create_request_dialog.dart';
import '../widgets/purchase_request/purchase_request_details_dialog.dart';
import '../widgets/purchase_request/delivery_confirmation_dialog.dart';

/// Purchase Requests Page
/// Create and manage medicine purchase requests based on inventory levels
class PurchaseRequestPage extends StatefulWidget {
  final Map<String, dynamic>? pendingActionData;
  final VoidCallback? onActionCompleted;
  const PurchaseRequestPage({super.key, this.pendingActionData, this.onActionCompleted});

  @override
  State<PurchaseRequestPage> createState() => _PurchaseRequestPageState();
}

class _PurchaseRequestPageState extends State<PurchaseRequestPage> {
  final PharmacyService _pharmacyService = PharmacyService();

  // Dynamic data
  bool _isLoading = true;
  List<dynamic> _purchaseRequests = [];
  List<dynamic> _lowStockAlerts = [];
  String _errorMessage = '';
  String _selectedStatusFilter = 'ALL'; // ALL, PENDING, APPROVED, DELIVERED, CANCELLED

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final requests = await _pharmacyService.getPurchaseRequests();
      final lowStock = await _pharmacyService.getLowStockAlerts();

      setState(() {
        _purchaseRequests = requests;
        _lowStockAlerts = lowStock;
        _isLoading = false;
      });

      // Check for deep link data from notification
      if (widget.pendingActionData != null && widget.pendingActionData!['id'] != null) {
        final prId = widget.pendingActionData!['id'];
        final targetPR = _purchaseRequests.firstWhere(
          (r) => r['pr_id'] == prId || r['id'] == prId || r['pr_no'] == prId,
          orElse: () => null,
        );
        
        if (targetPR != null) {
          _openPRDetails(targetPR);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  // Calculate pending requests
  int get _pendingCount => _purchaseRequests.where((r) => r['pr_status']?.toString().toLowerCase() == 'draft').length;

  // Calculate approved requests
  int get _approvedCount => _purchaseRequests.where((r) => r['pr_status']?.toString().toLowerCase() == 'approved').length;

  // Calculate delivered requests
  int get _deliveredCount => _purchaseRequests.where((r) => r['pr_status']?.toString().toLowerCase() == 'delivered').length;

  // Calculate cancelled requests
  int get _cancelledCount => _purchaseRequests.where((r) => r['pr_status']?.toString().toLowerCase() == 'cancelled').length;

  // Get filtered purchase requests based on selected tab
  List<dynamic> get _filteredPurchaseRequests {
    if (_selectedStatusFilter == 'ALL') {
      return _purchaseRequests;
    }
    final statusMap = {
      'PENDING': 'draft',
      'APPROVED': 'approved',
      'DELIVERED': 'delivered',
      'CANCELLED': 'cancelled',
    };
    final targetStatus = statusMap[_selectedStatusFilter];
    return _purchaseRequests.where((r) => 
      r['pr_status']?.toString().toLowerCase() == targetStatus
    ).toList();
  }

  void _openPRDetails(dynamic request) {
    PurchaseRequestDetailsDialog.show(
      context,
      request: request,
      onConfirmDelivery: () {
        DeliveryConfirmationDialog.show(
          context: context,
          purchaseRequest: request,
          onSave: (deliveryData) async {
            try {
              await _pharmacyService.confirmDelivery(deliveryData);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delivery confirmed and inventory restocked successfully!'),
                ),
              );
              _fetchData(); // Refresh local list
              widget.onActionCompleted?.call(); // Refresh global dashboard notifications instantly
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with New Request button - Responsive
          isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Purchase Requests',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage purchase requests',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await CreateRequestDialog.show(context);
                          if (result == true) {
                            _fetchData();
                          }
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Purchase Requests',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create and manage medicine purchase requests based on inventory levels',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await CreateRequestDialog.show(context);
                      if (result == true) {
                        _fetchData();
                      }
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Request'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
          const SizedBox(height: 24),

          // Stat Cards - Mobile: 2x2 Grid, Desktop: Row
          isMobile
            ? Column(
                children: [
                  // First row: 2 cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Pending',
                          value: _isLoading ? '-' : _pendingCount.toString(),
                          icon: Icons.access_time_outlined,
                          iconBgColor: const Color(0xFFFFF9C4),
                          iconColor: const Color(0xFFFBC02D),
                          valueColor: const Color(0xFFF57F17),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Approved',
                          value: _isLoading ? '-' : _approvedCount.toString(),
                          icon: Icons.check_circle_outline,
                          iconBgColor: const Color(0xFFE8F5E9),
                          iconColor: const Color(0xFF4CAF50),
                          valueColor: const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Second row: 2 cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Delivered',
                          value: _isLoading ? '-' : _deliveredCount.toString(),
                          icon: Icons.inventory_2_outlined,
                          iconBgColor: const Color(0xFFE3F2FD),
                          iconColor: const Color(0xFF2196F3),
                          valueColor: const Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Cancelled',
                          value: _isLoading ? '-' : _cancelledCount.toString(),
                          icon: Icons.cancel_outlined,
                          iconBgColor: const Color(0xFFFFEBEE),
                          iconColor: const Color(0xFFE53935),
                          valueColor: const Color(0xFFC62828),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  _buildStatCard(
                    title: 'Pending',
                    value: _isLoading ? '-' : _pendingCount.toString(),
                    icon: Icons.access_time_outlined,
                    iconBgColor: const Color(0xFFFFF9C4),
                    iconColor: const Color(0xFFFBC02D),
                    valueColor: const Color(0xFFF57F17),
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    title: 'Approved',
                    value: _isLoading ? '-' : _approvedCount.toString(),
                    icon: Icons.check_circle_outline,
                    iconBgColor: const Color(0xFFE8F5E9),
                    iconColor: const Color(0xFF4CAF50),
                    valueColor: const Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    title: 'Delivered',
                    value: _isLoading ? '-' : _deliveredCount.toString(),
                    icon: Icons.inventory_2_outlined,
                    iconBgColor: const Color(0xFFE3F2FD),
                    iconColor: const Color(0xFF2196F3),
                    valueColor: const Color(0xFF1976D2),
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    title: 'Cancelled',
                    value: _isLoading ? '-' : _cancelledCount.toString(),
                    icon: Icons.cancel_outlined,
                    iconBgColor: const Color(0xFFFFEBEE),
                    iconColor: const Color(0xFFE53935),
                    valueColor: const Color(0xFFC62828),
                  ),
                ],
              ),
          const SizedBox(height: 24),

          // Status Filter Tabs
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildFilterTab('ALL', 'All', _purchaseRequests.length),
                    _buildFilterTab('PENDING', 'Pending', _pendingCount),
                    _buildFilterTab('APPROVED', 'Approved', _approvedCount),
                    _buildFilterTab('DELIVERED', 'Delivered', _deliveredCount),
                    _buildFilterTab('CANCELLED', 'Cancelled', _cancelledCount),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Purchase Request Cards - Dynamic
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage.isNotEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[400], size: 48),
                  const SizedBox(height: 16),
                  Text(_errorMessage, style: TextStyle(color: Colors.red[600])),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _fetchData, child: const Text('Retry')),
                ],
              ),
            )
          else if (_filteredPurchaseRequests.isEmpty)
            CardContainer(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No ${_selectedStatusFilter.toLowerCase()} purchase requests found.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            ..._filteredPurchaseRequests.map((request) {
              final items = (request['items'] ?? []).where((item) => item is Map).toList();
              
              // Use actual totals if status is DELIVERED, otherwise use estimated totals
              final isDelivered = request['status']?.toString().toUpperCase() == 'DELIVERED' ||
                                request['pr_status']?.toString().toUpperCase() == 'DELIVERED';
              
              // Check if emergency purchase request
              final isEmergency = (request['purchase_type'] ?? '').toString().toUpperCase() == 'EMERGENCY';
              
              final totalAmount = items.fold(0.0, (sum, item) {
                final goodsReceiptItem = (item as Map)['goods_receipt_item'];
                final lineTotal = isDelivered && goodsReceiptItem != null
                    ? (double.tryParse(goodsReceiptItem['line_total_actual']?.toString() ?? '0') ?? 0)
                    : (double.tryParse(item['line_total_estimate']?.toString() ?? '0') ?? 0);
                return sum + lineTotal;
              });
              
              // Colors based on emergency status
              final primaryColor = isEmergency ? Colors.red : const Color(0xFF2196F3);
              final bgColor = isEmergency ? const Color(0xFFFFEBEE) : const Color(0xFFE3F2FD);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: CardContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // Header - Responsive
                    isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.shopping_cart_outlined, color: primaryColor, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  request['pr_no'] ?? request['pr_number'] ?? 'PR-???',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _getStatusBgColor(request['pr_status'] ?? request['status']),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    (request['pr_status'] ?? request['status'] ?? 'DRAFT').toString().toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: _getStatusTextColor(request['pr_status'] ?? request['status']),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    request['purchase_type'] ?? 'Regular',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                                Text(
                                  '₱${totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4CAF50),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${items.length} items • ${request['pr_date'] ?? '—'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.shopping_cart_outlined, color: primaryColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              request['pr_no'] ?? request['pr_number'] ?? 'PR-???',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusBgColor(request['pr_status'] ?? request['status']),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                (request['pr_status'] ?? request['status'] ?? 'DRAFT').toString().toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusTextColor(request['pr_status'] ?? request['status']),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                request['purchase_type'] ?? 'Regular',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Total Amount',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '₱${totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4CAF50),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                    const SizedBox(height: 8),
                    if (!isMobile)
                      Padding(
                        padding: const EdgeInsets.only(left: 50),
                        child: Text(
                          '${items.length} items • Requested on ${request['pr_date'] ?? '—'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    const Divider(height: 24),

                    // Requested Medicines Section
                    const Text(
                      'Requested Medicines',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Medicine Items - Responsive
                    ...items.where((item) => item is Map).map((item) {
                      String medicine = (item as Map)['medicine_name']?.toString() ?? '';
                      if (medicine.isEmpty && item['medicine'] != null && item['medicine'] is Map) {
                        medicine = item['medicine']['medicine_name']?.toString() ?? 'Unknown Medicine';
                      }
                      if (medicine.isEmpty) {
                        medicine = 'Unknown Medicine';
                      }
                      
                      // Use actual values if status is DELIVERED, otherwise use requested values
                      final isDelivered = request['status']?.toString().toUpperCase() == 'DELIVERED' ||
                                        request['pr_status']?.toString().toUpperCase() == 'DELIVERED';
                      
                      final goodsReceiptItem = item['goods_receipt_item'];
                      
                      final qty = isDelivered && goodsReceiptItem != null
                          ? (goodsReceiptItem['qty_received'] ?? item['qty_requested'] ?? item['quantity_requested'] ?? 0)
                          : (item['qty_requested'] ?? item['quantity_requested'] ?? 0);
                      
                      final price = isDelivered && goodsReceiptItem != null
                          ? (double.tryParse(goodsReceiptItem['unit_cost_actual']?.toString() ?? '0') ?? 0)
                          : (double.tryParse(item['unit_cost_estimate']?.toString() ?? '0') ?? 0);
                      
                      final total = isDelivered && goodsReceiptItem != null
                          ? (double.tryParse(goodsReceiptItem['line_total_actual']?.toString() ?? '0') ?? 0)
                          : (double.tryParse(item['line_total_estimate']?.toString() ?? item['total_cost']?.toString() ?? '0') ?? 0);
                      
                      return isMobile
                        ? Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.medication_outlined, color: Colors.grey[500], size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        medicine,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Qty: $qty',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      '₱${price.toDouble().toStringAsFixed(2)} each',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      '₱${total.toDouble().toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2196F3),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        : Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.medication_outlined, color: Colors.grey[500], size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        medicine,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Qty: $qty',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Text(
                                  'Price: ₱${price.toDouble().toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Text(
                                  '₱${total.toDouble().toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2196F3),
                                  ),
                                ),
                              ],
                            ),
                          );
                    }).toList(),
                    const SizedBox(height: 12),
                    // View Details button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _openPRDetails(request),
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: const Text('View Details'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey[300]!),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required Color valueColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusTextColor(String? status) {
    final s = status?.toLowerCase() ?? '';
    if (s == 'draft' || s == 'pending') {
      return const Color(0xFFF57F17); // Orange
    } else if (s == 'approved') {
      return const Color(0xFF2E7D32); // Green
    } else if (s == 'delivered') {
      return const Color(0xFF1976D2); // Blue
    } else if (s == 'rejected' || s == 'cancelled') {
      return Colors.red;
    }
    return const Color(0xFFF57F17);
  }

  Color _getStatusBgColor(String? status) {
    final s = status?.toLowerCase() ?? '';
    if (s == 'draft' || s == 'pending') {
      return const Color(0xFFFFF9C4); // Light yellow
    } else if (s == 'approved') {
      return const Color(0xFFE8F5E9); // Light green
    } else if (s == 'delivered') {
      return const Color(0xFFE3F2FD); // Light blue
    } else if (s == 'rejected' || s == 'cancelled') {
      return Colors.red[50]!;
    }
    return const Color(0xFFFFF9C4);
  }

  Widget _buildFilterTab(String filter, String label, int count) {
    final isSelected = _selectedStatusFilter == filter;
    
    // Color mapping for each status
    final colorMap = {
      'ALL': Colors.grey[600]!,
      'PENDING': const Color(0xFFF57F17), // Orange
      'APPROVED': const Color(0xFF2E7D32), // Green
      'DELIVERED': const Color(0xFF1976D2), // Blue
      'CANCELLED': const Color(0xFFC62828), // Red
    };
    
    final color = colorMap[filter] ?? Colors.grey[600]!;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatusFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: isSelected
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.25) : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
