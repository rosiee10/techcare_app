import 'package:flutter/material.dart';

/// Review Purchase Request Dialog for Chief Nurse
/// Table-style design with editable quantities
class ReviewPRDialog extends StatefulWidget {
  final Map<String, dynamic> purchaseRequest;
  final Function(Map<String, dynamic> updatedPR, String action) onAction;

  const ReviewPRDialog({
    super.key,
    required this.purchaseRequest,
    required this.onAction,
  });

  static Future<void> show({
    required BuildContext context,
    required Map<String, dynamic> purchaseRequest,
    required Function(Map<String, dynamic> updatedPR, String action) onAction,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ReviewPRDialog(
        purchaseRequest: purchaseRequest,
        onAction: onAction,
      ),
    );
  }

  @override
  State<ReviewPRDialog> createState() => _ReviewPRDialogState();
}

class _ReviewPRDialogState extends State<ReviewPRDialog> {
  late List<Map<String, dynamic>> _editableItems;
  late double _grandTotal;
  final Map<int, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _editableItems = List<Map<String, dynamic>>.from(
      widget.purchaseRequest['itemsList'].map((item) => Map<String, dynamic>.from(item)),
    );
    _calculateGrandTotal();
    // Initialize controllers
    for (int i = 0; i < _editableItems.length; i++) {
      _controllers[i] = TextEditingController(text: _editableItems[i]['qty'].toString());
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _calculateGrandTotal() {
    _grandTotal = _editableItems.fold<double>(
      0,
      (sum, item) => sum + ((item['total'] ?? 0) as double),
    );
  }

  void _updateQuantity(int index, String value) {
    final newQty = int.tryParse(value) ?? _editableItems[index]['qty'];
    final unitPrice = _editableItems[index]['unitPrice'] as double;

    setState(() {
      _editableItems[index]['qty'] = newQty;
      _editableItems[index]['qty_requested'] = newQty;
      _editableItems[index]['total'] = newQty * unitPrice;
      _calculateGrandTotal();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _editableItems.removeAt(index);
      _controllers[index]?.dispose();
      _controllers.remove(index);
      // Rebuild controllers map
      final newControllers = <int, TextEditingController>{};
      for (int i = 0; i < _editableItems.length; i++) {
        newControllers[i] = TextEditingController(text: _editableItems[i]['qty'].toString());
      }
      _controllers.clear();
      _controllers.addAll(newControllers);
      _calculateGrandTotal();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pr = widget.purchaseRequest;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 800,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with title and status
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Review Purchase Request',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.amber.shade800),
                        const SizedBox(width: 4),
                        Text(
                          'Pending',
                          style: TextStyle(
                            color: Colors.amber.shade800,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PURCHASE REQUEST Title
                    const Center(
                      child: Text(
                        'PURCHASE REQUEST',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // PR Details Grid
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow('LGU:', pr['lgu'] ?? 'PLARIDEL'),
                              _buildDetailRow('Department:', pr['department'] ?? 'PCH'),
                              _buildDetailRow('Section:', pr['section'] ?? 'Pharmacy'),
                            ],
                          ),
                        ),
                        // Middle column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _buildDetailRow('PR No.:', pr['prNo'] ?? 'N/A'),
                              _buildDetailRow('FPP:', pr['fpp'] ?? 'N/A'),
                            ],
                          ),
                        ),
                        // Right column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildDetailRow('Fund:', pr['fund'] ?? 'General Fund', alignRight: true),
                              _buildDetailRow('Date:', pr['date'] ?? 'Invalid Date', alignRight: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow('Requested by:', pr['requestedBy'] ?? 'Pharmacist'),
                    const SizedBox(height: 24),
                    // Items Table
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        children: [
                          // Table Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                            ),
                            child: Row(
                              children: [
                                _buildHeaderCell('Item No.', flex: 1),
                                _buildHeaderCell('Qty.', flex: 2),
                                _buildHeaderCell('Unit', flex: 2),
                                _buildHeaderCell('Name of Supplies/Materials/Services', flex: 6),
                                _buildHeaderCell('Unit Price', flex: 3),
                                _buildHeaderCell('Total', flex: 3),
                                _buildHeaderCell('Action', flex: 2),
                              ],
                            ),
                          ),
                          // Table Rows
                          ..._editableItems.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: index < _editableItems.length - 1
                                      ? BorderSide(color: Colors.grey.shade200)
                                      : BorderSide.none,
                                ),
                              ),
                              child: Row(
                                children: [
                                  _buildDataCell('${index + 1}', flex: 1),
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: _controllers[index],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (value) => _updateQuantity(index, value),
                                    ),
                                  ),
                                  _buildDataCell(item['unit'] ?? 'pcs', flex: 2),
                                  _buildDataCell(item['name'] ?? 'Unknown', flex: 6, alignLeft: true),
                                  _buildDataCell(
                                    '₱${(item['unitPrice'] ?? 0).toStringAsFixed(2)}',
                                    flex: 3,
                                  ),
                                  _buildDataCell(
                                    '₱${(item['total'] ?? 0).toStringAsFixed(2)}',
                                    flex: 3,
                                    bold: true,
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Center(
                                      child: TextButton(
                                        onPressed: () => _removeItem(index),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text(
                                          'Remove',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          // Grand Total Row
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              border: Border(top: BorderSide(color: Colors.grey.shade300)),
                            ),
                            child: Row(
                              children: [
                                const Spacer(flex: 11),
                                const Text(
                                  'GRAND TOTAL:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    '₱${_grandTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const Spacer(flex: 2),
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
            const Divider(height: 1),
            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      final updatedPR = Map<String, dynamic>.from(pr);
                      final itemsWithApprovedQty = _editableItems.map((item) => {
                        ...item,
                        'approved_qty': item['qty_requested'],
                      }).toList();
                      updatedPR['itemsList'] = itemsWithApprovedQty;
                      updatedPR['totalCost'] = _grandTotal;
                      widget.onAction(updatedPR, 'Approved');
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      widget.onAction(pr, 'Rejected');
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.cancel),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  Widget _buildDetailRow(String label, String value, {bool alignRight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, {required int flex, bool alignLeft = false, bool bold = false}) {
    return Expanded(
      flex: flex,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: alignLeft ? TextAlign.left : TextAlign.center,
        ),
      ),
    );
  }
}
