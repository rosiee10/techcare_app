import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/card_container.dart';

/// Reports Page for CSD Clerk
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _selectedReportType = 'Monthly Inventory Report';
  String _selectedPeriodType = 'Daily';
  DateTimeRange? _selectedDateRange;

  final List<String> _reportTypes = [
    'Monthly Inventory Report',
    'Supply Distribution Report',
    'Request Analysis',
    'Stock Level Report',
    'Kitchen Supply Report',
    'Stock Card',
  ];

  final List<String> _periodTypes = [
    'Daily',
    'Weekly',
    'Monthly',
    'Quarterly',
    'Yearly',
  ];

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _selectedDateRange ?? DateTimeRange(
        start: DateTime(2026, 3, 1),
        end: DateTime(2026, 3, 15),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF2563EB),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  String _formatDateRange() {
    if (_selectedDateRange == null) {
      return '2026-03-01 - 2026-03-15';
    }
    final start = _selectedDateRange!.start;
    final end = _selectedDateRange!.end;
    return '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')} - ${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
  }

  void _generateReport() {
    // TODO: Implement report generation logic
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report Type: $_selectedReportType'),
            const SizedBox(height: 8),
            Text('Period Type: $_selectedPeriodType'),
            const SizedBox(height: 8),
            Text('Date Range: ${_formatDateRange()}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report generated successfully')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 768;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'REPORTS',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 24),

          // Report Filters Card
          CardContainer(
            child: isSmallScreen
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Report Type
                      _buildFilterLabel('Report Type'),
                      _buildReportTypeDropdown(),
                      const SizedBox(height: 16),

                      // Period Type
                      _buildFilterLabel('Period Type'),
                      _buildPeriodTypeDropdown(),
                      const SizedBox(height: 16),

                      // Date Range
                      _buildFilterLabel('Date Range'),
                      _buildDateRangeField(),
                      const SizedBox(height: 20),

                      // Generate Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _generateReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Generate Report'),
                        ),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Report Type
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFilterLabel('Report Type'),
                            _buildReportTypeDropdown(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Period Type
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFilterLabel('Period Type'),
                            _buildPeriodTypeDropdown(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Date Range
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFilterLabel('Date Range'),
                            _buildDateRangeField(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Generate Button
                      ElevatedButton(
                        onPressed: _generateReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Generate Report'),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 32),

          // Recent Reports Section (optional enhancement)
          const Text(
            'Recent Reports',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),

          // Recent Reports List
          CardContainer(
            child: Column(
              children: [
                _buildRecentReportItem(
                  'Monthly Inventory Report - March 2026',
                  'Generated on 2026-04-01',
                  Icons.description_outlined,
                  const Color(0xFF3B82F6),
                ),
                const Divider(),
                _buildRecentReportItem(
                  'Supply Distribution Report - Q1 2026',
                  'Generated on 2026-03-31',
                  Icons.pie_chart_outline,
                  const Color(0xFF22C55E),
                ),
                const Divider(),
                _buildRecentReportItem(
                  'Stock Level Report - February 2026',
                  'Generated on 2026-03-01',
                  Icons.bar_chart_outlined,
                  const Color(0xFFF59E0B),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildReportTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF3B82F6), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedReportType,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: _reportTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(
                type,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedReportType = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildPeriodTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedPeriodType,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: _periodTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(
                type,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedPeriodType = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildDateRangeField() {
    return InkWell(
      onTap: () => _selectDateRange(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDateRange(),
              style: TextStyle(
                fontSize: 14,
                color: _selectedDateRange != null ? Colors.black : Colors.grey[600],
              ),
            ),
            Icon(Icons.calendar_today_outlined, color: Colors.grey[600], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReportItem(String title, String subtitle, IconData icon, Color iconColor) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Downloading $title...')),
              );
            },
            icon: const Icon(Icons.download_outlined, color: Color(0xFF3B82F6)),
            tooltip: 'Download',
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Viewing $title...')),
              );
            },
            icon: const Icon(Icons.visibility_outlined, color: Color(0xFF3B82F6)),
            tooltip: 'View',
          ),
        ],
      ),
    );
  }
}
