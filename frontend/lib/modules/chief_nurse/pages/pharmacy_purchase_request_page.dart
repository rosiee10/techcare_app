import 'package:flutter/material.dart';
import '../widgets/pharmacy_purchase_request/pr_stat_card.dart';
import '../widgets/pharmacy_purchase_request/pr_card.dart';
import '../services/chief_nurse_pharmacy_service.dart';

/// Pharmacy Purchase Request Page for Chief Nurse
/// Connects to pharmacy database to display real purchase requests from pharmacist users
class PharmacyPurchaseRequestPage extends StatefulWidget {
  const PharmacyPurchaseRequestPage({super.key});

  @override
  State<PharmacyPurchaseRequestPage> createState() => _PharmacyPurchaseRequestPageState();
}

class _PharmacyPurchaseRequestPageState extends State<PharmacyPurchaseRequestPage> {
  final TextEditingController _searchController = TextEditingController();
  final ChiefNursePharmacyService _pharmacyService = ChiefNursePharmacyService();
  String _selectedStatus = 'All Status';
  
  // Real data from database
  List<Map<String, dynamic>> _purchaseRequests = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Stats from database
  int _pendingCount = 0;
  int _approvedCount = 0;
  int _deliveredCount = 0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Fetch purchase requests from pharmacy database
      final prResult = await _pharmacyService.getPharmacyPurchaseRequests();
      final statsResult = await _pharmacyService.getPharmacyPRStats();

