import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/card_container.dart';
import '../services/inventory_cart_service.dart';
import '../services/pharmacy_service.dart';
import '../widgets/inventory_carts/restock_cart_dialog.dart';
import '../widgets/inventory/medicine_details_dialog.dart';

/// Inventory Carts Monitoring Page
/// Monitor and restock medicine quantities in patient carts for after-hours dispensing
class InventoryCartsPage extends StatefulWidget {
  const InventoryCartsPage({super.key});

  @override
  State<InventoryCartsPage> createState() => _InventoryCartsPageState();
}

class _InventoryCartsPageState extends State<InventoryCartsPage> {
  final TextEditingController _searchController = TextEditingController();
  final InventoryCartService _cartService = InventoryCartService();

  // Filter values
  String _selectedCategory = 'All Categories';
  String _selectedStatus = 'All Status';

  // Dynamic data
  bool _isLoading = false; // Default to false to prevent initial spinner
  List<Map<String, dynamic>> _cartItems = [];
  List<Map<String, dynamic>> _filteredCartItems = [];
  String _errorMessage = '';
  // Store raw cart batches grouped by medicine_id for dialog display
  Map<int, List<Map<String, dynamic>>> _cartBatchesByMedicine = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Initial fetch in background to avoid spin refresh on first load
    _loadCart(showLoading: false);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterCartItems();
  }

  void _filterCartItems() {
    final query = _searchController.text.toLowerCase().trim();
    
    setState(() {
      _filteredCartItems = _cartItems.where((item) {
        // Search query filter
        final medicineName = (item['medicine_name'] ?? '').toString().toLowerCase();
        final category = (item['category'] ?? '').toString().toLowerCase();
        final unit = (item['unit'] ?? '').toString().toLowerCase();
        
        final matchesQuery = query.isEmpty || 
            medicineName.contains(query) ||
            category.contains(query) ||
            unit.contains(query);
        
        // Category filter
        final itemCategory = (item['category'] ?? '').toString();
        final matchesCategory = _selectedCategory == 'All Categories' ||
            itemCategory == _selectedCategory;
        
        // Status filter
        final status = (item['status'] ?? 'In Cart').toString();
        final matchesStatus = _selectedStatus == 'All Status' ||
            (_selectedStatus == 'In Cart' && status == 'In Cart') ||
            (_selectedStatus == 'Low Stock' && status == 'Low Stock') ||
            (_selectedStatus == 'Restocked' && status == 'Restocked');
        
        return matchesQuery && matchesCategory && matchesStatus;
      }).toList();
    });
  }

  Future<void> _loadCart({bool showLoading = true}) async {
    try {
      if (showLoading) {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
        });
      }

      // Fetch from backend API - get cart location (location_id=2) inventory AND medicines list
      final pharmacyService = PharmacyService();
      final cartBalances = await pharmacyService.getInventoryBalancesByLocation(2); // Cart location
      final medicines = await pharmacyService.getMedicines();
      
      // Create medicine lookup map by ID for quick access to unit/category
      final medicineMap = <int, Map<String, dynamic>>{};
      for (final med in medicines) {
        final medId = med['medicine_id'] ?? med['id'];
        if (medId != null) {
          medicineMap[medId] = med;
        }
      }
      
      // Convert backend data to cart items format - ONLY for Cart location (location_id=2)
      // Group by medicine_id to prevent duplicates, sum quantities across batches
      final Map<int, Map<String, dynamic>> medicineGroups = {};
      // Store raw batch details by medicine_id for dialog display
      final Map<int, List<Map<String, dynamic>>> batchesByMedicine = {};
      
      for (final balance in cartBalances) {
        // Parse qty_on_hand which may be String or num from API
        final rawQty = balance['qty_on_hand'] ?? 0;
        final qty = rawQty is num ? rawQty.toDouble() : (double.tryParse(rawQty.toString()) ?? 0.0);
        
        // Get location - could be 'location' or 'location_id'
        final locationId = balance['location'] ?? balance['location_id'] ?? 0;
        
        // Get medicine details from lookup
        final medicineId = balance['medicine'] ?? 0;
        final medicineDetails = medicineMap[medicineId];
        
        // Only include items:
        // 1. Quantity > 0
        // 2. Location is Cart (location_id == 2)
        if (qty > 0 && locationId == 2) {
          // Store raw batch details with all fields needed for dialog
          final batchDetail = {
            'batch_no': balance['batch_no'] ?? 'N/A',
            'quantity': qty,
            'expiry_date': balance['expiry_date'],
            'received_date': balance['received_date'],
            'unit_cost': balance['unit_cost'] ?? 0,
            'batch_id': balance['batch'],
          };
          
          if (batchesByMedicine.containsKey(medicineId)) {
            batchesByMedicine[medicineId]!.add(batchDetail);
          } else {
            batchesByMedicine[medicineId] = [batchDetail];
          }
          
          if (medicineGroups.containsKey(medicineId)) {
            // Add quantity to existing medicine group
            medicineGroups[medicineId]!['quantity'] += qty;
            medicineGroups[medicineId]!['batch_count'] += 1;
          } else {
            // Create new medicine group
            medicineGroups[medicineId] = {
              'medicine_id': medicineId,
              'medicine_name': balance['medicine_name'] ?? medicineDetails?['generic_name'] ?? medicineDetails?['medicine_name'] ?? 'Unknown',
              'category': medicineDetails?['category'] ?? 'Uncategorized',
              'unit': medicineDetails?['unit_of_measure'] ?? medicineDetails?['unit'] ?? 'N/A',
              'quantity': qty,
              'batch_count': 1,
              'status': 'In Cart',
              'added_at': DateTime.now().toIso8601String(),
            };
          }
        }
      }
      
      // Convert grouped map to list
      final List<Map<String, dynamic>> backendCartItems = medicineGroups.values.toList();

      setState(() {
        _cartItems = backendCartItems;
        _filteredCartItems = List.from(backendCartItems);
        _cartBatchesByMedicine = batchesByMedicine;
        _isLoading = false;
      });
      
      // Sync with local storage
      await _cartService.init();
      await _cartService.syncWithBackend(backendCartItems);
      
      // Apply any existing search filter
      if (_searchController.text.isNotEmpty) {
        _filterCartItems();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load cart: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFromCart(int medicineId) async {
    // Get the medicine name from current items
    final item = _cartItems.firstWhere((i) => i['medicine_id'] == medicineId, orElse: () => {});
    final medicineName = item['medicine_name'] ?? 'Unknown';

    final String? reason = await showDialog<String>(
      context: context,
      builder: (context) {
        String selectedReason = 'Damaged';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Remove from Cart & Database: $medicineName', 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('This will remove the medicine from the CART and PERMANENTLY from the database. This action cannot be undone.',
                    style: TextStyle(color: Colors.red, fontSize: 13)),
                  const SizedBox(height: 20),
                  const Text('Please select a reason for removal:', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedReason,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'Damaged', child: Text('Damaged')),
                          DropdownMenuItem(value: 'Expired', child: Text('Expired')),
                          DropdownMenuItem(value: 'Disposed', child: Text('Disposed')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedReason = val);
                        },
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
                  onPressed: () => Navigator.pop(context, selectedReason),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), foregroundColor: Colors.white),
                  child: const Text('Remove'),
                ),
              ],
            );
          },
        );
      },
    );

    if (reason != null) {
      try {
        final result = await _cartService.removeFromCart(medicineId, reason: reason);
        if (result['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$medicineName removed successfully')),
            );
            await _loadCart();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${result['message']}'), backgroundColor: Colors.red),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error removing from cart: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // Calculate total medicines in cart (items with quantity > 0)
  int get _totalMedicinesCount => _cartItems.where((item) {
    final qty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
    return qty > 0;
  }).length;

  // Calculate low stock items (quantity < 10)
  int get _lowStockCount {
    return _cartItems.where((item) {
      final qty = item['quantity'] ?? 0;
      final qtyInt = qty is int ? qty : (qty is double ? qty.toInt() : int.tryParse(qty.toString()) ?? 0);
      return qtyInt > 0 && qtyInt < 10; // Has stock but low
    }).length;
  }

  // Calculate items expiring soon (within 30 days)
  int get _expiringSoonCount {
    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(const Duration(days: 30));
    
    return _cartItems.where((item) {
      final qty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
      if (qty <= 0) return false; // Skip empty items
      
      // Check expiry date if available
      final expiryDateStr = item['expiry_date'] ?? item['batch_expiry'];
      if (expiryDateStr == null) return false;
      
      try {
        final expiryDate = DateTime.parse(expiryDateStr.toString());
        return expiryDate.isAfter(now) && expiryDate.isBefore(thirtyDaysFromNow);
      } catch (e) {
        return false;
      }
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
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
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Monitor and restock medicine quantities in patient carts for after-hours dispensing',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stat Cards Row - 4 Cards: Total Medicines, Low Stock, Expiring Soon, Today Dispensed
          Row(
            children: [
              // Total Medicines in Cart
              Expanded(
                child: _buildStatCard(
                  title: 'Total Medicines',
                  value: _isLoading ? '-' : _totalMedicinesCount.toString(),
                  icon: Icons.medication_outlined,
                  iconBgColor: const Color(0xFFE3F2FD),
                  iconColor: const Color(0xFF2196F3),
                ),
              ),
              const SizedBox(width: 16),
              // Low Stock (quantity < 10)
              Expanded(
                child: _buildStatCard(
                  title: 'Low Stock',
                  value: _isLoading ? '-' : _lowStockCount.toString(),
                  icon: Icons.warning_amber_outlined,
                  iconBgColor: const Color(0xFFFFF3E0),
                  iconColor: const Color(0xFFFF9800),
                ),
              ),
              const SizedBox(width: 16),
              // Expiring Soon (within 30 days)
              Expanded(
                child: _buildStatCard(
                  title: 'Expiring Soon',
                  value: _isLoading ? '-' : _expiringSoonCount.toString(),
                  icon: Icons.access_time_outlined,
                  iconBgColor: const Color(0xFFFFF9C4),
                  iconColor: const Color(0xFFFFC107),
                ),
              ),
              const SizedBox(width: 16),
              // Today Dispensed
              Expanded(
                child: _buildStatCard(
                  title: 'Today Dispensed',
                  value: _isLoading ? '-' : '0',
                  icon: Icons.local_hospital_outlined,
                  iconBgColor: const Color(0xFFF3E5F5),
                  iconColor: const Color(0xFF7B1FA2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Search Bar with Filters
          CardContainer(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by medicine name or category...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Category Dropdown
                SizedBox(
                  width: 140,
                  child: _buildDropdown(
                    value: _selectedCategory,
                    items: const ['All Categories', 'Analgesics', 'Antibiotic', 'Vitamins', 'Supplements'],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                        _filterCartItems();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Status Dropdown
                SizedBox(
                  width: 120,
                  child: _buildDropdown(
                    value: _selectedStatus,
                    items: const ['All Status', 'In Cart', 'Low Stock', 'Restocked'],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                        _filterCartItems();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Data Table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2196F3),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Row(
                    children: [
                      _buildTableHeader('MEDICINE', flex: 2, align: TextAlign.left),
                      _buildTableHeader('UNIT', flex: 1),
                      _buildTableHeader('CATEGORY', flex: 2),
                      _buildTableHeader('QTY', flex: 1),
                      _buildTableHeader('BATCHES', flex: 1),
                      _buildTableHeader('STATUS', flex: 1),
                      _buildTableHeader('ACTIONS', flex: 2),
                    ],
                  ),
                ),
                // Table Rows - Dynamic
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_errorMessage.isNotEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[400], size: 48),
                          const SizedBox(height: 16),
                          Text(_errorMessage, style: TextStyle(color: Colors.red[600])),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadCart,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_filteredCartItems.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(_searchController.text.isEmpty ? Icons.shopping_cart_outlined : Icons.search_off, color: Colors.grey[400], size: 48),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty
                              ? 'Cart is empty'
                              : 'No cart items found matching "${_searchController.text}"',
                            style: TextStyle(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                          if (_searchController.text.isEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Go to Inventory and click "Add to Cart" to move medicines here',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[500], fontSize: 13),
                            ),
                          ],
                          if (_searchController.text.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _selectedCategory = 'All Categories';
                                  _selectedStatus = 'All Status';
                                });
                                _filterCartItems();
                              },
                              child: const Text('Clear Search'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else
                  ..._filteredCartItems.asMap().entries.map((entry) {
                    final item = entry.value;
                    final medicineId = item['medicine_id'] ?? 0;
                    final quantity = (item['quantity'] as num?)?.toDouble() ?? 0.0;
                    final status = quantity < 10 ? 'Low Stock' : 'In Cart';
                    final statusColor = quantity < 10 ? const Color(0xFFFFF3E0) : const Color(0xFFE3F2FD);
                    final statusTextColor = quantity < 10 ? const Color(0xFFEF6C00) : const Color(0xFF1976D2);

                    return _buildCartItemRow(
                      medicine: item['medicine_name'] ?? 'Unknown',
                      unit: item['unit'] ?? 'N/A',
                      category: item['category'] ?? 'Uncategorized',
                      quantity: quantity.toString(),
                      addedAt: item['added_at'] ?? '',
                      status: status,
                      statusColor: statusColor,
                      statusTextColor: statusTextColor,
                      onRemove: () => _removeFromCart(medicineId),
                      medicineId: medicineId,
                      batchCount: item['batch_count'] ?? 1,
                    );
                  }),
              ],
            ),
          ),
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
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
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

  Widget _buildTableHeader(String text, {required int flex, TextAlign align = TextAlign.center}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCartItemRow({
    required String medicine,
    required String unit,
    required String category,
    required String quantity,
    required String addedAt,
    required String status,
    required Color statusColor,
    required Color statusTextColor,
    required VoidCallback onRemove,
    required int medicineId,
    required int batchCount,
  }) {
    return InkWell(
      onTap: () async {
        // Get batches for this medicine from cart items
        final medicineData = {
          'medicine_name': medicine,
          'category': category,
          'price': '₱0.00', // Cart doesn't have price data
          'total_quantity': quantity,
          'unit': unit,
          'status': status == 'In Cart' ? 'OK' : status,
        };

        // Get cart batches for this medicine from stored batch data
        final rawBatches = _cartBatchesByMedicine[medicineId] ?? [];
        final cartBatches = rawBatches.map((batch) {
          return {
            'batch_no': batch['batch_no'] ?? 'N/A',
            'quantity': batch['quantity'] ?? 0,
            'expiry_date': batch['expiry_date'] ?? '',
            'received_date': batch['received_date'] ?? '',
            'created_at': '',
          };
        }).toList();

        final result = await MedicineDetailsDialog.show(context, medicine: medicineData, batches: cartBatches);
        if (result == true) {
          _loadCart();
        }
      },
      hoverColor: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
          // Medicine name
          Expanded(
            flex: 2,
            child: Text(
              medicine,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          // Unit
          Expanded(
            flex: 1,
            child: Text(
              unit,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ),
          // Category
          Expanded(
            flex: 2,
            child: Text(
              category,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ),
          // Quantity
          Expanded(
            flex: 1,
            child: Text(
              quantity,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          // Batches
          Expanded(
            flex: 1,
            child: Center(
              child: IntrinsicWidth(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$batchCount ${batchCount == 1 ? 'batch' : 'batches'}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
          // Status
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: status == 'In Cart' ? const Color(0xFFE8F5E9) : statusColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status == 'In Cart' ? 'OK' : status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: status == 'In Cart' ? const Color(0xFF2E7D32) : statusTextColor,
                ),
              ),
            ),
          ),
          // Actions
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Restock Button
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: IconButton(
                    onPressed: () async {
                      final medicineData = {
                        'id': medicineId,
                        'medicine_id': medicineId,
                        'name': medicine,
                        'currentTotal': int.tryParse(quantity) ?? 0,
                      };
                      final result = await RestockCartDialog.show(context, medicine: medicineData);
                      // Background refresh (no spinner)
                      await _loadCart(showLoading: false);
                    },
                    icon: const Icon(Icons.shopping_cart_outlined, size: 18, color: Color(0xFF2196F3)),
                    tooltip: 'Restock',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ),
                // Delete Icon
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFE53935)),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'Remove from cart',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[800],
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
