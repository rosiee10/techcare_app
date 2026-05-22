import 'package:flutter/material.dart';
import 'package:frontend/core/utils/responsive.dart';
import '../../../../core/reusable_widgets/card_container.dart';
import '../services/pharmacy_service.dart';
import '../widgets/reports/weekly_inventory_report.dart';
import '../widgets/reports/quarterly_dispensing_report.dart';
import '../widgets/reports/monthly_dispensing_report.dart';
import 'package:intl/intl.dart';

/// Reports Page
/// Generate and view pharmacy reports
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final PharmacyService _pharmacyService = PharmacyService();
  String _selectedReportType = 'Weekly Inventory Report';
  String _selectedPeriodType = 'Weekly';
  final TextEditingController _dateRangeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updatePeriodAndDateRange(_selectedReportType);
  }

  void _updatePeriodAndDateRange(String reportType) {
    setState(() {
      _selectedReportType = reportType;
      DateTime now = DateTime.now();
      String format(DateTime d) =>
          "${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year.toString().substring(2)}";

      if (reportType == 'Weekly Inventory Report') {
        _selectedPeriodType = 'Weekly';
        DateTime start = now.subtract(const Duration(days: 7));
        _dateRangeController.text = "${format(start)} - ${format(now)}";
      } else if (reportType == 'Monthly Dispensing Report') {
        _selectedPeriodType = 'Monthly';
        DateTime start = now.subtract(const Duration(days: 30));
        _dateRangeController.text = "${format(start)} - ${format(now)}";
      } else if (reportType == 'Quarterly Dispensing Report') {
        _selectedPeriodType = 'Quarterly';
        DateTime start = now.subtract(const Duration(days: 90));
        _dateRangeController.text = "${format(start)} - ${format(now)}";
      } else if (reportType == 'Annual Pharmacy Report') {
        _selectedPeriodType = 'Yearly';
        DateTime start = now.subtract(const Duration(days: 365));
        _dateRangeController.text = "${format(start)} - ${format(now)}";
      }
    });
  }

  @override
  void dispose() {
    _dateRangeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Responsive
          Text(
            'REPORTS',
            style: TextStyle(
              fontSize: isMobile ? 22 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 24),
          _buildReportConfigCard(isMobile, isTablet),
          const SizedBox(height: 32),
          _buildAvailableReportsSection(isMobile, isTablet),
        ],
      ),
    );
  }

  void _handleGenerateReport() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text('Generating Report...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );

      dynamic data;
      if (_selectedReportType == 'Weekly Inventory Report') {
        data = await _pharmacyService.getWeeklyInventoryReport();
      } else if (_selectedReportType == 'Monthly Dispensing Report') {
        data = await _pharmacyService.getMonthlyDispensingReport();
      } else if (_selectedReportType == 'Quarterly Dispensing Report') {
        data = await _pharmacyService.getQuarterlyDispensingReport();
      } else {
        data = await _pharmacyService.generateReport(
          _selectedReportType,
          _dateRangeController.text,
        );
      }

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      _showReportPreview(data);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating report: $e')),
      );
    }
  }

  void _handlePrintReport(dynamic data) {
    try {
      print('Print button clicked. Report type: $_selectedReportType');
      print('Data type: ${data.runtimeType}');
      
      if (data is Map) {
        print('Data keys: ${data.keys}');
        final reportTitle = data['report_title'] ?? '';
        print('Report title: $reportTitle');
        
        if (reportTitle == 'LIST OF MEDICINES') {
          print('Calling weekly inventory print');
          WeeklyInventoryReport.printPdf(
            title: _selectedReportType,
            dateRange: _dateRangeController.text,
            data: Map<String, dynamic>.from(data),
          );
          return;
        }
        if (reportTitle.contains('QUARTER')) {
          print('Calling quarterly dispensing print');
          QuarterlyDispensingReport.printPdf(
            title: _selectedReportType,
            dateRange: _dateRangeController.text,
            data: Map<String, dynamic>.from(data),
          );
          return;
        }
        if (reportTitle.contains('MONTH')) {
          print('Calling monthly dispensing print');
          MonthlyDispensingReport.printPdf(
            title: _selectedReportType,
            dateRange: _dateRangeController.text,
            data: Map<String, dynamic>.from(data),
          );
          return;
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Print not supported for this report type')),
      );
    } catch (e, stackTrace) {
      print('Print error: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error printing report: $e')),
      );
    }
  }

  void _showReportPreview(dynamic data) {
    final isQuarterly = _selectedReportType.contains('quarterly');
    final isMonthly = _selectedReportType.contains('monthly');
    final isSpecialReport = isQuarterly || isMonthly;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    showDialog(
      context: context,
      builder: (context) => Center(
        child: Container(
          width: isMobile
              ? screenWidth * 0.98
              : (isSpecialReport ? screenWidth * 0.95 : 780),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * (isMobile ? 0.46 : (isSpecialReport ? 0.95 : 0.9)),
          ),
          margin: EdgeInsets.all(isMobile ? 8 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
          ),
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedReportType.toUpperCase(),
                          style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Period: ${_dateRangeController.text}',
                          style: TextStyle(color: Colors.grey[600], fontSize: isMobile ? 12 : 14),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: isSpecialReport && isMobile ? Axis.horizontal : Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: _buildReportDataView(data),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _handlePrintReport(data),
                    icon: const Icon(Icons.print),
                    label: Text(isMobile ? 'Print' : 'Print Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 10 : 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportDataView(dynamic data) {
    if (data is Map && data['success'] == true) {
      if (data.containsKey('report_title')) {
        final title = data['report_title'] ?? '';
        if (title == 'LIST OF MEDICINES') {
          return WeeklyInventoryReport(data: Map<String, dynamic>.from(data));
        }
        if (title.contains('QUARTER')) {
          return QuarterlyDispensingReport(data: Map<String, dynamic>.from(data));
        }
        if (title.contains('MONTH')) {
          return MonthlyDispensingReport(data: Map<String, dynamic>.from(data));
        }
      }
      // Handle other Map responses
      return Column(
        children: data.entries.where((e) => e.value != null && e.value is! List).map((e) => _buildSummaryRow(e.key, e.value)).toList(),
      );
    }

    if (data is List) {
      if (data.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text('No records found for the selected period.'),
          ),
        );
      }

      return Table(
        border: TableBorder.all(color: Colors.grey[300]!, width: 1),
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.grey[100]),
            children: [
              _buildTableHeader('Medicine Name'),
              _buildTableHeader(_selectedReportType.contains('Inventory') ? 'Stock' : 'Qty'),
              _buildTableHeader(_selectedReportType.contains('Inventory') ? 'Status' : 'Txn'),
            ],
          ),
          ...data.map((item) {
            final name = item['medicine_name'] ?? item['medicine__medicine_name'] ?? 'N/A';
            final qty = item['current_stock'] ?? item['total_qty'] ?? '0';
            final status = item['status'] ?? item['transaction_count'] ?? 'OK';
            return TableRow(
              children: [
                _buildTableCell(name.toString()),
                _buildTableCell(qty.toString()),
                _buildTableCell(status.toString()),
              ],
            );
          }).toList(),
        ],
      );
    }

    return const Center(child: Text('No data found'));
  }

  Widget _buildSummaryRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value.toString()),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(text),
    );
  }

  Widget _buildReportConfigCard(bool isMobile, bool isTablet) {
    return CardContainer(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: (isMobile || isTablet) ? _buildMobileFilters(isMobile) : _buildDesktopFilters(),
      ),
    );
  }

  Widget _buildMobileFilters(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Report Type',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        _buildDropdown(
          value: _selectedReportType,
          items: const [
            'Weekly Inventory Report',
            'Monthly Dispensing Report',
            'Quarterly Dispensing Report',
            'Annual Pharmacy Report',
          ],
          onChanged: (value) => _updatePeriodAndDateRange(value!),
        ),
        const SizedBox(height: 16),
        const Text(
          'Period Type',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        _buildDropdown(
          value: _selectedPeriodType,
          items: const ['Daily', 'Weekly', 'Monthly', 'Quarterly', 'Yearly'],
          onChanged: (value) => setState(() => _selectedPeriodType = value!),
        ),
        const SizedBox(height: 16),
        const Text(
          'Date Range',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        _buildDateRangeField(true),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleGenerateReport,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Generate Report',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopFilters() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report Type',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    value: _selectedReportType,
                    items: const [
                      'Weekly Inventory Report',
                      'Monthly Dispensing Report',
                      'Quarterly Dispensing Report',
                      'Annual Pharmacy Report',
                    ],
                    onChanged: (value) => _updatePeriodAndDateRange(value!),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Period Type',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    value: _selectedPeriodType,
                    items: const ['Daily', 'Weekly', 'Monthly', 'Quarterly', 'Yearly'],
                    onChanged: (value) => setState(() => _selectedPeriodType = value!),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date Range',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDateRangeField(false),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: _handleGenerateReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Generate Report',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateRangeField(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _dateRangeController,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: 'Select date range',
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF64748B)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        readOnly: true,
        onTap: () {
          // TODO: Show date range picker
        },
      ),
    );
  }

  Widget _buildAvailableReportsSection(bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Available Report Types',
          style: TextStyle(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        (isMobile || isTablet) ? _buildMobileReportCards(isMobile) : _buildDesktopReportCards(),
      ],
    );
  }

  Widget _buildMobileReportCards(bool isMobile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildReportTypeCard(
                isMobile: true,
                title: 'Inventory Reports',
                description: 'Stock levels, movements, and valuations',
                icon: Icons.inventory_2_outlined,
                color: const Color(0xFF2196F3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildReportTypeCard(
                isMobile: true,
                title: 'Dispensing Reports',
                description: 'Medicine dispensing and usage statistics',
                icon: Icons.local_hospital_outlined,
                color: const Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildReportTypeCard(
                isMobile: true,
                title: 'Billing Reports',
                description: 'Revenue, charges, and payments',
                icon: Icons.receipt_long_outlined,
                color: const Color(0xFFFF9800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildReportTypeCard(
                isMobile: true,
                title: 'Purchase Reports',
                description: 'Purchase orders and supplier analysis',
                icon: Icons.shopping_cart_outlined,
                color: const Color(0xFF9C27B0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildReportTypeCard(
                isMobile: true,
                title: 'Forecasting Reports',
                description: 'Demand prediction and trends',
                icon: Icons.trending_up,
                color: const Color(0xFF00BCD4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopReportCards() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildReportTypeCard(
                isMobile: false,
                title: 'Inventory Reports',
                description: 'Stock levels, movements, and valuations',
                icon: Icons.inventory_2_outlined,
                color: const Color(0xFF2196F3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildReportTypeCard(
                isMobile: false,
                title: 'Dispensing Reports',
                description: 'Medicine dispensing and usage statistics',
                icon: Icons.local_hospital_outlined,
                color: const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildReportTypeCard(
                isMobile: false,
                title: 'Billing Reports',
                description: 'Revenue, charges, and payments',
                icon: Icons.receipt_long_outlined,
                color: const Color(0xFFFF9800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildReportTypeCard(
                isMobile: false,
                title: 'Purchase Reports',
                description: 'Purchase orders and supplier analysis',
                icon: Icons.shopping_cart_outlined,
                color: const Color(0xFF9C27B0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildReportTypeCard(
                isMobile: false,
                title: 'Forecasting Reports',
                description: 'Demand prediction and trends',
                icon: Icons.trending_up,
                color: const Color(0xFF00BCD4),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 22, color: Color(0xFF64748B)),
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w500,
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

  Widget _buildReportTypeCard({
    required bool isMobile,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: isMobile ? 24 : 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
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
}
