import 'package:flutter/material.dart';
import '../../../core/reusable_widgets/card_container.dart';
import '../../../core/reusable_widgets/section_header.dart';
import '../../pharmacy/pharmacist/services/pharmacy_service.dart';

/// Pharmacy Inventory Page for Chief Nurse
/// Read-only view of medicines in Main Pharmacy (location 1)
class PharmacyInventoryPage extends StatefulWidget {
  const PharmacyInventoryPage({super.key});

  @override
  State<PharmacyInventoryPage> createState() => _PharmacyInventoryPageState();
}

class _PharmacyInventoryPageState extends State<PharmacyInventoryPage> {
  final TextEditingController _searchController = TextEditingController();
  final PharmacyService _pharmacyService = PharmacyService();

  bool _isLoading = false;
  List<dynamic> _medicines = [];
  List<dynamic> _filteredMedicines = [];
  List<dynamic> _inventoryBalances = [];
  Map<String, dynamic> _dashboardStats = {};
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchData(showLoading: false);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() => _filterMedicines();

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
      if (showLoading) setState(() { _isLoading = true; _errorMessage = ''; });

      final medicines = await _pharmacyService.getMedicines();
      final inventoryBalances = await _pharmacyService.getInventoryBalances();
      final dashboardStats = await _pharmacyService.getDashboardStats();

      setState(() {
        _medicines = medicines;
        _filteredMedicines = List.from(medicines);
        _inventoryBalances = inventoryBalances;
        _dashboardStats = dashboardStats;
        _isLoading = false;
      });

      if (_searchController.text.isNotEmpty) _filterMedicines();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  double _getTotalQuantity(int? medicineId) {
    if (medicineId == null || medicineId == 0) return 0.0;
    try {
      return _inventoryBalances
          .where((balance) {
            final balanceMedId = balance['medicine'] ?? balance['medicine_id'];
            if (balanceMedId != medicineId) return false;
            final locationId = balance['location'] ?? balance['location_id'];
            return locationId == 1;
          })
          .fold(0.0, (sum, balance) {
            final qty = balance['qty_on_hand'];
            if (qty == null) return sum;
            if (qty is String) return sum + (double.tryParse(qty) ?? 0.0);
            return sum + (qty as num).toDouble();
          });
    } catch (e) { return 0.0; }
  }

