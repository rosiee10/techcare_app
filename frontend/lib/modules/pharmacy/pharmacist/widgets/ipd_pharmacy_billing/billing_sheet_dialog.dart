import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:frontend/core/utils/logger.dart';
import '../../services/pharmacy_service.dart';

/// Pharmacy Dispensing Sheet Dialog
/// Shows billing sheet with editable quantities and multi-stage actions
///
/// Database Integration Points:
/// - Pass billing data via [billing] parameter
/// - Call API to save finalized quantities
/// - Call API to send billing to billing department
/// - Call API to print/generate PDF
class BillingSheetDialog extends StatefulWidget {
  final Map<String, dynamic> billing;

  const BillingSheetDialog({
    super.key,
    required this.billing,
  });

  @override
  State<BillingSheetDialog> createState() => _BillingSheetDialogState();

  /// Show the dialog
  ///
  /// [billing] should contain:
  /// - patientName, age, gender, dateAdmitted, time, dateDischarge
  /// - address, ward, hospNumber, mgh (bool)
  /// - medicines: List<Map> with date, name, quantity, unitCost, totalCost
  static Future<dynamic> show(BuildContext context, {Map<String, dynamic>? billing}) async {
    return showDialog<dynamic>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BillingSheetDialog(billing: billing ?? {}),
    );
  }
}

class _BillingSheetDialogState extends State<BillingSheetDialog> {
  // Button states: 'finalize' -> 'save' -> 'send' -> 'print'
  String _buttonState = 'finalize';
  bool _isEditable = false;

  late final Map<String, dynamic> _billing;
  final Map<dynamic, TextEditingController> _quantityControllers = {};
  final PharmacyService _pharmacyService = PharmacyService();
  bool _isLoading = false;

