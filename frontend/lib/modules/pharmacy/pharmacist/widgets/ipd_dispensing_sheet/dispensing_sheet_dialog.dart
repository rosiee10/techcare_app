import 'package:flutter/material.dart';
import '../../../../ipd/ipd_nurse/services/ipd_inventory_service.dart';

/// Services and Dispensing Sheet Dialog
/// Shows dispensing sheet details with medicines to dispense
class DispensingSheetDialog extends StatefulWidget {
  final Map<String, dynamic> sheet;

  const DispensingSheetDialog({
    super.key,
    required this.sheet,
  });

  @override
  State<DispensingSheetDialog> createState() => _DispensingSheetDialogState();

  /// Show the dialog
  static Future<void> show(BuildContext context, {Map<String, dynamic>? sheet}) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DispensingSheetDialog(sheet: sheet ?? {}),
    );
  }
}

class _DispensingSheetDialogState extends State<DispensingSheetDialog> {
  late Map<String, dynamic> _sheet;
  final IpdInventoryService _inventoryService = IpdInventoryService();
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _sheet = widget.sheet;
  }

  Future<void> _handleDispense() async {
    final items = _sheet['items'] as List<dynamic>? ?? [];
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items to dispense')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Prepare the payload for DispensingSheetDispenseView
      // IMPORTANT: Ensure medicine_name is included for backend item_description
      final dispenseData = {
        'items': items.map((item) => {
          'dispensing_item_id': item['dispensing_item_id'],
          'medicine_id': item['medicine_id'],
          'medicine_name': item['medicine_name'], // REQUIRED by backend for item_description
          'quantity': item['quantity'],
          'unit': item['medicine_unit'] ?? item['unit'] ?? 'Unit',
          'unit_cost': item['medicine_unit_cost'] ?? item['unit_cost'] ?? 0,
        }).toList(),
      };

      final response = await _inventoryService.dispenseSheet(
        _sheet['dispensing_id'], 
        dispenseData
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicines dispensed and recorded successfully')),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error dispensing: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final dialogWidth = isMobile ? screenWidth * 0.98 : 900.0;

    return Dialog(
      insetPadding: EdgeInsets.all(isMobile ? 8 : 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
      ),
      child: Container(
        width: isMobile ? screenWidth * 0.98 : dialogWidth,
        constraints: BoxConstraints(
          maxHeight: isMobile ? MediaQuery.of(context).size.height * 0.46 : 800,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(isMobile ? 10 : 16),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 6 : 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                    ),
                    child: Icon(Icons.description, color: const Color(0xFF1976D2), size: isMobile ? 18 : 20),
                  ),
                  SizedBox(width: isMobile ? 10 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dispensing Sheet',
                          style: TextStyle(
                            fontSize: isMobile ? 15 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: isMobile ? 1 : 2),
                        Text(
                          'Sheet #${_sheet['dispensing_id'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: isMobile ? 10 : 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.grey),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 10 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hospital Header Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black87, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          // Logos and Header Text
                          Row(
                            children: [
                              // Left Logo
                              Image.asset(
                                'assets/logos/pchlogo.png',
                                width: 70,
                                height: 70,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.local_hospital, color: Colors.grey[600], size: 35),
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                              // Center Text
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      'REPUBLIC OF THE PHILIPPINES',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'PROVINCE OF MISAMIS OCCIDENTAL',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'MUNICIPALITY OF PLARIDEL',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'PLARIDEL COMMUNITY HOSPITAL',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'SITIO SANTOS, PANALSALAN, PLARIDEL, MISAMIS OCCIDENTAL',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Right Logo
                              Image.asset(
                                'assets/logos/pchlogo.png',
                                width: 70,
                                height: 70,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.local_hospital, color: Colors.grey[600], size: 35),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Services and Dispensing Sheet Title
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.black87, width: 0.5),
                                bottom: BorderSide(color: Colors.black87, width: 0.5),
                              ),
                            ),
                            child: const Text(
                              'SERVICES AND DISPENSING SHEET',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Patient Info
                          isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildPatientInfoRow('NAME:', _sheet['patient_name'] ?? '—'),
                                  const SizedBox(height: 4),
                                  _buildPatientInfoRow('DATE ADMITTED:', _sheet['admission_date'] ?? '—'),
                                  const SizedBox(height: 4),
                                  _buildPatientInfoRow('ADDRESS:', _sheet['patient_address'] ?? '—'),
                                  const SizedBox(height: 4),
                                  _buildPatientInfoRow('TIME:', _sheet['admission_time'] ?? '—'),
                                  const SizedBox(height: 4),
                                  _buildPatientInfoRow('DATE DISCHARGED:', _sheet['discharge_date'] ?? '—'),
                                  const SizedBox(height: 4),
                                  _buildPatientInfoRow('WARD:', _sheet['ward'] ?? '—'),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildPatientInfoRow('NAME:', _sheet['patient_name'] ?? '—'),
                                        const SizedBox(height: 4),
                                        _buildPatientInfoRow('DATE ADMITTED:', _sheet['admission_date'] ?? '—'),
                                        const SizedBox(height: 4),
                                        _buildPatientInfoRow('ADDRESS:', _sheet['patient_address'] ?? '—'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildPatientInfoRow('TIME:', _sheet['admission_time'] ?? '—'),
                                        const SizedBox(height: 4),
                                        _buildPatientInfoRow('DATE DISCHARGED:', _sheet['discharge_date'] ?? '—'),
                                        const SizedBox(height: 4),
                                        _buildPatientInfoRow('WARD:', _sheet['ward'] ?? '—'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Medicines Table Section
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section Header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                            ),
                            child: const Text(
                              'MEDICINES/SUPPLY - DISPENSE INDIVIDUAL ITEMS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          // Table Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                bottom: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            child: isMobile
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'MEDICINES/SUPPLY - DISPENSE INDIVIDUAL ITEMS',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    _buildTableHeader('DATE', flex: 2),
                                    _buildTableHeader('MEDICINES/SUPPLY', flex: 4),
                                    _buildTableHeader('QTY', flex: 1),
                                    _buildTableHeader('UNIT COST', flex: 1),
                                    _buildTableHeader('TOTAL', flex: 1),
                                    _buildTableHeader('PHARMACIST ACTION', flex: 2),
                                  ],
                                ),
                          ),
                          // Table Rows
                          ...(_sheet['items'] as List? ?? []).map((item) {
                            return _buildMedicineRow(item);
                          }).toList(),
                          const Divider(height: 1),
                          // Total Amount Footer
                          Padding(
                            padding: EdgeInsets.all(isMobile ? 10 : 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'TOTAL AMOUNT: ',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 14),
                                ),
                                Text(
                                  'P ${(_sheet['total_amount'] ?? 0).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Dispense All Button
                          if (_sheet['status'] == 'PENDING' || _sheet['status'] == 'APPROVED')
                            Padding(
                              padding: EdgeInsets.all(isMobile ? 10 : 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _isSaving ? null : _handleDispense,
                                    icon: _isSaving 
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : Icon(Icons.check_circle, size: isMobile ? 18 : 20),
                                    label: Text(_isSaving ? 'Dispensing...' : 'Dispense All', style: TextStyle(fontSize: isMobile ? 12 : 14)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 10 : 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
              ),
            ),
            // Footer Buttons
            Padding(
              padding: EdgeInsets.all(isMobile ? 10 : 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildMedicineRow(Map<String, dynamic> item) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    // In our IPD system, we check if medicine_id exists and if we have stock
    final bool hasStock = (item['medicine_stock'] ?? 0) > 0;
    final double qty = (item['quantity'] ?? 0).toDouble();
    final double unitCost = (item['medicine_unit_cost'] ?? 0).toDouble();
    final double total = qty * unitCost;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Medicine Name & Date
              Row(
                children: [
                  Icon(Icons.medication, size: 16, color: Colors.blue[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item['medicine_name'] ?? 'Unknown Item',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Date & Stock
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(
                    item['date_requested'] ?? '—',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    !hasStock ? Icons.error_outline : Icons.check_circle_outline,
                    size: 14,
                    color: !hasStock ? Colors.red[600] : Colors.green[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    !hasStock ? 'Out of Stock' : 'In Stock (${item['medicine_stock']})',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: !hasStock ? Colors.red[600] : Colors.green[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Quantity and Action Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Qty: $qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Cost: P ${total.toStringAsFixed(2)}'),
                  if (_sheet['status'] == 'PENDING' && hasStock)
                     const Icon(Icons.check_circle, color: Colors.green)
                ],
              ),
            ],
          )
        : Row(
            children: [
              // Date
              Expanded(
                flex: 2,
                child: Text(
                  item['date_requested'] ?? '—',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ),
              // Medicine Name
              Expanded(
                flex: 4,
                child: Text(
                  item['medicine_name'] ?? 'Unknown Item',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              // Quantity
              Expanded(
                flex: 1,
                child: Text(qty.toString(), textAlign: TextAlign.center),
              ),
              // Unit Cost
              Expanded(
                flex: 1,
                child: Text('P ${unitCost.toStringAsFixed(2)}'),
              ),
              // Total
              Expanded(
                flex: 1,
                child: Text('P ${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              // Action/Status
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Icon(
                      !hasStock ? Icons.error_outline : Icons.check_circle_outline,
                      size: 16,
                      color: !hasStock ? Colors.red[600] : Colors.green[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      !hasStock ? 'No Stock' : 'Available',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: !hasStock ? Colors.red[600] : Colors.green[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildQuantityInput(TextEditingController controller) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF90CAF9)),
      ),
      child: Row(
        children: [
          // Number input
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 4),
                border: InputBorder.none,
              ),
            ),
          ),
          // Up/Down buttons
          Container(
            width: 24,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Up arrow
                InkWell(
                  onTap: () {
                    final currentValue = int.tryParse(controller.text) ?? 0;
                    controller.text = (currentValue + 1).toString();
                  },
                  child: Icon(
                    Icons.arrow_drop_up,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ),
                // Down arrow
                InkWell(
                  onTap: () {
                    final currentValue = int.tryParse(controller.text) ?? 0;
                    if (currentValue > 0) {
                      controller.text = (currentValue - 1).toString();
                    }
                  },
                  child: Icon(
                    Icons.arrow_drop_down,
                    size: 16,
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
}
