import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/pharmacy_service.dart';

class MedicineDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> medicine;
  final List<Map<String, dynamic>> batches;

  const MedicineDetailsDialog({
    super.key,
    required this.medicine,
    required this.batches,
  });

  static Future<bool?> show(BuildContext context, {
    required Map<String, dynamic> medicine,
    required List<Map<String, dynamic>> batches,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => MedicineDetailsDialog(
        medicine: medicine,
        batches: batches,
      ),
    );
  }

  @override
  State<MedicineDetailsDialog> createState() => _MedicineDetailsDialogState();
}

class _MedicineDetailsDialogState extends State<MedicineDetailsDialog> {
  late List<Map<String, dynamic>> _currentBatches;
  final PharmacyService _pharmacyService = PharmacyService();
  bool _isProcessing = false;
  bool _anyRemoved = false;

  @override
  void initState() {
    super.initState();
    _currentBatches = List<Map<String, dynamic>>.from(widget.batches);
  }

  Future<void> _handleRemoveBatch(Map<String, dynamic> batch) async {
    final batchId = batch['batch_id'] ?? batch['id'];
    if (batchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Batch ID not found')),
      );
      return;
    }

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _RemoveBatchReasonDialog(batchNo: batch['batch_no'] ?? 'Unknown'),
    );

    if (result != null) {
      setState(() => _isProcessing = true);
      try {
        final response = await _pharmacyService.removeBatch(
          batchId,
          result['reason']!,
          result['remarks']!,
        );

        if (response['success'] == true) {
          setState(() {
            _currentBatches.removeWhere((b) => (b['batch_id'] ?? b['id']) == batchId);
            _isProcessing = false;
            _anyRemoved = true;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response['message'] ?? 'Batch removed successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        setState(() => _isProcessing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing batch: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final dialogWidth = isMobile ? screenWidth * 0.95 : 600.0;
    
    final medicineName = widget.medicine['medicine_name'] ?? 'Unknown';
    final price = widget.medicine['price'] ?? '₱0.00';
    final totalQty = widget.medicine['total_quantity'] ?? '0';
    final unit = widget.medicine['unit'] ?? 'N/A';
    final status = widget.medicine['status'] ?? 'Active';

    // Sort batches by expiry date
    final sortedBatches = List<Map<String, dynamic>>.from(_currentBatches)
      ..sort((a, b) {
        final dateA = DateTime.tryParse(a['expiry_date'] ?? '') ?? DateTime(9999);
        final dateB = DateTime.tryParse(b['expiry_date'] ?? '') ?? DateTime(9999);
        return dateA.compareTo(dateB);
      });

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          Container(
            width: dialogWidth,
            constraints: BoxConstraints(
              maxHeight: isMobile ? screenWidth * 0.9 : 700,
              maxWidth: 600,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header (Fixed)
                Padding(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.layers_outlined,
                          color: Color(0xFF9333EA),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Medicine Details & Batch Management',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              medicineName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(_anyRemoved),
                        icon: const Icon(Icons.close),
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),

                // Scrollable Content (Medicine Info + Batches)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Medicine Information Section
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                          child: Container(
                            padding: EdgeInsets.all(isMobile ? 16 : 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: Color(0xFF2563EB),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Medicine Information',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.edit, size: 14),
                                      label: const Text('Edit Medicine Details'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(0xFF2563EB),
                                        textStyle: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow('MEDICINE NAME', medicineName),
                                const SizedBox(height: 12),
                                isMobile
                                  ? Column(
                                      children: [
                                        _buildInfoRow('PRICE (₱)', price),
                                        const SizedBox(height: 12),
                                        _buildInfoRow('TOTAL QUANTITY', '$totalQty units'),
                                        const SizedBox(height: 12),
                                        _buildInfoRow('UNIT', unit),
                                        const SizedBox(height: 12),
                                        _buildInfoRow('STATUS', status),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Expanded(child: _buildInfoRow('PRICE (₱)', price)),
                                        const SizedBox(width: 16),
                                        Expanded(child: _buildInfoRow('TOTAL QUANTITY', '$totalQty units')),
                                      ],
                                    ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(child: _buildInfoRow('UNIT', unit)),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildInfoRow('STATUS', status)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Batches Section
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'All Batches (Sorted by Expiry Date)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ),

                        // Batch List
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                          child: Column(
                            children: sortedBatches.asMap().entries.map((entry) {
                              final index = entry.key;
                              final batch = entry.value;
                              final isFirst = index == 0;
                              return _buildBatchCard(batch, isFirst, index + 1, isMobile);
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black12,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey[500],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildBatchCard(Map<String, dynamic> batch, bool isFirst, int number, bool isMobile) {
    final batchNo = batch['batch_no'] ?? 'Unknown';
    final quantity = batch['quantity'] ?? batch['qty_on_hand'] ?? batch['stock_quantity'] ?? '0';
    final expiryDate = batch['expiry_date'] ?? '';
    final receivedDate = batch['received_date'] ?? batch['created_at'] ?? '';
    
    // Format the received date
    String formattedReceivedDate = 'N/A';
    if (receivedDate.isNotEmpty) {
      final date = DateTime.tryParse(receivedDate);
      if (date != null) {
        formattedReceivedDate = '${date.month}/${date.day}/${date.year}';
      }
    }
    
    final expiry = DateTime.tryParse(expiryDate);
    final now = DateTime.now();
    final daysUntilExpiry = expiry != null ? expiry.difference(now).inDays : 0;
    
    final isExpiringSoon = daysUntilExpiry <= 30 && daysUntilExpiry >= 0;
    final isExpired = daysUntilExpiry < 0;
    
    final statusText = isExpired ? 'Expired' : (isExpiringSoon ? 'Expiring Soon' : 'Good');
    final statusColor = isExpired 
        ? const Color(0xFFEF4444) 
        : (isExpiringSoon ? const Color(0xFFF59E0B) : const Color(0xFF22C55E));
    final statusBgColor = isExpired 
        ? const Color(0xFFFEE2E2) 
        : (isExpiringSoon ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isFirst ? const Color(0xFF9333EA) : Colors.grey[200]!,
          width: isFirst ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isFirst ? const Color(0xFFFDF4FF) : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Batch Header
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isFirst ? const Color(0xFF9333EA) : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isFirst ? Colors.white : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      batchNo,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    if (isFirst) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 12,
                            color: Color(0xFF9333EA),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'DISPENSE THIS FIRST',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF9333EA),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Batch Details - Responsive
          isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBatchDetail('Quantity', '$quantity units', isBold: true),
                  const SizedBox(height: 8),
                  _buildBatchDetail(
                    'Expiry Date',
                    expiryDate.isNotEmpty 
                        ? DateFormat('M/d/yyyy').format(DateTime.parse(expiryDate))
                        : 'N/A',
                  ),
                  const SizedBox(height: 8),
                  _buildBatchDetail(
                    'Days Until Expiry',
                    daysUntilExpiry >= 0 ? '$daysUntilExpiry days' : 'Expired',
                    valueColor: isExpiringSoon || isExpired ? statusColor : Colors.grey[700],
                  ),
                  const SizedBox(height: 8),
                  _buildBatchDetail(
                    'Received Date',
                    formattedReceivedDate,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _buildBatchDetail('Quantity', '$quantity units', isBold: true),
                  ),
                  Expanded(
                    child: _buildBatchDetail(
                      'Expiry Date',
                      expiryDate.isNotEmpty 
                          ? DateFormat('M/d/yyyy').format(DateTime.parse(expiryDate))
                          : 'N/A',
                    ),
                  ),
                  Expanded(
                    child: _buildBatchDetail(
                      'Days Until Expiry',
                      daysUntilExpiry >= 0 ? '$daysUntilExpiry days' : 'Expired',
                      valueColor: isExpiringSoon || isExpired ? statusColor : Colors.grey[700],
                    ),
                  ),
                  Expanded(
                    child: _buildBatchDetail(
                      'Received Date',
                      formattedReceivedDate,
                    ),
                  ),
                ],
              ),
          
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          
          // Remove Batch Button
          TextButton.icon(
            onPressed: () => _handleRemoveBatch(batch),
            icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444)),
            label: const Text(
              'Remove This Batch',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchDetail(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _RemoveBatchReasonDialog extends StatefulWidget {
  final String batchNo;

  const _RemoveBatchReasonDialog({required this.batchNo});

  @override
  State<_RemoveBatchReasonDialog> createState() => _RemoveBatchReasonDialogState();
}

class _RemoveBatchReasonDialogState extends State<_RemoveBatchReasonDialog> {
  String _selectedReason = 'DAMAGED';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Remove Batch: ${widget.batchNo}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Please select a reason for removal:'),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedReason,
            decoration: const InputDecoration(
              labelText: 'Reason',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'DAMAGED', child: Text('Damaged')),
              DropdownMenuItem(value: 'EXPIRED', child: Text('Expired')),
              DropdownMenuItem(value: 'DISPOSED', child: Text('Disposed')),
            ],
            onChanged: (val) => setState(() => _selectedReason = val!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop({
            'reason': _selectedReason,
            'remarks': '',
          }),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
          ),
          child: const Text('Remove Batch'),
        ),
      ],
    );
  }
}
