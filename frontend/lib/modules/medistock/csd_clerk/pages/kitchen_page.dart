import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/card_container.dart';

/// Kitchen Purchase Requests Page for CSD Clerk
class KitchenPage extends StatefulWidget {
  const KitchenPage({super.key});

  @override
  State<KitchenPage> createState() => _KitchenPageState();
}

class _KitchenPageState extends State<KitchenPage> {
  final TextEditingController _searchController = TextEditingController();

  // Sample data - replace with actual API calls
  // Empty list for now as shown in screenshot (all requests processed)
  final List<Map<String, dynamic>> _kitchenRequests = [
    // Example data structure when there are items:
    // {
    //   'id': 1,
    //   'requestNo': 'KR-2026-001',
    //   'date': '2026-05-01',
    //   'requestedBy': 'Kitchen Staff A',
    //   'items': 3,
    //   'totalAmount': 2500.00,
    //   'status': 'Pending Review',
    // },
  ];

  List<Map<String, dynamic>> _filteredRequests = [];

  @override
  void initState() {
    super.initState();
    _filteredRequests = List.from(_kitchenRequests);
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
      _filteredRequests = _kitchenRequests.where((req) {
        return query.isEmpty ||
            req['requestNo'].toString().toLowerCase().contains(query) ||
            req['requestedBy'].toString().toLowerCase().contains(query) ||
            req['status'].toString().toLowerCase().contains(query);
      }).toList();
    });
  }

  // Stats calculations
  int get _pendingReview => _kitchenRequests.where((req) => req['status'] == 'Pending Review').length;
  int get _totalApproved => _kitchenRequests.where((req) => req['status'] == 'Approved').length;
  int get _inProcessing => _kitchenRequests.where((req) => req['status'] == 'In Processing').length;
  int get _completed => _kitchenRequests.where((req) => req['status'] == 'Completed').length;

  (Color, Color) _getStatusColors(String status) {
    switch (status) {
      case 'Pending Review':
        return (const Color(0xFFFFF8E1), const Color(0xFFFF8F00));
      case 'Approved':
        return (const Color(0xFFE8F5E9), const Color(0xFF388E3C));
      case 'In Processing':
        return (const Color(0xFFEBF5FF), const Color(0xFF3B82F6));
      case 'Completed':
        return (const Color(0xFFF3E8FF), const Color(0xFFA855F7));
      default:
        return (const Color(0xFFF5F5F5), const Color(0xFF616161));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 768;
    final hasRequests = _kitchenRequests.isNotEmpty;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kitchen Purchase Requests',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Review and manage purchase requests from Kitchen Staff',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stats Cards
          isSmallScreen
              ? Column(
                  children: [
                    _buildStatCard('Pending Review', _pendingReview.toString(), Icons.access_time_outlined, const Color(0xFFFFF8E1), const Color(0xFFF59E0B)),
                    const SizedBox(height: 12),
                    _buildStatCard('Total Approved', _totalApproved.toString(), Icons.check_circle_outline, const Color(0xFFE6F7ED), const Color(0xFF22C55E)),
                    const SizedBox(height: 12),
                    _buildStatCard('In Processing', _inProcessing.toString(), Icons.inventory_2_outlined, const Color(0xFFEBF5FF), const Color(0xFF3B82F6)),
                    const SizedBox(height: 12),
                    _buildStatCard('Completed', _completed.toString(), Icons.task_alt_outlined, const Color(0xFFF3E8FF), const Color(0xFFA855F7)),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildStatCard('Pending Review', _pendingReview.toString(), Icons.access_time_outlined, const Color(0xFFFFF8E1), const Color(0xFFF59E0B))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard('Total Approved', _totalApproved.toString(), Icons.check_circle_outline, const Color(0xFFE6F7ED), const Color(0xFF22C55E))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard('In Processing', _inProcessing.toString(), Icons.inventory_2_outlined, const Color(0xFFEBF5FF), const Color(0xFF3B82F6))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard('Completed', _completed.toString(), Icons.task_alt_outlined, const Color(0xFFF3E8FF), const Color(0xFFA855F7))),
                  ],
                ),
          const SizedBox(height: 24),

          // Empty State or Table
          CardContainer(
            child: hasRequests
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by request number, requestor, or status...',
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
                      const SizedBox(height: 16),
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
                            _buildTableHeader('REQUEST NO.', flex: 2),
                            _buildTableHeader('DATE', flex: 2),
                            _buildTableHeader('REQUESTED BY', flex: 2),
                            _buildTableHeader('ITEMS', flex: 1),
                            _buildTableHeader('TOTAL AMOUNT', flex: 2),
                            _buildTableHeader('STATUS', flex: 2),
                            _buildTableHeader('ACTIONS', flex: 1),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // Table Body
                      ..._filteredRequests.map((req) {
                        final statusColors = _getStatusColors(req['status']);
                        return Container(
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
                                  req['requestNo'],
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
                                  req['date'],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  req['requestedBy'],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  req['items'].toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '₱${req['totalAmount'].toStringAsFixed(2)}',
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
                                    req['status'],
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
                                flex: 1,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (req['status'] == 'Pending Review')
                                      IconButton(
                                        onPressed: () {
                                          // Approve action
                                        },
                                        icon: const Icon(Icons.check_circle_outline, color: Color(0xFF22C55E), size: 20),
                                        tooltip: 'Approve',
                                      ),
                                    IconButton(
                                      onPressed: () {
                                        // View details action
                                      },
                                      icon: const Icon(Icons.visibility_outlined, color: Color(0xFF3B82F6), size: 20),
                                      tooltip: 'View Details',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  )
                : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Pending Requests',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All purchase requests have been processed.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color bgColor, Color iconColor) {
    return CardContainer(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
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
