import 'package:flutter/material.dart';
import '../../services/pharmacy_service.dart';
import 'package:intl/intl.dart';

/// Add New Batch Dialog
/// Shows a form to add a new batch to existing medicine
class AddBatchDialog extends StatefulWidget {
  final Map<String, dynamic>? medicine;

  const AddBatchDialog({
    super.key,
    this.medicine,
  });

  @override
  State<AddBatchDialog> createState() => _AddBatchDialogState();

  /// Show the dialog
  static Future<bool?> show(BuildContext context, {Map<String, dynamic>? medicine}) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddBatchDialog(medicine: medicine),
    );
  }
}

class _AddBatchDialogState extends State<AddBatchDialog> {
  final _formKey = GlobalKey<FormState>();
  final _batchNumberController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitCostController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final PharmacyService _pharmacyService = PharmacyService();
  bool _isLoading = false;
  late final Map<String, dynamic> _medicine;
  List<dynamic> _existingBatches = [];

  @override
  void initState() {
    super.initState();
    _medicine = widget.medicine ?? {
      'name': 'Biogesic 500mg',
      'currentTotal': 184,
      'existingBatches': 2,
      'unit_cost': 0.0,
    };
    // Initialize unit cost from medicine data if available
    _unitCostController.text = (_medicine['unit_cost'] ?? 0.0).toString();
    _fetchExistingBatches();
  }

  Future<void> _fetchExistingBatches() async {
    // Attempt to get medicine_id from different possible keys
    final medicineId = _medicine['medicine_id'] ?? _medicine['id'];
    debugPrint('AddBatchDialog: Fetching batches for medicineId: $medicineId');
    
    if (medicineId != null) {
      try {
        final batches = await _pharmacyService.getMedicineBatches(int.parse(medicineId.toString()));
        debugPrint('AddBatchDialog: Fetched ${batches.length} batches');
        if (mounted) {
          setState(() {
            _existingBatches = batches;
          });
        }
      } catch (e) {
        debugPrint('Error fetching batches: $e');
      }
    } else {
      debugPrint('AddBatchDialog: medicineId is null! _medicine keys: ${_medicine.keys}');
    }
  }

  void _onExpiryDateSelected(DateTime picked) {
    setState(() {
      final formattedDisplay = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      _expiryDateController.text = formattedDisplay;
      
      final formattedIso = DateFormat('yyyy-MM-dd').format(picked);
      
      final matchingBatch = _existingBatches.firstWhere(
        (b) => b['expiry_date'] == formattedIso,
        orElse: () => null,
      );

      if (matchingBatch != null) {
        _batchNumberController.text = matchingBatch['batch_no'] ?? '';
        // Also auto-fill unit cost for existing batches
        _unitCostController.text = (matchingBatch['unit_cost'] ?? 0.0).toString();
      } else {
        // GENERATE NEW BATCH NUMBER AUTOMATICALLY
        // Logic: BATCH-[MED-CODE]-[COUNT+1]
        final medicineName = _medicine['name']?.toString() ?? '';
        final medicineId = _medicine['medicine_id'] ?? _medicine['id'] ?? 0;
        
        // 1. Get a short 4-letter prefix from name (e.g., BIOGESIC -> BIOG)
        String prefix = medicineName.replaceAll(RegExp(r'[^a-zA-Z]'), '').toUpperCase();
        if (prefix.length > 4) prefix = prefix.substring(0, 4);
        if (prefix.isEmpty) prefix = 'MED';

        // 2. Count existing batches for this medicine
        final nextNum = _existingBatches.length + 1;
        
        // 3. Set the generated batch number
        _batchNumberController.text = 'BATCH-$prefix-${nextNum.toString().padLeft(2, '0')}';
      }
    });
  }

