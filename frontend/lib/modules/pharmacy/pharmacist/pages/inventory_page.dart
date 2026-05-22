import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../../../core/reusable_widgets/card_container.dart';

import '../../../../core/reusable_widgets/section_header.dart';

import '../services/pharmacy_service.dart';

import '../widgets/inventory/add_medicine_dialog.dart';

import '../widgets/inventory/dispense_medicine_dialog.dart';

import '../widgets/inventory/add_batch_dialog.dart';

import '../widgets/inventory/medicine_details_dialog.dart';



/// Medicine Inventory Page with FEFO tracking

class InventoryPage extends StatefulWidget {

  const InventoryPage({super.key});



  @override

  State<InventoryPage> createState() => _InventoryPageState();

}



class _InventoryPageState extends State<InventoryPage> {

  String _selectedCategory = 'All Categories';

  String _selectedStatus = 'All Status';

  final TextEditingController _searchController = TextEditingController();

  final PharmacyService _pharmacyService = PharmacyService();



  // Dynamic data

  bool _isLoading = false; // Default to false to prevent initial spinner

  List<dynamic> _medicines = [];

  List<dynamic> _filteredMedicines = [];

  List<dynamic> _stockBatches = [];

  List<dynamic> _inventoryBalances = [];

  Map<String, dynamic> _dashboardStats = {};

  String _errorMessage = '';



  @override

  void initState() {

    super.initState();

    _searchController.addListener(_onSearchChanged);

    // Initial fetch in background to avoid spin refresh on first load

    _fetchData(showLoading: false);

  }



  @override

  void dispose() {

    _searchController.removeListener(_onSearchChanged);

    _searchController.dispose();

    super.dispose();

  }



  void _onSearchChanged() {

    _filterMedicines();

  }



  void _filterMedicines() {

    final query = _searchController.text.toLowerCase().trim();

    

    setState(() {

      if (query.isEmpty) {

        _filteredMedicines = List.from(_medicines);

      } else {

        _filteredMedicines = _medicines.where((medicine) {

          final medicineName = (medicine['medicine_name'] ?? '').toString().toLowerCase();

          final medicineCode = (medicine['medicine_code'] ?? '').toString().toLowerCase();

          final category = (medicine['category'] ?? '').toString().toLowerCase();

          final unit = (medicine['unit'] ?? '').toString().toLowerCase();

          

          // Also search in batches for this medicine from location_id=1 (Main Pharmacy) only

          final medicineId = medicine['medicine_id'] ?? 0;

          final batches = _inventoryBalances.where((b) => 

            (b['medicine'] == medicineId || b['medicine_id'] == medicineId) &&
            (b['location'] == 1 || b['location_id'] == 1)

          );

          final batchNos = batches.map((b) => (b['batch_no'] ?? '').toString().toLowerCase()).join(' ');

          

          return medicineName.contains(query) ||

                 medicineCode.contains(query) ||

                 category.contains(query) ||

                 unit.contains(query) ||

                 batchNos.contains(query);

        }).toList();

      }

    });

  }



  Future<void> _fetchData({bool showLoading = true}) async {

    try {

      if (showLoading) {

        setState(() {

          _isLoading = true;

          _errorMessage = '';

        });

      }



      // Fetch all data in parallel with proper typing

      final medicines = await _pharmacyService.getMedicines();

      final stockBatches = await _pharmacyService.getStockBatches();

      final inventoryBalances = await _pharmacyService.getInventoryBalances();

      final dashboardStats = await _pharmacyService.getDashboardStats();



      setState(() {

        _medicines = medicines;

        _filteredMedicines = List.from(medicines);

        _stockBatches = stockBatches;

        _inventoryBalances = inventoryBalances;

        _dashboardStats = dashboardStats;

        _isLoading = false;

      });

      

      // Apply any existing search filter

      if (_searchController.text.isNotEmpty) {

        _filterMedicines();

      }

    } catch (e) {

      setState(() {

        _errorMessage = 'Failed to load data: $e';

        _isLoading = false;

      });

    }

  }





  // Calculate batch count for a medicine

  int _getBatchCount(int? medicineId) {

    if (medicineId == null || medicineId == 0) return 0;

    // Count only batches from location_id=1 (Main Pharmacy) for inventory features

    return _inventoryBalances.where((balance) {

      final batchMedId = balance['medicine'] ?? balance['medicine_id'];

      final locationId = balance['location'] ?? balance['location_id'];

      if (batchMedId == null) return false;

      return batchMedId == medicineId && (locationId == 1);

    }).length;

  }



  // Calculate total quantity for a medicine from Main Pharmacy only (location_id=1)

