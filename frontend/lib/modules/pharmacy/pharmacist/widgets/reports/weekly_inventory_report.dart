import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Weekly Inventory Report widget - exact physical form layout
class WeeklyInventoryReport extends StatelessWidget {
  final Map<String, dynamic> data;

  const WeeklyInventoryReport({super.key, required this.data});

  /// Build the PDF table with the exact same layout as the on-screen preview
  static pw.Widget buildPdf(List<String> weekDates, List<Map<String, dynamic>> medicines) {
    if (weekDates.isEmpty || medicines.isEmpty) {
      return pw.Text('No data available');
    }

    const double dateColWidth = 58;
    const double nearExpColWidth = 60;

    final purple = PdfColor(0.72, 0.66, 0.79); // #B8A9C9

    // Header row with purple title cell + date cells + NEAR EXP
    final headerChildren = <pw.Widget>[
      pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: pw.BoxDecoration(
            color: purple,
            border: pw.Border.all(color: PdfColors.black, width: 1),
          ),
          child: pw.Text(
            'LIST OF MEDICINES',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
        ),
      ),
    ];

    for (final date in weekDates) {
      headerChildren.add(
        pw.Container(
          width: dateColWidth,
          padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1),
          ),
          child: pw.Text(
            date,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
        ),
      );
    }

    headerChildren.add(
      pw.Container(
        width: nearExpColWidth,
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 1),
        ),
        child: pw.Text(
          'NEAR EXP',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
      ),
    );

    final dataRows = <pw.Widget>[
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: headerChildren,
      ),
    ];

    // Data rows matching the physical form exactly
    for (final med in medicines) {
      final quantities = (med['week_quantities'] ?? []).cast<num>();
      final nearExpiry = med['near_expiry'] ?? 0;

      final rowChildren = <pw.Widget>[
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 0.5),
            ),
            child: pw.Text(
              med['medicine_name'] ?? 'Unknown',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ),
      ];

      for (var i = 0; i < weekDates.length; i++) {
        final qty = i < quantities.length ? quantities[i] : 0;
        rowChildren.add(
          pw.Container(
            width: dateColWidth,
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 0.5),
            ),
            child: pw.Text(
              qty.toString(),
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        );
      }

      rowChildren.add(
        pw.Container(
          width: nearExpColWidth,
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 0.5),
          ),
          child: pw.Text(
            nearExpiry.toString(),
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: nearExpiry > 0 ? PdfColors.red : PdfColors.black,
            ),
          ),
        ),
      );

      dataRows.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: rowChildren,
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: dataRows,
    );
  }

  /// Print the weekly inventory report as PDF with the exact same design
  static Future<void> printPdf({
    required String title,
    required String dateRange,
    required Map<String, dynamic> data,
  }) async {
    final pdf = pw.Document();
    final weekDates = (data['week_dates'] ?? []).cast<String>();
    final medicines = (data['medicines'] ?? []).cast<Map<String, dynamic>>();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            pw.Center(
              child: buildPdf(weekDates, medicines),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${title.replaceAll(' ', '_')}_$dateRange',
    );
  }

  @override
  Widget build(BuildContext context) {
    final medicines = List<Map<String, dynamic>>.from(data['medicines'] ?? []);
    final weekDates = List<String>.from(data['week_dates'] ?? []);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (medicines.isEmpty) {
      return const Center(child: Text('No inventory data available'));
    }

    final int dateColCount = weekDates.length;
    final double dateColWidth = isMobile ? 50 : 80;
    final double nearExpColWidth = isMobile ? 60 : 90;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: title cell + date cells
          Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.black, width: 1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Purple "LIST OF MEDICINES" cell
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 14, horizontal: isMobile ? 8 : 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFB8A9C9),
                      border: Border(
                        right: BorderSide(color: Colors.black, width: 1),
                      ),
                    ),
                    child: Text(
                      'LIST OF MEDICINES',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                // Date columns
                ...weekDates.map((date) => Container(
                  width: dateColWidth,
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 14, horizontal: isMobile ? 2 : 4),
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.black, width: 1),
                    ),
                  ),
                  child: Text(
                    date,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 10 : 12,
                      color: Colors.black87,
                    ),
                  ),
                )),
                // NEAR EXP column
                Container(
                  width: nearExpColWidth,
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 14, horizontal: isMobile ? 2 : 4),
                  child: Text(
                    'NEAR EXP',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 10 : 12,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Data rows
          ...medicines.asMap().entries.map((entry) {
            final med = entry.value;
            final quantities = (med['week_quantities'] ?? []).cast<num>();
            final nearExpiry = med['near_expiry'] ?? 0;
            final isLast = entry.key == medicines.length - 1;
            return Container(
              decoration: BoxDecoration(
                border: isLast ? null : const Border(
                  bottom: BorderSide(color: Colors.black, width: 0.5),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Medicine Name
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: isMobile ? 6 : 10, horizontal: isMobile ? 8 : 12),
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.black, width: 1),
                        ),
                      ),
                      child: Text(
                        (med['medicine_name'] ?? 'UNKNOWN').toString().toUpperCase(),
                        style: TextStyle(fontSize: isMobile ? 9 : 12),
                      ),
                    ),
                  ),
                  // Quantity columns for each date
                  ...quantities.asMap().entries.map((qtyEntry) {
                    final isLastQty = qtyEntry.key == quantities.length - 1;
                    return Container(
                      width: dateColWidth,
                      padding: EdgeInsets.symmetric(vertical: isMobile ? 6 : 10, horizontal: isMobile ? 2 : 4),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.black, width: 1),
                        ),
                      ),
                      child: Text(
                        qtyEntry.value.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: isMobile ? 9 : 12),
                      ),
                    );
                  }),
                  // Near Expiry column
                  Container(
                    width: nearExpColWidth,
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 6 : 10, horizontal: isMobile ? 2 : 4),
                    child: Text(
                      nearExpiry.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isMobile ? 9 : 12,
                        fontWeight: FontWeight.w600,
                        color: nearExpiry > 0 ? Colors.red : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