  int _getBatchCount(int? medicineId) {
    if (medicineId == null || medicineId == 0) return 0;
    return _inventoryBalances.where((balance) {
      final batchMedId = balance['medicine'] ?? balance['medicine_id'];
      final locationId = balance['location'] ?? balance['location_id'];
      if (batchMedId == null) return false;
      return batchMedId == medicineId && locationId == 1;
    }).length;
  }

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
      try { return DateTime.parse(expiryDateStr).isBefore(now); } catch (e) { return false; }
    }).toList();
    if (expiredBatches.length == medicineBatches.length) return 'Expired';

    final expiringSoonBatches = medicineBatches.where((batch) {
      final expiryDateStr = batch['expiry_date'];
      if (expiryDateStr == null || expiryDateStr.isEmpty) return false;
      try {
        final expiryDate = DateTime.parse(expiryDateStr);
        final daysUntilExpiry = expiryDate.difference(now).inDays;
        return daysUntilExpiry <= 30 && daysUntilExpiry >= 0;
      } catch (e) { return false; }
    }).toList();
    if (expiringSoonBatches.isNotEmpty) return 'Expiring Soon';

    return 'Active';
  }

  (Color, Color) _getStatusColors(String status) {
    switch (status) {
      case 'Expired': return (const Color(0xFFFFEBEE), const Color(0xFFC62828));
      case 'Expiring Soon': return (const Color(0xFFFFF9C4), const Color(0xFFF57F17));
      case 'Out of Stock': return (const Color(0xFFF5F5F5), const Color(0xFF616161));
      default: return (const Color(0xFFE8F5E9), const Color(0xFF2E7D32));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 768;

    return Container(
      color: Colors.white,
      child: _isLoading && _medicines.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Pharmacy Inventory',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Main Pharmacy - All medicines in location 1',
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),

                // Stat Cards
                isSmallScreen
                  ? Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildStatCard('Total', '${_dashboardStats['total_medicines'] ?? 0}', Icons.medication_outlined, const Color(0xFFE3F2FD), const Color(0xFF2196F3))),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatCard('Low Stock', '${_dashboardStats['low_stock_count'] ?? 0}', Icons.warning_amber_outlined, const Color(0xFFFFF3E0), const Color(0xFFFF6F00))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildStatCard('Expiring', '${_dashboardStats['expiring_soon'] ?? 0}', Icons.access_time_outlined, const Color(0xFFFFFDE7), const Color(0xFFFBC02D))),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatCard('Expired', '${_dashboardStats['expired_count'] ?? 0}', Icons.cancel_outlined, const Color(0xFFFFEBEE), const Color(0xFFC62828))),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: _buildStatCard('Total Medicines', '${_dashboardStats['total_medicines'] ?? 0}', Icons.medication_outlined, const Color(0xFFE3F2FD), const Color(0xFF2196F3))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStatCard('Low Stock', '${_dashboardStats['low_stock_count'] ?? 0}', Icons.warning_amber_outlined, const Color(0xFFFFF3E0), const Color(0xFFFF6F00))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStatCard('Expiring Soon', '${_dashboardStats['expiring_soon'] ?? 0}', Icons.access_time_outlined, const Color(0xFFFFFDE7), const Color(0xFFFBC02D))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStatCard('Expired', '${_dashboardStats['expired_count'] ?? 0}', Icons.cancel_outlined, const Color(0xFFFFEBEE), const Color(0xFFC62828))),
                      ],
                    ),
                const SizedBox(height: 24),

                // Search
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search medicines...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),

                // Error message
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFC62828)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_errorMessage, style: const TextStyle(color: Color(0xFFC62828)))),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Color(0xFFC62828)),
                          onPressed: () => _fetchData(),
                        ),
                      ],
                    ),
                  ),

                // Table
                CardContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(title: 'Medicine List (${_filteredMedicines.length})'),
                      const SizedBox(height: 16),
                      if (_filteredMedicines.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No medicines found', style: TextStyle(color: Colors.grey)),
                          ),
                        )
                      else
                        ...[
                          // Table Header
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                            ),
                            child: Row(
                              children: [
                                _buildTableHeader('MEDICINE', flex: 2, align: TextAlign.left, textColor: Colors.white),
                                _buildTableHeader('UNIT', flex: 1, textColor: Colors.white),
                                _buildTableHeader('CATEGORY', flex: 2, textColor: Colors.white),
                                _buildTableHeader('TOTAL QTY', flex: 1, textColor: Colors.white),
                                _buildTableHeader('PRICE', flex: 1, textColor: Colors.white),
                                _buildTableHeader('STATUS', flex: 1, textColor: Colors.white),
                              ],
                            ),
                          ),
                          // Table Rows
                          ...List.generate(_filteredMedicines.length, (index) {
                            final medicine = _filteredMedicines[index];
                            final medicineId = medicine['medicine_id'] ?? 0;
                            final totalQty = _getTotalQuantity(medicineId);
                            final status = _getStatus(medicineId);
                            final (bgColor, textColor) = _getStatusColors(status);
                            final unitCost = medicine['unit_cost'] ?? 0;
                            final price = unitCost is String ? double.tryParse(unitCost) ?? 0.0 : (unitCost as num).toDouble();

                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                                      medicine['medicine_name'] ?? 'Unknown',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      medicine['unit_of_measure'] ?? medicine['unit'] ?? 'N/A',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      medicine['category'] ?? 'Uncategorized',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      totalQty.toStringAsFixed(0),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      price > 0 ? '₱${price.toStringAsFixed(2)}' : 'N/A',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: bgColor,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconBgColor, Color iconColor) {
    return CardContainer(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text, {required int flex, TextAlign align = TextAlign.center, Color? textColor}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor ?? Colors.grey[700],
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
