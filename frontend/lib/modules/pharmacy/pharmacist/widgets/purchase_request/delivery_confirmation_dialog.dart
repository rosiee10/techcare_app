import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/pharmacy_service.dart';

/// Delivery Confirmation Dialog for Pharmacist
/// Allows confirming delivered quantities, batch numbers, and expiry dates
class DeliveryConfirmationDialog extends StatefulWidget {
  final Map<String, dynamic> purchaseRequest;
  final Function(Map<String, dynamic> deliveryData) onSave;

  const DeliveryConfirmationDialog({
    super.key,
    required this.purchaseRequest,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required Map<String, dynamic> purchaseRequest,
    required Function(Map<String, dynamic> deliveryData) onSave,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeliveryConfirmationDialog(
        purchaseRequest: purchaseRequest,
        onSave: onSave,
      ),
    );
  }

  @override
  State<DeliveryConfirmationDialog> createState() => _DeliveryConfirmationDialogState();
}

class _DeliveryConfirmationDialogState extends State<DeliveryConfirmationDialog> {
  late List<Map<String, dynamic>> _deliveryItems;
  late List<TextEditingController> _qtyControllers;
  late List<TextEditingController> _batchControllers;
  late List<TextEditingController> _unitCostControllers;
  late List<DateTime?> _expiryDates;
  late TextEditingController _supplierController;
  List<dynamic> _existingBatches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize supplier controller immediately to avoid LateInitializationError
    _supplierController = TextEditingController();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    
    // Initialize delivery items from purchase request
    final items = widget.purchaseRequest['itemsList'] ?? widget.purchaseRequest['items'] ?? [];
    _deliveryItems = List<Map<String, dynamic>>.from(
      items.map((item) => Map<String, dynamic>.from(item)),
    );
    
    // Initialize controllers
    _qtyControllers = [];
    _batchControllers = [];
    _unitCostControllers = [];
    _expiryDates = [];
    
    // Fetch existing stock batches for each medicine in the request to avoid duplicates
    final Set<int> medicineIds = {};
    for (var item in _deliveryItems) {
      final id = item['medicine_id'] ?? item['id'] ?? (item['medicine'] is Map ? item['medicine']['medicine_id'] : item['medicine']);
      if (id != null) {
        final parsedId = int.tryParse(id.toString());
        if (parsedId != null) medicineIds.add(parsedId);
      }
    }

    try {
      final pharmacyService = PharmacyService();
      List<dynamic> allBatches = [];
      for (int id in medicineIds) {
        final batches = await pharmacyService.getMedicineBatches(id);
        allBatches.addAll(batches);
      }
      _existingBatches = allBatches;
    } catch (e) {
      print('Error fetching existing batches: $e');
      _existingBatches = [];
    }
    
    // Track batch sequences per medicine for this delivery
    final Map<String, int> medicineBatchCounters = {};
    
