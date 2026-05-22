import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/card_container.dart';
import '../services/pharmacy_service.dart';

/// Forecasting Page
/// Demand prediction, and usage trends
class ForecastingPage extends StatefulWidget {
  const ForecastingPage({super.key});

  @override
  State<ForecastingPage> createState() => _ForecastingPageState();
}

class _ForecastingPageState extends State<ForecastingPage> {
  int _selectedTab = 0; // 0 = Overview, 1 = Demand Analysis
  final PharmacyService _pharmacyService = PharmacyService();

  // Dynamic data
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final stats = await _pharmacyService.getForecastingStats();

      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  // Helpers to get dynamic values from stats map
  int get _highDemandCount => _stats['high_demand_count'] ?? 0;
  int get _mediumDemandCount => _stats['medium_demand_count'] ?? 0;
  int get _lowDemandCount => _stats['low_demand_count'] ?? 0;
  int get _criticalStockCount => _stats['critical_stock_count'] ?? 0;
  List<dynamic> get _topDispensed => _stats['top_dispensed'] ?? [];
  Map<String, dynamic> get _demandTrends => _stats['demand_trends'] ?? {};
  List<dynamic> get _monthlyDistribution => _stats['monthly_distribution'] ?? [];
  Map<String, dynamic> get _stockAnalysis => _stats['stock_analysis'] ?? {};
  List<dynamic> get _forecastTable => _stats['forecast_table'] ?? [];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Forecasting',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Demand prediction, and usage trends',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stat Cards Row - Dynamic
          Row(
            children: [
              _buildStatCard(
                title: 'High Demand',
                value: _isLoading ? '-' : _highDemandCount.toString(),
                subtitle: 'Rising demand items',
                icon: Icons.trending_up,
                cardColor: const Color(0xFFE8F5E9),
                iconBgColor: const Color(0xFF81C784),
                iconColor: const Color(0xFF2E7D32),
                valueColor: const Color(0xFF4CAF50),
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                title: 'Medium Demand',
                value: _isLoading ? '-' : _mediumDemandCount.toString(),
                subtitle: 'Moderate demand items',
                icon: Icons.bar_chart,
                cardColor: const Color(0xFFFFF9C4),
                iconBgColor: const Color(0xFFFFF176),
                iconColor: const Color(0xFFF9A825),
                valueColor: const Color(0xFFFBC02D),
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                title: 'Low Demand',
                value: _isLoading ? '-' : _lowDemandCount.toString(),
                subtitle: 'Low demand items',
                icon: Icons.trending_down,
                cardColor: const Color(0xFFFFEBEE),
                iconBgColor: const Color(0xFFEF9A9A),
                iconColor: const Color(0xFFD32F2F),
                valueColor: const Color(0xFFE53935),
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                title: 'Critical Stock',
                value: _isLoading ? '-' : _criticalStockCount.toString(),
                subtitle: 'Depleting soon',
                icon: Icons.access_time,
                cardColor: const Color(0xFFF3E5F5),
                iconBgColor: const Color(0xFFCE93D8),
                iconColor: const Color(0xFF8E24AA),
                valueColor: const Color(0xFF9C27B0),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tab Navigation
          Row(
            children: [
              _buildTabButton(
                label: 'Overview',
                isSelected: _selectedTab == 0,
                onTap: () => setState(() => _selectedTab = 0),
              ),
              const SizedBox(width: 8),
              _buildTabButton(
                label: 'Demand Analysis',
                isSelected: _selectedTab == 1,
                onTap: () => setState(() => _selectedTab = 1),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tab Content
          _selectedTab == 0 ? _buildOverviewTab() : _buildDemandAnalysisTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Column(
      children: [
        Row(
          children: [
            // Top 5 High Demand Card
            Expanded(
              child: CardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.trending_up, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Top 5 High Demand',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Most dispensed items',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Bar Chart - Dynamic Top 5 Medicines by Stock
                    Container(
                      height: 180,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _topDispensed.isEmpty
                              ? const Center(child: Text('No data available'))
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: _topDispensed.map((item) {
                                    final qty = (item['qty'] ?? 0.0).toDouble();
                                    final name = (item['name'] ?? 'Unknown').split(' ')[0];
                                    // Normalize height based on max qty
                                    final maxQty = _topDispensed.fold(0.0, (max, item) {
                                      final q = (item['qty'] ?? 0.0).toDouble();
                                      return q > max ? q : max;
                                    });
                                    final normalizedHeight = maxQty > 0 ? (qty / maxQty) * 10 : 0.0;
                                    return _buildBar(name, qty, normalizedHeight);
                                  }).toList(),
                                ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Demand Trends Card
            Expanded(
              child: CardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6F00),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.bar_chart, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Demand Trends',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Medicine classification',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildTrendItem('High Demand', _isLoading ? 0 : _highDemandCount, Colors.red, const Color(0xFFFFEBEE)),
                    const SizedBox(height: 12),
                    _buildTrendItem('Medium Demand', _isLoading ? 0 : _mediumDemandCount, Colors.orange, const Color(0xFFFFF3E0)),
                    const SizedBox(height: 12),
                    _buildTrendItem('Low Demand', _isLoading ? 0 : _lowDemandCount, Colors.green, const Color(0xFFE8F5E9)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Monthly Distribution Card
        CardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monthly Distribution',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Transaction volume by month',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Monthly Chart with Grid
              Container(
                height: 200,
                padding: const EdgeInsets.only(left: 40, right: 16, top: 16, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0F2F1)),
                ),
                child: Row(
                  children: [
                    // Y-axis labels
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('60', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                        Text('50', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                        Text('40', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                        Text('30', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                        Text('20', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                        Text('10', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                        Text('0', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                      ],
                    ),
                    const SizedBox(width: 8),
                    // Chart area with grid
                    Expanded(
                      child: Stack(
                        children: [
                          // Grid lines
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(7, (index) {
                                  return CustomPaint(
                                    size: Size(constraints.maxWidth, 1),
                                    painter: DottedLinePainter(),
                                  );
                                }),
                              );
                            },
                          ),
                          // Bars
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: _monthlyDistribution.isEmpty
                                ? [
                                    _buildMonthBar('Jan', 0),
                                    _buildMonthBar('Feb', 0),
                                    _buildMonthBar('Mar', 0),
                                    _buildMonthBar('Apr', 0),
                                    _buildMonthBar('May', 0),
                                    _buildMonthBar('Jun', 0),
                                    _buildMonthBar('Jul', 0),
                                    _buildMonthBar('Aug', 0),
                                    _buildMonthBar('Sep', 0),
                                    _buildMonthBar('Oct', 0),
                                    _buildMonthBar('Nov', 0),
                                    _buildMonthBar('Dec', 0),
                                  ]
                                : _monthlyDistribution.map((m) {
                                    return _buildMonthBar(m['month'], (m['count'] ?? 0.0).toDouble());
                                  }).toList(),
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
      ],
    );
  }

  Widget _buildDemandAnalysisTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filters Row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Forecasting Period',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    value: 'Monthly',
                    items: const ['Monthly', 'Weekly', 'Daily'],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Date Range',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          value: '2026',
                          items: const ['2026', '2025', '2024'],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDropdown(
                          value: 'April',
                          items: const ['April', 'March', 'February', 'January'],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Stock Analysis Cards
        Row(
          children: [
            _buildStockCard(
              title: 'Total Medicines',
              value: _isLoading ? '-' : (_stockAnalysis['total'] ?? 0).toString(),
              subtitle: 'In inventory',
              icon: Icons.inventory_2_outlined,
              iconColor: const Color(0xFF2196F3),
            ),
            const SizedBox(width: 16),
            _buildStockCard(
              title: 'Low Stock Items',
              value: _isLoading ? '-' : (_stockAnalysis['low'] ?? 0).toString(),
              subtitle: 'Need reorder',
              icon: Icons.trending_down,
              iconColor: const Color(0xFFF44336),
            ),
            const SizedBox(width: 16),
            _buildStockCard(
              title: 'Adequate Stock',
              value: _isLoading ? '-' : (_stockAnalysis['adequate'] ?? 0).toString(),
              subtitle: 'Well stocked',
              icon: Icons.inventory_2_outlined,
              iconColor: const Color(0xFF4CAF50),
            ),
            const SizedBox(width: 16),
            _buildStockCard(
              title: 'Moderate Stock',
              value: _isLoading ? '-' : (_stockAnalysis['moderate'] ?? 0).toString(),
              subtitle: 'Monitor closely',
              icon: Icons.trending_up,
              iconColor: const Color(0xFFFFA000),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Forecasting Table
        CardContainer(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 900,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                    child: Row(
                      children: [
                        _buildTableHeader('MEDICINE NAME', flex: 2),
                        _buildTableHeader('CATEGORY', flex: 1),
                        _buildTableHeader('CURRENT STOCK', flex: 1),
                        _buildTableHeader('FORECASTED DEMAND', flex: 1),
                        _buildTableHeader('GROWTH TREND', flex: 1),
                        _buildTableHeader('ACTION NEEDED', flex: 2),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  if (_isLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                  else if (_forecastTable.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No data available')))
                  else
                    ..._forecastTable.asMap().entries.map((entry) {
                      final item = entry.value;
                      return Column(
                        children: [
                          _buildForecastRow(
                            medicine: item['medicine'] ?? 'Unknown',
                            category: item['category'] ?? 'N/A',
                            currentStock: (item['current_stock'] ?? 0.0).toStringAsFixed(0),
                            forecastedDemand: (item['forecasted_demand'] ?? 0.0).toStringAsFixed(0),
                            growthTrend: item['trend'] ?? '0%',
                            action: item['action'] ?? 'None',
                            isUrgent: item['is_urgent'] ?? false,
                          ),
                          if (entry.key < _forecastTable.length - 1)
                            const Divider(height: 1, indent: 16, endIndent: 16),
                        ],
                      );
                    }).toList(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color cardColor,
    required Color iconBgColor,
    required Color iconColor,
    required Color valueColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildBar(String label, double value, double height) {
    return Flexible(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 24,
            height: height * 12,
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthBar(String month, double value, {bool isSelected = false}) {
    // Calculate bar height based on max value of 60 (chart max Y)
    final double barHeight = value > 0 ? (value / 60) * 140 : 0;
    final bool hasData = value > 0;

    return Flexible(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (hasData)
            Container(
              width: 20,
              height: barHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            month,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: hasData ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendItem(String label, int count, Color dotColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: dotColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[800],
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: (value) {},
        ),
      ),
    );
  }

  Widget _buildStockCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildForecastRow({
    required String medicine,
    required String category,
    required String currentStock,
    required String forecastedDemand,
    required String growthTrend,
    required String action,
    required bool isUrgent,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              medicine,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              category,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              currentStock,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                forecastedDemand,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1976D2),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.trending_up, size: 14, color: Color(0xFF4CAF50)),
                  const SizedBox(width: 4),
                  Text(
                    growthTrend,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    action,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isUrgent) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning, size: 12, color: Colors.red[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Urgent',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for dotted grid lines
class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0F2F1)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    const dashWidth = 4;
    const dashSpace = 4;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