  // Excludes cart inventory (location_id=2) from the total

  double _getTotalQuantity(int? medicineId) {

    if (medicineId == null || medicineId == 0) return 0.0;

    try {

      return _inventoryBalances

          .where((balance) {

            // Match medicine

            final balanceMedId = balance['medicine'] ?? balance['medicine_id'];

            if (balanceMedId != medicineId) return false;

            

            // Only include Main Pharmacy (location_id=1), exclude Cart (location_id=2)

            final locationId = balance['location'] ?? balance['location_id'];

            return locationId == 1;

          })

          .fold(0.0, (sum, balance) {

            final qty = balance['qty_on_hand'];

            if (qty == null) return sum;

            // Handle both string and numeric types from API

            if (qty is String) {

              return sum + (double.tryParse(qty) ?? 0.0);

            }

            return sum + (qty as num).toDouble();

          });

    } catch (e) {

      debugPrint('Error calculating total quantity: $e');

      return 0.0;

    }

  }



  // Get earliest expiry batch unit cost (FEFO - what will be used next for dispensing)

  // Falls back to medicine's unit_cost if no batches exist (for auto-created medicines)

  // Only considers batches from location_id=1 (Main Pharmacy) for inventory features

  double _getEarliestExpiryBatchCost(int? medicineId) {

    if (medicineId == null || medicineId == 0) return 0.0;

    

    try {

      // Get batches from inventory balances sorted by expiry date (earliest first - FEFO)

      // Only from location_id=1 (Main Pharmacy)

      final medicineBatches = _inventoryBalances

          .where((balance) =>

            (balance['medicine'] == medicineId || balance['medicine_id'] == medicineId) &&

            (balance['location'] == 1 || balance['location_id'] == 1)

          )

          .toList();

      

      if (medicineBatches.isNotEmpty) {

        medicineBatches.sort((a, b) => (a['expiry_date'] ?? '').compareTo(b['expiry_date'] ?? ''));

        

        final now = DateTime.now();

        

        // Find first non-expired batch with available quantity

        for (final batch in medicineBatches) {

          final batchId = batch['batch'] ?? batch['batch_id'];

          if (batchId == null) continue;

          

          // Check if batch is not expired

          final expiryDateStr = batch['expiry_date'];

          if (expiryDateStr != null && expiryDateStr.isNotEmpty) {

            final expiryDate = DateTime.tryParse(expiryDateStr);

            if (expiryDate != null && expiryDate.isBefore(now)) {

              continue; // Skip expired batches

            }

          }

          

          final batchQty = _inventoryBalances

              .where((balance) => (balance['batch'] ?? balance['batch_id']) == batchId)

              .fold(0.0, (sum, balance) {

                final qty = balance['qty_on_hand'];

                if (qty == null) return sum;

                if (qty is String) {

                  return sum + (double.tryParse(qty) ?? 0.0);

                }

                return sum + (qty as num).toDouble();

              });

          

          if (batchQty > 0) {

            final unitCost = batch['unit_cost'];

            if (unitCost != null) {

              if (unitCost is String) {

                return double.tryParse(unitCost) ?? 0.0;

              }

              return (unitCost as num).toDouble();

            }

          }

        }

      }

      

      // If no valid batch found, fallback to medicine's unit_cost (for auto-created medicines)

      final medicine = _medicines.firstWhere(

        (m) => (m['medicine_id'] ?? m['id']) == medicineId,

        orElse: () => <String, dynamic>{},

      );

      

      if (medicine.isNotEmpty) {

        final unitCost = medicine['unit_cost'];

        if (unitCost != null) {

          if (unitCost is String) {

            return double.tryParse(unitCost) ?? 0.0;

          }

          return (unitCost as num).toDouble();

        }

      }

    } catch (e) {

      debugPrint('Error calculating earliest expiry cost: $e');

    }

    

    return 0.0;

  }



  // Determine status based on batches from location_id=1 (Main Pharmacy) only

