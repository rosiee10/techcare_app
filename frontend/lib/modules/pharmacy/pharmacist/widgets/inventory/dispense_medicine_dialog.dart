import 'package:flutter/material.dart';
import '../../services/inventory_cart_service.dart';
import '../../services/pharmacy_service.dart';

/// Dispense Medicine Dialog
/// Shows medicine info and allows dispensing with FEFO batch tracking
class DispenseMedicineDialog extends StatefulWidget {
  final Map<String, dynamic>? medicine;

  const DispenseMedicineDialog({
    super.key,
    this.medicine,
  });

  @override
  State<DispenseMedicineDialog> createState() => _DispenseMedicineDialogState();

  /// Show the dialog
  static Future<bool> show(BuildContext context, {Map<String, dynamic>? medicine}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DispenseMedicineDialog(medicine: medicine),
    );
    return result ?? false;
  }
}

class _DispenseMedicineDialogState extends State<DispenseMedicineDialog> {
  final _quantityController = TextEditingController(text: '1');
  bool _showPatientField = false;
  bool _isLoading = false;
  int? _selectedBatchId;

  // Medicine data with real batches from backend
  late Map<String, dynamic> _medicine;
  List<dynamic> _batches = [];
  double _totalAvailableStock = 0;

  @override
  void initState() {
    super.initState();
    _medicine = widget.medicine ?? {};
    _fetchBatchData();
  }