    for (int i = 0; i < _deliveryItems.length; i++) {
      // Use qty_received if available (for partial deliveries), otherwise use qty_ordered/qty_requested
      final qtyValue = _deliveryItems[i]['qty_received'] ?? 
                      _deliveryItems[i]['qty'] ?? 
                      _deliveryItems[i]['qty_requested'] ?? 0;
      _qtyControllers.add(TextEditingController(
        text: qtyValue.toString(),
      ));
      
      // Auto-generate batch number based on medicine name and existing batches
      final medicineName = _deliveryItems[i]['name'] ?? _deliveryItems[i]['medicine_name'] ?? '';
      final batchNumber = _generateBatchNumber(medicineName, medicineBatchCounters);
      _batchControllers.add(TextEditingController(text: batchNumber));
      _deliveryItems[i]['batch_number'] = batchNumber;
      
      // Initialize unit cost with estimated price
      _unitCostControllers.add(TextEditingController(
        text: (_deliveryItems[i]['unitPrice'] ?? _deliveryItems[i]['unit_price'] ?? '0.00').toString(),
      ));
      _expiryDates.add(null);
      _deliveryItems[i]['expiry_date'] = '';
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _generateBatchNumber(String medicineName, Map<String, int> counters) {
    if (medicineName.isEmpty) {
      final now = DateTime.now();
      final year = now.year.toString().substring(2);
      final random = now.millisecond.toString().padLeft(3, '0');
      return 'BATCH-$year-$random';
    }
    
    // Get first 4 letters of medicine name (uppercase)
    final medPrefix = medicineName.substring(0, medicineName.length > 4 ? 4 : medicineName.length).toUpperCase();
    
    // Find the highest existing batch number for this medicine from database
    int maxExistingSeq = 0;
    for (final batch in _existingBatches) {
      final batchNo = batch['batch_no']?.toString() ?? '';
      // Check if batch matches pattern BATCH-MEDPREFIX-XX
      final pattern = RegExp(r'^BATCH-([A-Z]+)-(\d+)$');
      final match = pattern.firstMatch(batchNo);
      if (match != null) {
        final existingPrefix = match.group(1);
        final existingSeq = int.tryParse(match.group(2) ?? '0') ?? 0;
        if (existingPrefix == medPrefix && existingSeq > maxExistingSeq) {
          maxExistingSeq = existingSeq;
        }
      }
    }
    
    // Get next sequence number (consider both existing batches and current delivery)
    final currentDeliverySeq = counters[medPrefix] ?? 0;
    final nextSeq = (maxExistingSeq > currentDeliverySeq ? maxExistingSeq : currentDeliverySeq) + 1;
    counters[medPrefix] = nextSeq;
    
    // Format: BATCH-MED4-XX
    return 'BATCH-$medPrefix-${nextSeq.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    for (var controller in _qtyControllers) {
      controller.dispose();
    }
    for (var controller in _batchControllers) {
      controller.dispose();
    }
    for (var controller in _unitCostControllers) {
      controller.dispose();
    }
    _supplierController.dispose();
    super.dispose();
  }

  void _updateQtyDelivered(int index, String value) {
    final newQty = int.tryParse(value) ?? 0;
    setState(() {
      _deliveryItems[index]['qty_delivered'] = newQty;
    });
  }

  Future<void> _selectExpiryDate(int index) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade600,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _expiryDates[index] = picked;
        _deliveryItems[index]['expiry_date'] = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  Future<void> _saveDelivery() async {
    // Validate all items have expiry dates
    for (var item in _deliveryItems) {
      if (item['expiry_date'] == null || item['expiry_date'].toString().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please set expiry date for all items')),
        );
        return;
      }
    }

