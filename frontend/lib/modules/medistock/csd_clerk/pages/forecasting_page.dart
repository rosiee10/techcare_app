import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/card_container.dart';

/// Forecasting Page for CSD Clerk
class ForecastingPage extends StatefulWidget {
  const ForecastingPage({super.key});

  @override
  State<ForecastingPage> createState() => _ForecastingPageState();
}

class _ForecastingPageState extends State<ForecastingPage> {
  int _selectedTab = 0; // 0 = Overview, 1 = Demand Analysis

  // Overview stats
  int get _highDemand => 2;
  int get _mediumDemand => 3;
  int get _lowDemand => 1;
  int get _criticalStock => 2;

  // Demand Analysis stats
  int get _totalSupplies => 18;
  int get _lowStockItems => 0;
  int get _adequateStock => 0;
  int get _moderateStock => 0;

  String _selectedPeriod = 'Monthly';
  String _selectedYear = '2026';
  String _selectedMonth = 'May';

  final List<Map<String, dynamic>> _forecastData = [
    {
      'supplyName': 'Surgical Gloves (Large)',
      'category': 'Medical Supplies',
      'currentStock': 50,
      'forecastedDemand': 150,
      'growthTrend': '+200%',
      'actionNeeded': 'Order 100 boxes',
      'isUrgent': true,
    },
    {
      'supplyName': 'Disposable Syringes',
      'category': 'Medical Supplies',
      'currentStock': 120,
      'forecastedDemand': 160,
      'growthTrend': '+33%',
      'actionNeeded': 'Order 40 units',
      'isUrgent': false,
    },
    {
      'supplyName': 'Gauze Pads',
      'category': 'Medical Supplies',
      'currentStock': 75,
      'forecastedDemand': 100,
      'growthTrend': '+25%',
      'actionNeeded': 'Order 25 packs',
      'isUrgent': false,
    },
    {
      'supplyName': 'Alcohol Swabs',
      'category': 'Medical Supplies',
      'currentStock': 200,
      'forecastedDemand': 180,
      'growthTrend': '-10%',
      'actionNeeded': 'Monitor stock',
      'isUrgent': false,
    },
  ];

  final List<Map<String, dynamic>> _topDemandItems = [
    {'name': 'Surgical Gloves (Large)', 'demand': 150},
    {'name': 'Disposable Syringes', 'demand': 120},
    {'name': 'Gauze Pads', 'demand': 85},
    {'name': 'Alcohol Swabs', 'demand': 70},
    {'name': 'Bandage Rolls', 'demand': 45},
  ];

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Forecasting',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
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