  String _getStatus(int? medicineId) {

    if (medicineId == null || medicineId == 0) return 'Out of Stock';

    final medicineBatches = _inventoryBalances.where((balance) =>

      (balance['medicine'] == medicineId || balance['medicine_id'] == medicineId) &&

      (balance['location'] == 1 || balance['location_id'] == 1)

    ).toList();

    if (medicineBatches.isEmpty) return 'Out of Stock';



    final now = DateTime.now();

    final expiredBatches = medicineBatches.where((batch) {

      final expiryDateStr = batch['expiry_date'];

      if (expiryDateStr == null || expiryDateStr.isEmpty) return false;

      try {

        final expiryDate = DateTime.parse(expiryDateStr);

        return expiryDate.isBefore(now);

      } catch (e) {

        return false;

      }

    }).toList();



    if (expiredBatches.length == medicineBatches.length) return 'Expired';



    final expiringSoonBatches = medicineBatches.where((batch) {

      final expiryDateStr = batch['expiry_date'];

      if (expiryDateStr == null || expiryDateStr.isEmpty) return false;

      try {

        final expiryDate = DateTime.parse(expiryDateStr);

        final daysUntilExpiry = expiryDate.difference(now).inDays;

        return daysUntilExpiry <= 30 && daysUntilExpiry >= 0;

      } catch (e) {

        return false;

      }

    }).toList();



    if (expiringSoonBatches.isNotEmpty) return 'Expiring Soon';



    return 'Active';

  }



  // Get status colors

  (Color, Color) _getStatusColors(String status) {

    switch (status) {

      case 'Expired':

        return (const Color(0xFFFFEBEE), const Color(0xFFC62828));

      case 'Expiring Soon':

        return (const Color(0xFFFFF9C4), const Color(0xFFF57F17));

      case 'Out of Stock':

        return (const Color(0xFFF5F5F5), const Color(0xFF616161));

      default:

        return (const Color(0xFFE8F5E9), const Color(0xFF2E7D32));

    }

  }



  @override

