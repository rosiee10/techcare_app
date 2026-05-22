import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PurchaseRequestDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback? onConfirmDelivery;

  const PurchaseRequestDetailsDialog({
    super.key,
    required this.request,
    this.onConfirmDelivery,
  });

  /// Show the dialog
  static Future<void> show(BuildContext context, {
    required Map<String, dynamic> request,
    VoidCallback? onConfirmDelivery,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => PurchaseRequestDetailsDialog(
        request: request,
        onConfirmDelivery: onConfirmDelivery,
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _getStatusLabel(String? status) {
    if (status == null) return 'DRAFT';
    return status.toUpperCase();
  }

  Color _getStatusColor(String? status) {
    final s = status?.toLowerCase() ?? '';
    if (s == 'draft' || s == 'pending') {
      return const Color(0xFFF57F17); // Orange
    } else if (s == 'approved') {
      return const Color(0xFF2E7D32); // Green
    } else if (s == 'delivered') {
      return const Color(0xFF1976D2); // Blue
    } else if (s == 'rejected' || s == 'cancelled') {
      return Colors.red;
    }
    return const Color(0xFFF57F17);
  }

  Color _getStatusBgColor(String? status) {
    final s = status?.toLowerCase() ?? '';
    if (s == 'draft' || s == 'pending') {
      return const Color(0xFFFFF9C4); // Light yellow
    } else if (s == 'approved') {
      return const Color(0xFFE8F5E9); // Light green
    } else if (s == 'delivered') {
      return const Color(0xFFE3F2FD); // Light blue
    } else if (s == 'rejected' || s == 'cancelled') {
      return Colors.red[50]!;
    }
    return const Color(0xFFFFF9C4);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final dialogWidth = isMobile ? screenWidth * 0.98 : 700.0;

    final items = request['items'] ?? [];
    
    // Use actual totals if status is DELIVERED, otherwise use estimated totals
    final isDelivered = request['status']?.toString().toUpperCase() == 'DELIVERED' ||
                      request['pr_status']?.toString().toUpperCase() == 'DELIVERED';
    
    final totalAmount = items.fold(0.0, (sum, item) {
      final goodsReceiptItem = item['goods_receipt_item'];
      final lineTotal = isDelivered && goodsReceiptItem != null
          ? (double.tryParse(goodsReceiptItem['line_total_actual']?.toString() ?? '0') ?? 0)
          : (double.tryParse(item['line_total_estimate']?.toString() ?? '0') ?? 0);
      return sum + lineTotal;
    });

    return Dialog(
      insetPadding: EdgeInsets.all(isMobile ? 8 : 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isMobile ? 12 : 16)),
      child: Container(
        width: isMobile ? screenWidth * 0.98 : dialogWidth,
        constraints: BoxConstraints(
          maxHeight: isMobile ? MediaQuery.of(context).size.height * 0.46 : 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 24),
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
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      SizedBox(height: isMobile ? 3 : 4),
                      Text(
                        request['pr_no'] ?? request['pr_number'] ?? 'PR-???',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.grey),
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
                    // Status
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Status:',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(width: isMobile ? 6 : 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 12, vertical: isMobile ? 3 : 4),
                          decoration: BoxDecoration(
                            color: _getStatusBgColor(request['pr_status'] ?? request['status']),
                            borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                          ),
                          child: Text(
                            _getStatusLabel(request['pr_status'] ?? request['status']),
                            style: TextStyle(
                              fontSize: isMobile ? 10 : 12,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(request['pr_status'] ?? request['status']),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: isMobile ? 16 : 24),

                    // Request Type and Date
                    isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoColumn('Request Type', '${request['purchase_type'] ?? 'Regular'} Purchase Request'),
                            SizedBox(height: isMobile ? 12 : 16),
                            _buildInfoColumn('Date Requested', _formatDate(request['requested_date'] ?? request['request_date'])),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _buildInfoColumn('Request Type', '${request['purchase_type'] ?? 'Regular'} Purchase Request'),
                            ),
                            SizedBox(width: isMobile ? 12 : 16),
                            Expanded(
                              child: _buildInfoColumn('Date Requested', _formatDate(request['requested_date'] ?? request['request_date'])),
                            ),
                          ],
                        ),

                    SizedBox(height: isMobile ? 16 : 24),

                    // Items Section
                    Text(
                      'Items',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: isMobile ? 12 : 16),

                    // Items Table Header
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 8 : 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(isMobile ? 6 : 8)),
                      ),
                      child: isMobile
                        ? SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    'Medicine',
                                    style: TextStyle(
                                      fontSize: isMobile ? 10 : 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                                SizedBox(width: isMobile ? 8 : 12),
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    isDelivered ? 'Qty' : 'Qty',
                                    style: TextStyle(
                                      fontSize: isMobile ? 10 : 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                                SizedBox(width: isMobile ? 8 : 12),
                                SizedBox(
                                  width: 70,
                                  child: Text(
                                    'Price',
                                    style: TextStyle(
                                      fontSize: isMobile ? 10 : 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                SizedBox(width: isMobile ? 8 : 12),
                                SizedBox(
                                  width: 70,
                                  child: Text(
                                    'Total',
                                    style: TextStyle(
                                      fontSize: isMobile ? 10 : 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Medicine',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  isDelivered ? 'Qty Delivered' : 'Qty Requested',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Unit Price',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                    ),

                    // Items Table Content
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(isMobile ? 6 : 8)),
                      ),
                      child: Column(
                        children: [
                          const Divider(height: 1),

                          // Table Rows
                          ...items.where((item) => item is Map).map<Widget>((item) {
                            // Get medicine name - use medicine_name field first, fallback to medicine lookup
                            String medicine = (item as Map)['medicine_name']?.toString() ?? '';
                            if (medicine.isEmpty && item['medicine'] != null && item['medicine'] is Map) {
                              medicine = item['medicine']['medicine_name']?.toString() ?? 'Unknown Medicine';
                            }
                            if (medicine.isEmpty) {
                              medicine = 'Unknown Medicine';
                            }

                            // Use actual values if status is DELIVERED, otherwise use requested values
                            final isDelivered = request['status']?.toString().toUpperCase() == 'DELIVERED' ||
                                              request['pr_status']?.toString().toUpperCase() == 'DELIVERED';
                            
                            final goodsReceiptItem = item['goods_receipt_item'];
                            
                            final qty = isDelivered && goodsReceiptItem != null
                                ? (goodsReceiptItem['qty_received'] ?? item['qty_requested'] ?? item['quantity_requested'] ?? 0)
                                : (item['qty_requested'] ?? item['quantity_requested'] ?? 0);
                            
                            final price = isDelivered && goodsReceiptItem != null
                                ? (double.tryParse(goodsReceiptItem['unit_cost_actual']?.toString() ?? '0') ?? 0)
                                : (double.tryParse(item['unit_cost_estimate']?.toString() ?? '0') ?? 0);
                            
                            final total = isDelivered && goodsReceiptItem != null
                                ? (double.tryParse(goodsReceiptItem['line_total_actual']?.toString() ?? '0') ?? 0)
                                : (double.tryParse(item['line_total_estimate']?.toString() ?? item['total_cost']?.toString() ?? '0') ?? 0);

                            return Container(
                              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 10 : 12),
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                              ),
                              child: isMobile
                                ? SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 120,
                                          child: Text(
                                            medicine,
                                            style: TextStyle(
                                              fontSize: isMobile ? 12 : 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                        ),
                                        SizedBox(width: isMobile ? 8 : 12),
                                        SizedBox(
                                          width: 60,
                                          child: Text(
                                            qty.toString(),
                                            style: TextStyle(
                                              fontSize: isMobile ? 11 : 13,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: isMobile ? 8 : 12),
                                        SizedBox(
                                          width: 70,
                                          child: Text(
                                            '₱${price.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: isMobile ? 11 : 13,
                                              color: Colors.grey[700],
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                        SizedBox(width: isMobile ? 8 : 12),
                                        SizedBox(
                                          width: 70,
                                          child: Text(
                                            '₱${total.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: isMobile ? 11 : 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF2196F3),
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          medicine,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          qty.toString(),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '₱${price.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '₱${total.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF2196F3),
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                            );
                          }).toList(),

                          // Total Row
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 10 : 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.vertical(bottom: Radius.circular(isMobile ? 6 : 8)),
                            ),
                            child: isMobile
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total Amount:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      '₱${totalAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2196F3),
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    const Spacer(flex: 5),
                                    const Text(
                                      'Total Amount:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      '₱${totalAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2196F3),
                                      ),
                                    ),
                                  ],
                                ),
                          ),
                        ],
                      ),
                    ),

                    if (request['remarks'] != null && request['remarks'].toString().isNotEmpty) ...[
                      SizedBox(height: isMobile ? 16 : 24),
                      Text(
                        'Remarks',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: isMobile ? 6 : 8),
                      Container(
                        padding: EdgeInsets.all(isMobile ? 10 : 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          request['remarks'].toString(),
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],

                    // Confirm Delivery Button for Approved PRs
                    if (request['status']?.toString().toUpperCase() == 'APPROVED' ||
                        request['pr_status']?.toString().toUpperCase() == 'APPROVED') ...[
                      SizedBox(height: isMobile ? 16 : 24),
                      isMobile
                        ? SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                onConfirmDelivery?.call();
                              },
                              icon: Icon(Icons.check_circle_outline, size: isMobile ? 18 : 20),
                              label: Text('Confirm Delivery', style: TextStyle(fontSize: isMobile ? 12 : 14)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20, vertical: isMobile ? 10 : 12),
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  onConfirmDelivery?.call();
                                },
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text('Confirm Delivery'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                    ],
                  ],
                ),
              ),
            ),

            // Actions
            Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Print button for DELIVERED PRs
                  if (isDelivered)
                    ElevatedButton.icon(
                      onPressed: () => _printPDF(context),
                      icon: Icon(Icons.print, size: isMobile ? 18 : 20),
                      label: Text('Print', style: TextStyle(fontSize: isMobile ? 12 : 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20, vertical: isMobile ? 10 : 12),
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

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  /// Generate PDF document for the Purchase Request
  Future<pw.Document> _generatePDF() async {
    final pdf = pw.Document();
    final items = request['items'] as List<dynamic>;
    final isDelivered = request['status']?.toString().toUpperCase() == 'DELIVERED' ||
                        request['pr_status']?.toString().toUpperCase() == 'DELIVERED';
    final dateFormat = DateFormat('MM/dd/yyyy');
    
    // Calculate total amount
    final totalAmount = items.fold(0.0, (sum, item) {
      final goodsReceiptItem = item['goods_receipt_item'];
      final lineTotal = isDelivered && goodsReceiptItem != null
          ? (double.tryParse(goodsReceiptItem['line_total_actual']?.toString() ?? '0') ?? 0)
          : (double.tryParse(item['line_total_estimate']?.toString() ?? '0') ?? 0);
      return sum + lineTotal;
    });

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Text(
                  'PURCHASE REQUEST',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // PR Information Grid - 2 columns
              pw.Container(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildPDFRowWithUnderline('LGU:', 'PLARIDEL'),
                        ),
                        pw.Expanded(
                          child: _buildPDFRowWithUnderline('Fund:', 'General Fund'),
                        ),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildPDFRowWithUnderline('Department:', 'PCH'),
                        ),
                        pw.Expanded(
                          child: _buildPDFRowWithUnderline('PR No.:', request['pr_no'] ?? request['pr_number'] ?? 'N/A'),
                        ),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildPDFRowWithUnderline('Section:', 'Pharmacy'),
                        ),
                        pw.Expanded(
                          child: _buildPDFRowWithUnderline('FPP:', 'N/A'),
                        ),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildPDFRowWithUnderline('Date:', request['requested_date'] != null ? dateFormat.format(DateTime.parse(request['requested_date'])) : 'N/A'),
                        ),
                        pw.Expanded(
                          child: _buildPDFRowWithUnderline('Type:', request['purchase_type'] ?? 'Regular'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Items Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black),
                columnWidths: {
                  0: const pw.FixedColumnWidth(40),
                  1: const pw.FixedColumnWidth(45),
                  2: const pw.FlexColumnWidth(3),
                  3: const pw.FixedColumnWidth(55),
                  4: const pw.FixedColumnWidth(70),
                  5: const pw.FixedColumnWidth(70),
                },
                children: [
                  // Header Row with sub-headers
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Center(child: pw.Text('Item No.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Center(child: pw.Text('Unit', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Center(child: pw.Text('Item Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Center(child: pw.Text('Quantity', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Center(child: pw.Text('Unit Cost', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Center(child: pw.Text('Total Cost', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      ),
                    ],
                  ),
                  // Sub-header Row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Center(child: pw.Text('ITEM NO.', style: pw.TextStyle(fontSize: 8))),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Center(child: pw.Text('Qty.', style: pw.TextStyle(fontSize: 8))),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Center(child: pw.Text('Unit', style: pw.TextStyle(fontSize: 8))),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.SizedBox(),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Center(child: pw.Text('UNIT PRICE', style: pw.TextStyle(fontSize: 8))),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Center(child: pw.Text('TOTAL', style: pw.TextStyle(fontSize: 8))),
                      ),
                    ],
                  ),
                  // Data Rows
                  ...items.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final item = entry.value;
                    
                    // Use actual values if delivered
                    final goodsReceiptItem = item['goods_receipt_item'];
                    final qty = isDelivered && goodsReceiptItem != null
                        ? (goodsReceiptItem['qty_received'] ?? item['qty_requested'] ?? 0)
                        : (item['qty_requested'] ?? 0);
                    final price = isDelivered && goodsReceiptItem != null
                        ? (goodsReceiptItem['unit_cost_actual'] ?? item['unit_cost_estimate'] ?? 0.0)
                        : (item['unit_cost_estimate'] ?? 0.0);
                    final total = isDelivered && goodsReceiptItem != null
                        ? (goodsReceiptItem['line_total_actual'] ?? item['line_total_estimate'] ?? 0.0)
                        : (item['line_total_estimate'] ?? 0.0);
                    
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Center(child: pw.Text('$index', style: pw.TextStyle(fontSize: 9))),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Center(child: pw.Text(item['unit_snapshot'] ?? 'pcs', style: pw.TextStyle(fontSize: 9))),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Padding(padding: const pw.EdgeInsets.only(left: 8), child: pw.Text(item['medicine_name'] ?? 'Unknown', style: pw.TextStyle(fontSize: 9))),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Center(child: pw.Text('$qty', style: pw.TextStyle(fontSize: 9))),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Center(child: pw.Text('$price', style: pw.TextStyle(fontSize: 9))),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Center(child: pw.Text('$total', style: pw.TextStyle(fontSize: 9))),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 20),

              // Grand Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Grand Total: ',
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    '${totalAmount.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 40),

              // Footer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.SizedBox(height: 35),
                      pw.Text('_____________________'),
                      pw.SizedBox(height: 4),
                      pw.Text('Requested By', style: pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(height: 4),
                      pw.Text('Pharmacist', style: pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.SizedBox(height: 35),
                      pw.Text('_____________________'),
                      pw.SizedBox(height: 4),
                      pw.Text('Approved By', style: pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(height: 4),
                      pw.Text('Chief Nurse', style: pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildPDFRow(String label, String value, {bool hasBorder = false, double labelWidth = 70}) {
    return pw.Container(
      decoration: hasBorder ? pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black)) : null,
      padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: labelWidth,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFRowWithUnderline(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
          ),
          pw.Expanded(
            child: pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
              ),
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(
                value,
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Print the PDF
  Future<void> _printPDF(BuildContext context) async {
    try {
      final pdf = await _generatePDF();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'PR-${request['pr_no'] ?? request['pr_number'] ?? 'N/A'}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing: ${e.toString()}')),
        );
      }
    }
  }

  /// Download the PDF
  Future<void> _downloadPDF(BuildContext context) async {
    try {
      final pdf = await _generatePDF();
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/PR-${request['pr_no'] ?? request['pr_number'] ?? 'N/A'}.pdf');
      await file.writeAsBytes(await pdf.save());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved to: ${file.path}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading: ${e.toString()}')),
        );
      }
    }
  }
}