      if (prResult['success'] && mounted) {
        setState(() {
          // Transform database data to match UI format
          final rawPRs = prResult['purchaseRequests'] as List<dynamic>;
          _purchaseRequests = rawPRs.map((pr) => _transformPurchaseRequest(pr)).toList();
          
          // Sort by PR number descending (newest first)
          _purchaseRequests.sort((a, b) {
            final aNo = a['prNo'].toString();
            final bNo = b['prNo'].toString();
            // Extract numeric part from PR number (e.g., "PR-012" -> 12)
            final aNum = int.tryParse(aNo.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            final bNum = int.tryParse(bNo.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            return bNum.compareTo(aNum); // Descending order
          });
          
          // Update stats
          if (statsResult['success']) {
            final stats = statsResult['stats'];
            _pendingCount = stats['pending'] ?? 0;
            _approvedCount = stats['approved'] ?? 0;
            _deliveredCount = stats['delivered'] ?? 0;
            _totalCount = stats['total'] ?? 0;
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = prResult['message'] ?? 'Failed to load purchase requests';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// Transform raw database data to UI-friendly format
  Map<String, dynamic> _transformPurchaseRequest(Map<String, dynamic> pr) {
    final items = pr['items'] as List<dynamic>? ?? [];
    
    // Use actual values if status is DELIVERED, otherwise use estimated values
    final isDelivered = (pr['pr_status'] ?? '').toString().toUpperCase() == 'DELIVERED';
    
    final totalCost = items.fold<double>(
      0,
      (sum, item) {
        final goodsReceiptItem = item['goods_receipt_item'];
        final lineTotal = isDelivered && goodsReceiptItem != null
            ? (goodsReceiptItem['line_total_actual'] ?? 0) as double
            : (item['line_total_estimate'] ?? 0) as double;
        return sum + lineTotal;
      },
    );

    return {
      'prNo': pr['pr_no'] ?? 'N/A',
      'fpp': 'N/A',
      'requestedBy': 'Pharmacist User',
      'date': pr['requested_date'] != null ? pr['requested_date'].toString() : 'N/A',
      'items': items.length,
      'totalCost': totalCost,
      'status': _mapStatus(pr['pr_status'] ?? 'DRAFT'),
      'fund': 'General Fund',
      'lgu': 'PLARIDEL',
      'department': 'PCH',
      'section': 'Pharmacy',
      'itemsList': items.map((item) {
        final goodsReceiptItem = item['goods_receipt_item'];
        return {
          'itemNo': item['pr_item_id'] ?? 0,
          'qty': isDelivered && goodsReceiptItem != null
              ? (goodsReceiptItem['qty_received'] ?? item['qty_requested'] ?? 0)
              : (item['qty_requested'] ?? 0),
          'unit': item['unit_snapshot'] ?? 'pcs',
          'name': item['medicine_name'] ?? 'Unknown',
          'unitPrice': isDelivered && goodsReceiptItem != null
              ? (goodsReceiptItem['unit_cost_actual'] ?? item['unit_cost_estimate'] ?? 0.0)
              : (item['unit_cost_estimate'] ?? 0.0),
          'total': isDelivered && goodsReceiptItem != null
              ? (goodsReceiptItem['line_total_actual'] ?? item['line_total_estimate'] ?? 0.0)
              : (item['line_total_estimate'] ?? 0.0),
        };
      }).toList(),
      'rawData': pr, // Keep original for API calls
    };
  }

  /// Map database status to UI status
  String _mapStatus(String dbStatus) {
    switch (dbStatus.toUpperCase()) {
      case 'SUBMITTED':
        return 'Pending';
      case 'APPROVED':
        return 'Approved';
      case 'ON_DELIVERY':
        return 'On Delivery';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
      case 'REJECTED':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  List<Map<String, dynamic>> get _filteredPRs {
    if (_searchController.text.isEmpty && _selectedStatus == 'All Status') {
      return _purchaseRequests;
    }
    return _purchaseRequests.where((pr) {
      final searchText = _searchController.text.toLowerCase();
      final matchesSearch = pr['prNo'].toString().toLowerCase().contains(searchText) ||
          pr['requestedBy'].toString().toLowerCase().contains(searchText);
      final matchesStatus = _selectedStatus == 'All Status' || pr['status'] == _selectedStatus;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildFilterTab(String filter, String label, int count) {
    final isSelected = _selectedStatus == filter;
    
    // Color mapping for each status
    final colorMap = {
      'All Status': Colors.grey[600]!,
      'Pending': const Color(0xFFF57F17), // Orange
      'Approved': const Color(0xFF2E7D32), // Green
      'Delivered': const Color(0xFF1976D2), // Blue
    };
    
    final color = colorMap[filter] ?? Colors.grey[600]!;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = filter;
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
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePRAction(Map<String, dynamic> updatedPR, String action) async {
    final rawData = updatedPR['rawData'] as Map<String, dynamic>;
    final prId = rawData['pr_id']?.toString();
    
    if (prId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Could not find PR ID')),
      );
      return;
    }
    
    final result = await _pharmacyService.approvePurchaseRequest(
      prId,
      action: action.toUpperCase(),
      updatedItems: (updatedPR['itemsList'] as List<dynamic>).map((item) => {
        'pr_item_id': item['itemNo'],
        'approved_qty': item['approved_qty'] ?? item['qty'],
        'unit_cost_estimate': item['unitPrice'],
      }).toList(),
    );

    if (result['success'] && mounted) {
      // Refresh data after action
      await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase Request $action')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to $action')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading pharmacy purchase requests...'),
          ],
        ),
      );
    }

    // Show error if any
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show empty state
    if (_purchaseRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No purchase requests found',
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'New requests from pharmacists will appear here',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Pharmacy Purchase Requests',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Review and approve purchase requests from pharmacist users',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          
          // Stats Cards - Responsive 2x2 or 1x4 grid
          LayoutBuilder(
            builder: (context, constraints) {
              final cardsPerRow = constraints.maxWidth >= 800 ? 4 : 2;
              final spacing = 16.0;
              final cardWidth = (constraints.maxWidth - (spacing * (cardsPerRow - 1))) / cardsPerRow;
              
              final cards = [
                PRStatCard(
                  title: 'Total',
                  value: _totalCount.toString(),
                  subtitle: 'All requests',
                  color: Colors.indigo,
                  icon: Icons.receipt_long_outlined,
                ),
                PRStatCard(
                  title: 'Pending',
                  value: _pendingCount.toString(),
                  subtitle: 'Awaiting review',
                  color: Colors.orange,
                  icon: Icons.access_time,
                ),
                PRStatCard(
                  title: 'Approved',
                  value: _approvedCount.toString(),
                  subtitle: 'Ready for procurement',
                  color: Colors.green,
                  icon: Icons.check_circle_outline,
                ),
                PRStatCard(
                  title: 'Delivered',
                  value: _deliveredCount.toString(),
                  subtitle: 'Completed orders',
                  color: Colors.blue,
                  icon: Icons.local_shipping_outlined,
                ),
              ];
              
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: cards.map((card) => SizedBox(
                  width: cardWidth,
                  child: card,
                )).toList(),
              );
            },
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
                    _buildFilterTab('All Status', 'All', _totalCount),
                    _buildFilterTab('Pending', 'Pending', _pendingCount),
                    _buildFilterTab('Approved', 'Approved', _approvedCount),
                    _buildFilterTab('Delivered', 'Delivered', _deliveredCount),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Purchase Request Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              int cardsPerRow;
              if (availableWidth >= 960) {
                cardsPerRow = 3;
              } else if (availableWidth >= 640) {
                cardsPerRow = 2;
              } else {
                cardsPerRow = 1;
              }
              final cardWidth = (availableWidth - (16 * (cardsPerRow - 1))) / cardsPerRow;
              
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _filteredPRs.map((pr) => SizedBox(
                  width: cardWidth,
                  child: PRCard(
                    purchaseRequest: pr,
                    onAction: (updatedPR, action) => _handlePRAction(updatedPR, action),
                  ),
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
