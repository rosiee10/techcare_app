import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/card_container.dart';
import '../widgets/opd_charge_slip/charge_slip_dialog.dart';
import '../services/pharmacy_service.dart';

/// OPD Charge Slip Management Page
/// Review prescriptions, generate OPD charge slips, and track billing status
class OpdChargeSlipPage extends StatefulWidget {
  const OpdChargeSlipPage({super.key});

  @override
  State<OpdChargeSlipPage> createState() => _OpdChargeSlipPageState();
}

class _OpdChargeSlipPageState extends State<OpdChargeSlipPage> {
  String _selectedStatus = 'All Status';
  final TextEditingController _searchController = TextEditingController();
  final PharmacyService _pharmacyService = PharmacyService();

  // Dynamic data
  List<dynamic> _chargeSlips = [];
  List<dynamic> _filteredChargeSlips = [];

  // OPD Prescriptions data
  List<dynamic> _opdPrescriptions = [];
  List<dynamic> _groupedPrescriptions = [];
  bool _isLoadingPrescriptions = false;
  String? _prescriptionsError;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchOpdPrescriptions();
  }

  Future<void> _fetchOpdPrescriptions() async {
    setState(() {
      _isLoadingPrescriptions = true;
      _prescriptionsError = null;
    });

    try {
      final prescriptions = await _pharmacyService.getOpdPrescriptions();

      // Group prescriptions by patient_id
      final Map<String, Map<String, dynamic>> grouped = {};
      for (final rx in prescriptions) {
        final patientId = rx['patient_id']?.toString() ?? 'unknown';
        if (!grouped.containsKey(patientId)) {
          grouped[patientId] = {
            'patient_id': patientId,
            'patient_name': rx['patient_name'] ?? 'Unknown',
            'rx_id': rx['rx_id'],
            'medicines': <Map<String, dynamic>>[],
            'doctor': 'Dr. Unknown', // opd_prescription has no doctor field
          };
        }
        grouped[patientId]!['medicines'].add(rx);
      }

      setState(() {
        _opdPrescriptions = prescriptions;
        _groupedPrescriptions = grouped.values.toList();
        _isLoadingPrescriptions = false;
      });
    } catch (e) {
      setState(() {
        _prescriptionsError = 'Failed to load prescriptions: $e';
        _isLoadingPrescriptions = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Responsive
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OPD Charge Slip Management',
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Review prescriptions, generate OPD charge slips, and track billing status',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Incoming Prescriptions Section - Responsive
          CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.description_outlined, color: const Color(0xFF2196F3), size: isMobile ? 18 : 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Incoming Prescriptions from OPD Doctors (${_groupedPrescriptions.length})',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (_isLoadingPrescriptions)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: const Color(0xFF2196F3),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_prescriptionsError != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[400], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _prescriptionsError!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red[700],
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _fetchOpdPrescriptions,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                else if (_groupedPrescriptions.isEmpty && !_isLoadingPrescriptions)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No incoming prescriptions at this time',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  )
                else
                  ..._groupedPrescriptions.map((group) {
                    final medicines = group['medicines'] as List;
                    final medicineCount = medicines.length;
                    final patientName = group['patient_name'] as String;
                    final initials = _getInitials(patientName);
                    final rxNumber = 'RX-${group['rx_id']?.toString().padLeft(3, '0') ?? '000'}';
                    final patientId = group['patient_id']?.toString() ?? 'N/A';
                    final doctor = group['doctor'] ?? 'Dr. Unknown';
                    final medicinesCount = '$medicineCount medicine${medicineCount > 1 ? 's' : ''} prescribed';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildPrescriptionItem(
                        isMobile: isMobile,
                        initials: initials,
                        rxNumber: rxNumber,
                        patientName: patientName,
                        patientId: patientId,
                        doctor: doctor,
                        medicinesCount: medicinesCount,
                        prescriptionData: group,
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Search and Filter Bar - Responsive
          CardContainer(
            child: isMobile
              ? Column(
                  children: [
                    // Search Field
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by patient, ID, slip...',
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Status Dropdown
                    SizedBox(
                      width: double.infinity,
                      child: _buildDropdown(
                        value: _selectedStatus,
                        items: const ['All Status', 'Pending', 'Generated', 'Paid'],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                          });
                        },
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    // Search Field
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by patient name, ID, or charge slip number...',
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
                        items: const ['All Status', 'Pending', 'Generated', 'Paid'],
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

          // Empty State - No Charge Slips Found
          CardContainer(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Icon(
                    _searchController.text.isNotEmpty ? Icons.search_off : Icons.receipt_long_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isEmpty
                      ? 'No charge slips found'
                      : 'No charge slips found matching "${_searchController.text}"',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchController.text.isEmpty
                      ? 'Charge slips will appear here after you review and generate them from prescriptions'
                      : 'Try a different search term or clear the search',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (_searchController.text.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                        _filterChargeSlips();
                      },
                      child: const Text('Clear Search'),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return '?';
  }

  Widget _buildPrescriptionItem({
    required bool isMobile,
    required String initials,
    required String rxNumber,
    required String patientName,
    required String patientId,
    required String doctor,
    required String medicinesCount,
    Map<String, dynamic>? prescriptionData,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Avatar + Info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Prescription Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rxNumber,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          patientName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Details
              Text(
                'Patient ID: $patientId',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Doctor: $doctor',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                medicinesCount,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              // Action Button (Full width)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (prescriptionData != null) {
                      final medicines = (prescriptionData['medicines'] as List?) ?? [];
                      final dialogPrescription = {
                        'rxNumber': rxNumber,
                        'patientName': patientName,
                        'patientId': patientId,
                        'doctorName': doctor,
                        'rx_id': prescriptionData['rx_id'],
                        'patient_id': prescriptionData['patient_id'],
                        'medicines': medicines.map((med) => {
                          'name': med['medicine_name_snapshot'] ?? 'Unknown',
                          'medicine_id': med['medicine_id'],
                          'prescribedQty': 1,
                          'releaseQty': 1,
                          'unitPrice': 0.0,
                          'available': true,
                        }).toList(),
                      };
                      ChargeSlipDialog.show(context, prescription: dialogPrescription);
                    } else {
                      ChargeSlipDialog.show(context);
                    }
                  },
                  icon: const Icon(Icons.description_outlined, size: 16),
                  label: const Text('Review & Generate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          )
        : Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Prescription Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          rxNumber,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          patientName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Patient ID: $patientId     Doctor: $doctor     $medicinesCount',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Action Button
              ElevatedButton.icon(
                onPressed: () {
                  if (prescriptionData != null) {
                    final medicines = (prescriptionData['medicines'] as List?) ?? [];
                    final dialogPrescription = {
                      'rxNumber': rxNumber,
                      'patientName': patientName,
                      'patientId': patientId,
                      'doctorName': doctor,
                      'rx_id': prescriptionData['rx_id'],
                      'patient_id': prescriptionData['patient_id'],
                      'medicines': medicines.map((med) => {
                        'name': med['medicine_name_snapshot'] ?? 'Unknown',
                        'medicine_id': med['medicine_id'],
                        'prescribedQty': 1,
                        'releaseQty': 1,
                        'unitPrice': 0.0,
                        'available': true,
                      }).toList(),
                    };
                    ChargeSlipDialog.show(context, prescription: dialogPrescription);
                  } else {
                    ChargeSlipDialog.show(context);
                  }
                },
                icon: const Icon(Icons.description_outlined, size: 16),
                label: const Text('Review & Generate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
}