          // Stats Cards (always visible)
          isSmallScreen
              ? Column(
                  children: [
                    _buildDemandStatCard('High Demand', _highDemand.toString(), 'Rising demand items', const Color(0xFFE6F7ED), const Color(0xFF22C55E), Icons.trending_up),
                    const SizedBox(height: 12),
                    _buildDemandStatCard('Medium Demand', _mediumDemand.toString(), 'Moderate demand items', const Color(0xFFFEF9E7), const Color(0xFFF59E0B), Icons.bar_chart),
                    const SizedBox(height: 12),
                    _buildDemandStatCard('Low Demand', _lowDemand.toString(), 'Low demand items', const Color(0xFFFFEBEE), const Color(0xFFEF4444), Icons.trending_down),
                    const SizedBox(height: 12),
                    _buildDemandStatCard('Critical Stock', _criticalStock.toString(), 'Depleting soon', const Color(0xFFF3E8FF), const Color(0xFFA855F7), Icons.warning_amber),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildDemandStatCard('High Demand', _highDemand.toString(), 'Rising demand items', const Color(0xFFE6F7ED), const Color(0xFF22C55E), Icons.trending_up)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDemandStatCard('Medium Demand', _mediumDemand.toString(), 'Moderate demand items', const Color(0xFFFEF9E7), const Color(0xFFF59E0B), Icons.bar_chart)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDemandStatCard('Low Demand', _lowDemand.toString(), 'Low demand items', const Color(0xFFFFEBEE), const Color(0xFFEF4444), Icons.trending_down)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDemandStatCard('Critical Stock', _criticalStock.toString(), 'Depleting soon', const Color(0xFFF3E8FF), const Color(0xFFA855F7), Icons.warning_amber)),
                  ],
                ),
          const SizedBox(height: 24),

          // Tabs
          Row(
            children: [
              _buildTabButton('Overview', 0),
              const SizedBox(width: 8),
              _buildTabButton('Demand Analysis', 1),
            ],
          ),
          const SizedBox(height: 24),

          // Tab Content
          if (_selectedTab == 0)
            _buildOverviewTab(isSmallScreen)
          else
            _buildDemandAnalysisTab(isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(bool isSmallScreen) {
    return isSmallScreen
        ? Column(
            children: [
              _buildTopDemandCard(),
              const SizedBox(height: 16),
              _buildDemandTrendsCard(),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTopDemandCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildDemandTrendsCard()),
            ],
          );
  }

  Widget _buildDemandAnalysisTab(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filters
        isSmallScreen
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterDropdown('Select Forecasting Period', _selectedPeriod, ['Monthly', 'Weekly', 'Daily'], (value) {
                    setState(() => _selectedPeriod = value!);
                  }),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildFilterDropdown('Select Date Range', _selectedYear, ['2026', '2025', '2024'], (value) {
                        setState(() => _selectedYear = value!);
                      })),
                      const SizedBox(width: 12),
                      Expanded(child: _buildFilterDropdown('', _selectedMonth, ['May', 'April', 'March', 'February', 'January'], (value) {
                        setState(() => _selectedMonth = value!);
                      })),
                    ],
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFilterDropdown('Select Forecasting Period', _selectedPeriod, ['Monthly', 'Weekly', 'Daily'], (value) {
                    setState(() => _selectedPeriod = value!);
                  }),
                  Row(
                    children: [
                      _buildFilterDropdown('Select Date Range', _selectedYear, ['2026', '2025', '2024'], (value) {
                        setState(() => _selectedYear = value!);
                      }),
                      const SizedBox(width: 12),
                      _buildFilterDropdown('', _selectedMonth, ['May', 'April', 'March', 'February', 'January'], (value) {
                        setState(() => _selectedMonth = value!);
                      }),
                    ],
                  ),
                ],
              ),
        const SizedBox(height: 20),

        // Analysis Stats Cards
        isSmallScreen
            ? Column(
                children: [
                  _buildAnalysisStatCard('Total Supplies', _totalSupplies.toString(), 'In inventory', const Color(0xFF3B82F6), Icons.inventory_2_outlined),
                  const SizedBox(height: 12),
                  _buildAnalysisStatCard('Low Stock Items', _lowStockItems.toString(), 'Need reorder', const Color(0xFFEF4444), Icons.trending_down),
                  const SizedBox(height: 12),
                  _buildAnalysisStatCard('Adequate Stock', _adequateStock.toString(), 'Well stocked', const Color(0xFF22C55E), Icons.check_circle_outline),
                  const SizedBox(height: 12),
                  _buildAnalysisStatCard('Moderate Stock', _moderateStock.toString(), 'Monitor closely', const Color(0xFFF59E0B), Icons.trending_up),
                ],
              )
            : Row(
                children: [
                  Expanded(child: _buildAnalysisStatCard('Total Supplies', _totalSupplies.toString(), 'In inventory', const Color(0xFF3B82F6), Icons.inventory_2_outlined)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildAnalysisStatCard('Low Stock Items', _lowStockItems.toString(), 'Need reorder', const Color(0xFFEF4444), Icons.trending_down)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildAnalysisStatCard('Adequate Stock', _adequateStock.toString(), 'Well stocked', const Color(0xFF22C55E), Icons.check_circle_outline)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildAnalysisStatCard('Moderate Stock', _moderateStock.toString(), 'Monitor closely', const Color(0xFFF59E0B), Icons.trending_up)),
                ],
              ),
        const SizedBox(height: 24),

        // Forecast Table
        CardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Table Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    _buildTableHeader('SUPPLY NAME', flex: 2),
                    _buildTableHeader('CATEGORY', flex: 2),
                    _buildTableHeader('CURRENT STOCK', flex: 1),
                    _buildTableHeader('FORECASTED DEMAND', flex: 2),
                    _buildTableHeader('GROWTH TREND', flex: 2),
                    _buildTableHeader('ACTION NEEDED', flex: 2),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Table Body
              ..._forecastData.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          item['supplyName'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          item['category'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          item['currentStock'].toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF5FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item['forecastedDemand'].toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF3B82F6),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Icon(
                              item['growthTrend'].startsWith('+') ? Icons.trending_up : Icons.trending_down,
                              color: item['growthTrend'].startsWith('+') ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: item['growthTrend'].startsWith('+') ? const Color(0xFFE6F7ED) : const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item['growthTrend'],
                                style: TextStyle(
                                  color: item['growthTrend'].startsWith('+') ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Text(
                              item['actionNeeded'],
                              style: TextStyle(
                                color: item['isUrgent'] ? const Color(0xFFDC2626) : Colors.grey[700],
                                fontSize: 13,
                                fontWeight: item['isUrgent'] ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            if (item['isUrgent']) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.warning_amber, color: Color(0xFFDC2626), size: 12),
                                    SizedBox(width: 2),
                                    Text(
                                      'Urgent',
                                      style: TextStyle(
                                        color: Color(0xFFDC2626),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
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
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTab == index;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedTab = index;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF2563EB) : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.grey[700],
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
      ),
      child: Text(title),
    );
  }

  Widget _buildFilterDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        if (label.isNotEmpty) const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              onChanged: onChanged,
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDemandStatCard(String title, String value, String subtitle, Color bgColor, Color iconColor, IconData icon) {
    return CardContainer(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
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
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisStatCard(String title, String value, String subtitle, Color iconColor, IconData icon) {
    return CardContainer(
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
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
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
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildTopDemandCard() {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(10),
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
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    'Most requested items',
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
          // Simple Bar Chart
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _topDemandItems.map((item) {
                      final maxDemand = 150;
                      final height = (item['demand'] / maxDemand) * 140;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            item['demand'].toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 40,
                            height: height,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _topDemandItems.map((item) {
                    return SizedBox(
                      width: 40,
                      child: Text(
                        item['name'].toString().split(' ')[0],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemandTrendsCard() {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316),
                  borderRadius: BorderRadius.circular(10),
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
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    'Supply classification',
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
          _buildTrendItem('High Demand', _highDemand.toString(), const Color(0xFFEF4444)),
          const SizedBox(height: 12),
          _buildTrendItem('Medium Demand', _mediumDemand.toString(), const Color(0xFFF59E0B)),
          const SizedBox(height: 12),
          _buildTrendItem('Low Demand', _lowDemand.toString(), const Color(0xFF22C55E)),
          const SizedBox(height: 12),
          _buildTrendItem('Critical Stock', _criticalStock.toString(), const Color(0xFFA855F7)),
        ],
      ),
    );
  }

  Widget _buildTrendItem(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String title, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}