  @override
  void dispose() {
    _batchNumberController.dispose();
    _quantityController.dispose();
    _unitCostController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final dialogWidth = isMobile ? screenWidth * 0.98 : 500.0;

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
                  Container(
                    padding: EdgeInsets.all(isMobile ? 8 : 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                    ),
                    child: Icon(Icons.inventory_2_outlined, color: const Color(0xFF4CAF50), size: isMobile ? 20 : 24),
                  ),
                  SizedBox(width: isMobile ? 12 : 16),
                  Expanded(
                    child: Text(
                      'Add New Batch',
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
            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 12 : 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Medicine Info Card
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isMobile ? 12 : 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F7FF),
                          borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                          border: Border.all(color: const Color(0xFFE3F2FD)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MEDICINE',
                              style: TextStyle(
                                fontSize: isMobile ? 10 : 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[700],
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: isMobile ? 16 : 24),
                            Text(
                              _medicine['name'],
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: isMobile ? 6 : 8),
                            Text(
                              'Current Total: ${_medicine['currentTotal']} units',
                              style: TextStyle(
                                fontSize: isMobile ? 11 : 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isMobile ? 16 : 24),
                      // Expiry Date
                      _buildLabel('Expiry Date', required: true),
                      SizedBox(height: isMobile ? 6 : 8),
                      GestureDetector(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 365)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                          );
                          if (picked != null) {
                            _onExpiryDateSelected(picked);
                          }
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: _expiryDateController,
                            decoration: InputDecoration(
                              hintText: 'DD/MM/YYYY',
                              hintStyle: TextStyle(
                                fontSize: isMobile ? 12 : 14,
                                color: Colors.grey[400],
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                                borderSide: const BorderSide(color: Color(0xFF2563EB)),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 12 : 16),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isMobile ? 16 : 20),
                      // Batch Number
                      _buildLabel('Batch Number', required: true),
                      SizedBox(height: isMobile ? 6 : 8),
                      TextFormField(
                        controller: _batchNumberController,
                        decoration: InputDecoration(
                          hintText: 'e.g., BATCH-2026-001',
                          hintStyle: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            color: Colors.grey[400],
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                            borderSide: const BorderSide(color: Color(0xFF2563EB)),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 12 : 16),
                        ),
                      ),
                      SizedBox(height: isMobile ? 16 : 20),
                      // Quantity and Unit Cost in one line
                      isMobile
                        ? Column(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Quantity', required: true),
                                  SizedBox(height: isMobile ? 6 : 8),
                                  TextFormField(
                                    controller: _quantityController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: 'Qty',
                                      hintStyle: TextStyle(
                                        fontSize: isMobile ? 12 : 14,
                                        color: Colors.grey[400],
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                                        borderSide: BorderSide(color: Colors.grey[300]!),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                                        borderSide: BorderSide(color: Colors.grey[300]!),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                                        borderSide: const BorderSide(color: Color(0xFF2563EB)),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 12 : 16),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isMobile ? 12 : 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Unit Cost (₱)', required: true),
                                  SizedBox(height: isMobile ? 6 : 8),
                                  TextFormField(
                                    controller: _unitCostController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      hintText: '0.00',
                                      hintStyle: TextStyle(
                                        fontSize: isMobile ? 12 : 14,
                                        color: Colors.grey[400],
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                                        borderSide: BorderSide(color: Colors.grey[300]!),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                                        borderSide: BorderSide(color: Colors.grey[300]!),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                                        borderSide: const BorderSide(color: Color(0xFF2563EB)),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 12 : 16),
                                    ),
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
                                    _buildLabel('Quantity', required: true),
                                    SizedBox(height: isMobile ? 6 : 8),
                                    TextFormField(
                                      controller: _quantityController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: 'Qty',
                                        hintStyle: TextStyle(
                                          fontSize: isMobile ? 12 : 14,
                                          color: Colors.grey[400],
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                                          borderSide: BorderSide(color: Colors.grey[300]!),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                                          borderSide: BorderSide(color: Colors.grey[300]!),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                                          borderSide: const BorderSide(color: Color(0xFF2563EB)),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 12 : 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: isMobile ? 12 : 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Unit Cost (₱)', required: true),
                                    SizedBox(height: isMobile ? 6 : 8),
                                    TextFormField(
                                      controller: _unitCostController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: InputDecoration(
                                        hintText: '0.00',
                                        hintStyle: TextStyle(
                                          fontSize: isMobile ? 12 : 14,
                                          color: Colors.grey[400],
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                                          borderSide: BorderSide(color: Colors.grey[300]!),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                                          borderSide: BorderSide(color: Colors.grey[300]!),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                                          borderSide: const BorderSide(color: Color(0xFF2563EB)),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 12 : 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                    ],
                  ),
                ),
              ),
            ),
            // Footer Buttons - Responsive
            Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 24),
              child: isMobile
                  ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _onReturnMedicine,
                            icon: const Icon(Icons.restore, size: 18),
                            label: Text('Return Medicine', style: TextStyle(fontSize: isMobile ? 11 : 16)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange[800],
                              side: BorderSide(color: Colors.orange[300]!),
                              padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 24, vertical: isMobile ? 10 : 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        SizedBox(width: isMobile ? 8 : 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _submitForm,
                            icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.add),
                            label: Text(_isLoading ? 'Adding...' : 'Add Batch', style: TextStyle(fontSize: isMobile ? 11 : 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 24, vertical: isMobile ? 10 : 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _onReturnMedicine,
                          icon: const Icon(Icons.restore),
                          label: const Text('Return Medicine', style: TextStyle(fontSize: 14)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange[800],
                            side: BorderSide(color: Colors.orange[300]!),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _submitForm,
                          icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.add),
                          label: Text(_isLoading ? 'Adding...' : 'Add Batch', style: const TextStyle(fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Future<void> _onReturnMedicine() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final medicineId = _medicine['medicine_id'] ?? _medicine['id'];
        
        await _pharmacyService.manualReturn({
          'medicine_id': medicineId,
          'batch_no': _batchNumberController.text,
          'quantity': double.tryParse(_quantityController.text) ?? 0.0,
          'location_id': 1, // Main Pharmacy
          'remarks': 'Manual return to Main Inventory via Add Batch Dialog',
        });

        if (mounted) {
          Navigator.of(context).pop(true); // Return true to trigger refresh in parent
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicine returned to Main Inventory successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error returning medicine: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final DateFormat formatter = DateFormat('dd/MM/yyyy');
        final DateTime expiryDate = formatter.parse(_expiryDateController.text);
        final String formattedExpiryDate = DateFormat('yyyy-MM-dd').format(expiryDate);

        final result = await _pharmacyService.addBatch({
          'medicine': _medicine['medicine_id'] ?? _medicine['id'],
          'batch_no': _batchNumberController.text,
          'expiry_date': formattedExpiryDate,
          'initial_qty': double.tryParse(_quantityController.text) ?? 0.0,
          'unit_cost': double.tryParse(_unitCostController.text) ?? 0.0,
        });

        if (mounted) {
          // Explicitly clear focus to ensure all state is committed
          FocusScope.of(context).unfocus();
          // Pop with true to signal refresh
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding batch: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
