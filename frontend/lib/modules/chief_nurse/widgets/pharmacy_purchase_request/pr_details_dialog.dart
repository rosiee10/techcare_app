import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'pr_status_chip.dart';

/// Purchase Request Details Dialog for Chief Nurse
/// Shows full PR details with print option for approved PRs
class PRDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> purchaseRequest;

  const PRDetailsDialog({
    super.key,
    required this.purchaseRequest,
  });

  static Future<void> show({
    required BuildContext context,
    required Map<String, dynamic> purchaseRequest,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => PRDetailsDialog(purchaseRequest: purchaseRequest),
    );
  }

  /// Generate PDF document for the Purchase Request
  Future<pw.Document> _generatePDF() async {
    final pdf = pw.Document();
    final pr = purchaseRequest;
    final items = pr['itemsList'] as List<dynamic>;
    final dateFormat = DateFormat('MM/dd/yyyy');

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
                          child: _buildPDFRowWithUnderline('LGU:', pr['lgu'] ?? 'PLARIDEL'),
                        ),
                        pw.Expanded(
                          child: _buildPDFRowWithUnderline('Fund:', pr['fund'] ?? 'N/A'),
                        ),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildPDFRowWithUnderline('Department:', pr['department'] ?? 'PCH'),
                        ),
                        pw.Expanded(
                          child: _buildPDFRowWithUnderline('PR No.:', pr['prNo'] ?? 'N/A'),
                        ),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildPDFRowWithUnderline('Section:', pr['section'] ?? 'N/A'),
                        ),
                        pw.Expanded(
                          child: _buildPDFRowWithUnderline('FPP :', pr['fpp'] ?? 'N/A'),
                        ),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildPDFRowWithUnderline('Date:', pr['date'] != null ? dateFormat.format(DateTime.parse(pr['date'])) : 'N/A'),
                        ),
                        pw.Expanded(
                          child: pw.SizedBox(),
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
                  4: const pw.FixedColumnWidth(55),
                  5: const pw.FixedColumnWidth(60),
                  6: const pw.FixedColumnWidth(65),
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
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Center(child: pw.Text('$index', style: pw.TextStyle(fontSize: 9))),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Center(child: pw.Text(item['unit'] ?? 'pcs', style: pw.TextStyle(fontSize: 9))),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Padding(padding: const pw.EdgeInsets.only(left: 8), child: pw.Text(item['name'] ?? 'Unknown', style: pw.TextStyle(fontSize: 9))),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Center(child: pw.Text('${item['qty']}', style: pw.TextStyle(fontSize: 9))),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Center(child: pw.Text(item['unit'] ?? 'pcs', style: pw.TextStyle(fontSize: 9))),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Center(child: pw.Text((item['unitPrice'] as double).toStringAsFixed(2), style: pw.TextStyle(fontSize: 9))),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Center(child: pw.Text((item['total'] as double).toStringAsFixed(2), style: pw.TextStyle(fontSize: 9))),
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
                    (pr['totalCost'] as double).toStringAsFixed(2),
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
                      pw.Text(pr['requestedBy'] ?? 'N/A', style: pw.TextStyle(fontSize: 9)),
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
        name: 'PR-${purchaseRequest['prNo']}.pdf',
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
      final file = File('${directory.path}/PR-${purchaseRequest['prNo']}.pdf');
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

  @override
  Widget build(BuildContext context) {
    final pr = purchaseRequest;
    final items = pr['itemsList'] as List<dynamic>;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    // Use actual values if status is DELIVERED, otherwise use requested values
    final isDelivered = pr['status']?.toString().toUpperCase() == 'DELIVERED';
    
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('PR: ${pr['prNo']}'),
          Row(
            children: [
              PRStatusChip(status: pr['status']),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
      content: Container(
        width: isMobile ? screenWidth * 0.95 : 700.0,
        constraints: BoxConstraints(
          maxHeight: isMobile ? screenWidth * 0.9 : 600,
          maxWidth: 700,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                Expanded(
                  child: _buildPRInfoRow('LGU:', pr['lgu']),
                ),
                Expanded(
                  child: _buildPRInfoRow('Fund:', pr['fund']),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _buildPRInfoRow('Department:', pr['department']),
                ),
                Expanded(
                  child: _buildPRInfoRow('PR No.:', pr['prNo']),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _buildPRInfoRow('Section:', pr['section']),
                ),
                Expanded(
                  child: _buildPRInfoRow('FPP:', pr['fpp']),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _buildPRInfoRow('Date:', pr['date']),
                ),
                Expanded(
                  child: _buildPRInfoRow('Requested by:', pr['requestedBy']),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Items Section
            const Text(
              'Items',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 12),

            // Items Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Medicine',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Qty',
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
                    ],
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
                          isDelivered ? 'Qty Received' : 'Qty Requested',
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
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: Column(
                children: [
                  const Divider(height: 1),

                  // Table Rows
                  ...items.where((item) => item is Map).map<Widget>((item) {
                    String medicine = (item as Map)['name']?.toString() ?? '';
                    if (medicine.isEmpty) {
                      medicine = 'Unknown Medicine';
                    }

                    final qty = item['qty'] ?? 0;
                    final price = double.tryParse(item['unitPrice']?.toString() ?? '0') ?? 0;
                    final total = double.tryParse(item['total']?.toString() ?? '0') ?? 0;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                      ),
                      child: isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                medicine,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Qty: ${qty.toString()}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '₱${price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '₱${total.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2196F3),
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Total Amount: ', style: TextStyle(fontSize: 16)),
                Text(
                  '₱${pr['totalCost'].toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
      actions: [
        if (pr['status'] == 'Approved')
          ElevatedButton.icon(
            onPressed: () => _printPDF(context),
            icon: const Icon(Icons.print),
            label: const Text('Print'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
            ),
          ),
      ],
    );
  }

  Widget _buildPRInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
