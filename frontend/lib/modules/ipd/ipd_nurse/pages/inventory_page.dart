import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/card_container.dart';
import '../services/ipd_inventory_service.dart';

/// Inventory Page for IPD Nurse with Pharmacy and Central Supply tabs
class IpdNurseInventoryPage extends StatefulWidget {
  const IpdNurseInventoryPage({super.key});

  @override
  State<IpdNurseInventoryPage> createState() => _IpdNurseInventoryPageState();
}

class _IpdNurseInventoryPageState extends State<IpdNurseInventoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final IpdInventoryService _inventoryService = IpdInventoryService();
  
  String _selectedPharmacyFilter = 'All';
  String _selectedCsdFilter = 'All';
  final TextEditingController _pharmacySearchController =
      TextEditingController();
  final TextEditingController _csdSearchController = TextEditingController();
  Timer? _pharmacySearchDebounce;

  List<Map<String, dynamic>> _pharmacyItems = [];
  bool _isLoadingPharmacy = false;
  Map<String, int> _pharmacyStats = {
    'total': 0,
    'normal': 0,
    'low': 0,
    'expiry': 0,
  };

  // Central Supply (CSD) sample data (Keep for now or implement CSD backend later)
  final List<Map<String, dynamic>> _csdItems = [
    {
      'id': 1,
      'itemName': 'Surgical Gloves (Large)',
      'unit': 'box',
      'category': 'Medical Supplies',
      'quantity': 50,
      'expiryDate': '2026-04-15',
      'status': 'Low Stock',
    },
    // ... other CSD items
  ];

  List<Map<String, dynamic>> _filteredPharmacyItems = [];
  List<Map<String, dynamic>> _filteredCsdItems = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPharmacyInventory();
    _filteredCsdItems = List.from(_csdItems);
    _csdSearchController.addListener(_onCsdSearchChanged);
  }

  Future<void> _loadPharmacyInventory() async {
    setState(() => _isLoadingPharmacy = true);
    try {
      final response = await _inventoryService.getInventory();

      if (response['success'] == true) {
        final List<dynamic> items = response['inventory'];
        setState(() {
          _pharmacyItems = items.map((item) => {
            'id': item['medicine_id'],
            'itemName': item['medicine_name'],
            'unit': item['unit'],
            'category': item['category'],
            'quantity': item['quantity'],
            'expiryDate': item['expiry_date'],
            'status': item['status'],
          }).toList();

          _pharmacyStats = {
            'total': response['total_items'] ?? 0,
            'normal': response['normal_stock'] ?? 0,
            'low': response['low_stock'] ?? 0,
            'expiry': response['expiry_alert'] ?? 0,
          };
        });
        _applyPharmacyFilters();
      }
    } catch (e) {
      debugPrint('Error loading pharmacy inventory: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading inventory: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingPharmacy = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pharmacySearchDebounce?.cancel();
    _csdSearchController.removeListener(_onCsdSearchChanged);
    _pharmacySearchController.dispose();
    _csdSearchController.dispose();
    super.dispose();
  }

  void _onPharmacySearchChanged() {
    _pharmacySearchDebounce?.cancel();
    _pharmacySearchDebounce = Timer(const Duration(milliseconds: 400), () {
      _applyPharmacyFilters();
    });
  }
  
  void _onCsdSearchChanged() => _filterCsdItems();

  void _applyPharmacyFilters() {
    final query = _pharmacySearchController.text.toLowerCase().trim();
    setState(() {
      _filteredPharmacyItems = _pharmacyItems.where((item) {
        final matchesSearch = query.isEmpty ||
            item['itemName'].toString().toLowerCase().contains(query) ||
            item['category'].toString().toLowerCase().contains(query);
        final matchesFilter = _selectedPharmacyFilter == 'All' ||
            (_selectedPharmacyFilter == 'Low Stock' &&
                item['status'] == 'Low Stock') ||
            (_selectedPharmacyFilter == 'Normal' && item['status'] == 'Normal') ||
            (_selectedPharmacyFilter == 'Near Expiry' &&
                item['status'] == 'Near Expiry') ||
            (_selectedPharmacyFilter == 'Expired' && item['status'] == 'Expired');
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void _filterCsdItems() {
    final query = _csdSearchController.text.toLowerCase().trim();
    setState(() {
      _filteredCsdItems = _csdItems.where((item) {
        final matchesSearch = query.isEmpty ||
            item['itemName'].toString().toLowerCase().contains(query) ||
            item['category'].toString().toLowerCase().contains(query);
        final matchesFilter = _selectedCsdFilter == 'All' ||
            (_selectedCsdFilter == 'Low Stock' &&
                item['status'] == 'Low Stock') ||
            (_selectedCsdFilter == 'Normal' && item['status'] == 'Normal') ||
            (_selectedCsdFilter == 'Near Expiry' &&
                item['status'] == 'Near Expiry') ||
            (_selectedCsdFilter == 'Expired' && item['status'] == 'Expired');
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void _onPharmacyFilterChanged(String? value) {
    if (value != null) {
      setState(() => _selectedPharmacyFilter = value);
      _applyPharmacyFilters();
    }
  }

  void _onCsdFilterChanged(String? value) {
    if (value != null) {
      setState(() => _selectedCsdFilter = value);
      _filterCsdItems();
    }
  }

  (Color, Color) _getStatusColors(String status) {
    switch (status) {
      case 'Low Stock':
        return (const Color(0xFFFFF8E1), const Color(0xFFFF8F00));
      case 'Near Expiry':
      case 'Expiry Alert':
        return (const Color(0xFFFFEBEE), const Color(0xFFD32F2F));
      case 'Expired':
        return (const Color(0xFFEFEBE9), const Color(0xFF5D4037));
      default:
        return (const Color(0xFFE8F5E9), const Color(0xFF388E3C));
    }
  }

  // Stats calculations - Not needed anymore as stats come from API
  // but keeping signature for build method consistency
  Map<String, int> _getPharmacyStats() => _pharmacyStats;

  Map<String, int> _getCsdStats() => {
    'total': _csdItems.length,
    'normal': _csdItems.where((i) => i['status'] == 'Normal').length,
    'low': _csdItems.where((i) => i['status'] == 'Low Stock').length,
    'expiry': _csdItems
        .where((i) =>
            i['status'] == 'Near Expiry' || i['status'] == 'Expired')
        .length,
  };

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 768;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and tabs inline
          isSmallScreen
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Inventory',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View pharmacy and central supply inventory',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Compact Pill-style Tabs
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        indicator: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: const Color(0xFF64748B),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        tabAlignment: TabAlignment.start,
                        labelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 20),
                        tabs: const [
                          Tab(
                            height: 36,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.local_pharmacy_outlined, size: 16),
                                SizedBox(width: 6),
                                Text('Pharmacy'),
                              ],
                            ),
                          ),
                          Tab(
                            height: 36,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 16),
                                SizedBox(width: 6),
                                Text('Central Supply'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left: Title
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Inventory',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'View pharmacy and central supply inventory',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    // Right: Compact Pill-style Tabs
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        indicator: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: const Color(0xFF64748B),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        tabAlignment: TabAlignment.start,
                        labelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 20),
                        tabs: const [
                          Tab(
                            height: 36,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.local_pharmacy_outlined, size: 16),
                                SizedBox(width: 6),
                                Text('Pharmacy'),
                              ],
                            ),
                          ),
                          Tab(
                            height: 36,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 16),
                                SizedBox(width: 6),
                                Text('Central Supply'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 32),

          // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _isLoadingPharmacy 
                ? const Center(child: CircularProgressIndicator())
                : _buildInventoryTab(
                    isSmallScreen: isSmallScreen,
                    items: _filteredPharmacyItems,
                    stats: _getPharmacyStats(),
                    searchController: _pharmacySearchController,
                    selectedFilter: _selectedPharmacyFilter,
                    onFilterChanged: _onPharmacyFilterChanged,
                    onRequestItem: (item) => _showRequestDialog(item, 'Pharmacy'),
                  ),
              _buildInventoryTab(
                isSmallScreen: isSmallScreen,
                items: _filteredCsdItems,
                stats: _getCsdStats(),
                searchController: _csdSearchController,
                selectedFilter: _selectedCsdFilter,
                onFilterChanged: _onCsdFilterChanged,
                onRequestItem: (item) => _showRequestDialog(item, 'CSD'),
              ),
            ],
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildInventoryTab({
    required bool isSmallScreen,
    required List<Map<String, dynamic>> items,
    required Map<String, int> stats,
    required TextEditingController searchController,
    required String selectedFilter,
    required Function(String?) onFilterChanged,
    required Function(Map<String, dynamic>) onRequestItem,
  }) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards
          isSmallScreen
              ? Column(
                  children: [
                    _buildStatCard('Total Items', stats['total'].toString(),
                        Icons.inventory_2_outlined, const Color(0xFFEBF5FF),
                        const Color(0xFF3B82F6)),
                    const SizedBox(height: 12),
                    _buildStatCard(
                        'Normal Stock',
                        stats['normal'].toString(),
                        Icons.check_circle_outline,
                        const Color(0xFFE6F7ED),
                        const Color(0xFF22C55E)),
                    const SizedBox(height: 12),
                    _buildStatCard('Low Stock', stats['low'].toString(),
                        Icons.warning_amber_outlined, const Color(0xFFFEF9E7),
                        const Color(0xFFF59E0B)),
                    const SizedBox(height: 12),
                    _buildStatCard('Expiry Alert', stats['expiry'].toString(),
                        Icons.error_outline, const Color(0xFFFEE2E2),
                        const Color(0xFFEF4444)),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                        child: _buildStatCard(
                            'Total Items',
                            stats['total'].toString(),
                            Icons.inventory_2_outlined,
                            const Color(0xFFEBF5FF),
                            const Color(0xFF3B82F6))),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _buildStatCard(
                            'Normal Stock',
                            stats['normal'].toString(),
                            Icons.check_circle_outline,
                            const Color(0xFFE6F7ED),
                            const Color(0xFF22C55E))),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _buildStatCard(
                            'Low Stock',
                            stats['low'].toString(),
                            Icons.warning_amber_outlined,
                            const Color(0xFFFEF9E7),
                            const Color(0xFFF59E0B))),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _buildStatCard(
                            'Expiry Alert',
                            stats['expiry'].toString(),
                            Icons.error_outline,
                            const Color(0xFFFEE2E2),
                            const Color(0xFFEF4444))),
                  ],
                ),
          const SizedBox(height: 24),

          // Search and Filter
          CardContainer(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: (_) {
                      if (searchController == _pharmacySearchController) {
                        _onPharmacySearchChanged();
                      }
                    },
                    onSubmitted: (_) {
                      if (searchController == _pharmacySearchController) {
                        _pharmacySearchDebounce?.cancel();
                        _applyPharmacyFilters();
                      }
                    },
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
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
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
                      value: selectedFilter,
                      onChanged: onFilterChanged,
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
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: isSmallScreen
                      ? Row(
                          children: [
                            _buildTableHeader('ITEM NAME', flex: 3, textColor: Colors.white),
                            _buildTableHeader('QTY', flex: 1, textColor: Colors.white),
                            _buildTableHeader('STATUS', flex: 2, textColor: Colors.white),
                          ],
                        )
                      : Row(
                          children: [
                            _buildTableHeader('ITEM NAME', flex: 3, textColor: Colors.white),
                            _buildTableHeader('UNIT', flex: 1, textColor: Colors.white),
                            _buildTableHeader('CATEGORY', flex: 2, textColor: Colors.white),
                            _buildTableHeader('QUANTITY', flex: 1, textColor: Colors.white),
                            _buildTableHeader('EXPIRY DATE', flex: 2, textColor: Colors.white),
                            _buildTableHeader('STATUS', flex: 1, textColor: Colors.white),
                            _buildTableHeader('ACTIONS', flex: 1, textColor: Colors.white),
                          ],
                        ),
                ),
                const Divider(height: 1),
                // Table Body
                ...items.map((item) {
                  final statusColors = _getStatusColors(item['status']);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: isSmallScreen
                        ? Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['itemName'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item['category']} • ${item['expiryDate']}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
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
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
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
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () => onRequestItem(item),
                                      icon: const Icon(Icons.add_shopping_cart,
                                          color: Color(0xFF2563EB), size: 20),
                                      tooltip: 'Request Item',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Row(
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
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
                                flex: 1,
                                child: IconButton(
                                  onPressed: () => onRequestItem(item),
                                  icon: const Icon(Icons.add_shopping_cart,
                                      color: Color(0xFF2563EB)),
                                  tooltip: 'Request Item',
                                ),
                              ),
                            ],
                          ),
                  );
                }).toList(),
                if (items.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(40),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 48, color: Colors.grey[400]),
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

  void _showRequestDialog(Map<String, dynamic> item, String source) {
    final TextEditingController quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Request $source Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item: ${item['itemName']}'),
            const SizedBox(height: 8),
            Text('Available: ${item['quantity']} ${item['unit']}'),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity to Request',
                hintText: 'Enter quantity',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Request for ${quantityController.text} ${item['unit']} of ${item['itemName']} submitted')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
            ),
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color bgColor, Color iconColor) {
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

  Widget _buildTableHeader(String title, {int flex = 1, Color? textColor}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor ?? Colors.grey[600],
        ),
      ),
    );
  }
}
