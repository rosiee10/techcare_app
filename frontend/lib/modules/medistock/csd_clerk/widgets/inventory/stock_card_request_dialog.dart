import 'package:flutter/material.dart';

/// Stock Card Request Form Dialog
class StockCardRequestDialog extends StatefulWidget {
  const StockCardRequestDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const StockCardRequestDialog(),
    );
  }

  @override
  State<StockCardRequestDialog> createState() => _StockCardRequestDialogState();
}

class _StockCardRequestDialogState extends State<StockCardRequestDialog> {
  final List<Map<String, dynamic>> _requestRows = [];

  final List<String> _products = [
    'Surgical Gloves (Large)',
    'Disposable Syringes',
    'Gauze Pads',
    'Alcohol Swabs',
    'Bandage Rolls',
    'Cotton Balls',
  ];

  final List<String> _departments = [
    'OPD',
    'IPD',
    'Laboratory',
    'Pharmacy',
    'Billing',
    'Kitchen',
    'Admin',
  ];

  @override
  void initState() {
    super.initState();
    _addNewRow();
  }

  void _addNewRow() {
    setState(() {
      _requestRows.add({
        'date': DateTime.now(),
        'product': null,
        'quantity': 0,
        'requestedBy': '',
        'patientName': '',
        'department': null,
      });
    });
  }

  void _removeRow(int index) {
    if (_requestRows.length > 1) {
      setState(() {
        _requestRows.removeAt(index);
      });
    }
  }

  Future<void> _selectDate(BuildContext context, int index) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _requestRows[index]['date'] ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _requestRows[index]['date'] = picked;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _dispense() {
    // Validate all rows
    bool isValid = true;
    for (var row in _requestRows) {
      if (row['product'] == null || row['department'] == null || row['requestedBy'].isEmpty) {
        isValid = false;
        break;
      }
    }

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    // TODO: Implement dispense API call
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogWidth = screenWidth > 900 ? 900.0 : screenWidth * 0.95;
    final dialogHeight = screenHeight > 700 ? 700.0 : screenHeight * 0.9;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PLARIDEL COMMUNITY HOSPITAL',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stock Card Request Form',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            const Divider(height: 24),

            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  _buildTableHeader('DATE', flex: 2),
                  _buildTableHeader('PRODUCT NAME', flex: 3),
                  _buildTableHeader('STOCK CARD\nQUANTITY', flex: 1),
                  _buildTableHeader('REQUESTED BY', flex: 2),
                  _buildTableHeader('PATIENT NAME\nOptional', flex: 2),
                  _buildTableHeader('DEPARTMENT', flex: 2),
                  _buildTableHeader('ACTION', flex: 1),
                ],
              ),
            ),

            // Table Body (Scrollable)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: _requestRows.asMap().entries.map((entry) {
                    final index = entry.key;
                    final row = entry.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Date
                          Expanded(
                            flex: 2,
                            child: InkWell(
                              onTap: () => _selectDate(context, index),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDate(row['date']),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Product Name
                          Expanded(
                            flex: 3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  hint: const Text('Select product', style: TextStyle(fontSize: 12)),
                                  value: row['product'],
                                  items: _products.map((product) {
                                    return DropdownMenuItem(
                                      value: product,
                                      child: Text(product, style: const TextStyle(fontSize: 12)),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _requestRows[index]['product'] = value;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Quantity
                          Expanded(
                            flex: 1,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                hintText: '0',
                                hintStyle: const TextStyle(fontSize: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                              ),
                              style: const TextStyle(fontSize: 12),
                              onChanged: (value) {
                                setState(() {
                                  _requestRows[index]['quantity'] = int.tryParse(value) ?? 0;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Requested By
                          Expanded(
                            flex: 2,
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Enter your name',
                                hintStyle: const TextStyle(fontSize: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              ),
                              style: const TextStyle(fontSize: 12),
                              onChanged: (value) {
                                setState(() {
                                  _requestRows[index]['requestedBy'] = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Patient Name
                          Expanded(
                            flex: 2,
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Enter patient name',
                                hintStyle: const TextStyle(fontSize: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              ),
                              style: const TextStyle(fontSize: 12),
                              onChanged: (value) {
                                setState(() {
                                  _requestRows[index]['patientName'] = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Department
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  hint: const Text('Select department', style: TextStyle(fontSize: 12)),
                                  value: row['department'],
                                  items: _departments.map((dept) {
                                    return DropdownMenuItem(
                                      value: dept,
                                      child: Text(dept, style: const TextStyle(fontSize: 12)),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _requestRows[index]['department'] = value;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Delete Action
                          Expanded(
                            flex: 1,
                            child: IconButton(
                              onPressed: () => _removeRow(index),
                              icon: Icon(Icons.delete_outline, color: Colors.grey[600], size: 20),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _addNewRow,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Row'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _dispense,
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Dispense'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(String title, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
    );
  }
}
