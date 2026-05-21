import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/card_container.dart';
import '../services/pharmacy_service.dart';
import '../widgets/ipd_pharmacy_billing/billing_sheet_dialog.dart';

/// IPD Pharmacy Billing Page
/// Generate and send pharmacy billing sheets to Billing Staff for IPD patients
class IpdPharmacyBillingPage extends StatefulWidget {
  const IpdPharmacyBillingPage({super.key});

  @override
  State<IpdPharmacyBillingPage> createState() => _IpdPharmacyBillingPageState();
}

class _IpdPharmacyBillingPageState extends State<IpdPharmacyBillingPage> {
  String _selectedStatus = 'All Status';
  final TextEditingController _searchController = TextEditingController();
  final PharmacyService _pharmacyService = PharmacyService();

  // Dynamic data
  bool _isLoading = true;
  List<dynamic> _chargeSlips = [];
  List<dynamic> _filteredChargeSlips = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterChargeSlips();
  }

  void _filterChargeSlips() {
    final query = _searchController.text.toLowerCase().trim();
    
    setState(() {
      if (query.isEmpty) {
        _filteredChargeSlips = List.from(_chargeSlips);
      } else {
        _filteredChargeSlips = _chargeSlips.where((slip) {
          final patientName = (slip['patient_name'] ?? '').toString().toLowerCase();
          final patientId = (slip['patient_id'] ?? '').toString().toLowerCase();
          final slipNo = (slip['charge_slip_no'] ?? '').toString().toLowerCase();
          
          return patientName.contains(query) ||
                 patientId.contains(query) ||
                 slipNo.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _fetchData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final slips = await _pharmacyService.getChargeSlips();

      setState(() {
        _chargeSlips = slips;
        _filteredChargeSlips = List.from(slips);
        _isLoading = false;
      });
      
      // Apply any existing search filter
      if (_searchController.text.isNotEmpty) {
        _filterChargeSlips();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  // Calculate total patients
  int get _totalPatients => _chargeSlips.length;

  // Calculate pending billing
  int get _pendingBilling => _chargeSlips.where((s) => (s['received_status']?.toString().toLowerCase() ?? '') != 'paid').length;

  // Calculate total amount
  double get _totalAmount {
    double total = 0.0;
    for (var slip in _chargeSlips) {
      final items = slip['items'] as List? ?? [];
      if (items.isNotEmpty) {
        // Calculate based on items to ensure quantity is respected
        for (var item in items) {
          double qty = double.tryParse((item['quantity'] ?? 0).toString()) ?? 0.0;
          double cost = double.tryParse((item['unit_cost'] ?? 0).toString()) ?? 0.0;
          total += (qty * cost);
        }
      } else {
        // Fallback to total_amount if items are not available
        var amount = slip['total_amount'];
        if (amount != null) {
          if (amount is String) {
            total += double.tryParse(amount) ?? 0.0;
          } else if (amount is num) {
            total += amount.toDouble();
          }
        }
      }
    }
    return total;
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
                'IPD Pharmacy Billing',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Generate and send pharmacy billing sheets to Billing Staff for IPD patients',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stat Cards Row - Dynamic
          Row(
            children: [
              _buildStatCard(
                title: 'Total IPD Patients',
                value: _isLoading ? '-' : _totalPatients.toString(),
                icon: Icons.description_outlined,
                iconBgColor: const Color(0xFFE3F2FD),
                iconColor: const Color(0xFF2196F3),
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                title: 'Pending Billing',
                value: _isLoading ? '-' : _pendingBilling.toString(),
                icon: Icons.access_time_outlined,
                iconBgColor: const Color(0xFFFFF9C4),
                iconColor: const Color(0xFFFBC02D),
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                title: 'Total Amount',
                value: _isLoading ? '-' : '₱${_totalAmount.toStringAsFixed(2)}',
                icon: Icons.attach_money,
                iconBgColor: const Color(0xFFE8F5E9),
                iconColor: const Color(0xFF4CAF50),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Search and Filter Bar
          CardContainer(
            child: Row(
              children: [
                // Search Field
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by patient name, ID, or ward...',
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
                const SizedBox(width: 16),
                // Status Dropdown
                SizedBox(
                  width: 140,
                  child: _buildDropdown(
                    value: _selectedStatus,
                    items: const ['All Status', 'Draft', 'Sent', 'Paid'],
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

          // Data Table
          CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Row(
                    children: [
                      _buildTableHeader('PATIENT DETAILS', flex: 2),
                      _buildTableHeader('WARD', flex: 1),
                      _buildTableHeader('DATE ADMITTED', flex: 1),
                      _buildTableHeader('ITEMS DISPENSED', flex: 1),
                      _buildTableHeader('TOTAL AMOUNT', flex: 1),
                      _buildTableHeader('STATUS', flex: 1),
                      _buildTableHeader('ACTION', flex: 1),
                    ],
                  ),
                ),
                const Divider(height: 1),
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
                          ElevatedButton(onPressed: _fetchData, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  )
                else if (_filteredChargeSlips.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.search_off, color: Colors.grey[400], size: 48),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty
                              ? 'No billing records found'
                              : 'No records found matching "${_searchController.text}"',
                            style: TextStyle(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                          if (_searchController.text.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                _searchController.clear();
                                _filterChargeSlips();
                              },
                              child: const Text('Clear Search'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else
                  ..._filteredChargeSlips.asMap().entries.map((entry) {
                    final slip = entry.value;
                    final items = slip['items'] ?? [];

                    // Calculate row total dynamically to respect quantity
                    double rowTotal = 0.0;
                    if (items is List) {
                      for (var item in items) {
                        double qty = double.tryParse((item['quantity'] ?? 0).toString()) ?? 0.0;
                        double cost = double.tryParse((item['unit_cost'] ?? 0).toString()) ?? 0.0;
                        rowTotal += (qty * cost);
                      }
                    } else {
                      rowTotal = double.tryParse((slip['total_amount'] ?? 0).toString()) ?? 0.0;
                    }
                    
                    return Column(
                      children: [
                        BillingPatientRow(
                          initials: (slip['patient_name']?.toString() ?? '??').isNotEmpty ? (slip['patient_name']?.toString() ?? '??').substring(0, 1).toUpperCase() : '?',
                          name: (slip['patient_name'] ?? 'Unknown').toString(),
                          patientId: (slip['patient_hospital_id'] ?? '—').toString(),
                          ward: (slip['ward'] ?? 'N/A').toString(),
                          dateAdmitted: (slip['created_at']?.toString().substring(0, 10) ?? 'N/A').toString(),
                          items: '${items.length} items',
                          totalAmount: '₱${rowTotal.toStringAsFixed(2)}',
                          status: (slip['received_status'] ?? 'Draft').toString(),
                          onTap: () async {
                            final result = await BillingSheetDialog.show(context, billing: slip);
                            if (result == true) {
                              _fetchData(); // Refresh list if dialog was finalized
                            }
                          },
                        ),
                        if (entry.key < _filteredChargeSlips.length - 1)
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      ],
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _parseTotal(dynamic amount) {
    if (amount == null) return "0.00";
    if (amount is String) {
      return (double.tryParse(amount) ?? 0.0).toStringAsFixed(2);
    }
    if (amount is num) {
      return amount.toDouble().toStringAsFixed(2);
    }
    return "0.00";
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

  Widget _buildTableHeader(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