  /// Safety parsing helper for numeric values from JSON
  double _getVal(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  // Additional items added by pharmacist during finalization
  final List<Map<String, dynamic>> _additionalItems = [];
  final Map<int, TextEditingController> _additionalQtyControllers = {};

  @override
  void initState() {
    super.initState();
    _billing = widget.billing;

    // Initialize quantity controllers from passed data using receipt_item_id
    final items = _billing['items'];
    if (items != null) {
      for (var item in items) {
        final itemId = item['receipt_item_id'];
        if (itemId != null) {
          // STRICTLY use quantity for accuracy.
          final displayQty = double.tryParse(item['quantity']?.toString() ?? '0') ?? 0.0;

          _quantityControllers[itemId] = TextEditingController(
            text: displayQty.toInt().toString(),
          );
          
          // Add listener to update total cost dynamically in the UI
          _quantityControllers[itemId]!.addListener(() {
            if (mounted) setState(() {});
          });
        }
      }
    }
    
    // Default to 'finalize' state to show "Finalize Quantity" button first
    _buttonState = 'finalize';
    _isEditable = false;
  }

  @override
  void dispose() {
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    for (var controller in _additionalQtyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _onEnableEditing() async {
    setState(() {
      _buttonState = 'save';
      _isEditable = true;
    });
  }

  Future<void> _onSaveAndFinalize() async {
    try {
      final List<Map<String, dynamic>> itemsToFinalize = [];
      
      // 1. Existing items
      _quantityControllers.forEach((itemId, controller) {
        itemsToFinalize.add({
          'receipt_item_id': itemId,
          'quantity': double.tryParse(controller.text) ?? 0.0,
        });
      });

      // 2. Additional items added by pharmacist
      for (int i = 0; i < _additionalItems.length; i++) {
        final item = _additionalItems[i];
        final qtyController = _additionalQtyControllers[i];
        
        if (qtyController != null) {
          itemsToFinalize.add({
            'medicine_id': item['medicine_id'],
            'medicine_name': item['medicine_name'],
            'quantity': double.tryParse(qtyController.text) ?? 0.0,
            'unit_cost': item['unit_cost'],
            'is_new_billing_item': true, // Flag for backend to identify new items
          });
        }
      }

      final pharmacyService = PharmacyService();
      final response = await pharmacyService.finalizeBilling(
        _billing['receipt_id'],
        itemsToFinalize,
      );

      if (response.isNotEmpty) {
        // UPDATE LOCAL DATA with finalized quantities to ensure UI reflects database exactly
        final List<dynamic> currentItems = _billing['items'] as List? ?? [];
        for (var item in currentItems) {
          final itemId = item['receipt_item_id'];
          final controller = _quantityControllers[itemId];
          if (controller != null) {
            final finalQty = double.tryParse(controller.text) ?? 0.0;
            item['quantity'] = finalQty;
            
            // Recalculate item total cost locally
            double unitCost = 0.0;
            var rawUnitCost = item['unit_cost'];
            if (rawUnitCost != null) {
              unitCost = (rawUnitCost is String) ? (double.tryParse(rawUnitCost) ?? 0.0) : (rawUnitCost as num).toDouble();
            }
            item['total_cost'] = finalQty * unitCost;
          }
        }
        
        // ADD NEWLY ADDED ITEMS to the main items list
        for (int i = 0; i < _additionalItems.length; i++) {
          final item = _additionalItems[i];
          final qtyController = _additionalQtyControllers[i];
          final qty = double.tryParse(qtyController?.text ?? '0') ?? 0.0;
          final unitCost = _getVal(item['unit_cost']);
          
          // Create a new item structure matching the existing items
          final newItem = {
            'receipt_item_id': DateTime.now().millisecondsSinceEpoch + i, // Temporary ID
            'medicine_id': item['medicine_id'],
            'item_description': item['medicine_name'],
            'quantity': qty,
            'unit_cost': unitCost,
            'total_cost': qty * unitCost,
            'dispensing_date': DateTime.now().toIso8601String(),
          };
          
          currentItems.add(newItem);
          
          // Create quantity controller for the new item
          _quantityControllers[newItem['receipt_item_id']] = TextEditingController(text: qty.toInt().toString());
          _quantityControllers[newItem['receipt_item_id']]!.addListener(() {
            if (mounted) setState(() {});
          });
        }
        
        // Clear additional items list since they're now part of main items
        _additionalItems.clear();
        _additionalQtyControllers.clear();
        
        // Recalculate patient total locally
        double newPatientTotal = 0.0;
        for (var item in currentItems) {
          newPatientTotal += (item['total_cost'] as num).toDouble();
        }
        _billing['total_amount'] = newPatientTotal;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Billing quantities finalized successfully')),
          );
          // Update local state to reflect finalized status and disable editing
          setState(() {
            _isEditable = false;
            _buttonState = 'print'; // Directly show only Print button
          });
          
          // Close dialog and return true to trigger parent page refresh
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error finalizing quantities: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onSendToBilling() async {
    try {
      setState(() => _isLoading = true);
      
      await _pharmacyService.sendToBilling(_billing['receipt_id']);
      
      setState(() {
        _buttonState = 'print';
        _isEditable = false;
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pharmacy bill sent to Billing Department')),
        );
        
        // AUTOMATICALLY TRIGGER PRINT DIALOG AFTER SENDING
        await _onPrint();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending to billing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onPrint() async {
    final pdf = pw.Document();

    final items = _billing['items'] as List? ?? [];
    
    // Calculate correct total amount based on finalized quantities
    double calculatedTotalAmount = 0.0;
    
    // Existing items
    for (var item in items) {
      final itemId = item['receipt_item_id'];
      final controller = _quantityControllers[itemId];
      final actualQty = double.tryParse(controller?.text ?? item['quantity'].toString()) ?? 0.0;
      final unitCost = _getVal(item['unit_cost']);
      calculatedTotalAmount += (unitCost * actualQty);
    }

    // Additional items
    for (int i = 0; i < _additionalItems.length; i++) {
      final qtyController = _additionalQtyControllers[i];
      final actualQty = double.tryParse(qtyController?.text ?? '0') ?? 0.0;
      final unitCost = _getVal(_additionalItems[i]['unit_cost']);
      calculatedTotalAmount += (unitCost * actualQty);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 25, vertical: 30),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // HEADER SECTION - Centered as in image
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('Republic of the Philippines', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('Province of Misamis Occidental', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('MUNICIPALITY OF PLARIDEL', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    pw.Text('PLARIDEL COMMUNITY HOSPITAL', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 2),
                    pw.Container(
                      padding: const pw.EdgeInsets.only(bottom: 1),
                      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1, color: PdfColors.purple))),
                      child: pw.Text('PHARMACY DISPENSING SHEET', 
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.purple)),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // PATIENT INFO SECTION - Horizontal Underlined Layout
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('NAME : ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.only(left: 4),
                      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
                      child: pw.Text(_billing['patient_name'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text('AGE: ', style: pw.TextStyle(fontSize: 8)),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Container(
                      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
                      child: pw.Text(_billing['patient_age']?.toString() ?? '', style: const pw.TextStyle(fontSize: 8)),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text('GENDER: ', style: pw.TextStyle(fontSize: 8)),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Container(
                      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
                      child: pw.Text(_billing['patient_gender'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text('HOSP#: ', style: pw.TextStyle(fontSize: 8)),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Container(
                      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
                      child: pw.Text(_billing['patient_hospital_id']?.toString() ?? '', style: const pw.TextStyle(fontSize: 8)),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('DATE ADMITTED: ', style: pw.TextStyle(fontSize: 8)),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Container(
                      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
                      child: pw.Text(_billing['created_at']?.toString().substring(0, 10) ?? '', style: const pw.TextStyle(fontSize: 8)),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text('TIME: ', style: pw.TextStyle(fontSize: 8)),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Container(
                      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
                      child: pw.Text('', style: const pw.TextStyle(fontSize: 8)),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Container(
                    color: PdfColors.yellow100,
                    child: pw.Text('DATE DISCHARGE: ', style: pw.TextStyle(fontSize: 8)),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Container(
                      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
                      child: pw.Text('02/14/2026', style: const pw.TextStyle(fontSize: 8)),
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                    child: pw.Text('MGH', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('ADDRESS: ', style: pw.TextStyle(fontSize: 8)),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Container(
                      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
                      child: pw.Text(_billing['patient_address'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                    ),
                  ),
                  pw.SizedBox(width: 15),
                  pw.Text('WARD: ', style: pw.TextStyle(fontSize: 8)),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Container(
                      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
                      child: pw.Text(_billing['ward'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                    ),
                  ),
                  pw.Spacer(flex: 1),
                ],
              ),

              pw.SizedBox(height: 20),

              // TABLES SECTION - Side-by-Side
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // MEDICAL SUPPLIES
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.all(1),
                          decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5), color: PdfColors.grey200),
                          width: double.infinity,
                          child: pw.Center(child: pw.Text('MEDICAL SUPPLIES', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                        ),
                        pw.Table(
                          border: pw.TableBorder.all(width: 0.5),
                          columnWidths: {
                            0: const pw.FlexColumnWidth(1.2), // DATE
                            1: const pw.FlexColumnWidth(3.5), // ITEM
                            2: const pw.FlexColumnWidth(0.8), // QTY
                            3: const pw.FlexColumnWidth(1.2), // UNIT COST
                            4: const pw.FlexColumnWidth(1.2), // TOTAL COST
                          },
                          children: [
                            pw.TableRow(
                              children: [
                                pw.Center(child: pw.Text('DATE', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold))),
                                pw.Center(child: pw.Text('ITEM USED', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold))),
                                pw.Center(child: pw.Text('QTY', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold))),
                                pw.Center(child: pw.Text('UNIT COST', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold))),
                                pw.Center(child: pw.Text('TOTAL COST', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold))),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  // MEDICINES
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.all(1),
                          decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5), color: PdfColors.grey200),
                          width: double.infinity,
                          child: pw.Center(child: pw.Text('MEDICINES', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                        ),
                        pw.Table(
                          border: pw.TableBorder.all(width: 0.5),
                          columnWidths: {
                            0: const pw.FlexColumnWidth(1.2),
                            1: const pw.FlexColumnWidth(3.5),
                            2: const pw.FlexColumnWidth(0.8),
                            3: const pw.FlexColumnWidth(1.2),
                            4: const pw.FlexColumnWidth(1.2),
                          },
                          children: [
                            pw.TableRow(
                              children: [
                                pw.Center(child: pw.Text('DATE', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold))),
                                pw.Center(child: pw.Text('ITEM USED', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold))),
                                pw.Center(child: pw.Text('QTY', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold))),
                                pw.Center(child: pw.Text('UNIT COST', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold))),
                                pw.Center(child: pw.Text('TOTAL COST', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold))),
                              ],
                            ),
                            ...items.map((item) {
                              final itemId = item['receipt_item_id'];
                              final controller = _quantityControllers[itemId];
                              // Strictly use quantity column
                              final actualQty = double.tryParse(controller?.text ?? item['quantity']?.toString() ?? '0') ?? 0.0;
                              final unitCost = _getVal(item['unit_cost']);
                              final lineTotal = unitCost * actualQty;

                              return pw.TableRow(
                                children: [
                                  pw.Center(child: pw.Text(item['dispensing_date']?.toString().substring(0, 10) ?? '', style: const pw.TextStyle(fontSize: 6))),
                                  pw.Padding(padding: const pw.EdgeInsets.only(left: 2), child: pw.Text(item['medicine_name'] ?? '', style: const pw.TextStyle(fontSize: 6))),
                                  pw.Center(child: pw.Text(actualQty.toInt().toString(), style: const pw.TextStyle(fontSize: 6))),
                                  pw.Center(child: pw.Text(unitCost.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 6))),
                                  pw.Center(child: pw.Text(lineTotal.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 6))),
                                ],
                              );
                            }).toList(),
                            // ADD ADDITIONAL ITEMS TO PDF
                            ..._additionalItems.asMap().entries.map((entry) {
                              final i = entry.key;
                              final item = entry.value;
                              final qtyController = _additionalQtyControllers[i];
                              
                              final actualQty = double.tryParse(qtyController?.text ?? '0') ?? 0.0;
                              final unitCost = _getVal(item['unit_cost']);
                              final lineTotal = unitCost * actualQty;

                              return pw.TableRow(
                                children: [
                                  pw.Center(child: pw.Text(DateTime.now().toString().substring(0, 10), style: const pw.TextStyle(fontSize: 6))),
                                  pw.Padding(padding: const pw.EdgeInsets.only(left: 2), child: pw.Text(item['medicine_name'] ?? '', style: const pw.TextStyle(fontSize: 6))),
                                  pw.Center(child: pw.Text(actualQty.toInt().toString(), style: const pw.TextStyle(fontSize: 6))),
                                  pw.Center(child: pw.Text(unitCost.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 6))),
                                  pw.Center(child: pw.Text(lineTotal.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 6))),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                        pw.SizedBox(height: 30),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          children: [
                            pw.Text('TOTAL AMOUNT: P${calculatedTotalAmount.toStringAsFixed(2)}', 
                              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Dispensing_Sheet_${_billing['patient_name'] ?? 'Record'}.pdf',
    );
    
    // Do not close dialog after printing - keep it open for user to review
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Dialog(
      insetPadding: EdgeInsets.all(isMobile ? 8 : 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
      ),
      child: Container(
        width: isMobile ? screenWidth * 0.98 : 1000,
        constraints: BoxConstraints(maxHeight: isMobile ? MediaQuery.of(context).size.height * 0.46 : 850),
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
                    child: Icon(Icons.description, color: const Color(0xFF1976D2), size: isMobile ? 20 : 24),
                  ),
                  SizedBox(width: isMobile ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pharmacy Dispensing Sheet',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: isMobile ? 1 : 2),
                        Text(
                          'IPD Patient Billing Summary',
                          style: TextStyle(
                            fontSize: isMobile ? 11 : 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
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
                    // Hospital Form Section
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(isMobile ? 2 : 4),
                        border: Border.all(color: Colors.black87, width: isMobile ? 1 : 1.5),
                      ),
                      child: Column(
                        children: [
                          // Header Section
                          Container(
                            padding: EdgeInsets.all(isMobile ? 12 : 16),
                            child: Column(
                              children: [
                                Text('Republic of the Philippines', style: TextStyle(fontSize: isMobile ? 8 : 10, color: Colors.grey[700])),
                                Text('Province of Misamis Occidental', style: TextStyle(fontSize: isMobile ? 8 : 10, color: Colors.grey[700])),
                                Text('MUNICIPALITY OF PLARIDEL', style: TextStyle(fontSize: isMobile ? 8 : 10, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                                SizedBox(height: isMobile ? 6 : 8),
                                Text('PLARIDEL COMMUNITY HOSPITAL', style: TextStyle(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                                SizedBox(height: isMobile ? 3 : 4),
                                Container(
                                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.purple, width: 1.5))),
                                  child: Text('PHARMACY DISPENSING SHEET', style: TextStyle(fontSize: isMobile ? 12 : 14, fontWeight: FontWeight.bold, color: Colors.purple)),
                                ),
                              ],
                            ),
                          ),
                          // Patient Info Grid
                          Container(
                            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.black87, width: 1))),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Column 1
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.black87, width: 1))),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildFormField('NAME:', _billing['patient_name'] ?? ''),
                                          const SizedBox(height: 12),
                                          _buildFormField('DATE ADMITTED:', _billing['created_at']?.toString().substring(0, 10) ?? ''),
                                          const SizedBox(height: 12),
                                          _buildFormField('ADDRESS:', _billing['patient_address'] ?? ''),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Column 2
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.black87, width: 1))),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildFormField('AGE:', _billing['patient_age']?.toString() ?? 'N/A'),
                                          const SizedBox(height: 12),
                                          _buildFormField('TIME:', '—'),
                                          const SizedBox(height: 12),
                                          _buildFormField('WARD:', _billing['ward'] ?? ''),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Column 3
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildFormField('GENDER:', _billing['patient_gender'] ?? 'N/A'),
                                          const SizedBox(height: 12),
                                          _buildFormField('DATE DISCHARGE:', '—'),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(child: _buildFormField('HOSP#:', _billing['patient_hospital_id']?.toString() ?? '')),
                                              if (_billing['mgh'] == true || true)
                                                Container(
                                                  margin: const EdgeInsets.only(left: 8),
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(border: Border.all(color: Colors.black87, width: 1)),
                                                  child: const Text('MGH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Tables Header
                          Container(
                            padding: EdgeInsets.symmetric(vertical: isMobile ? 6 : 8),
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
                                  child: Center(
                                    child: Text(
                                      'MEDICAL SUPPLIES',
                                      style: TextStyle(
                                        fontSize: isMobile ? 10 : 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ),
                                ),
                                Container(width: 1, height: 20, color: Colors.black87),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      'MEDICINES',
                                      style: TextStyle(
                                        fontSize: isMobile ? 10 : 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Tables
                          SingleChildScrollView(
                            scrollDirection: isMobile ? Axis.horizontal : Axis.vertical,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Medical Supplies Table (Left - Empty)
                                Expanded(
                                  child: _buildSuppliesTable(),
                                ),
                                Container(width: 1, color: Colors.black87),
                                // Medicines Table (Right)
                                Expanded(
                                  child: _buildMedicinesTable(),
                                ),
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
            // Footer Buttons
            Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: _buildFooterButtons(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField(String label, String value) {
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
                  fontSize: 12,
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

  Widget _buildSuppliesTable() {
    return Column(
      children: [
        // Table Header
        Container(
          height: 32,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTableCell(flex: 2, child: _buildTableHeaderInternal('DATE')),
                _buildTableCell(flex: 4, child: _buildTableHeaderInternal('ITEM USED')),
                _buildTableCell(flex: 2, child: _buildTableHeaderInternal('QTY')),
                _buildTableCell(flex: 2, child: _buildTableHeaderInternal('UNIT COST')),
                _buildTableCell(flex: 2, child: _buildTableHeaderInternal('TOTAL COST')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicinesTable() {
    final List<dynamic> items = _billing['items'] as List? ?? [];
    final int medicineRowCount = items.length + _additionalItems.length;
    
    // Build list of children with all items (no limit)
    final List<Widget> children = [
      // Table Header
      Container(
        height: 32,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTableCell(flex: 2, child: _buildTableHeaderInternal('DATE')),
              _buildTableCell(flex: 4, child: _buildTableHeaderInternal('ITEM USED')),
              _buildTableCell(flex: 2, child: _buildTableHeaderInternal('QTY')),
              _buildTableCell(flex: 2, child: _buildTableHeaderInternal('UNIT COST')),
              _buildTableCell(flex: 2, child: _buildTableHeaderInternal('TOTAL COST')),
            ],
          ),
        ),
      ),
      // Medicine rows - show all items
      ...items.map((item) {
        return _buildMedicineRow(item);
      }).toList(),
      
      // ADDITIONAL ITEMS ROWS - show all
      ..._additionalItems.asMap().entries.map((entry) {
        return _buildAdditionalMedicineRow(entry.key, entry.value);
      }).toList(),

      // ADD ITEM BUTTON (Only if editable)
      if (_isEditable)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: TextButton.icon(
            onPressed: _showAddMedicineDialog,
            icon: const Icon(Icons.add_circle_outline, size: 16, color: Colors.green),
            label: const Text(
              'Add Medicine from Chart',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ),
        ),
    ];
    
    return Column(
      children: children,
    );
  }

  Future<void> _showAddMedicineDialog() async {
    // ONLY GET MEDICINES THAT ARE IN THE CART (location_id 2)
    // We prioritize location 2 as it's the standard Cart location shown in Inventory Carts
    const int cartLocationId = 2; 
    
    try {
      AppLogger.info('Fetching cart inventory for location: $cartLocationId');
      final List<dynamic> cartInventory = await _pharmacyService.getInventoryBalancesByLocation(cartLocationId);
      
      if (!mounted) return;

      // Filter out items with 0 stock and map to medicine structure
      final List<Map<String, dynamic>> availableMedicines = [];
      final Set<int> addedMedicineIds = {};

      for (var item in cartInventory) {
        final rawQty = item['qty_on_hand'];
        final qty = rawQty is num ? rawQty.toDouble() : (double.tryParse(rawQty?.toString() ?? '0') ?? 0.0);
        
        // Check for medicine ID in multiple possible keys
        final medId = item['medicine_id'] ?? item['medicine'];
        
        if (qty > 0 && medId != null && !addedMedicineIds.contains(medId)) {
          availableMedicines.add({
            'medicine_id': medId is String ? int.tryParse(medId) : medId,
            'medicine_name': item['medicine_name'] ?? 'Unknown',
            'unit_cost': item['unit_cost'],
            'unit': item['unit'] ?? 'Tablet',
            'qty_on_hand': qty,
          });
          addedMedicineIds.add(medId is String ? int.parse(medId) : medId);
        }
      }

      AppLogger.info('Found ${availableMedicines.length} medicines with stock in cart');

      final selectedMedicine = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) {
          String searchQuery = '';
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final filtered = availableMedicines.where((m) {
                final name = m['medicine_name']?.toString().toLowerCase() ?? '';
                return name.contains(searchQuery.toLowerCase());
              }).toList();

              return AlertDialog(
                title: const Text('Add Medicine from Chart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                content: SizedBox(
                  width: 400,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search medicine in cart...',
                            prefixIcon: Icon(Icons.search),
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) => setDialogState(() => searchQuery = val),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 300,
                          child: filtered.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey[300]),
                                      const SizedBox(height: 16),
                                      Text(
                                        availableMedicines.isEmpty 
                                            ? 'No medicines with stock found in cart' 
                                            : 'No matching medicines in cart',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: filtered.length,
                                  separatorBuilder: (context, index) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final med = filtered[index];
                                    final double cost = (med['unit_cost'] is num) 
                                        ? med['unit_cost'].toDouble() 
                                        : (double.tryParse(med['unit_cost']?.toString() ?? '0') ?? 0.0);
                                    
                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      title: Text(med['medicine_name'] ?? 'Unknown', 
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                      subtitle: Text('₱${cost.toStringAsFixed(2)} / ${med['unit']}', 
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Stock: ${med['qty_on_hand'].toInt()}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                                        ),
                                      ),
                                      onTap: () => Navigator.pop(context, med),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ],
              );
            },
          );
        },
      );

      if (selectedMedicine != null) {
        double fefoUnitCost = double.tryParse(selectedMedicine['unit_cost']?.toString() ?? '0') ?? 0.0;
        
        try {
          final batches = await _pharmacyService.getMedicineBatches(selectedMedicine['medicine_id']);
          if (batches.isNotEmpty) {
            // Filter batches with stock and sort by expiry date (FEFO)
            final validBatches = batches.where((b) {
              final qty = double.tryParse(b['quantity']?.toString() ?? '0') ?? 0.0;
              return qty > 0;
            }).toList();
            
            if (validBatches.isNotEmpty) {
              validBatches.sort((a, b) {
                final dateA = DateTime.tryParse(a['expiry_date'] ?? '') ?? DateTime(9999);
                final dateB = DateTime.tryParse(b['expiry_date'] ?? '') ?? DateTime(9999);
                return dateA.compareTo(dateB);
              });
              
              fefoUnitCost = double.tryParse(validBatches.first['unit_cost']?.toString() ?? '0') ?? fefoUnitCost;
            }
          }
        } catch (e) {
          AppLogger.error('Error fetching FEFO cost: $e');
        }

        setState(() {
          final index = _additionalItems.length;
          _additionalItems.add({
            'medicine_id': selectedMedicine['medicine_id'],
            'medicine_name': selectedMedicine['medicine_name'],
            'unit_cost': fefoUnitCost,
          });
          
          _additionalQtyControllers[index] = TextEditingController(text: '1');
          _additionalQtyControllers[index]!.addListener(() { if (mounted) setState(() {}); });
        });
      }
    } catch (e) {
      AppLogger.error('Error in _showAddMedicineDialog: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cart medicines: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildTableHeaderInternal(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildAdditionalMedicineRow(int index, Map<String, dynamic> item) {
    final qtyController = _additionalQtyControllers[index];
    
    double unitCost = _getVal(item['unit_cost']);
    double qty = double.tryParse(qtyController?.text ?? '0') ?? 0.0;
    double totalCost = unitCost * qty;

    return Container(
      height: 32,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTableCell(
              flex: 2,
              child: Text(
                DateTime.now().toString().substring(0, 10),
                style: const TextStyle(fontSize: 10, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),
            _buildTableCell(
              flex: 4,
              child: Row(
                children: [
                  const Icon(Icons.add_circle, size: 10, color: Colors.green),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item['medicine_name'] ?? 'Unknown',
                      style: const TextStyle(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (_isEditable)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 14, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _additionalItems.removeAt(index);
                          _additionalQtyControllers.remove(index);
                        });
                      },
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
            _buildTableCell(
              flex: 2,
              child: _isEditable && qtyController != null
                  ? _buildQuantityInput(qtyController)
                  : Text(
                      qty.toInt().toString(),
                      style: const TextStyle(fontSize: 10, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
            ),
            _buildTableCell(
              flex: 2,
              child: Text(
                '₱${unitCost.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 10, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),
            _buildTableCell(
              flex: 2,
              child: Text(
                '₱${totalCost.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineRow(Map<String, dynamic> item) {
    final itemId = item['receipt_item_id'];
    final controller = _quantityControllers[itemId];

    // Format date from created_at or dispensing_date
    String displayDate = item['dispensing_date'] ?? _billing['dispensing_date'] ?? '';
    if (displayDate.length > 10) displayDate = displayDate.substring(0, 10);

    // Safely parse unit cost and total cost
    double unitCost = 0.0;
    double totalCost = 0.0;
    
    var rawUnitCost = item['unit_cost'];
    if (rawUnitCost != null) {
      unitCost = (rawUnitCost is String) ? (double.tryParse(rawUnitCost) ?? 0.0) : (rawUnitCost as num).toDouble();
    }
    
    var rawTotalCost = item['total_cost'];
    if (rawTotalCost != null) {
      totalCost = (rawTotalCost is String) ? (double.tryParse(rawTotalCost) ?? 0.0) : (rawTotalCost as num).toDouble();
    }

    // DYNAMICALLY RECALCULATE TOTAL COST IN THE UI
    if (controller != null) {
      final currentQty = double.tryParse(controller.text) ?? 0.0;
      totalCost = unitCost * currentQty;
    }

    return Container(
      height: 32,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTableCell(
              flex: 2,
              child: Text(
                displayDate,
                style: const TextStyle(fontSize: 10, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),
            _buildTableCell(
              flex: 4,
              child: Text(
                item['medicine_name'] ?? item['item_description'] ?? 'Unknown',
                style: const TextStyle(fontSize: 10, color: Colors.black87),
              ),
            ),
            _buildTableCell(
              flex: 2,
              child: _isEditable && controller != null
                  ? _buildQuantityInput(controller)
                  : Text(
                      // Strictly use the value from our backend quantity column
                      (double.tryParse(controller?.text ?? item['quantity']?.toString() ?? '0') ?? 0.0).toInt().toString(),
                      style: const TextStyle(fontSize: 10, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
            ),
            _buildTableCell(
              flex: 2,
              child: Text(
                '₱${unitCost.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 10, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),
            _buildTableCell(
              flex: 2,
              child: Text(
                '₱${totalCost.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 10, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCell({required int flex, required Widget child}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black87, width: 1.0),
        ),
        child: Align(alignment: Alignment.center, child: child),
      ),
    );
  }

  Widget _buildEmptyTableRow() {
    return Container(
      height: 32,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTableCell(flex: 2, child: Container()),
            _buildTableCell(flex: 4, child: Container()),
            _buildTableCell(flex: 2, child: Container()),
            _buildTableCell(flex: 2, child: Container()),
            _buildTableCell(flex: 2, child: Container()),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityInput(TextEditingController controller) {
    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF4CAF50), width: 1.5),
      ),
      child: Row(
        children: [
          // Number input
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 2),
                border: InputBorder.none,
              ),
            ),
          ),
          // Up/Down buttons
          Container(
            width: 16,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    final currentValue = int.tryParse(controller.text) ?? 0;
                    controller.text = (currentValue + 1).toString();
                  },
                  child: Icon(
                    Icons.arrow_drop_up,
                    size: 10,
                    color: Colors.grey[600],
                  ),
                ),
                InkWell(
                  onTap: () {
                    final currentValue = int.tryParse(controller.text) ?? 0;
                    if (currentValue > 0) {
                      controller.text = (currentValue - 1).toString();
                    }
                  },
                  child: Icon(
                    Icons.arrow_drop_down,
                    size: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFooterButtons() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    if (_isLoading) {
      return [const Center(child: CircularProgressIndicator())];
    }

    var buttons = <Widget>[];

    // Add state-specific primary action buttons first
    switch (_buttonState) {
      case 'finalize':
        buttons.add(
          OutlinedButton.icon(
            onPressed: _onEnableEditing,
            icon: Icon(Icons.edit_note, size: isMobile ? 18 : 20),
            label: Text('Finalize Quantity', style: TextStyle(fontSize: isMobile ? 12 : 14)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2E7D32),
              side: const BorderSide(color: Color(0xFF2E7D32)),
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20, vertical: isMobile ? 10 : 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        );
        break;
      case 'save':
        buttons.add(
          ElevatedButton.icon(
            onPressed: _onSaveAndFinalize,
            icon: Icon(Icons.save_as, size: isMobile ? 18 : 20),
            label: Text('Save & Finalize', style: TextStyle(fontSize: isMobile ? 12 : 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20, vertical: isMobile ? 10 : 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        );
        break;
      case 'send':
        buttons.add(
          ElevatedButton.icon(
            onPressed: _onSendToBilling,
            icon: Icon(Icons.send, size: isMobile ? 18 : 20),
            label: Text('Send to Billing', style: TextStyle(fontSize: isMobile ? 12 : 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20, vertical: isMobile ? 10 : 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        );
        break;
      case 'print':
        buttons.add(
          ElevatedButton.icon(
            onPressed: _onPrint,
            icon: Icon(Icons.print, size: isMobile ? 18 : 20),
            label: Text('Print', style: TextStyle(fontSize: isMobile ? 12 : 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20, vertical: isMobile ? 10 : 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        );
        break;
    }

    // Add spacing between buttons
    if (buttons.isNotEmpty) {
      final List<Widget> spacedButtons = [];
      for (int i = 0; i < buttons.length; i++) {
        spacedButtons.add(buttons[i]);
        if (i < buttons.length - 1) {
          spacedButtons.add(SizedBox(width: isMobile ? 8 : 12));
        }
      }
      buttons = spacedButtons;
    }

    // Always add the Print button after the primary actions
    buttons.add(
      ElevatedButton.icon(
        onPressed: _onPrint,
        icon: const Icon(Icons.print, size: 20),
        label: const Text('Print'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF64748B),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );

    return buttons;
  }
}

/// A standalone row widget for the IPD Pharmacy Billing list.
/// Moved here from the page file to centralize billing-related UI components.
class BillingPatientRow extends StatelessWidget {
  final dynamic initials;
  final dynamic name;
  final dynamic patientId;
  final dynamic ward;
  final dynamic dateAdmitted;
  final dynamic items;
  final dynamic totalAmount;
  final dynamic status;
  final VoidCallback onTap;

  const BillingPatientRow({
    super.key,
    required this.initials,
    required this.name,
    required this.patientId,
    required this.ward,
    required this.dateAdmitted,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // FORCE ALL INPUTS TO STRING IMMEDIATELY
    final String sInitials = initials?.toString() ?? '?';
    final String sName = name?.toString() ?? 'Unknown';
    final String sPatientId = patientId?.toString() ?? '—';
    final String sWard = ward?.toString() ?? 'N/A';
    final String sDateAdmitted = dateAdmitted?.toString() ?? 'N/A';
    final String sItems = items?.toString() ?? '0 items';
    final String sTotalAmount = totalAmount?.toString() ?? '₱0.00';
    final String sStatus = status?.toString() ?? 'Draft';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Patient Details
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      sInitials,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      sPatientId,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Ward
          Expanded(
            flex: 1,
            child: Text(
              sWard,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ),
          // Date Admitted
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  sDateAdmitted,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Items Dispensed
          Expanded(
            flex: 1,
            child: Text(
              sItems,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          // Total Amount
          Expanded(
            flex: 1,
            child: Text(
              sTotalAmount,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          // Status
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    sStatus,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Action
          Expanded(
            flex: 1,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.description_outlined, size: 16),
              label: const Text('View Billing Sheet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
