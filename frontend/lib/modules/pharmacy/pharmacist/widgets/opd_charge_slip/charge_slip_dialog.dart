import 'package:flutter/material.dart';
import '../../services/pharmacy_service.dart';

/// Review Prescription & Generate Charge Slip Dialog
/// Two-stage dialog: Review -> Charge Slip -> Send to Billing
///
/// Database Integration Points:
/// - Pass prescription data via [prescription] parameter
/// - Call API to generate charge slip number
/// - Call API to send charge slip to billing
/// - Call API to print/generate PDF
class ChargeSlipDialog extends StatefulWidget {
  final Map<String, dynamic> prescription;

  const ChargeSlipDialog({
    super.key,
    required this.prescription,
  });

  @override
  State<ChargeSlipDialog> createState() => _ChargeSlipDialogState();

  /// Show the dialog
  ///
  /// [prescription] should contain:
  /// - rxNumber, doctorName, patientName, patientId
  /// - medicines: List<Map> with name, unitPrice, available, prescribedQty, releaseQty
  static Future<void> show(BuildContext context, {Map<String, dynamic>? prescription}) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ChargeSlipDialog(prescription: prescription ?? {}),
    );
  }
}

class _ChargeSlipDialogState extends State<ChargeSlipDialog> {
  // Stage: 'review' -> 'charge_slip' -> 'sent'
  String _stage = 'review';
  String? _chargeSlipNumber;

  late final Map<String, dynamic> _prescription;
  final Map<String, TextEditingController> _releaseControllers = {};
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _scIdController = TextEditingController();
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _errorMessage;

  final PharmacyService _pharmacyService = PharmacyService();

