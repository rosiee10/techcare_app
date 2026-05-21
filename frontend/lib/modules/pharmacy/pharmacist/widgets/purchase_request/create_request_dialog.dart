import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/pharmacy_service.dart';

/// Create Purchase Request Dialog
/// Two-stage: 1) Select purchase type, 2) Fill purchase request form
/// Fetches real medicines from inventory backend
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
  String _stage = 'select'; // 'select' or 'form'
  String _selectedPurchaseType = 'regular'; // 'regular' or 'emergency'

  // Form controllers
  final TextEditingController _prNumberController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _fundController = TextEditingController();

  // Purchase request items
  List<Map<String, dynamic>> _items = [];
  Map<int, Timer?> _debounceTimers = {};
  
  // Medicines from inventory (fetched from backend)
  List<Map<String, dynamic>> _inventoryMedicines = [];
  bool _isLoadingMedicines = false;
  String? _medicineError;

  // Common units and categories for suggestions
  final List<String> _commonUnits = [
    'Piece', 'Tablet', 'Capsule', 'Bottle', 'Vial', 'Ampule', 'Box', 'Kit', 'Tube', 'Sachet', 'Roll', 'Pack'
  ];
  
  final List<String> _commonCategories = [
    'Analgesics', 'Antibiotics', 'Antivirals', 'Vitamins', 'Supplements', 'Cardiovascular', 
    'Dermatological', 'Gastrointestinal', 'Hormonal', 'Respiratory', 'Neurological', 
    'Ophthalmic', 'Emergency', 'Supplies', 'Others'
  ];

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
    try {
      final pharmacyService = PharmacyService();
      final purchaseRequests = await pharmacyService.getPurchaseRequests();
      
      int nextNumber = 1;
      if (purchaseRequests.isNotEmpty) {
        // Find the highest PR number
        int maxNum = 0;
        for (final pr in purchaseRequests) {
          final prNo = pr['pr_no']?.toString() ?? '';
          if (prNo.isNotEmpty) {
            // Extract number from PR-001 format
            final digits = RegExp(r'\d+').allMatches(prNo).map((m) => m.group(0)).last;
            if (digits != null) {
              final num = int.tryParse(digits) ?? 0;
              if (num > maxNum) maxNum = num;
            }
          }
        }
        nextNumber = maxNum + 1;
      }
      
      setState(() {
        _prNumberController.text = 'PR-${nextNumber.toString().padLeft(3, '0')}';
      });
    } catch (e) {
      print('Error fetching PR number: $e');
      // If error, just start with PR-001
      setState(() {
        _prNumberController.text = 'PR-001';
      });
    }
  }

  /// Fetch medicines from backend inventory
  Future<void> _fetchInventoryMedicines() async {
    setState(() {
      _isLoadingMedicines = true;
      _medicineError = null;
    });
    
    try {
      final pharmacyService = PharmacyService();
      final medicines = await pharmacyService.getMedicines();
      
      setState(() {
        _inventoryMedicines = medicines.map((med) {
          return {
            'medicine_id': med['medicine_id'] ?? med['id'],
            'name': med['medicine_name'] ?? med['generic_name'] ?? med['name'] ?? 'Unknown',
            'category': med['category'] ?? 'Uncategorized',
            'unit': med['unit'] ?? med['unit_of_measure'] ?? 'N/A',
            'unit_cost': med['unit_cost'] ?? med['price'] ?? med['reference_price'] ?? 0,
            'available_stock': med['available_stock'] ?? 0,
          };
        }).toList();
        _isLoadingMedicines = false;
      });
    } catch (e) {
      setState(() {
        _medicineError = 'Failed to load medicines: $e';
        _isLoadingMedicines = false;
      });
    }
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
      final categoryController = TextEditingController();
      final medicineFocusNode = FocusNode();
      final showCategoryNotifier = ValueNotifier<bool>(false);
      
      final item = {
        'product': '', // Empty initially, user can select or type
        'qtyController': qtyController,
        'unitController': TextEditingController(),
        'categoryController': categoryController,
        'priceController': priceController,
        'medicineFocusNode': medicineFocusNode,
        'isNew': false,
        'showCategoryNotifier': showCategoryNotifier,
        'fieldKey': GlobalKey(), // Stable key for focus management
      };

      // Add listeners to auto-calculate total when qty or price changes
      qtyController.addListener(() => setState(() {}));
      priceController.addListener(() => setState(() {}));
      categoryController.addListener(() => setState(() {}));
      
      _items.add(item);
    });
  }

  void _removeRow(int index) {
    if (_items.length > 1) {
      setState(() {
        _items[index]['qtyController'].dispose();
        _items[index]['unitController'].dispose();
        _items[index]['categoryController'].dispose();
        _items[index]['priceController'].dispose();
        _items[index]['medicineFocusNode'].dispose();
        (_items[index]['showCategoryNotifier'] as ValueNotifier<bool>).dispose();
        _debounceTimers[index]?.cancel();
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

  void _onCreatePurchaseRequest() {
    setState(() {
      _stage = 'form';
    });
  }

  void _onBack() {
    setState(() {
      _stage = 'select';
    });
  }

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
      final pharmacyService = PharmacyService();
      
      // Build items data
      final itemsData = _items.map((item) {
        final qty = int.tryParse(item['qtyController'].text) ?? 0;
        final price = double.tryParse(item['priceController'].text) ?? 0.0;
        return {
          'medicine_name': item['product'],
          'quantity': qty,
          'unit': item['unitController'].text,
          'category': item['isNew'] ? item['categoryController'].text : null,
          'unit_price': price,
          'total_price': qty * price,
        };
      }).toList();
      
      // Convert date from DD/MM/YYYY to YYYY-MM-DD
      final dateParts = _dateController.text.split('/');
      final isoDate = dateParts.length == 3 
          ? '${dateParts[2]}-${dateParts[1]}-${dateParts[0]}'
          : _dateController.text;
      
      // Build purchase request data - match backend model field names
      final purchaseRequestData = {
        'pr_no': _prNumberController.text.trim(),
        'requested_date': isoDate,
        'purchase_type': _selectedPurchaseType.toUpperCase(),  // REGULAR or EMERGENCY
        'pr_status': 'DRAFT',
        'items': itemsData,
      };
      
      print('Submitting Purchase Request: $purchaseRequestData');
      
      // Submit to backend
      final result = await pharmacyService.createPurchaseRequest(purchaseRequestData);
      
      // Get the auto-generated PR number from response
      final generatedPrNo = result['pr_no'] ?? result['pr_number'] ?? '';
      if (generatedPrNo.isNotEmpty) {
        _prNumberController.text = generatedPrNo;
      }
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show success message with PR number
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase Request $generatedPrNo created successfully!'),
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
    if (_stage == 'select') {
      return _buildSelectStage();
    } else {
      return _buildFormStage();
    }
  }

  // Stage 1: Select Purchase Type
  Widget _buildSelectStage() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final dialogWidth = isMobile ? screenWidth * 0.98 : 600.0;

    return Dialog(
      insetPadding: EdgeInsets.all(isMobile ? 8 : 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
      ),
      child: Container(
        width: isMobile ? screenWidth * 0.98 : dialogWidth,
        constraints: BoxConstraints(
          maxHeight: isMobile ? MediaQuery.of(context).size.height * 0.46 : 550,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 24),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Create Purchase Request',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 20,
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
                padding: EdgeInsets.all(isMobile ? 12 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Purchase Type Label
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Purchase Type',
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          TextSpan(
                            text: ' *',
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isMobile ? 8 : 12),
                    // Purchase Type Options
                    isMobile
                      ? Column(
                          children: [
                            // Regular Purchase Request
                            _buildPurchaseTypeOption(
                              isMobile: isMobile,
                              type: 'regular',
                              icon: Icons.trending_up,
                              title: 'Regular Purchase Request',
                              description: 'Weekly inventory check and restock',
                              color: const Color(0xFF2563EB),
                            ),
                            SizedBox(height: isMobile ? 8 : 12),
                            // Emergency Purchase
                            _buildPurchaseTypeOption(
                              isMobile: isMobile,
                              type: 'emergency',
                              icon: Icons.warning_amber_outlined,
                              title: 'Emergency Purchase',
                              description: 'Urgent medicine requirement',
                              color: const Color(0xFFDC2626),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            // Regular Purchase Request
                            Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedPurchaseType = 'regular';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _selectedPurchaseType == 'regular'
                                    ? const Color(0xFFF0F7FF)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _selectedPurchaseType == 'regular'
                                      ? const Color(0xFF2563EB)
                                      : Colors.grey[300]!,
                                  width: _selectedPurchaseType == 'regular' ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.trending_up,
                                    color: _selectedPurchaseType == 'regular'
                                        ? const Color(0xFF2563EB)
                                        : Colors.grey[600],
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Regular Purchase Request',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: _selectedPurchaseType == 'regular'
                                                ? const Color(0xFF2563EB)
                                                : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Weekly inventory check and restock',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Emergency Purchase
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedPurchaseType = 'emergency';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _selectedPurchaseType == 'emergency'
                                    ? const Color(0xFFFFF5F5)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _selectedPurchaseType == 'emergency'
                                      ? const Color(0xFFDC2626)
                                      : Colors.grey[300]!,
                                  width: _selectedPurchaseType == 'emergency' ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_outlined,
                                    color: _selectedPurchaseType == 'emergency'
                                        ? const Color(0xFFDC2626)
                                        : Colors.grey[600],
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Emergency Purchase',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: _selectedPurchaseType == 'emergency'
                                                ? const Color(0xFFDC2626)
                                                : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Urgent medicine requirement',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // CSD Purchase Requests Label
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'CSD Purchase Requests from Central Supply',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          TextSpan(
                            text: ' *',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Empty State
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No CSD Purchase Requests',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No purchase requests forwarded from Central Supply Department at this time',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
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
            // Footer Buttons - Responsive
            Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: isMobile
                ? Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _onCreatePurchaseRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Create Purchase Request',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: _onCreatePurchaseRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Create Purchase Request',
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

  // Stage 2: Purchase Request Form
  Widget _buildFormStage() {
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
              padding: EdgeInsets.all(isMobile ? 12 : 24),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Create Purchase Request',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 20,
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
                padding: EdgeInsets.all(isMobile ? 12 : 24),
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
                                if (_items.any((item) => item['isNew'] == true && (item['showCategoryNotifier'] as ValueNotifier<bool>).value == true))
                                  Expanded(
                                    flex: 3,
                                    child: Center(
                                      child: Text(
                                        'Category',
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
            // Footer Buttons - Responsive
            Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: isMobile
                ? Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
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
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
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
      child: Column(
        children: [
          Row(
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
                      setState(() {});
                    },
                  ),
                ),
              ),
              // Unit (Searchable)
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildSearchableField(
                    controller: item['unitController'],
                    options: _commonUnits,
                    hint: 'Unit',
                  ),
                ),
              ),
              // Category (Searchable - only appears for new medicines that haven't been assigned yet)
              ValueListenableBuilder<bool>(
                valueListenable: item['showCategoryNotifier'] as ValueNotifier<bool>,
                builder: (context, showCategory, child) {
                  final anyItemHasCategory = _items.any((i) => (i['showCategoryNotifier'] as ValueNotifier<bool>).value);
                  if (!anyItemHasCategory) return const SizedBox.shrink();
                  
                  return Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: item['isNew'] && showCategory
                          ? _buildSearchableField(
                              controller: item['categoryController'],
                              options: _commonCategories,
                              hint: 'Category',
                              onSelected: (val) {
                                (item['showCategoryNotifier'] as ValueNotifier<bool>).value = false;
                              },
                            )
                          : const SizedBox(),
                    ),
                  );
                },
              ),
              // Product Dropdown with Autocomplete (Searchable)
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildSearchableMedicineField(index, item),
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
              // Delete Button
              IconButton(
                onPressed: () => _removeRow(index),
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper to build searchable autocomplete field for Unit and Category
  Widget _buildSearchableField({
    required TextEditingController controller,
    required List<String> options,
    required String hint,
    bool highlight = false,
    Function(String)? onSelected,
  }) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (TextEditingValue textEditingValue) {
        // Only show options if the user has typed at least one character
        // This prevents the dropdown from popping up automatically when the field appears
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return options.where((String option) {
          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        controller.text = selection;
        if (onSelected != null) onSelected(selection);
        setState(() {});
      },
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        // Keep controllers in sync
        if (controller.text != textController.text) {
          textController.text = controller.text;
        }
        return TextField(
          controller: textController,
          focusNode: focusNode,
          onChanged: (val) {
            controller.text = val;
            setState(() {});
          },
          style: TextStyle(
            fontSize: 11,
            color: highlight ? Colors.blue[700] : Colors.black87,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 10,
              color: highlight ? Colors.blue[300] : Colors.grey[400],
              fontStyle: highlight ? FontStyle.italic : FontStyle.normal,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: highlight ? Colors.blue : Colors.grey[400]!),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: highlight ? Colors.blue : Colors.grey[400]!),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: highlight ? Colors.blue[700]! : const Color(0xFF2563EB)),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(option, style: const TextStyle(fontSize: 11)),
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build searchable medicine field with autocomplete
  /// Allows selecting from inventory OR typing custom medicine name
  Widget _buildSearchableMedicineField(int index, Map<String, dynamic> item) {
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
          item['isNew'] = false;
          item['showCategory'] = false;
          
          // Auto-fill unit and price if found in inventory
          final foundMed = _inventoryMedicines.firstWhere(
            (med) => med['name'] == selection,
            orElse: () => <String, dynamic>{},
          );
          if (foundMed.isNotEmpty) {
            // Auto-fill unit
            if (foundMed['unit'] != null) {
              item['unitController'].text = foundMed['unit'].toString();
            }
            // Auto-fill category if exists
            if (foundMed['category'] != null) {
              item['categoryController'].text = foundMed['category'].toString();
            }
            
            // Try multiple possible price field names
            double? price;
            final possiblePriceFields = ['unit_cost', 'price', 'reference_price', 'cost', 'unit_price'];
            for (final field in possiblePriceFields) {
              if (foundMed[field] != null) {
                final val = foundMed[field];
                if (val is num) {
                  price = val.toDouble();
                  break;
                } else if (val is String) {
                  price = double.tryParse(val);
                  if (price != null) break;
                }
              }
            }
            if (price != null && price > 0) {
              item['priceController'].text = price.toString();
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
          // Move cursor to end to prevent jumping to start
          textEditingController.selection = TextSelection.fromPosition(
            TextPosition(offset: textEditingController.text.length),
          );
        }
        
        return TextField(
          key: item['fieldKey'] as GlobalKey,
          controller: textEditingController,
          focusNode: focusNode,
          onChanged: (value) {
            item['product'] = value;
            
            // Debounce logic: Wait until user is 'done' typing before showing Category
            _debounceTimers[index]?.cancel();
            _debounceTimers[index] = Timer(const Duration(milliseconds: 700), () {
              if (mounted) {
                final medicineName = value.trim();
                if (medicineName.isNotEmpty) {
                  final List<String> existingNames = _inventoryMedicines
                      .map((med) => med['name'].toString().toLowerCase())
                      .toList();
                  
                  final bool isExisting = existingNames.contains(medicineName.toLowerCase());
                  item['isNew'] = !isExisting;
                  // Update ValueNotifier instead of setState to avoid rebuilding medicine field
                  (item['showCategoryNotifier'] as ValueNotifier<bool>).value = !isExisting;
                } else {
                  item['isNew'] = false;
                  (item['showCategoryNotifier'] as ValueNotifier<bool>).value = false;
                }
              }
            });
          },
          onEditingComplete: () {
            // Immediately check when field is submitted/finished
            _debounceTimers[index]?.cancel();
            final medicineName = textEditingController.text.trim();
            final List<String> existingNames = _inventoryMedicines
                .map((med) => med['name'].toString().toLowerCase())
                .toList();
            final bool isExisting = existingNames.contains(medicineName.toLowerCase());
            item['isNew'] = !isExisting && medicineName.isNotEmpty;
            (item['showCategoryNotifier'] as ValueNotifier<bool>).value = item['isNew'];
            onFieldSubmitted();
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

  // Helper method for building purchase type option cards
  Widget _buildPurchaseTypeOption({
    required bool isMobile,
    required String type,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    final isSelected = _selectedPurchaseType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPurchaseType = type;
        });
      },
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: isMobile ? 24 : 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
