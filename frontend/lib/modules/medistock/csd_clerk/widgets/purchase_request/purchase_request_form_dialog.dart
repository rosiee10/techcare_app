import 'package:flutter/material.dart';

/// Create Purchase Request Dialog for CSD Clerk
/// Shows the purchase request form directly (single stage)
class CreateRequestDialog extends StatefulWidget {
  const CreateRequestDialog({super.key});

  @override
  State<CreateRequestDialog> createState() => _CreateRequestDialogState();

  /// Show the dialog
  static Future<dynamic> show(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CreateRequestDialog(),
    );
  }
}

class _CreateRequestDialogState extends State<CreateRequestDialog> {
  String _stage = 'form'; // Start directly at form stage
  String _selectedPurchaseType = 'regular'; // 'regular' or 'emergency'

  // Form controllers
  final TextEditingController _prNumberController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _fundController = TextEditingController();

  // Purchase request items
  List<Map<String, dynamic>> _items = [];
  
  // Medicines from inventory (fetched from backend)
  List<Map<String, dynamic>> _inventoryMedicines = [];
  bool _isLoadingMedicines = false;
  String? _medicineError;

  @override
  void initState() {
    super.initState();
    _fetchInventoryMedicines();
    _fetchNextPrNumber(); // Pre-fetch next PR number
    _addNewRow();
    
    // Set today's date as default
    final now = DateTime.now();
    _dateController.text = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  // Fetch purchase requests to determine next PR number
  Future<void> _fetchNextPrNumber() async {
    // Mock PR number generation - start with PR-007
    setState(() {
      _prNumberController.text = 'PR-007';
    });
  }

  /// Fetch supplies from inventory (mock data for CSD)
  Future<void> _fetchInventoryMedicines() async {
    setState(() {
      _isLoadingMedicines = true;
      _medicineError = null;
    });
    
    // Mock supplies data for CSD Clerk
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _inventoryMedicines = [
        {'medicine_id': 1, 'name': 'Surgical Gloves (Large)', 'category': 'Medical Supplies', 'unit': 'box', 'unit_cost': 150.0, 'available_stock': 50},
        {'medicine_id': 2, 'name': 'Disposable Syringes', 'category': 'Medical Supplies', 'unit': 'pcs', 'unit_cost': 25.0, 'available_stock': 120},
        {'medicine_id': 3, 'name': 'Gauze Pads', 'category': 'Medical Supplies', 'unit': 'pack', 'unit_cost': 75.0, 'available_stock': 75},
        {'medicine_id': 4, 'name': 'Alcohol Swabs', 'category': 'Medical Supplies', 'unit': 'box', 'unit_cost': 45.0, 'available_stock': 200},
        {'medicine_id': 5, 'name': 'Bandage Rolls', 'category': 'Medical Supplies', 'unit': 'pcs', 'unit_cost': 35.0, 'available_stock': 60},
        {'medicine_id': 6, 'name': 'Cotton Balls', 'category': 'Medical Supplies', 'unit': 'pack', 'unit_cost': 25.0, 'available_stock': 100},
      ];
      _isLoadingMedicines = false;
    });
  }

  @override
  void dispose() {
    _prNumberController.dispose();
    _dateController.dispose();
    _fundController.dispose();
    for (var item in _items) {
      item['qtyController'].dispose();
      item['unitController'].dispose();
      item['priceController'].dispose();
    }
    super.dispose();
  }

  void _addNewRow() {
    setState(() {
      final qtyController = TextEditingController();
      final priceController = TextEditingController();
      
      // Add listeners to auto-calculate total when qty or price changes
      qtyController.addListener(() => setState(() {}));
      priceController.addListener(() => setState(() {}));
      
      _items.add({
        'product': '', // Empty initially, user can select or type
        'qtyController': qtyController,
        'unitController': TextEditingController(),
        'priceController': priceController,
      });
    });
  }

  void _removeRow(int index) {
    if (_items.length > 1) {
      setState(() {
        _items[index]['qtyController'].dispose();
        _items[index]['unitController'].dispose();
        _items[index]['priceController'].dispose();
        _items.removeAt(index);
      });
    }
  }

  double _calculateTotal() {
    double total = 0;
    for (var item in _items) {
      final qty = int.tryParse(item['qtyController'].text) ?? 0;
      final price = double.tryParse(item['priceController'].text) ?? 0;
      total += qty * price;
    }
    return total;
  }

  // Removed: _onCreatePurchaseRequest() and _onBack() - no longer needed
  // Dialog now starts directly at form stage

  void _onSubmit() async {
    // Validate required fields (PR number is now auto-generated if empty)
    // Date is pre-filled with today's date but user can change it
    if (_dateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Validate items
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    for (var item in _items) {
      if (item['product'].toString().trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a medicine for all items'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final qty = int.tryParse(item['qtyController'].text) ?? 0;
      if (qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter valid quantity for all items'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      // Build items data
      final itemsData = _items.map((item) {
        final qty = int.tryParse(item['qtyController'].text) ?? 0;
        final price = double.tryParse(item['priceController'].text) ?? 0.0;
        return {
          'medicine_name': item['product'],
          'quantity': qty,
          'unit': item['unitController'].text,
          'unit_price': price,
          'total_price': qty * price,
        };
      }).toList();
      
      // Convert date from DD/MM/YYYY to YYYY-MM-DD
      final dateParts = _dateController.text.split('/');
      final isoDate = dateParts.length == 3 
          ? '${dateParts[2]}-${dateParts[1]}-${dateParts[0]}'
          : _dateController.text;
      
      // Build purchase request data
      final purchaseRequestData = {
        'pr_no': _prNumberController.text.trim(),
        'requested_date': isoDate,
        'purchase_type': _selectedPurchaseType.toUpperCase(),
        'pr_status': 'DRAFT',
        'items': itemsData,
      };
      
      print('Submitting Purchase Request: $purchaseRequestData');
      
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show success message with PR number
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase Request ${_prNumberController.text} created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Close dialog and return success
      Navigator.of(context).pop(true);
      
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating Purchase Request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildFormStage();
  }

  // Stage 2: Purchase Request Form
  Widget _buildFormStage() {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 900,
        constraints: const BoxConstraints(maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Create Purchase Request',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PURCHASE REQUEST Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black87, width: 1.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: Text(
                          'PURCHASE REQUEST',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Form Fields Grid
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black87, width: 1),
                      ),
                      child: Column(
                        children: [
                          // Row 1: LGU and Fund
                          IntrinsicHeight(
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildFormRow('LGU:', 'PLARIDEL'),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: _buildInputRow('Fund:', _fundController),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Colors.black87),
                          // Row 2: Department, PR No, Date
                          IntrinsicHeight(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildFormRow('Department:', 'PCH'),
                                ),
                                Expanded(
                                  child: _buildInputRow('PR No.:', _prNumberController, hintText: 'Auto (PR-001, PR-002...)'),
                                ),
                                Expanded(
                                  child: _buildDateRow(),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Colors.black87),
                          // Row 3: Section
                          _buildFormRow('Section:', 'FPP'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Items Table
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black87, width: 1),
                      ),
                      child: Column(
                        children: [
                          // Table Header
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              border: const Border(
                                bottom: BorderSide(color: Colors.black87, width: 1),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Expanded(
                                  flex: 1,
                                  child: Text(
                                    'ITEM\nNO.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Text(
                                      'Qty.',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Text(
                                      'Unit',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 5,
                                  child: Center(
                                    child: Text(
                                      'Name of Supplies/Materials/Services Etc.',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Text(
                                      'UNIT\nPRICE',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Text(
                                      'TOTAL',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Table Rows
                          ..._items.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            return _buildItemRow(index, item);
                          }).toList(),
                          // Total Row
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.black87, width: 1),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Expanded(flex: 12, child: SizedBox()),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'TOTAL AMOUNT:',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '₱${_calculateTotal().toStringAsFixed(2)}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Add Row Button
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _addNewRow,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Row'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_items.length} item(s)',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            // Footer Buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Submit Purchase Request',
                      style: TextStyle(fontWeight: FontWeight.w600),
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

  Widget _buildFormRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  height: 1,
                  color: Colors.black54,
                  margin: const EdgeInsets.only(top: 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow(String label, TextEditingController controller, {String? hintText}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.black87, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  style: const TextStyle(fontSize: 11),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: hintText,
                    hintStyle: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  ),
                ),
                Container(
                  height: 1,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.black87, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Date:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() {
                    _dateController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                  });
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _dateController.text.isEmpty ? 'dd/mm/yyyy' : _dateController.text,
                          style: TextStyle(
                            fontSize: 11,
                            color: _dateController.text.isEmpty ? Colors.grey : Colors.black87,
                          ),
                        ),
                      ),
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                    ],
                  ),
                  Container(
                    height: 1,
                    color: Colors.black54,
                    margin: const EdgeInsets.only(top: 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(int index, Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[400]!),
        ),
      ),
      child: Row(
        children: [
          // Item No.
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          // Qty
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: item['qtyController'],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 11),
                decoration: InputDecoration(
                  hintText: 'Qty',
                  hintStyle: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF2563EB)),
                  ),
                ),
                onChanged: (value) {
                  // Update the item quantity and trigger rebuild for total calculation
                  setState(() {});
                },
              ),
            ),
          ),
          // Unit
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: item['unitController'],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11),
                decoration: InputDecoration(
                  hintText: 'Unit',
                  hintStyle: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF2563EB)),
                  ),
                ),
              ),
            ),
          ),
          // Product Dropdown with Autocomplete (Searchable)
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildSearchableMedicineField(item),
            ),
          ),
          // Unit Price
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  const Text('₱', style: TextStyle(fontSize: 10)),
                  Expanded(
                    child: TextField(
                      controller: item['priceController'],
                      textAlign: TextAlign.right,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 11),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: TextStyle(fontSize: 11, color: Colors.grey[400]),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[400]!),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[400]!),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF2563EB)),
                        ),
                      ),
                      onChanged: (value) {
                        // Trigger rebuild for total calculation
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Total
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                '₱${_calculateItemTotal(item).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build searchable medicine field with autocomplete
  /// Allows selecting from inventory OR typing custom medicine name
  Widget _buildSearchableMedicineField(Map<String, dynamic> item) {
    // Get medicine names from inventory for autocomplete suggestions
    final List<String> medicineNames = _isLoadingMedicines
        ? []
        : _inventoryMedicines
            .map((med) => med['name'].toString())
            .where((name) => name != 'Unknown')
            .toList();

    // If loading, show loading indicator
    if (_isLoadingMedicines) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Loading medicines...',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // If there's an error, show a simple text field
    if (_medicineError != null) {
      return TextField(
        controller: TextEditingController(text: item['product'] ?? ''),
        onChanged: (value) => item['product'] = value,
        style: const TextStyle(fontSize: 11),
        decoration: InputDecoration(
          hintText: 'Type medicine name',
          hintStyle: TextStyle(fontSize: 11, color: Colors.grey[400]),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFF2563EB)),
          ),
        ),
      );
    }

    // Use Autocomplete widget for searchable dropdown
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: item['product'] ?? ''),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return medicineNames;
        }
        return medicineNames.where((String name) {
          return name.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        setState(() {
          item['product'] = selection;
          // Auto-fill unit and price if found in inventory
          final foundMed = _inventoryMedicines.firstWhere(
            (med) => med['name'] == selection,
            orElse: () => <String, dynamic>{},
          );
          if (foundMed.isNotEmpty) {
            // Debug: print available fields
            print('Selected medicine: $selection');
            print('Available fields: ${foundMed.keys.toList()}');
            
            // Auto-fill unit
            if (foundMed['unit'] != null) {
              item['unitController'].text = foundMed['unit'].toString();
            }
            // Try multiple possible price field names
            double? price;
            final possiblePriceFields = ['unit_cost', 'price', 'reference_price', 'cost', 'unit_price'];
            for (final field in possiblePriceFields) {
              if (foundMed[field] != null) {
                final val = foundMed[field];
                if (val is num) {
                  price = val.toDouble();
                  print('Found price in field "$field": $price');
                  break;
                } else if (val is String) {
                  price = double.tryParse(val);
                  if (price != null) {
                    print('Found price in field "$field": $price');
                    break;
                  }
                }
              }
            }
            if (price != null && price > 0) {
              item['priceController'].text = price.toString();
              print('Set price to: ${item['priceController'].text}');
            } else {
              print('No price found in medicine data');
            }
          }
        });
      },
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController textEditingController,
        FocusNode focusNode,
        VoidCallback onFieldSubmitted,
      ) {
        // Sync the controller with item['product']
        if (item['product'] != null && item['product'] != textEditingController.text) {
          textEditingController.text = item['product'];
        }
        
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          onChanged: (value) {
            item['product'] = value;
          },
          style: const TextStyle(fontSize: 11),
          decoration: InputDecoration(
            hintText: 'Select or type medicine...',
            hintStyle: TextStyle(fontSize: 11, color: Colors.grey[400]),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
            suffixIcon: Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: Colors.grey[600],
            ),
          ),
        );
      },
      optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(4),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: index < options.length - 1
                            ? Border(bottom: BorderSide(color: Colors.grey[200]!))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.medication_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              option,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  double _calculateItemTotal(Map<String, dynamic> item) {
    final qty = int.tryParse(item['qtyController'].text) ?? 0;
    final price = double.tryParse(item['priceController'].text) ?? 0;
    return qty * price;
  }
}
