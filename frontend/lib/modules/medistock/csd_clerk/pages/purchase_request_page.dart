import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/card_container.dart';
import '../widgets/purchase_request/purchase_request_form_dialog.dart';
import '../widgets/purchase_request/purchase_request_details_dialog.dart';

/// Purchase Request Page for CSD Clerk
class PurchaseRequestPage extends StatefulWidget {
  const PurchaseRequestPage({super.key});

  @override
  State<PurchaseRequestPage> createState() => _PurchaseRequestPageState();
}

class _PurchaseRequestPageState extends State<PurchaseRequestPage> {
  final TextEditingController _searchController = TextEditingController();

  // Sample data - replace with actual API calls
  final List<Map<String, dynamic>> _purchaseRequests = [
    {
      'id': 1,
      'prNo': 'PR-2026-001',
      'date': '2026-05-01',
      'department': 'Central Supply',
      'items': 5,
      'totalAmount': 15000.00,
      'status': 'Pending',
      'requestedBy': 'John Doe',
    },
    {
      'id': 2,
      'prNo': 'PR-2026-002',
      'date': '2026-05-02',
      'department': 'Central Supply',
      'items': 3,
      'totalAmount': 8500.00,
      'status': 'Approved',
      'requestedBy': 'Jane Smith',
    },
    {
      'id': 3,
      'prNo': 'PR-2026-003',
      'date': '2026-05-03',
      'department': 'Central Supply',
      'items': 8,
      'totalAmount': 25000.00,
      'status': 'Processing',
      'requestedBy': 'Mike Johnson',
    },
    {
      'id': 4,
      'prNo': 'PR-2026-004',
      'date': '2026-04-28',
      'department': 'Central Supply',
      'items': 2,
      'totalAmount': 3200.00,
      'status': 'Delivered',
      'requestedBy': 'Sarah Williams',
    },
    {
      'id': 5,
      'prNo': 'PR-2026-005',
      'date': '2026-04-25',
      'department': 'Central Supply',
      'items': 6,
      'totalAmount': 18000.00,
      'status': 'Rejected',
      'requestedBy': 'Tom Brown',
    },
  ];

  List<Map<String, dynamic>> _filteredRequests = [];

  @override
  void initState() {
    super.initState();
    _filteredRequests = List.from(_purchaseRequests);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterRequests();
  }

  void _filterRequests() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      _filteredRequests = _purchaseRequests.where((pr) {
        return query.isEmpty ||
            pr['prNo'].toString().toLowerCase().contains(query) ||
            pr['requestedBy'].toString().toLowerCase().contains(query) ||
            pr['status'].toString().toLowerCase().contains(query);
      }).toList();
    });
  }

  // Stats calculations
  int get _totalRequests => _purchaseRequests.length;
  int get _pendingRequests => _purchaseRequests.where((pr) => pr['status'] == 'Pending').length;
  int get _approvedRequests => _purchaseRequests.where((pr) => pr['status'] == 'Approved' || pr['status'] == 'Processing').length;
  double get _totalAmount => _purchaseRequests.fold(0.0, (sum, pr) => sum + (pr['totalAmount'] as double));

  (Color, Color) _getStatusColors(String status) {
    switch (status) {
      case 'Pending':
        return (const Color(0xFFFFF8E1), const Color(0xFFFF8F00));
      case 'Approved':
      case 'Processing':
        return (const Color(0xFFE8F5E9), const Color(0xFF388E3C));
      case 'Delivered':
        return (const Color(0xFFEBF5FF), const Color(0xFF3B82F6));
      case 'Rejected':
        return (const Color(0xFFFFEBEE), const Color(0xFFD32F2F));
      default:
        return (const Color(0xFFF5F5F5), const Color(0xFF616161));
    }
  }

  Future<void> _showCreateRequestDialog() async {
    final result = await CreateRequestDialog.show(context);
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase request created successfully')),
      );
    }
  }

  Future<void> _showRequestDetails(Map<String, dynamic> request) async {
    await PurchaseRequestDetailsDialog.show(context, request: request);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 768;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          isSmallScreen
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Purchase Requests',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage and track purchase requests for supplies',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showCreateRequestDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Create Request'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
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
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage and track purchase requests for supplies',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _showCreateRequestDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Create Request'),
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

          // Stats Cards
          isSmallScreen
              ? Column(
                  children: [
                    _buildStatCard('Total Requests', _totalRequests.toString(), Icons.request_page_outlined, const Color(0xFFEBF5FF), const Color(0xFF3B82F6)),
                    const SizedBox(height: 12),
                    _buildStatCard('Pending', _pendingRequests.toString(), Icons.pending_outlined, const Color(0xFFFFF8E1), const Color(0xFFF59E0B)),
                    const SizedBox(height: 12),
                    _buildStatCard('Approved', _approvedRequests.toString(), Icons.check_circle_outline, const Color(0xFFE6F7ED), const Color(0xFF22C55E)),
                    const SizedBox(height: 12),
                    _buildStatCard('Total Value', '₱${_totalAmount.toStringAsFixed(2)}', Icons.payments_outlined, const Color(0xFFF3E8FF), const Color(0xFFA855F7)),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildStatCard('Total Requests', _totalRequests.toString(), Icons.request_page_outlined, const Color(0xFFEBF5FF), const Color(0xFF3B82F6))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard('Pending', _pendingRequests.toString(), Icons.pending_outlined, const Color(0xFFFFF8E1), const Color(0xFFF59E0B))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard('Approved', _approvedRequests.toString(), Icons.check_circle_outline, const Color(0xFFE6F7ED), const Color(0xFF22C55E))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard('Total Value', '₱${_totalAmount.toStringAsFixed(2)}', Icons.payments_outlined, const Color(0xFFF3E8FF), const Color(0xFFA855F7))),
                  ],
                ),
          const SizedBox(height: 24),

          // Search Bar
          CardContainer(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by PR number, requestor, or status...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF2563EB)),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Purchase Requests Table
          CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildTableHeader('PR NO.', flex: 2),
                      _buildTableHeader('DATE', flex: 2),
                      _buildTableHeader('DEPARTMENT', flex: 2),
                      _buildTableHeader('ITEMS', flex: 1),
                      _buildTableHeader('TOTAL AMOUNT', flex: 2),
                      _buildTableHeader('STATUS', flex: 2),
                      _buildTableHeader('REQUESTED BY', flex: 2),
                      _buildTableHeader('ACTIONS', flex: 1),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Table Body
                ..._filteredRequests.map((pr) {
                  final statusColors = _getStatusColors(pr['status']);
                  return InkWell(
                    onTap: () => _showRequestDetails(pr),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              pr['prNo'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              pr['date'],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              pr['department'],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              pr['items'].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '₱${pr['totalAmount'].toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColors.$1,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                pr['status'],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: statusColors.$2,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              pr['requestedBy'],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: IconButton(
                              onPressed: () => _showRequestDetails(pr),
                              icon: const Icon(Icons.visibility_outlined, color: Color(0xFF3B82F6), size: 20),
                              tooltip: 'View Details',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                if (_filteredRequests.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(40),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.request_page_outlined, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No purchase requests found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color bgColor, Color iconColor) {
    return CardContainer(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String title, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}
