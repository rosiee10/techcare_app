import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/card_container.dart';
import '../../../../core/reusable_widgets/section_header.dart';
import '../widgets/inventory/add_item_dialog.dart';
import '../widgets/inventory/edit_item_dialog.dart';
import '../widgets/inventory/stock_card_request_dialog.dart';
import '../widgets/inventory/item_details_dialog.dart';

/// Inventory Management Page for CSD Clerk
class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  // Sample data - replace with actual API calls
  final List<Map<String, dynamic>> _inventoryItems = [
    {
      'id': 1,
      'itemName': 'Surgical Gloves (Large)',
      'unit': 'box',
      'category': 'Medical Supplies',
      'quantity': 50,
      'expiryDate': '2026-04-15',
      'status': 'Low Stock',
    },
    {
      'id': 2,
      'itemName': 'Disposable Syringes',
      'unit': 'pcs',
      'category': 'Medical Supplies',
      'quantity': 120,
      'expiryDate': '2027-01-20',
      'status': 'Normal',
    },
    {
      'id': 3,
      'itemName': 'Gauze Pads',
      'unit': 'pack',
      'category': 'Medical Supplies',
      'quantity': 75,
      'expiryDate': '2026-03-10',
      'status': 'Near Expiry',
    },
    {
      'id': 4,
      'itemName': 'Alcohol Swabs',
      'unit': 'box',
      'category': 'Medical Supplies',
      'quantity': 200,
      'expiryDate': '2026-08-15',
      'status': 'Normal',
    },
    {
      'id': 5,
      'itemName': 'Bandage Rolls',
      'unit': 'pcs',
      'category': 'Medical Supplies',
      'quantity': 30,
      'expiryDate': '2025-12-20',
      'status': 'Low Stock',
    },
    {
      'id': 6,
      'itemName': 'Cotton Balls',
      'unit': 'pack',
      'category': 'Medical Supplies',
      'quantity': 45,
      'expiryDate': '2026-02-28',
      'status': 'Normal',
    },
  ];

  List<Map<String, dynamic>> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(_inventoryItems);
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
      _filteredItems = _inventoryItems.where((item) {
        final matchesSearch = query.isEmpty ||
            item['itemName'].toString().toLowerCase().contains(query) ||
            item['category'].toString().toLowerCase().contains(query) ||
            item['unit'].toString().toLowerCase().contains(query);

        final matchesFilter = _selectedFilter == 'All' ||
            (_selectedFilter == 'Low Stock' && item['status'] == 'Low Stock') ||
            (_selectedFilter == 'Normal' && item['status'] == 'Normal') ||
            (_selectedFilter == 'Near Expiry' && item['status'] == 'Near Expiry') ||
            (_selectedFilter == 'Expired' && item['status'] == 'Expired');

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void _onFilterChanged(String? value) {
    if (value != null) {
      setState(() {
        _selectedFilter = value;
      });
      _filterItems();
    }
  }

  // Stats calculations
  int get _totalItems => _inventoryItems.length;
  int get _normalStock => _inventoryItems.where((item) => item['status'] == 'Normal').length;
  int get _lowStock => _inventoryItems.where((item) => item['status'] == 'Low Stock').length;
  int get _expiryAlert => _inventoryItems.where((item) => item['status'] == 'Near Expiry' || item['status'] == 'Expired').length;

  (Color, Color) _getStatusColors(String status) {
    switch (status) {
      case 'Low Stock':
        return (const Color(0xFFFFF8E1), const Color(0xFFFF8F00));
      case 'Near Expiry':
        return (const Color(0xFFFFEBEE), const Color(0xFFD32F2F));
      case 'Expired':
        return (const Color(0xFFEFEBE9), const Color(0xFF5D4037));
      default:
        return (const Color(0xFFE8F5E9), const Color(0xFF388E3C));
    }
  }

  Future<void> _showAddItemDialog() async {
    final result = await AddItemDialog.show(context);
    if (result == true) {
      // Refresh data after adding
      setState(() {});
    }
  }

  Future<void> _showEditItemDialog(Map<String, dynamic> item) async {
    final result = await EditItemDialog.show(context, item: item);
    if (result == true) {
      // Refresh data after editing
      setState(() {});
    }
  }

  Future<void> _showItemDetailsDialog(Map<String, dynamic> item) async {
    await ItemDetailsDialog.show(context, item: item);
  }

  Future<void> _showStockCardRequestDialog() async {
    final result = await StockCardRequestDialog.show(context);
    if (result == true) {
      // Handle dispense action
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock request submitted successfully')),
      );
    }
  }

  void _deleteItem(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item['itemName']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _inventoryItems.removeWhere((i) => i['id'] == item['id']);
                _filterItems();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${item['itemName']} deleted successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
          // Header with title and add button
          isSmallScreen
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Inventory Management',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage central supply inventory',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showAddItemDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Item'),
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
                          'Inventory Management',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage central supply inventory',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddItemDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Item'),
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
                    _buildStatCard('Total Items', _totalItems.toString(), Icons.inventory_2_outlined, const Color(0xFFEBF5FF), const Color(0xFF3B82F6)),
                    const SizedBox(height: 12),
                    _buildStatCard('Normal Stock', _normalStock.toString(), Icons.check_circle_outline, const Color(0xFFE6F7ED), const Color(0xFF22C55E)),
                    const SizedBox(height: 12),
                    _buildStatCard('Low Stock', _lowStock.toString(), Icons.warning_amber_outlined, const Color(0xFFFEF9E7), const Color(0xFFF59E0B)),
                    const SizedBox(height: 12),
                    _buildStatCard('Expiry Alert', _expiryAlert.toString(), Icons.error_outline, const Color(0xFFFEE2E2), const Color(0xFFEF4444)),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildStatCard('Total Items', _totalItems.toString(), Icons.inventory_2_outlined, const Color(0xFFEBF5FF), const Color(0xFF3B82F6))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard('Normal Stock', _normalStock.toString(), Icons.check_circle_outline, const Color(0xFFE6F7ED), const Color(0xFF22C55E))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard('Low Stock', _lowStock.toString(), Icons.warning_amber_outlined, const Color(0xFFFEF9E7), const Color(0xFFF59E0B))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard('Expiry Alert', _expiryAlert.toString(), Icons.error_outline, const Color(0xFFFEE2E2), const Color(0xFFEF4444))),
                  ],
                ),
          const SizedBox(height: 24),

          // Search and Filter
          CardContainer(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search items...',
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
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.tune, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFilter,
                      onChanged: _onFilterChanged,
                      items: ['All', 'Normal', 'Low Stock', 'Near Expiry', 'Expired']
                          .map((filter) => DropdownMenuItem(
                                value: filter,
                                child: Text(filter),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Inventory Table
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
                      _buildTableHeader('QUANTITY', flex: 1),
                      _buildTableHeader('EXPIRY DATE', flex: 2),
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
                            item['quantity'].toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            item['expiryDate'],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
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
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => _showStockCardRequestDialog(),
                                icon: const Icon(Icons.verified_outlined, color: Color(0xFF22C55E), size: 20),
                                tooltip: 'Dispense',
                              ),
                              IconButton(
                                onPressed: () => _showEditItemDialog(item),
                                icon: const Icon(Icons.edit_outlined, color: Color(0xFF3B82F6), size: 20),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                onPressed: () => _deleteItem(item),
                                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                                tooltip: 'Delete',
                              ),
                            ],
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
                        Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[400]),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
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