    // Validate supplier name
    final supplierName = _supplierController.text.trim();
    if (supplierName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter supplier name')),
      );
      return;
    }

    // Get pr_id from rawData (actual database ID)
    final rawData = widget.purchaseRequest['rawData'] ?? {};
    final prId = rawData['pr_id'] ?? widget.purchaseRequest['pr_id'];
    
    if (prId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Could not find PR ID')),
      );
      return;
    }
    
    // Collect quantities and unit costs from controllers
    for (int i = 0; i < _deliveryItems.length; i++) {
      _deliveryItems[i]['qty_delivered'] = _qtyControllers[i].text;
      _deliveryItems[i]['unit_price'] = _unitCostControllers[i].text;
    }
    
    final itemsData = _deliveryItems.map((item) => {
      'pr_item_id': item['itemNo'] ?? item['pr_item_id'],
      'medicine_name': item['name'] ?? item['medicine_name'],
      'qty_requested': item['qty'] ?? item['qty_requested'],
      'qty_delivered': item['qty_delivered'] ?? item['qty'] ?? item['qty_requested'],
      'batch_number': item['batch_number'],
      'expiry_date': item['expiry_date'],
      'unit_price': item['unit_price'],
    }).toList();
    
    final deliveryData = {
      'pr_id': prId,
      'pr_no': widget.purchaseRequest['prNo'] ?? rawData['pr_no'],
      'supplier_name': supplierName,
      'items': itemsData,
      'delivery_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
    };

    try {
      await widget.onSave(deliveryData);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving delivery: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pr = widget.purchaseRequest;
    final prNo = pr['prNo'] ?? pr['pr_no'] ?? 'N/A';
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    // Show loading indicator while data is being initialized
    if (_isLoading) {
      return Dialog(
        insetPadding: EdgeInsets.all(isMobile ? 16 : 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isMobile ? 12 : 16)),
        child: Container(
          width: isMobile ? screenWidth * 0.8 : 400,
          height: isMobile ? 150 : 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: isMobile ? 12 : 16),
                Text('Loading...', style: TextStyle(fontSize: isMobile ? 14 : 16)),
              ],
            ),
          ),
        ),
      );
    }
    
    return Dialog(
      insetPadding: EdgeInsets.all(isMobile ? 8 : 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isMobile ? 12 : 16)),
      child: Container(
        width: isMobile ? screenWidth * 0.98 : 900,
        constraints: BoxConstraints(
          maxHeight: isMobile ? MediaQuery.of(context).size.height * 0.46 : MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Purchase Request Details',
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: isMobile ? 2 : 4),
                      Text(
                        prNo,
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 12 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status
                    Row(
                      children: [
                        Text(
                          'Status: ',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 12, vertical: isMobile ? 4 : 6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(isMobile ? 12 : 20),
                          ),
                          child: Text(
                            'Approved',
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.w600,
                              fontSize: isMobile ? 10 : 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    // Request Details
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Request Type',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Regular Purchase Request',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date Requested',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                pr['date']?.toString() ?? 'Invalid Date',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Date Approved
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date Approved',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('M/d/yyyy').format(DateTime.now()),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Supplier Name Input
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Supplier Name *',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _supplierController,
                          decoration: InputDecoration(
                            hintText: 'Enter supplier name',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                            prefixIcon: const Icon(Icons.business),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Items Section
                    const Text(
                      'Items',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Items Table
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          // Table Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                _buildHeaderCell('Medicine', flex: 3),
                                _buildHeaderCell('Qty Requested', flex: 2),
                                _buildHeaderCell('Qty Delivered', flex: 2),
                                _buildHeaderCell('Batch Number', flex: 3),
                                _buildHeaderCell('Unit Cost', flex: 2),
                                _buildHeaderCell('Expiry Date', flex: 2),
                              ],
                            ),
                          ),
                          // Table Rows
                          ..._deliveryItems.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: index < _deliveryItems.length - 1
                                      ? BorderSide(color: Colors.grey.shade200)
                                      : BorderSide.none,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Medicine Name
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      item['name'] ?? item['medicine_name'] ?? 'Unknown',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  // Qty Requested
                                  Expanded(
                                    flex: 2,
                                    child: Center(
                                      child: Text(
                                        (item['qty'] ?? item['qty_requested'] ?? 0).toString(),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                  // Qty Delivered (Editable)
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: TextField(
                                        controller: _qtyControllers[index],
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          border: OutlineInputBorder(),
                                        ),
                                        onChanged: (value) => _updateQtyDelivered(index, value),
                                      ),
                                    ),
                                  ),
                                  // Batch Number (Auto-generated, editable)
                                  Expanded(
                                    flex: 3,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: TextField(
                                        controller: _batchControllers[index],
                                        textAlign: TextAlign.center,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          border: OutlineInputBorder(),
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _deliveryItems[index]['batch_number'] = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  // Unit Cost (Editable)
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: TextField(
                                        controller: _unitCostControllers[index],
                                        textAlign: TextAlign.center,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          border: OutlineInputBorder(),
                                          hintText: '0.00',
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _deliveryItems[index]['unit_price'] = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  // Expiry Date Picker
                                  Expanded(
                                    flex: 2,
                                    child: GestureDetector(
                                      onTap: () => _selectExpiryDate(index),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade400),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              item['expiry_date']?.toString().isNotEmpty == true
                                                  ? item['expiry_date'].toString()
                                                  : 'Select',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: item['expiry_date']?.toString().isNotEmpty == true
                                                    ? Colors.black
                                                    : Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.calendar_today,
                                              size: 16,
                                              color: Colors.grey.shade600,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
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
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _saveDelivery,
                    icon: Icon(Icons.save, size: isMobile ? 18 : 20),
                    label: Text('Save Delivery & Restock Inventory', style: TextStyle(fontSize: isMobile ? 12 : 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 10 : 12),
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
  Widget _buildHeaderCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