  @override
  void initState() {
    super.initState();
    _prescription = widget.prescription;

    // Initialize release quantity controllers from passed data
    final medicines = _prescription['medicines'];
    if (medicines != null) {
      for (var medicine in medicines) {
        final name = medicine['name'] ?? 'Unknown';
        final releaseQty = medicine['releaseQty'] ?? medicine['prescribedQty'] ?? 0;
        _releaseControllers[name] = TextEditingController(
          text: releaseQty.toString(),
        );
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _releaseControllers.values) {
      controller.dispose();
    }
    _addressController.dispose();
    _ageController.dispose();
    _scIdController.dispose();
    super.dispose();
  }

  Future<void> _onGenerateChargeSlip() async {
    setState(() => _isGenerating = true);

    try {
      final patientId = _prescription['patient_id'];
      final rxId = _prescription['rx_id'];
      final medicines = _prescription['medicines'] as List? ?? [];

      if (patientId == null || rxId == null) {
        setState(() {
          _errorMessage = 'Missing patient_id or rx_id';
          _isGenerating = false;
        });
        return;
      }

      final items = medicines.map((med) {
        final name = med['name'] ?? 'Unknown';
        final releaseQty = int.tryParse(_releaseControllers[name]?.text ?? '0') ?? 0;
        return {
          'medicine_id': med['medicine_id'],
          'qty': releaseQty,
          'unit_cost': med['unitPrice'] ?? 0.0,
        };
      }).toList();

      final result = await _pharmacyService.createChargeSlip(
        patientId: patientId is int ? patientId : int.parse(patientId.toString()),
        rxId: rxId is int ? rxId : int.parse(rxId.toString()),
        items: List<Map<String, dynamic>>.from(items),
      );

      setState(() {
        _stage = 'charge_slip';
        _chargeSlipNumber = result['charge_slip_no'] ?? 'CS-001';
        _isGenerating = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to generate charge slip: $e';
        _isGenerating = false;
      });
    }
  }

  void _onSendToBilling() {
    setState(() {
      _stage = 'sent';
    });
  }

  void _onPrint() {
    // TODO: Print functionality
  }

  double _calculateTotal() {
    double total = 0;
    final medicines = _prescription['medicines'];
    if (medicines == null) return total;
    
    for (var medicine in medicines) {
      final name = medicine['name'] ?? 'Unknown';
      final releaseQty = int.tryParse(_releaseControllers[name]?.text ?? '0') ?? 0;
      final unitPrice = (medicine['unitPrice'] as num?)?.toDouble() ?? 0.0;
      total += releaseQty * unitPrice;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    if (_stage == 'review') {
      return _buildReviewDialog();
    } else if (_stage == 'charge_slip') {
      return _buildChargeSlipDialog();
    } else {
      return _buildSentDialog();
    }
  }

  // Stage 1: Review Prescription Dialog
  Widget _buildReviewDialog() {
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Review Prescription & Generate Charge Slip',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: isMobile ? 3 : 4),
                        Text(
                          'Prescription ${_prescription['rxNumber'] ?? 'RX-000'} from ${_prescription['doctorName'] ?? 'Dr. Unknown'}',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
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
                    // Patient Information Section
                    Container(
                      padding: EdgeInsets.all(isMobile ? 12 : 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Patient Information',
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: isMobile ? 12 : 16),
                          isMobile
                            ? Column(
                                children: [
                                  _buildFormField('Patient Name', _prescription['patientName'] ?? ''),
                                  const SizedBox(height: 12),
                                  _buildFormField('Patient ID', _prescription['patientId'] ?? ''),
                                  const SizedBox(height: 12),
                                  _buildTextField('Address', _addressController, 'Enter patient address'),
                                  const SizedBox(height: 12),
                                  _buildTextField('Age', _ageController, 'Enter age'),
                                  SizedBox(height: isMobile ? 12 : 12),
                                  _buildTextField('SC ID # (if applicable)', _scIdController, 'Enter SC ID'),
                                ],
                              )
                            : Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildFormField('Patient Name', _prescription['patientName'] ?? ''),
                                      ),
                                      SizedBox(width: isMobile ? 12 : 16),
                                      Expanded(
                                        child: _buildFormField('Patient ID', _prescription['patientId'] ?? ''),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isMobile ? 12 : 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField('Address', _addressController, 'Enter patient address'),
                                      ),
                                      SizedBox(width: isMobile ? 12 : 16),
                                      Expanded(
                                        child: _buildTextField('Age', _ageController, 'Enter age'),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isMobile ? 12 : 16),
                                  _buildTextField('SC ID # (if applicable)', _scIdController, 'Enter SC ID'),
                                ],
                              ),
                        ],
                      ),
                    ),
                    SizedBox(height: isMobile ? 16 : 24),
                    // Review Medicine Quantities Section
                    Text(
                      'Review Medicine Quantities',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: isMobile ? 3 : 4),
                    Text(
                      'Adjust quantities based on available stock and patient needs',
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    // Medicine Cards
                    ...((_prescription['medicines'] ?? []) as List).map((medicine) {
                      return _buildMedicineCard(medicine);
                    }).toList(),
                    SizedBox(height: isMobile ? 12 : 16),
                    // Total Amount
                    Container(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F7FF),
                        borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                        border: Border.all(color: const Color(0xFFE3F2FD)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Charge Slip Amount:',
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '₱${_calculateTotal().toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                  isMobile
                    ? Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isGenerating ? null : _onGenerateChargeSlip,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isGenerating
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Generate Charge Slip',
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
                            onPressed: _isGenerating ? null : _onGenerateChargeSlip,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isGenerating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Generate Charge Slip',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                          ),
                        ],
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Stage 2: Charge Slip Dialog
  Widget _buildChargeSlipDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final dialogWidth = isMobile ? screenWidth * 0.98 : 850.0;

    return Dialog(
      insetPadding: EdgeInsets.all(isMobile ? 8 : 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
      ),
      child: Container(
        width: isMobile ? screenWidth * 0.98 : dialogWidth,
        constraints: BoxConstraints(
          maxHeight: isMobile ? MediaQuery.of(context).size.height * 0.46 : 900,
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
                      'Pharmacy Charge Slip - $_chargeSlipNumber',
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
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black87, width: isMobile ? 1 : 1.5),
                  ),
                  child: Column(
                    children: [
                      // Hospital Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Left Logo
                            Image.asset(
                              'assets/logos/pchlogo.png',
                              width: 60,
                              height: 60,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.local_hospital, color: Colors.grey[600], size: 30),
                                );
                              },
                            ),
                            const SizedBox(width: 20),
                            // Center Text
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    'PLARIDEL COMMUNITY HOSPITAL',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'SITIO-MATCO, PANALSALAN, PLARIDEL, MISAMIS OCCIDENTAL',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    'pchpriccr@yhi18@gmail.com',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'PHARMACY CHARGE SLIP',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            // Right Logo and Date
                            Column(
                              children: [
                                Image.asset(
                                  'assets/logos/pchlogo.png',
                                  width: 50,
                                  height: 50,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.local_hospital, color: Colors.grey[600], size: 25),
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '10:25 PM',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                Text(
                                  'Apr 10, 2026',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Patient Info Section
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.black87, width: 1),
                          ),
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Left Column
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: BorderSide(color: Colors.black87, width: 1),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildChargeFormField('NAME:', _prescription['patientName'] ?? ''),
                                      const Divider(height: 16, color: Colors.black54),
                                      _buildChargeFormField('ADDRESS:', _addressController.text.isNotEmpty ? _addressController.text : 'MIS. OCC.'),
                                      const Divider(height: 16, color: Colors.black54),
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: false,
                                            onChanged: (value) {},
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          const Text('admit', style: TextStyle(fontSize: 11)),
                                          const SizedBox(width: 8),
                                          Checkbox(
                                            value: true,
                                            onChanged: (value) {},
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          const Text('opd', style: TextStyle(fontSize: 11)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Right Column
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildChargeFormField('DATE:', 'Apr 10, 2026'),
                                      const Divider(height: 16, color: Colors.black54),
                                      _buildChargeFormField('AGE:', _ageController.text.isNotEmpty ? _ageController.text : ''),
                                      const Divider(height: 16, color: Colors.black54),
                                      _buildChargeFormField('SC.ID #:', _scIdController.text.isNotEmpty ? _scIdController.text : ''),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Table Header
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          border: Border(
                            top: BorderSide(color: Colors.black87, width: 1),
                            bottom: BorderSide(color: Colors.black87, width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Center(
                                child: Text(
                                  'ITEM',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Center(
                                child: Text(
                                  'QTY',
                                  style: TextStyle(
                                    fontSize: 11,
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
                                  'UNIT COST',
                                  style: TextStyle(
                                    fontSize: 11,
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
                                  'TOTAL COST',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Medicine Rows
                      ...((_prescription['medicines'] ?? []) as List).map((medicine) {
                        final name = medicine['name'] ?? 'Unknown';
                        final releaseQty = int.tryParse(_releaseControllers[name]?.text ?? '0') ?? 0;
                        final unitPrice = (medicine['unitPrice'] as num?)?.toDouble() ?? 0.0;
                        final totalCost = releaseQty * unitPrice;
                        return _buildChargeMedicineRow(medicine, releaseQty, totalCost);
                      }).toList(),
                      // Empty rows
                      ...List.generate(2, (index) => _buildChargeEmptyRow()),
                      // Discount Row
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey[400]!),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Expanded(flex: 5, child: SizedBox()),
                            const Expanded(flex: 1, child: SizedBox()),
                            const Expanded(flex: 2, child: SizedBox()),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Text(
                                  'PWD/SC Discount 20%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Total Amount Row
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F7FF),
                          border: Border(
                            top: BorderSide(color: Colors.black87, width: 1),
                            bottom: BorderSide(color: Colors.black87, width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              flex: 5,
                              child: Text(
                                'TOTAL AMOUNT:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const Expanded(flex: 1, child: SizedBox()),
                            const Expanded(flex: 2, child: SizedBox()),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Text(
                                  '₱${_calculateTotal().toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Footer Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFooterField('SUPPLIER:', '#N/A'),
                                    const SizedBox(height: 12),
                                    _buildFooterField('PHYSICIAN:', _prescription['doctorName'] ?? 'Dr. Unknown', valueColor: Colors.blue[600]),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFooterField('PREPARED BY:', 'Rose Marie Espiritu', valueColor: Colors.red[400]),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'RECEIVED BY:',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      height: 1,
                                      color: Colors.black54,
                                      margin: const EdgeInsets.only(top: 8),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            // Footer Buttons - Responsive
            Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 24),
              child: isMobile
                  ? Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _onGenerateChargeSlip,
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Generate Charge Slip'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _onGenerateChargeSlip,
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Generate Charge Slip'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
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

  // Stage 3: Sent Confirmation Dialog
  Widget _buildSentDialog() {
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
          maxHeight: isMobile ? MediaQuery.of(context).size.height * 0.46 : 500,
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
                    child: Icon(Icons.receipt_long, color: const Color(0xFF1976D2), size: isMobile ? 20 : 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pharmacy Charge Slip - $_chargeSlipNumber',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Sent to Billing',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
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
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Patient Header
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.blue[700],
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                'MR',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _chargeSlipNumber ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE3F2FD),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Sent to Billing',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _prescription['patientName'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '00-00-02    Ward: OPD    Doctor: Dr. Jose Cruz',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Apr 10, 2026 • 10:25 PM',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                'Prepared by: Rose Marie Espiritu',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      // Medicine Table
                      Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              'Medicine',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Qty',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Price',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...((_prescription['medicines'] ?? []) as List).map((medicine) {
                        final name = medicine['name'] ?? 'Unknown';
                        final releaseQty = int.tryParse(_releaseControllers[name]?.text ?? '0') ?? 0;
                        final unitPrice = (medicine['unitPrice'] as num?)?.toDouble() ?? 0.0;
                        final totalCost = releaseQty * unitPrice;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  medicine['name'],
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  releaseQty.toString(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '₱${medicine['unitPrice'].toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '₱${totalCost.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const Divider(height: 24),
                      // Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            'Subtotal:',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 60),
                          Text(
                            '₱${_calculateTotal().toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            'Total Amount:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 40),
                          Text(
                            '₱${_calculateTotal().toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            // Footer
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.send, size: 16, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Awaiting payment confirmation from Billing',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _onPrint,
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('Print'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF64748B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

  // Helper Widgets
  Widget _buildFormField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13,
              color: Colors.grey[400],
            ),
            filled: true,
            fillColor: const Color(0xFFF0F0F0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicineCard(Map<String, dynamic> medicine) {
    final controller = _releaseControllers[medicine['name']]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            medicine['name'],
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Unit Price: ₱${medicine['unitPrice'].toStringAsFixed(2)} • Available: ${medicine['available']} units',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prescribed Qty',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        medicine['prescribedQty'].toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Quantity to Release',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          ' *',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF2563EB)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Cost',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: controller,
                        builder: (context, value, child) {
                          final qty = int.tryParse(value.text) ?? 0;
                          final unitPrice = (medicine['unitPrice'] as num?)?.toDouble() ?? 0.0;
                          final total = qty * unitPrice;
                          return Text(
                            '₱${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChargeFormField(String label, String value) {
    return Row(
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
    );
  }

  Widget _buildChargeMedicineRow(Map<String, dynamic> medicine, int qty, double totalCost) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[400]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              medicine['name'],
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                qty.toString(),
                style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                qty > 0 ? '₱${medicine['unitPrice'].toStringAsFixed(2)}' : '-',
                style: const TextStyle(fontSize: 11, color: Colors.black87),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                qty > 0 ? '₱${totalCost.toStringAsFixed(2)}' : '-',
                style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChargeEmptyRow() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[400]!),
        ),
      ),
    );
  }

  Widget _buildFooterField(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
