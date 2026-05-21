import 'package:flutter/material.dart';
import '../../services/pharmacy_service.dart';

/// Add New Medicine Dialog
/// Shows a form to add new medicine to inventory
class AddMedicineDialog extends StatefulWidget {
  const AddMedicineDialog({super.key});

  @override
  State<AddMedicineDialog> createState() => _AddMedicineDialogState();

  /// Show the dialog
  static Future<bool?> show(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AddMedicineDialog(),
    );
  }
}

class _AddMedicineDialogState extends State<AddMedicineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _medicineNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _reorderLevelController = TextEditingController(text: '100');
  final _batchNumberController = TextEditingController();
  final _quantityController = TextEditingController();
  final _expiryDateController = TextEditingController();

  String _selectedUnit = '';
  String _selectedCategory = '';
  String _generatedMedicineCode = '';

  final List<String> _units = ['Tablet', 'Capsule', 'Syrup', 'Injection', 'Drops', 'Ointment', 'Powder'];
  final List<String> _categories = ['Analgesics', 'Antibiotics', 'Antihistamines', 'Antiseptics', 'Cardiovascular', 'Gastrointestinal', 'Respiratory', 'Vitamins'];

  @override
  void initState() {
    super.initState();
    // Add listener to auto-generate batch number when medicine name changes
    _medicineNameController.addListener(_onMedicineNameChanged);
  }

  @override
  void dispose() {
    _medicineNameController.removeListener(_onMedicineNameChanged);
    _medicineNameController.dispose();
    _priceController.dispose();
    _reorderLevelController.dispose();
    _batchNumberController.dispose();
    _quantityController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  // Auto-generate batch number preview when medicine name changes
  void _onMedicineNameChanged() {
    final medicineName = _medicineNameController.text.trim();
    if (medicineName.isNotEmpty) {
      final code = _generateMedicineCode(medicineName);
      if (code != _generatedMedicineCode) {
        _generatedMedicineCode = code;
        // Generate preview batch number (will be finalized on submit)
        final previewBatch = 'BATCH-$code-01';
        _batchNumberController.text = previewBatch;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final dialogWidth = isSmallScreen ? screenWidth * 0.98 : 600.0;
    
    return Dialog(
      insetPadding: EdgeInsets.all(isSmallScreen ? 8 : 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
      ),
      child: Container(
        width: isSmallScreen ? screenWidth * 0.98 : dialogWidth,
        constraints: BoxConstraints(
          maxHeight: isSmallScreen ? MediaQuery.of(context).size.height * 0.46 : 700,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 24),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                    ),
                    child: Icon(Icons.add, color: const Color(0xFF1976D2), size: isSmallScreen ? 20 : 24),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 12),
                  Expanded(
                    child: Text(
                      'Add New Medicine',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
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
            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Medicine Name
                      _buildLabel('Medicine Name', required: true),
                      SizedBox(height: isSmallScreen ? 6 : 8),
                      _buildTextField(
                        controller: _medicineNameController,
                        hintText: 'e.g., Paracetamol 500mg',
                        required: true,
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      // Unit and Category Row - Responsive
                      isSmallScreen
                        ? Column(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Unit', required: true),
                                  SizedBox(height: isSmallScreen ? 6 : 8),
                                  _buildDropdown(
                                    value: _selectedUnit.isEmpty ? null : _selectedUnit,
                                    hintText: 'Select unit',
                                    items: _units,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedUnit = value ?? '';
                                      });
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: isSmallScreen ? 12 : 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Category', required: true),
                                  SizedBox(height: isSmallScreen ? 6 : 8),
                                  _buildDropdown(
                                    value: _selectedCategory.isEmpty ? null : _selectedCategory,
                                    hintText: 'Select category',
                                    items: _categories,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedCategory = value ?? '';
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Unit', required: true),
                                    SizedBox(height: isSmallScreen ? 6 : 8),
                                    _buildDropdown(
                                      value: _selectedUnit.isEmpty ? null : _selectedUnit,
                                      hintText: 'Select unit',
                                      items: _units,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedUnit = value ?? '';
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 12 : 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Category', required: true),
                                    SizedBox(height: isSmallScreen ? 6 : 8),
                                    _buildDropdown(
                                      value: _selectedCategory.isEmpty ? null : _selectedCategory,
                                      hintText: 'Select category',
                                      items: _categories,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedCategory = value ?? '';
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      // Price and Reorder Level Row - Responsive
                      isSmallScreen
                        ? Column(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Price (₱)', required: true),
                                  SizedBox(height: isSmallScreen ? 6 : 8),
                                  _buildTextField(
                                    controller: _priceController,
                                    hintText: '0.00',
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    required: true,
                                  ),
                                ],
                              ),
                              SizedBox(height: isSmallScreen ? 12 : 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Reorder Level', required: true),
                                  SizedBox(height: isSmallScreen ? 6 : 8),
                                  _buildTextField(
                                    controller: _reorderLevelController,
                                    hintText: '100',
                                    keyboardType: TextInputType.number,
                                    required: true,
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Price (₱)', required: true),
                                    SizedBox(height: isSmallScreen ? 6 : 8),
                                    _buildTextField(
                                      controller: _priceController,
                                      hintText: '0.00',
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      required: true,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 12 : 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Reorder Level', required: true),
                                    SizedBox(height: isSmallScreen ? 6 : 8),
                                    _buildTextField(
                                      controller: _reorderLevelController,
                                      hintText: '100',
                                      keyboardType: TextInputType.number,
                                      required: true,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      SizedBox(height: isSmallScreen ? 16 : 20),
                      const Divider(height: 1),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      // Initial Batch Information Section
                      Row(
                        children: [
                          Icon(Icons.layers, color: Colors.deepPurple[400], size: isSmallScreen ? 18 : 20),
                          SizedBox(width: isSmallScreen ? 6 : 8),
                          Expanded(
                            child: Text(
                              'Initial Batch Information',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      // Batch Number, Quantity, Expiry Date Row - Responsive
                      isSmallScreen
                        ? Column(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Batch Number', required: true),
                                  SizedBox(height: isSmallScreen ? 6 : 8),
                                  _buildTextField(
                                    controller: _batchNumberController,
                                    hintText: 'Auto-generated',
                                    readOnly: true,
                                  ),
                                ],
                              ),
                              SizedBox(height: isSmallScreen ? 12 : 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Quantity', required: true),
                                  SizedBox(height: isSmallScreen ? 6 : 8),
                                  _buildTextField(
                                    controller: _quantityController,
                                    hintText: '0',
                                    keyboardType: TextInputType.number,
                                    required: true,
                                  ),
                                ],
                              ),
                              SizedBox(height: isSmallScreen ? 12 : 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Expiry Date', required: true),
                                  SizedBox(height: isSmallScreen ? 6 : 8),
                                  _buildTextField(
                                    controller: _expiryDateController,
                                    hintText: 'YYYY-MM-DD',
                                    required: true,
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Batch Number', required: true),
                                    SizedBox(height: isSmallScreen ? 6 : 8),
                                    _buildTextField(
                                      controller: _batchNumberController,
                                      hintText: 'Auto-generated',
                                      readOnly: true,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 12 : 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Quantity', required: true),
                                    SizedBox(height: isSmallScreen ? 6 : 8),
                                    _buildTextField(
                                      controller: _quantityController,
                                      hintText: '0',
                                      keyboardType: TextInputType.number,
                                      required: true,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 12 : 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Expiry Date', required: true),
                                    SizedBox(height: isSmallScreen ? 6 : 8),
                                    _buildTextField(
                                      controller: _expiryDateController,
                                      hintText: 'YYYY-MM-DD',
                                      required: true,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      SizedBox(height: isSmallScreen ? 16 : 20),
                    ],
                  ),
                ),
              ),
            ),
            // Footer Buttons
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 24, vertical: isSmallScreen ? 10 : 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Add Medicine',
                      style: TextStyle(fontSize: isSmallScreen ? 14 : 16, fontWeight: FontWeight.w600),
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

  Widget _buildLabel(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'This field is required';
              }
              return null;
            }
          : null,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 14,
          color: Colors.grey[400],
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2563EB)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hintText,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          hint: Text(
            hintText,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
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

  Widget _buildDateField({
    required TextEditingController controller,
    required String hintText,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty || value == 'dd/mm/yyyy') {
                return 'Please select an expiry date';
              }
              // Validate date format DD/MM/YYYY
              final parts = value.split('/');
              if (parts.length != 3) {
                return 'Invalid date format (DD/MM/YYYY)';
              }
              final day = int.tryParse(parts[0]);
              final month = int.tryParse(parts[1]);
              final year = int.tryParse(parts[2]);
              if (day == null || month == null || year == null) {
                return 'Invalid date';
              }
              if (day < 1 || day > 31 || month < 1 || month > 12 || year < 2000) {
                return 'Invalid date values';
              }
              return null;
            }
          : null,
      readOnly: true,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 14,
          color: Colors.grey[400],
        ),
        suffixIcon: Icon(Icons.calendar_today_outlined, color: Colors.grey[500], size: 18),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2563EB)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
        );
        if (picked != null) {
          setState(() {
            controller.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
          });
        }
      },
    );
  }

  void _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return; // Form validation failed
    }
    
    // Validate dropdowns (Unit and Category)
    if (_selectedUnit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Unit'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final pharmacyService = PharmacyService();

      try {
        final medicineName = _medicineNameController.text.trim();
        
        // Step 1: Generate medicine code from name (e.g., "Paracetamol" -> "PARA")
        final medicineCode = _generateMedicineCode(medicineName);
        
        // Step 2: Generate batch number based on medicine code (e.g., "BATCH-PARA-01")
        final existingBatches = await pharmacyService.getStockBatches();
        final batchNo = _generateBatchNumber(medicineCode, existingBatches);

        // Create medicine data
        final medicineData = {
          'medicine_code': medicineCode,
          'medicine_name': medicineName,
          'category': _selectedCategory,
          'unit': _selectedUnit,
          'reorder_level': double.parse(_reorderLevelController.text),
          'unit_cost': double.parse(_priceController.text),
          'is_active': true,
        };

        final createdMedicine = await pharmacyService.createMedicine(medicineData);
        final medicineId = createdMedicine['medicine_id'];

        // Step 3: Create the stock batch with unit cost
        final batchData = {
          'medicine': medicineId,
          'batch_no': batchNo,
          'expiry_date': _convertDateToIso(_expiryDateController.text),
          'received_date': DateTime.now().toIso8601String().split('T')[0],
          'unit_cost': double.parse(_priceController.text), // Store price per batch
        };

        final createdBatch = await pharmacyService.createStockBatch(batchData);
        final batchId = createdBatch['batch_id'];

        // Step 4: Create inventory balance with the quantity
        final balanceData = {
          'medicine': medicineId,
          'batch': batchId,
          'location': 1, // Default location (Main Pharmacy)
          'qty_on_hand': double.parse(_quantityController.text),
        };

        await pharmacyService.createInventoryBalance(balanceData);

        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicine and initial stock added successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding medicine: $e')),
          );
        }
      }
    }

  // Generate medicine code from name (first 4 letters of first word, uppercase)
  // e.g., "Paracetamol" -> "PARA", "Biogesic" -> "BIO"
  String _generateMedicineCode(String medicineName) {
    if (medicineName.isEmpty) return 'MED';
    
    // Get first word
    final firstWord = medicineName.split(' ').first;
    
    // Take first 4 letters (or all if less than 4)
    final code = firstWord.length >= 4 
        ? firstWord.substring(0, 4).toUpperCase()
        : firstWord.toUpperCase();
    
    return code;
  }

  // Generate batch number based on medicine code
  // e.g., "BATCH-PARA-01", "BATCH-PARA-02"
  String _generateBatchNumber(String medicineCode, List<dynamic> existingBatches) {
    // Find existing batches for this medicine code
    final batchesForMedicine = existingBatches.where((batch) {
      final batchNo = batch['batch_no']?.toString() ?? '';
      return batchNo.contains('-${medicineCode}-');
    }).toList();
    
    // Get next batch number
    int nextNumber = 1;
    if (batchesForMedicine.isNotEmpty) {
      for (final batch in batchesForMedicine) {
        final batchNo = batch['batch_no']?.toString() ?? '';
        final parts = batchNo.split('-');
        if (parts.length >= 3) {
          final numStr = parts.last;
          final num = int.tryParse(numStr) ?? 0;
          if (num >= nextNumber) {
            nextNumber = num + 1;
          }
        }
      }
    }
    
    // Format: BATCH-MEDICINECODE-XX
    final batchNo = 'BATCH-$medicineCode-${nextNumber.toString().padLeft(2, '0')}';
    
    // Update the controller to show the generated batch number
    _batchNumberController.text = batchNo;
    
    return batchNo;
  }

  // Convert DD/MM/YYYY to YYYY-MM-DD
  String _convertDateToIso(String dateStr) {
    if (dateStr.isEmpty) return '';
    final parts = dateStr.split('/');
    if (parts.length == 3) {
      return '${parts[2]}-${parts[1]}-${parts[0]}';
    }
    return dateStr;
  }
}
