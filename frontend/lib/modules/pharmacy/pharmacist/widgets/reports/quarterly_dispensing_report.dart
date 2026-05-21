import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

/// Quarterly Dispensing Report widget - exact physical form layout
class QuarterlyDispensingReport extends StatelessWidget {
  final Map<String, dynamic> data;

  const QuarterlyDispensingReport({super.key, required this.data});

  /// Build the PDF title block matching physical form: light bg, olive green text
  static pw.Widget buildPdfTitleBlock(String reportTitle, double width) {
    final oliveGreen = PdfColor(0.56, 0.66, 0.38); // #8FA860
    final lightGreen = PdfColor(0.91, 0.94, 0.89); // #E8F0E4

    return pw.Container(
      width: width,
      padding: const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: pw.BoxDecoration(
        color: lightGreen,
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            reportTitle,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: oliveGreen,
            ),
          ),
        ],
      ),
    );
  }

  /// Build the PDF table matching the exact physical form layout
  static pw.Widget buildPdf(List<String> months, List<Map<String, dynamic>> medicines, [String reportTitle = 'QUARTERLY REPORT']) {
    if (months.isEmpty || medicines.isEmpty) {
      return pw.Text('No dispensing data available');
    }

    const double nameColWidth = 239;
    const double ipdColWidth = 54;
    const double opdColWidth = 54;
    const double totalColWidth = 54;
    const double monthGroupWidth = ipdColWidth + opdColWidth + totalColWidth;
    final double tableWidth = nameColWidth + (monthGroupWidth * months.length);

    final beige = PdfColor(0.91, 0.86, 0.78);     // #E8DCC8
    final green = PdfColor(0.56, 0.66, 0.38);     // #8FA860
    final lightBeige = PdfColor(0.96, 0.94, 0.90);   // #F5EFE6
    final lightGreen = PdfColor(0.91, 0.94, 0.89);   // #E8F0E4

    const double headerTopHeight = 20;
    const double headerSubHeight = 18;
    const double headerTotalHeight = headerTopHeight + headerSubHeight;

    // Build month header rows
    final monthTopRow = <pw.Widget>[];
    final monthSubRow = <pw.Widget>[];

    for (final month in months) {
      monthTopRow.add(
        pw.Container(
          width: monthGroupWidth,
          height: headerTopHeight,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 0.5),
          ),
          child: pw.Text(
            'MONTH OF ${month.toUpperCase()}',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
        ),
      );

      monthSubRow.add(
        pw.Container(
          width: ipdColWidth,
          height: headerSubHeight,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: beige,
            border: pw.Border.all(color: PdfColors.black, width: 0.5),
          ),
          child: pw.Text(
            'IPD',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
        ),
      );
      monthSubRow.add(
        pw.Container(
          width: opdColWidth,
          height: headerSubHeight,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: green,
            border: pw.Border.all(color: PdfColors.black, width: 0.5),
          ),
          child: pw.Text(
            'OPD',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          ),
        ),
      );
      monthSubRow.add(
        pw.Container(
          width: totalColWidth,
          height: headerSubHeight,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 0.5),
          ),
          child: pw.Text(
            'TOTAL',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
        ),
      );
    }

    // Table header with beige left cell spanning both header rows
    final tableHeader = pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: nameColWidth,
          height: headerTotalHeight,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: beige,
            border: pw.Border.all(color: PdfColors.black, width: 0.5),
          ),
          child: pw.Text(
            'INVENTORY OF CONSUMED MEDICINES',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(children: monthTopRow),
            pw.Row(children: monthSubRow),
          ],
        ),
      ],
    );

    // Data rows
    final dataRows = <pw.Widget>[];
    for (final med in medicines) {
      final monthData = List<Map<String, dynamic>>.from(med['months'] ?? []);
      final rowChildren = <pw.Widget>[
        pw.Container(
          width: nameColWidth,
          padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 0.5),
          ),
          child: pw.Text(
            (med['medicine_name'] ?? 'UNKNOWN').toString().toUpperCase(),
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
      ];

      for (final m in monthData) {
        rowChildren.add(
          pw.Container(
            width: ipdColWidth,
            padding: const pw.EdgeInsets.symmetric(vertical: 5),
            decoration: pw.BoxDecoration(
              color: lightBeige,
              border: pw.Border.all(color: PdfColors.black, width: 0.5),
            ),
            child: pw.Text(
              (m['ipd'] ?? 0).toString(),
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
        );
        rowChildren.add(
          pw.Container(
            width: opdColWidth,
            padding: const pw.EdgeInsets.symmetric(vertical: 5),
            decoration: pw.BoxDecoration(
              color: lightGreen,
              border: pw.Border.all(color: PdfColors.black, width: 0.5),
            ),
            child: pw.Text(
              (m['opd'] ?? 0).toString(),
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
        );
        rowChildren.add(
          pw.Container(
            width: totalColWidth,
            padding: const pw.EdgeInsets.symmetric(vertical: 5),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 0.5),
            ),
            child: pw.Text(
              (m['total'] ?? 0).toString(),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ),
        );
      }

      dataRows.add(pw.Row(children: rowChildren));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildPdfTitleBlock(reportTitle, tableWidth),
        tableHeader,
        ...dataRows,
      ],
    );
  }

  /// Print the quarterly dispensing report as PDF with the exact same design
  static Future<void> printPdf({
    required String title,
    required String dateRange,
    required Map<String, dynamic> data,
  }) async {
    final pdf = pw.Document();
    final medicines = (data['medicines'] ?? []).cast<Map<String, dynamic>>();
    final months = (data['months'] ?? []).cast<String>();
    final reportTitle = data['report_title'] ?? title;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            pw.Center(
              child: buildPdf(months, medicines, reportTitle),
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
    final months = List<String>.from(data['months'] ?? []);
    final reportTitle = data['report_title'] ?? 'QUARTERLY REPORT';
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (medicines.isEmpty) {
      return const Center(child: Text('No dispensing data available for this quarter'));
    }

    final double nameColWidth = isMobile ? 100 : 239;
    final double ipdColWidth = isMobile ? 30 : 54;
    final double opdColWidth = isMobile ? 30 : 54;
    final double totalColWidth = isMobile ? 30 : 54;
    final double monthGroupWidth = ipdColWidth + opdColWidth + totalColWidth;
    final double tableWidth = nameColWidth + (monthGroupWidth * months.length);

    final double headerTopHeight = isMobile ? 20 : 24;
    final double headerSubHeight = isMobile ? 18 : 22;
    final double headerTotalHeight = headerTopHeight + headerSubHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title block: light green bg, olive green text
        Container(
          width: tableWidth,
          padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 14, horizontal: isMobile ? 16 : 24),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0E4),
            border: Border.all(color: Colors.black, width: 1),
          ),
          child: Column(
            children: [
              Text(
                reportTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF8FA860),
                ),
              ),
            ],
          ),
        ),
        // Table header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: INVENTORY OF CONSUMED MEDICINES (beige, tall)
            Container(
              width: nameColWidth,
              height: headerTotalHeight,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFE8DCC8),
                border: Border(
                  top: BorderSide(color: Colors.black, width: 0.5),
                  bottom: BorderSide(color: Colors.black, width: 0.5),
                  left: BorderSide(color: Colors.black, width: 0.5),
                ),
              ),
              child: Text(
                'INVENTORY OF CONSUMED MEDICINES',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: isMobile ? 8 : 11, fontWeight: FontWeight.bold),
              ),
            ),
            // Right: Month headers
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month names row
                Row(
                  children: [
                    for (int i = 0; i < months.length; i++) Container(
                      width: monthGroupWidth,
                      height: headerTopHeight,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          top: const BorderSide(color: Colors.black, width: 0.5),
                          left: const BorderSide(color: Colors.black, width: 0.5),
                          right: i == months.length - 1 ? const BorderSide(color: Colors.black, width: 0.5) : BorderSide.none,
                        ),
                      ),
                      child: Text(
                        months[i].toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 7 : 10),
                      ),
                    ),
                  ],
                ),
                // IPD/OPD/TOTAL sub-header row
                Row(
                  children: [
                    for (int i = 0; i < months.length; i++) ...[
                      Container(
                        width: ipdColWidth,
                        height: headerSubHeight,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8DCC8),
                          border: Border(
                            top: BorderSide(color: Colors.black, width: 0.5),
                            left: BorderSide(color: Colors.black, width: 0.5),
                          ),
                        ),
                        child: const Text(
                          'IPD',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9),
                        ),
                      ),
                      Container(
                        width: opdColWidth,
                        height: headerSubHeight,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFF8FA860),
                          border: Border(
                            top: BorderSide(color: Colors.black, width: 0.5),
                            left: BorderSide(color: Colors.black, width: 0.5),
                          ),
                        ),
                        child: const Text(
                          'OPD',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.white),
                        ),
                      ),
                      Container(
                        width: totalColWidth,
                        height: headerSubHeight,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            top: const BorderSide(color: Colors.black, width: 0.5),
                            left: const BorderSide(color: Colors.black, width: 0.5),
                            right: i == months.length - 1 ? const BorderSide(color: Colors.black, width: 0.5) : BorderSide.none,
                          ),
                        ),
                        child: const Text(
                          'TOTAL',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
        // Data rows
        for (final med in medicines)
          Builder(builder: (context) {
            final monthData = List<Map<String, dynamic>>.from(med['months'] ?? []);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Medicine Name
                Container(
                  width: nameColWidth,
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 4 : 6, horizontal: isMobile ? 4 : 6),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.black, width: 0.5),
                      left: BorderSide(color: Colors.black, width: 0.5),
                    ),
                  ),
                  child: Text(
                    (med['medicine_name'] ?? 'UNKNOWN').toString().toUpperCase(),
                    style: TextStyle(fontSize: isMobile ? 8 : 10),
                  ),
                ),
                // Month data columns
                for (int i = 0; i < monthData.length; i++) ...[
                  Container(
                    width: ipdColWidth,
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 4 : 6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5EFE6),
                      border: Border(
                        bottom: BorderSide(color: Colors.black, width: 0.5),
                        left: BorderSide(color: Colors.black, width: 0.5),
                      ),
                    ),
                    child: Text(
                      (monthData[i]['ipd'] ?? 0).toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: isMobile ? 8 : 10),
                    ),
                  ),
                  Container(
                    width: opdColWidth,
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 4 : 6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F0E4),
                      border: Border(
                        bottom: BorderSide(color: Colors.black, width: 0.5),
                        left: BorderSide(color: Colors.black, width: 0.5),
                      ),
                    ),
                    child: Text(
                      (monthData[i]['opd'] ?? 0).toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: isMobile ? 8 : 10),
                    ),
                  ),
                  Container(
                    width: totalColWidth,
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 4 : 6),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: const BorderSide(color: Colors.black, width: 0.5),
                        left: const BorderSide(color: Colors.black, width: 0.5),
                        right: i == monthData.length - 1 ? const BorderSide(color: Colors.black, width: 0.5) : BorderSide.none,
                      ),
                    ),
                    child: Text(
                      (monthData[i]['total'] ?? 0).toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: isMobile ? 8 : 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            );
          }),
      ],
    );
  }
}
