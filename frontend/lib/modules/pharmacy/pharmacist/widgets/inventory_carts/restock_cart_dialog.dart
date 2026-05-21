import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/pharmacy_service.dart';

/// Restock Cart Medicine Dialog
/// Shows a form to add stock to a cart medicine
class RestockCartDialog extends StatefulWidget {
  final Map<String, dynamic>? medicine;

  const RestockCartDialog({
    super.key,
    this.medicine,
  });

  @override
  State<RestockCartDialog> createState() => _RestockCartDialogState();

  /// Show the dialog
  static Future<bool?> show(BuildContext context, {Map<String, dynamic>? medicine}) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RestockCartDialog(medicine: medicine),
    );
  }
}

class _RestockCartDialogState extends State<RestockCartDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _batchNumberController = TextEditingController();
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
      'name': 'Paracetamol 500mg',
      'currentTotal': 41,
      'unit_cost': 0.0,
    };
    // Initialize unit cost from medicine data
    _unitCostController.text = (_medicine['unit_cost'] ?? 0.0).toString();
    _fetchExistingBatches();
  }

  Future<void> _fetchExistingBatches() async {
    // Attempt to get medicine_id from different possible keys
    final medicineId = _medicine['medicine_id'] ?? _medicine['id'];
    debugPrint('RestockCartDialog: Fetching batches for medicineId: $medicineId');
    
    if (medicineId != null) {
      try {
        final batches = await _pharmacyService.getMedicineBatches(int.parse(medicineId.toString()));
        debugPrint('RestockCartDialog: Fetched ${batches.length} batches');
        if (mounted) {
          setState(() {
            _existingBatches = batches;
          });
        }
      } catch (e) {
        debugPrint('Error fetching batches: $e');
      }
    } else {
      debugPrint('RestockCartDialog: medicineId is null! _medicine keys: ${_medicine.keys}');
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
        // Auto-fill unit cost for existing batches
        _unitCostController.text = (matchingBatch['unit_cost'] ?? 0.0).toString();
      } else {
        // GENERATE NEW BATCH NUMBER AUTOMATICALLY
        // Logic: BATCH-[MED-CODE]-[COUNT+1]
        final medicineName = _medicine['name']?.toString() ?? '';
        
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
    _quantityController.dispose();
    _batchNumberController.dispose();
    _unitCostController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 480,
        constraints: const BoxConstraints(maxHeight: 550),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF4CAF50), size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Restock Cart Medicine',
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
            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Medicine Name Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F7FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE3F2FD)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MEDICINE NAME',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[700],
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _medicine['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Current Total Quantity (read-only)
                      _buildLabel('Current Total Quantity'),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Text(
                          '${_medicine['currentTotal']} units',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Expiry Date
                      _buildLabel('Expiry Date', required: true),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _expiryDateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: 'dd/mm/yyyy',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                          prefixIcon: Icon(Icons.calendar_today_outlined, color: Colors.grey[500], size: 18),
                          suffixIcon: Icon(Icons.calendar_month_outlined, color: Colors.grey[500], size: 18),
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
                            initialDate: DateTime.now().add(const Duration(days: 365)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                          );
                          if (picked != null) {
                            _onExpiryDateSelected(picked);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      // Batch Number
                      _buildLabel('Batch Number', required: true),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _batchNumberController,
                        decoration: InputDecoration(
                          hintText: 'e.g., BATCH-2026-001',
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Quantity and Unit Cost in one line
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Quantity to Add', required: true),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _quantityController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'Qty',
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
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Unit Cost', required: true),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _unitCostController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    hintText: '0.00',
                                    prefixText: '₱ ',
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
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            // Footer Buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _onReturnMedicine,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange[800],
                      side: BorderSide(color: Colors.orange[300]!),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Return Medicine',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Confirm Restock',
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
          'location_id': 2, // Cart Location
          'remarks': 'Manual return to Cart via Restock Dialog',
        });

        if (mounted) {
          Navigator.of(context).pop(true); // Return true to trigger refresh in parent
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicine returned to Cart successfully')),
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

        await _pharmacyService.restockCart({
          'medicine_id': _medicine['medicine_id'] ?? _medicine['id'],
          'batch_no': _batchNumberController.text,
          'expiry_date': formattedExpiryDate,
          'quantity': double.tryParse(_quantityController.text) ?? 0.0,
          'unit_cost': double.tryParse(_unitCostController.text) ?? 0.0,
        });

        if (mounted) {
          Navigator.of(context).pop(true); // Return true to refresh list
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cart restocked successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error restocking cart: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
