import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/card_container.dart';
import '../widgets/inventory_carts/restock_cart_dialog.dart';

/// Inventory Carts Monitoring Page for CSD Clerk
class InventoryCartsPage extends StatefulWidget {
  const InventoryCartsPage({super.key});

  @override
  State<InventoryCartsPage> createState() => _InventoryCartsPageState();
}

class _InventoryCartsPageState extends State<InventoryCartsPage> {
  final TextEditingController _searchController = TextEditingController();

  // Sample data - replace with actual API calls
  final List<Map<String, dynamic>> _cartItems = [
    {
      'id': 1,
      'itemName': 'Surgical Gloves (Large)',
      'unit': 'box',
      'category': 'Medical Supplies',
      'totalQty': 90,
      'batches': 3,
      'status': 'Good Stock',
    },
    {
      'id': 2,
      'itemName': 'Disposable Syringes',
      'unit': 'pcs',
      'category': 'Medical Supplies',
      'totalQty': 135,
      'batches': 3,
      'status': 'Good Stock',
    },
    {
      'id': 3,
      'itemName': 'Gauze Pads',
      'unit': 'pack',
      'category': 'Medical Supplies',
      'totalQty': 43,
      'batches': 2,
      'status': 'Expired',
    },
    {
      'id': 4,
      'itemName': 'Alcohol Swabs',
      'unit': 'box',
      'category': 'Medical Supplies',
      'totalQty': 75,
      'batches': 2,
      'status': 'Good Stock',
    },
    {
      'id': 5,
      'itemName': 'Bandage Rolls',
      'unit': 'pcs',
      'category': 'Medical Supplies',
      'totalQty': 60,
      'batches': 2,
      'status': 'Low Stock',
    },
  ];

  List<Map<String, dynamic>> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(_cartItems);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterItems();
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      _filteredItems = _cartItems.where((item) {
        return query.isEmpty ||
            item['itemName'].toString().toLowerCase().contains(query) ||
            item['category'].toString().toLowerCase().contains(query);
      }).toList();
    });
  }

  // Stats calculations
  int get _totalCarts => 4;
  int get _uniqueItems => _cartItems.length;
  int get _activeCarts => 3;
  int get _totalBatches => _cartItems.fold(0, (sum, item) => sum + (item['batches'] as int));

  (Color, Color) _getStatusColors(String status) {
    switch (status) {
      case 'Low Stock':
        return (const Color(0xFFFFF8E1), const Color(0xFFFF8F00));
      case 'Expired':
        return (const Color(0xFFFFEBEE), const Color(0xFFD32F2F));
      case 'Near Expiry':
        return (const Color(0xFFFFF3E0), const Color(0xFFEF6C00));
      default:
        return (const Color(0xFFE8F5E9), const Color(0xFF388E3C));
    }
  }

  Future<void> _showRestockDialog(Map<String, dynamic> item) async {
    final result = await RestockCartDialog.show(context, item: item);
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item['itemName']} restocked successfully')),
      );
    }
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Inventory Carts Monitoring',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Monitor and restock supply quantities in nurse station carts across all departments',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Search Bar
          CardContainer(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by item name or category...',
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

          // Stats Cards
          isSmallScreen
              ? Column(
                  children: [
                    _buildStatCard('Total Carts', _totalCarts.toString(), Icons.shopping_cart_outlined, const Color(0xFFEBF5FF), const Color(0xFF3B82F6)),
                    const SizedBox(height: 12),
                    _buildStatCard('Unique Items', _uniqueItems.toString(), Icons.inventory_2_outlined, const Color(0xFFE6F7ED), const Color(0xFF22C55E)),
                    const SizedBox(height: 12),
                    _buildStatCard('Active Carts', _activeCarts.toString(), Icons.inventory_outlined, const Color(0xFFFEF9E7), const Color(0xFFF59E0B)),
                    const SizedBox(height: 12),
                    _buildStatCard('Total Batches', _totalBatches.toString(), Icons.layers_outlined, const Color(0xFFF3E8FF), const Color(0xFFA855F7)),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildStatCard('Total Carts', _totalCarts.toString(), Icons.shopping_cart_outlined, const Color(0xFFEBF5FF), const Color(0xFF3B82F6))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard('Unique Items', _uniqueItems.toString(), Icons.inventory_2_outlined, const Color(0xFFE6F7ED), const Color(0xFF22C55E))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard('Active Carts', _activeCarts.toString(), Icons.inventory_outlined, const Color(0xFFFEF9E7), const Color(0xFFF59E0B))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard('Total Batches', _totalBatches.toString(), Icons.layers_outlined, const Color(0xFFF3E8FF), const Color(0xFFA855F7))),
                  ],
                ),
          const SizedBox(height: 24),

          // Inventory Carts Table
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
                      _buildTableHeader('ITEM NAME', flex: 3),
                      _buildTableHeader('UNIT', flex: 1),
                      _buildTableHeader('CATEGORY', flex: 2),
                      _buildTableHeader('TOTAL QTY', flex: 1),
                      _buildTableHeader('BATCHES', flex: 1),
                      _buildTableHeader('STATUS', flex: 1),
                      _buildTableHeader('ACTIONS', flex: 2),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Table Body
                ..._filteredItems.map((item) {
                  final statusColors = _getStatusColors(item['status']);
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
                          flex: 3,
                          child: Text(
                            item['itemName'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            item['unit'],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            item['category'],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            item['totalQty'].toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${item['batches']} batches',
                              style: const TextStyle(
                                color: Color(0xFFA855F7),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColors.$1,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item['status'],
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
                          child: ElevatedButton.icon(
                            onPressed: () => _showRestockDialog(item),
                            icon: const Icon(Icons.add_circle_outline, size: 16),
                            label: const Text('Restock'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22C55E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                if (_filteredItems.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(40),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No items found',
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
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