  Future<void> _fetchBatchData() async {
    setState(() => _isLoading = true);
    
    try {
      final medicineId = _medicine['id'] ?? _medicine['medicine_id'];
      if (medicineId == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      final pharmacyService = PharmacyService();
      final result = await pharmacyService.getMedicineBatches(int.parse(medicineId.toString()));
      
      if (result is List) {
        _batches = result.map((batch) {
          return {
            'batchNumber': batch['batch_no'],
            'quantity': batch['quantity'],
            'expiryDate': batch['expiry_date'] != null
                ? _formatDate(batch['expiry_date'])
                : null,
            'unitCost': batch['unit_cost'],
            'isExpired': false,
            'batch_id': batch['batch_id'],
          };
        }).toList();
        
        _totalAvailableStock = result.fold(0.0, (sum, b) => sum + (double.tryParse(b['quantity']?.toString() ?? '0') ?? 0.0));
      } else {
        _batches = [];
        _totalAvailableStock = 0;
      }
    } catch (e) {
      print('Error fetching batch data: $e');
      _batches = [];
      _totalAvailableStock = 0;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return isoDate;
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _onReleaseToNurse() {
    setState(() {
      _showPatientField = true;
    });
  }

  void _onAddToCart() async {
    // Validate medicine ID
    final rawMedicineId = _medicine['id'] ?? _medicine['medicine_id'];
    final medicineId = rawMedicineId is int ? rawMedicineId : int.tryParse(rawMedicineId?.toString() ?? '');
    
    if (medicineId == null || medicineId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Invalid medicine ID. Please refresh the page and try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    final cartService = InventoryCartService();
    await cartService.init();
    
    // Get medicine details from the dialog
    final medicineData = {
      'medicine_id': medicineId,
      'medicine_name': _medicine['name'] ?? _medicine['medicine_name'] ?? 'Unknown Medicine',
      'category': _medicine['category'] ?? 'Uncategorized',
      'unit': _medicine['unit'] ?? 'unit',
      'batch_id': _selectedBatchId, // Include selected batch if any
    };
    
    // Get quantity to add
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    
    // Show loading indicator
    setState(() {
      _isLoading = true;
    });
    
    // Call backend API to transfer to cart
    final result = await cartService.addToCart(medicineData, quantity: quantity);
    
    setState(() {
      _isLoading = false;
    });
    
    if (mounted) {
      if (result['success'] == true) {
        // Backend transfer successful
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${medicineData['medicine_name']} transferred to inventory cart'),
            backgroundColor: const Color(0xFF22C55E),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
        return;  // Exit the method
      } else {
        // Backend transfer failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result['message']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _onConfirmRelease() {
    // TODO: Confirm release to nurse logic
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final dialogWidth = isMobile ? screenWidth * 0.98 : 700.0;

    return Dialog(
      insetPadding: EdgeInsets.all(isMobile ? 8 : 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
      ),
      child: Container(
        width: isMobile ? screenWidth * 0.98 : dialogWidth,
        constraints: BoxConstraints(
          maxHeight: isMobile ? MediaQuery.of(context).size.height * 0.46 : 600,
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
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                    ),
                    child: Icon(Icons.medication, color: const Color(0xFF1976D2), size: isMobile ? 20 : 24),
                  ),
                  SizedBox(width: isMobile ? 12 : 16),
                  Expanded(
                    child: Text(
                      'Dispense Medicine',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
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
                padding: EdgeInsets.all(isMobile ? 12 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Medicine Information Section
                    Container(
                      padding: EdgeInsets.all(isMobile ? 12 : 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F7FF),
                        borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                        border: Border.all(color: const Color(0xFFE3F2FD)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(isMobile ? 4 : 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                                ),
                                child: Icon(Icons.link, color: const Color(0xFF1976D2), size: isMobile ? 16 : 18),
                              ),
                              SizedBox(width: isMobile ? 8 : 10),
                              Text(
                                'Medicine Information',
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isMobile ? 12 : 20),
                          isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoLabel('MEDICINE NAME'),
                                  SizedBox(height: isMobile ? 4 : 6),
                                  _buildInfoValue(_medicine['name'] ?? 'Unknown'),
                                  SizedBox(height: isMobile ? 8 : 12),
                                  _buildInfoLabel('CATEGORY'),
                                  SizedBox(height: isMobile ? 4 : 6),
                                  _buildInfoValue(_medicine['category'] ?? 'Uncategorized'),
                                  SizedBox(height: isMobile ? 8 : 12),
                                  _buildInfoLabel('UNIT'),
                                  SizedBox(height: isMobile ? 4 : 6),
                                  _buildInfoValue(_medicine['unit'] ?? 'unit'),
                                  SizedBox(height: isMobile ? 8 : 12),
                                  _buildInfoLabel('AVAILABLE STOCK'),
                                  SizedBox(height: isMobile ? 4 : 6),
                                  _buildInfoValue('${(_totalAvailableStock ?? 0.0).toStringAsFixed(0)} units'),
                                ],
                              )
                            : Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildInfoLabel('MEDICINE NAME'),
                                            const SizedBox(height: 6),
                                            _buildInfoValue(_medicine['name'] ?? 'Unknown'),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildInfoLabel('CATEGORY'),
                                            const SizedBox(height: 6),
                                            _buildInfoValue(_medicine['category'] ?? 'Uncategorized'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildInfoLabel('UNIT'),
                                            const SizedBox(height: 6),
                                            _buildInfoValue(_medicine['unit'] ?? 'unit'),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildInfoLabel('AVAILABLE STOCK'),
                                            const SizedBox(height: 6),
                                            _buildInfoValue('${(_totalAvailableStock?.toDouble() ?? 0.0).toStringAsFixed(0)} units'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Batches Section
                    Text(
                      'BATCHES (FEFO ORDER - FIRST EXPIRY FIRST OUT)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Dynamic Batch Cards
                    ...(_batches).map((batch) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E5F5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE1BEE7)),
                        ),
                        child: isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.layers, color: Colors.deepPurple[400], size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        batch['batchNumber'] ?? 'N/A',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.deepPurple[900],
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '₱${(double.tryParse(batch['unitCost']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${batch['quantity']} units',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Text(
                                      'Exp: ${batch['expiryDate'] ?? 'N/A'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Icon(Icons.layers, color: Colors.deepPurple[400], size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    batch['batchNumber'] ?? 'N/A',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.deepPurple[900],
                                    ),
                                  ),
                                ),
                                // Unit Cost (what will be charged)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '₱${(double.tryParse(batch['unitCost']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${batch['quantity']} units',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  batch['expiryDate'] ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                      );
                    }).toList(),
                    const SizedBox(height: 12),
                    // FEFO Note
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber[600], size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Medicines will be dispensed from batch with earliest expiry date first (FEFO). Cost shown is actual batch unit cost.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.deepPurple[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Dispense Quantity
                    _buildLabel('Dispense Quantity', required: true),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '1',
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
                    const SizedBox(height: 8),
                    Text(
                      'Maximum available: ${(_totalAvailableStock?.toDouble() ?? 0.0).toStringAsFixed(0)} units',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    // Patient Name Field (shown when Release to Nurse is clicked)
                    if (_showPatientField) ...[
                      const SizedBox(height: 20),
                      _buildLabel('Patient Name', required: true),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Enter patient name',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                          prefixIcon: Icon(Icons.person_outline, color: Colors.grey[500], size: 20),
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
                      const SizedBox(height: 8),
                      Text(
                        'The total amount will be recorded to this patient\'s account',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Footer Buttons - Responsive
            Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 24),
              child: isMobile
                ? Row(
                    children: [
                      if (!_showPatientField) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _onAddToCart,
                            icon: Icon(Icons.shopping_cart_outlined, size: isMobile ? 16 : 18),
                            label: Text('Add to Inventory Cart', style: TextStyle(fontSize: isMobile ? 11 : 14)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9333EA),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 20, vertical: isMobile ? 10 : 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isMobile ? 8 : 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _onReleaseToNurse,
                            icon: Icon(Icons.send, size: isMobile ? 16 : 18),
                            label: Text('Release to Nurse', style: TextStyle(fontSize: isMobile ? 11 : 14)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 20, vertical: isMobile ? 10 : 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _onConfirmRelease,
                            icon: Icon(Icons.check_circle, size: isMobile ? 16 : 18),
                            label: Text('Confirm Release', style: TextStyle(fontSize: isMobile ? 12 : 14)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20, vertical: isMobile ? 10 : 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!_showPatientField) ...[
                        ElevatedButton.icon(
                          onPressed: _onAddToCart,
                          icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                          label: const Text('Add to Inventory Cart'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9333EA),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _onReleaseToNurse,
                          icon: const Icon(Icons.send, size: 18),
                          label: const Text('Release to Nurse'),
                        ),
                      ] else ...[
                        ElevatedButton.icon(
                          onPressed: _onConfirmRelease,
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('Confirm Release'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.grey[500],
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildInfoValue(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A2E),
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
}