  Widget build(BuildContext context) {

    final screenWidth = MediaQuery.of(context).size.width;

    final isSmallScreen = screenWidth < 768;

    final isMediumScreen = screenWidth >= 768 && screenWidth < 1024;

    

    return SingleChildScrollView(

      padding: EdgeInsets.all(isSmallScreen ? 16 : 32),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          // Header with title and add button - Responsive

          isSmallScreen

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

                              'Medicine Inventory',

                              style: TextStyle(

                                fontSize: 20,

                                fontWeight: FontWeight.bold,

                                color: Colors.black87,

                              ),

                            ),

                            const SizedBox(height: 4),

                            Text(

                              'Multi-batch tracking with FEFO logic',

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

                          final result = await AddMedicineDialog.show(context);

                          if (result == true) {

                            await _fetchData();

                          }

                        },

                        icon: const Icon(Icons.add, size: 18),

                        label: const Text('Add Medicine'),

                        style: ElevatedButton.styleFrom(

                          backgroundColor: const Color(0xFF2563EB),

                          foregroundColor: Colors.white,

                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

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

                        'Medicine Inventory',

                        style: TextStyle(

                          fontSize: 24,

                          fontWeight: FontWeight.bold,

                          color: Colors.black87,

                        ),

                      ),

                      const SizedBox(height: 4),

                      Text(

                        'Multi-batch tracking with FEFO (First Expiry First Out) logic for optimal inventory management',

                        style: TextStyle(

                          fontSize: 14,

                          color: Colors.grey[600],

                        ),

                      ),

                    ],

                  ),

                  ElevatedButton.icon(

                    onPressed: () async {

                      final result = await AddMedicineDialog.show(context);

                      if (result == true) {

                        await _fetchData();

                      }

                    },

                    icon: const Icon(Icons.add, size: 18),

                    label: const Text('Add New Medicine'),

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

          isSmallScreen

            ? Column(

                children: [

                  // First row: 2 cards

                  Row(

                    children: [

                      Expanded(

                        child: _buildStatCard(

                          title: 'Total',

                          value: '${_dashboardStats['total_medicines'] ?? 0}',

                          icon: Icons.medication_outlined,

                          iconBgColor: const Color(0xFFE3F2FD),

                          iconColor: const Color(0xFF2196F3),

                        ),

                      ),

                      const SizedBox(width: 12),

                      Expanded(

                        child: _buildStatCard(

                          title: 'Low Stock',

                          value: '${_dashboardStats['low_stock_count'] ?? 0}',

                          icon: Icons.warning_amber_outlined,

                          iconBgColor: const Color(0xFFFFF3E0),

                          iconColor: const Color(0xFFFF6F00),

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

                          title: 'Expiring',

                          value: '${_dashboardStats['expiring_soon'] ?? 0}',

                          icon: Icons.access_time_outlined,

                          iconBgColor: const Color(0xFFFFFDE7),

                          iconColor: const Color(0xFFFBC02D),

                        ),

                      ),

                      const SizedBox(width: 12),

                      Expanded(

                        child: _buildStatCard(

                          title: 'Today Dispensed',

                          value: '${_dashboardStats['today_dispensed'] ?? 0}',

                          icon: Icons.local_hospital_outlined,

                          iconBgColor: const Color(0xFFF3E5F5),

                          iconColor: const Color(0xFF7B1FA2),

                        ),

                      ),

                    ],

                  ),

                ],

              )

            : Row(

                children: [

                  Expanded(child: _buildStatCard(

                    title: 'Total Medicines',

                    value: '${_dashboardStats['total_medicines'] ?? 0}',

                    icon: Icons.medication_outlined,

                    iconBgColor: const Color(0xFFE3F2FD),

                    iconColor: const Color(0xFF2196F3),

                  )),

                  const SizedBox(width: 16),

                  Expanded(child: _buildStatCard(

                    title: 'Low Stock',

                    value: '${_dashboardStats['low_stock_count'] ?? 0}',

                    icon: Icons.warning_amber_outlined,

                    iconBgColor: const Color(0xFFFFF3E0),

                    iconColor: const Color(0xFFFF6F00),

                  )),

                  const SizedBox(width: 16),

                  Expanded(child: _buildStatCard(

                    title: 'Expiring Soon',

                    value: '${_dashboardStats['expiring_soon'] ?? 0}',

                    icon: Icons.access_time_outlined,

                    iconBgColor: const Color(0xFFFFFDE7),

                    iconColor: const Color(0xFFFBC02D),

                  )),

                  const SizedBox(width: 16),

                  Expanded(child: _buildStatCard(

                    title: 'Today Dispensed',

                    value: '${_dashboardStats['today_dispensed'] ?? 0}',

                    icon: Icons.local_hospital_outlined,

                    iconBgColor: const Color(0xFFF3E5F5),

                    iconColor: const Color(0xFF7B1FA2),

                  )),

                ],

              ),

          const SizedBox(height: 24),



          // Search and Filter Bar - Responsive

          CardContainer(

            child: isSmallScreen

              ? Column(

                  children: [

                    TextField(

                      controller: _searchController,

                      decoration: InputDecoration(

                        hintText: 'Search medicines...',

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

                    const SizedBox(height: 12),

                    Row(

                      children: [

                        Expanded(

                          child: _buildDropdown(

                            value: _selectedCategory,

                            items: const ['All Categories', 'Analgesics', 'Antibiotic', 'Antidiabetic', 'Vitamins'],

                            onChanged: (value) {

                              setState(() {

                                _selectedCategory = value!;

                              });

                            },

                          ),

                        ),

                        const SizedBox(width: 12),

                        Expanded(

                          child: _buildDropdown(

                            value: _selectedStatus,

                            items: const ['All Status', 'Active', 'Expiring Soon', 'Expired', 'Low Stock'],

                            onChanged: (value) {

                              setState(() {

                                _selectedStatus = value!;

                              });

                            },

                          ),

                        ),

                      ],

                    ),

                  ],

                )

              : Row(

                  children: [

                    Expanded(

                      flex: isMediumScreen ? 2 : 3,

                      child: TextField(

                        controller: _searchController,

                        decoration: InputDecoration(

                          hintText: 'Search by medicine name, category, or batch number...',

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

                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

                        ),

                      ),

                    ),

                    const SizedBox(width: 16),

                    Expanded(

                      flex: 1,

                      child: _buildDropdown(

                        value: _selectedCategory,

                        items: const ['All Categories', 'Analgesics', 'Antibiotic', 'Antidiabetic', 'Vitamins'],

                        onChanged: (value) {

                          setState(() {

                            _selectedCategory = value!;

                          });

                        },

                      ),

                    ),

                    const SizedBox(width: 16),

                    Expanded(

                      flex: 1,

                      child: _buildDropdown(

                        value: _selectedStatus,

                        items: const ['All Status', 'Active', 'Expiring Soon', 'Expired', 'Low Stock'],

                        onChanged: (value) {

                          setState(() {

                            _selectedStatus = value!;

                          });

                        },

                      ),

                    ),

                  ],

                ),

          ),

          const SizedBox(height: 24),



          // Data Table - Responsive with horizontal scroll on small screens

          Container(

            decoration: BoxDecoration(

              color: Colors.white,

              borderRadius: BorderRadius.circular(8),

            ),

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                // Scrollable Table for small screens

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

                          Text(

                            _errorMessage,

                            style: TextStyle(color: Colors.red[600]),

                          ),

                          const SizedBox(height: 16),

                          ElevatedButton(

                            onPressed: _fetchData,

                            child: const Text('Retry'),

                          ),

                        ],

                      ),

                    ),

                  )

                else if (_filteredMedicines.isEmpty)

                  Center(

                    child: Padding(

                      padding: const EdgeInsets.all(32),

                      child: Column(

                        children: [

                          Icon(Icons.search_off, color: Colors.grey[400], size: 48),

                          const SizedBox(height: 16),

                          Text(

                            _searchController.text.isEmpty

                              ? 'No medicines found. Add your first medicine!'

                              : 'No medicines found matching "${_searchController.text}"',

                            style: TextStyle(color: Colors.grey[600]),

                            textAlign: TextAlign.center,

                          ),

                          if (_searchController.text.isNotEmpty) ...[

                            const SizedBox(height: 12),

                            TextButton(

                              onPressed: () {

                                _searchController.clear();

                                _filterMedicines();

                              },

                              child: const Text('Clear Search'),

                            ),

                          ],

                        ],

                      ),

                    ),

                  )

                else

                  isSmallScreen

                    ? // Mobile: Card-based Medicine List

                      Column(

                        children: [

                          const SizedBox(height: 8),

                          ..._filteredMedicines.asMap().entries.map((entry) {

                            final medicine = entry.value;

                            final medicineId = medicine['medicine_id'] ?? medicine['id'] ?? 0;

                            final batchCount = _getBatchCount(medicineId);

                            final totalQty = _getTotalQuantity(medicineId);

                            final earliestExpiryCost = _getEarliestExpiryBatchCost(medicineId);

                            final status = _getStatus(medicineId);

                            final (statusColor, statusTextColor) = _getStatusColors(status);



                            return _buildMedicineCard(

                              medicine: medicine['medicine_name'] ?? 'Unknown',

                              unit: medicine['unit'] ?? 'N/A',

                              category: medicine['category'] ?? 'Uncategorized',

                              totalQty: totalQty.toStringAsFixed(0),

                              batches: '$batchCount',

                              price: '₱${earliestExpiryCost.toStringAsFixed(2)}',

                              status: status,

                              statusColor: statusColor,

                              statusTextColor: statusTextColor,

                              medicineId: medicineId,

                            );

                          }).toList(),

                        ],

                      )

                    : Column(

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

                                _buildTableHeader('TOTAL QTY', flex: 1),

                                _buildTableHeader('BATCHES', flex: 1),

                                _buildTableHeader('PRICE', flex: 1),

                                _buildTableHeader('STATUS', flex: 1),

                                _buildTableHeader('ACTIONS', flex: 2),

                              ],

                            ),

                          ),

                          // Table Rows - Dynamic

                          ..._filteredMedicines.asMap().entries.map((entry) {

                            final medicine = entry.value;

                            final medicineId = medicine['medicine_id'] ?? medicine['id'] ?? 0;

                            final batchCount = _getBatchCount(medicineId);

                            final totalQty = _getTotalQuantity(medicineId);

                            final earliestExpiryCost = _getEarliestExpiryBatchCost(medicineId);

                            final status = _getStatus(medicineId);

                            final (statusColor, statusTextColor) = _getStatusColors(status);



                            return Column(

                              children: [

                                _buildMedicineRow(

                                  medicine: medicine['medicine_name'] ?? 'Unknown',

                                  unit: medicine['unit'] ?? 'N/A',

                                  category: medicine['category'] ?? 'Uncategorized',

                                  totalQty: totalQty.toStringAsFixed(0),

                                  batches: '$batchCount batch${batchCount != 1 ? 'es' : ''}',

                                  price: '₱${earliestExpiryCost.toStringAsFixed(2)}',

                                  status: status,

                                  statusColor: statusColor,

                                  statusTextColor: statusTextColor,

                                  medicineId: medicineId,

                                ),

                              ],

                            );

                          }),

                        ],

                      ),

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

                  style: TextStyle(

                    fontSize: 32,

                    fontWeight: FontWeight.bold,

                    color: iconColor,

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



  Widget _buildDropdown({

    required String value,

    required List<String> items,

    required ValueChanged<String?> onChanged,

  }) {

    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 12),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(8),

        border: Border.all(color: Colors.grey[300]!),

      ),

      child: DropdownButtonHideUnderline(

        child: DropdownButton<String>(

          value: value,

          isExpanded: true,

          icon: const Icon(Icons.keyboard_arrow_down, size: 20),

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



  // Mobile: Card-based Medicine Item

  Widget _buildMedicineCard({

    required String medicine,

    required String unit,

    required String category,

    required String totalQty,

    required String batches,

    required String price,

    required String status,

    required Color statusColor,

    required Color statusTextColor,

    required int medicineId,

  }) {

    return Container(

      margin: const EdgeInsets.only(bottom: 12),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: Colors.grey[200]!),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withOpacity(0.04),

            blurRadius: 8,

            offset: const Offset(0, 2),

          ),

        ],

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          // Header: Medicine Name + Status

          Container(

            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(

              color: const Color(0xFFF8FAFC),

              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),

            ),

            child: Row(

              children: [

                Expanded(

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      Text(

                        medicine,

                        style: const TextStyle(

                          fontSize: 15,

                          fontWeight: FontWeight.bold,

                          color: Color(0xFF1E293B),

                        ),

                      ),

                      const SizedBox(height: 2),

                      Text(

                        '$category • $unit',

                        style: TextStyle(

                          fontSize: 12,

                          color: Colors.grey[600],

                        ),

                      ),

                    ],

                  ),

                ),

                Container(

                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

                  decoration: BoxDecoration(

                    color: statusColor,

                    borderRadius: BorderRadius.circular(20),

                  ),

                  child: Text(

                    status,

                    style: TextStyle(

                      fontSize: 11,

                      fontWeight: FontWeight.w600,

                      color: statusTextColor,

                    ),

                  ),

                ),

              ],

            ),

          ),

          // Details Row

          Padding(

            padding: const EdgeInsets.all(12),

            child: Row(

              children: [

                // Quantity

                Expanded(

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      Text(

                        'Quantity',

                        style: TextStyle(

                          fontSize: 11,

                          color: Colors.grey[500],

                        ),

                      ),

                      const SizedBox(height: 2),

                      Text(

                        totalQty,

                        style: const TextStyle(

                          fontSize: 16,

                          fontWeight: FontWeight.bold,

                          color: Color(0xFF1E293B),

                        ),

                      ),

                    ],

                  ),

                ),

                // Batches

                Expanded(

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      Text(

                        'Batches',

                        style: TextStyle(

                          fontSize: 11,

                          color: Colors.grey[500],

                        ),

                      ),

                      const SizedBox(height: 2),

                      Text(

                        batches,

                        style: const TextStyle(

                          fontSize: 16,

                          fontWeight: FontWeight.bold,

                          color: Color(0xFF1E293B),

                        ),

                      ),

                    ],

                  ),

                ),

                // Price

                Expanded(

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      Text(

                        'Price',

                        style: TextStyle(

                          fontSize: 11,

                          color: Colors.grey[500],

                        ),

                      ),

                      const SizedBox(height: 2),

                      Text(

                        price,

                        style: const TextStyle(

                          fontSize: 14,

                          fontWeight: FontWeight.w600,

                          color: Color(0xFF2563EB),

                        ),

                      ),

                    ],

                  ),

                ),

              ],

            ),

          ),

          // Actions

          Padding(

            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),

            child: Row(

              children: [

                // Dispense Button

                Expanded(

                  child: OutlinedButton.icon(

                    onPressed: () async {

                      try {

                        // Get batches for this medicine from inventory balances (includes batch info from JOIN with pharmacy_stock_batches)

                        final medicineBatches = _inventoryBalances

                            .where((balance) => balance['medicine'] == medicineId || balance['medicine_id'] == medicineId)

                            .map((balance) => {

                              'batch_id': balance['batch'] ?? balance['batch_id'],

                              'batch_no': balance['batch_no'] ?? '',

                              'expiry_date': balance['expiry_date'] ?? '',

                              'quantity': balance['qty_on_hand'] ?? 0,

                            })

                            .toList()

                          ..sort((a, b) => (a['expiry_date'] ?? '').compareTo(b['expiry_date'] ?? ''));



                        final now = DateTime.now();



                        final batchesWithQty = medicineBatches.map((b) {

                          final batchId = b['batch_id'];

                          final expiryDate = DateTime.tryParse(b['expiry_date'] ?? '');

                          final isExpired = expiryDate != null && expiryDate.isBefore(now);



                          final qty = b['quantity'] ?? 0;



                          final unitCostVal = b['unit_cost'];

                          double unitCost = 0;

                          if (unitCostVal != null) {

                            if (unitCostVal is String) {

                              unitCost = double.tryParse(unitCostVal) ?? 0;

                            } else {

                              unitCost = (unitCostVal as num).toDouble();

                            }

                          }



                          return {

                            'batchId': batchId,

                            'batchNumber': b['batch_no'],

                            'expiryDate': b['expiry_date'],

                            'quantity': qty,

                            'unitCost': unitCost,

                            'isExpired': isExpired,

                          };

                        }).where((b) => b['quantity'] > 0 && !b['isExpired']).toList();



                        final medicineData = {

                          'id': medicineId,

                          'name': medicine,

                          'category': category,

                          'unit': unit,

                          'availableStock': int.tryParse(totalQty) ?? 0,

                          'batches': batchesWithQty,

                        };

                        final result = await DispenseMedicineDialog.show(context, medicine: medicineData);



                        if (result == true) {

                          _fetchData();

                        }

                      } catch (e) {

                        ScaffoldMessenger.of(context).showSnackBar(

                          SnackBar(content: Text('Error: $e')),

                        );

                      }

                    },

                    icon: const Icon(Icons.medication_outlined, size: 16),

                    label: const Text('Dispense', style: TextStyle(fontSize: 12)),

                    style: OutlinedButton.styleFrom(

                      foregroundColor: const Color(0xFF2196F3),

                      side: const BorderSide(color: Color(0xFF2196F3)),

                      padding: const EdgeInsets.symmetric(vertical: 8),

                      shape: RoundedRectangleBorder(

                        borderRadius: BorderRadius.circular(6),

                      ),

                    ),

                  ),

                ),

                const SizedBox(width: 8),

                // Add Batch Button

                Expanded(

                  child: OutlinedButton.icon(

                    onPressed: () async {

                      final medicineData = {

                        'id': medicineId,

                        'medicine_id': medicineId,

                        'name': medicine,

                        'currentTotal': int.tryParse(totalQty) ?? 0,

                        'existingBatches': int.tryParse(batches) ?? 0,

                      };

                      final result = await AddBatchDialog.show(context, medicine: medicineData);

                      if (result != null) {

                        await _fetchData();

                        if (mounted) {

                          ScaffoldMessenger.of(context).hideCurrentSnackBar();

                          ScaffoldMessenger.of(context).showSnackBar(

                            const SnackBar(

                              content: Text('Inventory updated'),

                              duration: Duration(seconds: 1),

                            ),

                          );

                        }

                      }

                    },

                    icon: const Icon(Icons.add_circle_outline, size: 16),

                    label: const Text('Add Batch', style: TextStyle(fontSize: 12)),

                    style: OutlinedButton.styleFrom(

                      foregroundColor: const Color(0xFF059669),

                      side: const BorderSide(color: Color(0xFF059669)),

                      padding: const EdgeInsets.symmetric(vertical: 8),

                      shape: RoundedRectangleBorder(

                        borderRadius: BorderRadius.circular(6),

                      ),

                    ),

                  ),

                ),

              ],

            ),

          ),

        ],

      ),

    );

  }



  Widget _buildMedicineRow({

    required String medicine,

    required String unit,

    required String category,

    required String totalQty,

    required String batches,

    required String price,

    required String status,

    required Color statusColor,

    required Color statusTextColor,

    required int medicineId,

  }) {

    return InkWell(

      onTap: () async {

        // Get batches for this medicine from inventory balances (includes batch info from JOIN with pharmacy_stock_batches)

        // Only include location_id=1 (Main Pharmacy) for inventory features

        final medicineBatches = _inventoryBalances

            .where((balance) => 

                (balance['medicine'] == medicineId || balance['medicine_id'] == medicineId) &&

                (balance['location'] == 1 || balance['location_id'] == 1)

            )

            .map((balance) => {

              'batch_id': balance['batch'] ?? balance['batch_id'],

              'batch_no': balance['batch_no'] ?? '',

              'expiry_date': balance['expiry_date'] ?? '',

              'received_date': balance['received_date'] ?? '',

              'quantity': balance['qty_on_hand'] ?? 0,

              'location_id': balance['location'] ?? balance['location_id'],

              'location_name': balance['location_name'] ?? '',

              'unit_cost': 0, // Can be added if needed from batch data

            })

            .toList()

          ..sort((a, b) => (a['expiry_date'] ?? '').compareTo(b['expiry_date'] ?? ''));



        final medicineData = {

          'medicine_name': medicine,

          'category': category,

          'price': price,

          'total_quantity': totalQty,

          'unit': unit,

          'status': status == 'Active' ? 'OK' : status,

        };



        final result = await MedicineDetailsDialog.show(context, medicine: medicineData, batches: medicineBatches.cast<Map<String, dynamic>>());
        
        if (result == true) {
          _fetchData();
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

          // Total Qty

          Expanded(

            flex: 1,

            child: Text(

              totalQty,

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

                    batches,

                    textAlign: TextAlign.center,

                    style: const TextStyle(

                      fontSize: 11,

                      fontWeight: FontWeight.w600,

                      color: Color(0xFF1976D2),

                    ),

                  ),

                ),

              ),

            ),

          ),

          // Price

          Expanded(

            flex: 1,

            child: Text(

              price,

              textAlign: TextAlign.center,

              style: const TextStyle(

                fontSize: 14,

                fontWeight: FontWeight.w600,

                color: Colors.black87,

              ),

            ),

          ),

          // Status

          Expanded(

            flex: 1,

            child: Container(

              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

              decoration: BoxDecoration(

                color: status == 'Active' ? const Color(0xFFE8F5E9) : statusColor,

                borderRadius: BorderRadius.circular(12),

              ),

              child: Text(

                status == 'Active' ? 'OK' : status,

                textAlign: TextAlign.center,

                style: TextStyle(

                  fontSize: 12,

                  fontWeight: FontWeight.w600,

                  color: status == 'Active' ? const Color(0xFF2E7D32) : statusTextColor,

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

                // Dispense Icon

                Container(

                  margin: const EdgeInsets.only(right: 4),

                  decoration: BoxDecoration(

                    color: const Color(0xFFE3F2FD),

                    borderRadius: BorderRadius.circular(6),

                  ),

                  child: IconButton(

                    onPressed: () async {

                      try {

                        // Get batches for this medicine from inventory balances (includes batch info from JOIN with pharmacy_stock_batches)

                        final medicineBatches = _inventoryBalances

                            .where((balance) => balance['medicine'] == medicineId || balance['medicine_id'] == medicineId)

                            .map((balance) => {

                              'batch_id': balance['batch'] ?? balance['batch_id'],

                              'batch_no': balance['batch_no'] ?? '',

                              'expiry_date': balance['expiry_date'] ?? '',

                              'quantity': balance['qty_on_hand'] ?? 0,

                            })

                            .toList()

                            ..sort((a, b) => (a['expiry_date'] ?? '').compareTo(b['expiry_date'] ?? ''));



                        final now = DateTime.now();

                        

                        final batchesWithQty = medicineBatches.map((b) {

                          final batchId = b['batch_id'];

                          final expiryDate = DateTime.tryParse(b['expiry_date'] ?? '');

                          final isExpired = expiryDate != null && expiryDate.isBefore(now);

                          

                          final qty = b['quantity'] ?? 0;

                          

                          return {

                            'batchId': batchId,

                            'batchNumber': b['batch_no'],

                            'expiryDate': b['expiry_date'],

                            'quantity': qty,

                            'unitCost': 0, // Can be added if needed

                            'isExpired': isExpired,

                          };

                        }).where((b) => b['quantity'] > 0 && !b['isExpired']).toList();



                        final medicineData = {

                          'id': medicineId,

                          'name': medicine,

                          'category': category,

                          'unit': unit,

                          'availableStock': int.tryParse(totalQty) ?? 0,

                          'batches': batchesWithQty,

                        };

                        final result = await DispenseMedicineDialog.show(context, medicine: medicineData);

                        

                        // Background instant refresh (no loading spinner)

                        await _fetchData(showLoading: false);

                      } catch (e) {

                        ScaffoldMessenger.of(context).showSnackBar(

                          SnackBar(content: Text('Error: $e')),

                        );

                      }

                    },

                    icon: const Icon(Icons.medication_outlined, size: 16, color: Color(0xFF2196F3)),

                    padding: const EdgeInsets.all(8),

                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),

                    tooltip: 'Dispense',

                  ),

                ),

                // Add Batch Icon

                Container(

                  margin: const EdgeInsets.only(right: 4),

                  decoration: BoxDecoration(

                    color: const Color(0xFFE8F5E9),

                    borderRadius: BorderRadius.circular(6),

                  ),

                  child: IconButton(

                    onPressed: () async {

                      final medicineData = {

                        'id': medicineId,

                        'medicine_id': medicineId,

                        'name': medicine,

                        'currentTotal': int.tryParse(totalQty) ?? 0,

                        'existingBatches': int.tryParse(batches) ?? 0,

                      };

                      final result = await AddBatchDialog.show(context, medicine: medicineData);

                      

                      // Instant Refresh in background

                      await _fetchData(showLoading: false);

                    },

                    icon: const Icon(Icons.add_box_outlined, size: 20, color: Color(0xFF2E7D32)),

                    tooltip: 'Add Batch',

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

                    onPressed: () async {

                      final String? reason = await showDialog<String>(
                        context: context,
                        builder: (context) {
                          String selectedReason = 'Damaged';
                          return StatefulBuilder(
                            builder: (context, setDialogState) {
                              return AlertDialog(
                                title: Text('Remove Medicine: $medicine', 
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('This will remove the medicine and ALL its batches. This action cannot be undone.',
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
                                    child: const Text('Remove Medicine'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );

                      if (reason != null) {
                        try {
                          final response = await _pharmacyService.removeMedicine(medicineId, reason);

                          if (response['success'] == true) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$medicine removed successfully')),
                              );
                              _fetchData();
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      }
                    },

                    icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFE53935)),

                    padding: const EdgeInsets.all(8),

                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),

                    tooltip: 'Delete',

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

}

