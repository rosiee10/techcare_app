import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/provider/auth_provider.dart';
import '../../../core/reusable_widgets/stat_card.dart';
import '../../../core/reusable_widgets/card_container.dart';
import '../../../core/reusable_widgets/section_header.dart';
import '../../../core/config/api_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/logger.dart';
import '../../shared/widgets/dashboard_theme_wrapper.dart';
import '../../shared/appbar/appbar_header.dart';
import '../../shared/settings_profile/pages/profile_page.dart';
import '../../shared/settings_profile/pages/settings_page.dart';
import '../widgets/sidebar.dart';
import 'mobile_dashboard_page.dart';
import '../../../core/reusable_widgets/mobile_bottom_nav.dart';
import '../../../core/utils/responsive.dart';
import '../widgets/homepage/mobile_dashboard_header.dart';
import '../widgets/homepage/mobile_welcome_section.dart';
import '../widgets/homepage/mobile_patient_section.dart';
import 'pharmacy_inventory_page.dart';
import 'pharmacy_purchase_request_page.dart';
import '../services/chief_nurse_pharmacy_service.dart';

class ChiefNurseDashboard extends StatelessWidget {
  const ChiefNurseDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardThemeWrapper(
      child: _ChiefNurseDashboardContent(),
    );
  }
}

class _ChiefNurseDashboardContent extends StatefulWidget {
  const _ChiefNurseDashboardContent();

  @override
  State<_ChiefNurseDashboardContent> createState() => _ChiefNurseDashboardState();
}

class _ChiefNurseDashboardState extends State<_ChiefNurseDashboardContent> {
  int _selectedIndex = 0;
  bool _showProfile = false;
  bool _showSettings = false;
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _pharmacyStats = {};
  String? _token;

  // Calendar state
  DateTime _focusedDate = DateTime.now();

  // Mobile bottom nav items for Chief Nurse - 4 main features
  final List<NavItem> _mobileNavItems = const [
    NavItem(icon: Icons.dashboard_outlined, label: 'Home'),
    NavItem(icon: Icons.request_page_outlined, label: 'Pharmacy'),
    NavItem(icon: Icons.schedule_outlined, label: 'Schedule'),
    NavItem(icon: Icons.shopping_cart_outlined, label: 'Kitchen'),
  ];

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchData();
  }

  Future<void> _loadTokenAndFetchData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    await _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    if (_token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Fetch original dashboard stats
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/chief-nurse/dashboard/stats/'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _stats = data['stats'] ?? {};
      }

      // Fetch pharmacy purchase request stats
      final pharmacyService = ChiefNursePharmacyService();
      final prStatsResult = await pharmacyService.getPharmacyPRStats();
      if (prStatsResult['success']) {
        _pharmacyStats = prStatsResult['stats'] ?? {};
      }

      setState(() => _isLoading = false);
    } catch (e) {
      AppLogger.error('Error fetching dashboard data', tag: 'ChiefNurseDashboard', error: e);
      setState(() => _isLoading = false);
    }
  }

  /// Build mobile layout with bottom navigation
  Widget _buildMobileLayout(AppThemeData theme, String nurseName) {
    return Column(
      children: [
        // Main content
        Expanded(
          child: _buildContent(nurseName, theme),
        ),
        // Bottom navigation
        MobileBottomNav(
          selectedIndex: _selectedIndex == 0 ? 0 : _selectedIndex == 1 ? 1 : _selectedIndex == 3 ? 2 : _selectedIndex == 4 ? 3 : 0,
          onTabChange: (index) {
            setState(() {
              _showProfile = false;
              _showSettings = false;
              if (index == 0) _selectedIndex = 0;
              else if (index == 1) _selectedIndex = 1;
              else if (index == 2) _selectedIndex = 3;
              else if (index == 3) _selectedIndex = 4;
            });
          },
          items: _mobileNavItems,
          backgroundColor: theme.cardBackground,
          activeColor: theme.buttonPrimary,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final nurseName = authProvider.fullName ?? 'Chief Nurse';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.pageBackground,
        body: ResponsiveBuilder(
          builder: (context, constraints) {
            final isMobile = Responsive.isMobile(context);

            if (isMobile) {
              return _buildMobileLayout(theme, nurseName);
            }

            return Row(
              children: [
                ChiefNurseSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() {
                _showProfile = false;
                _showSettings = false;
                _selectedIndex = index;
              });
            },
          ),
          Expanded(
            child: Column(
              children: [
                AppBarHeader(
                  currentPage: _getPageTitle(),
                  onHomePressed: () {
                    setState(() {
                      _showProfile = false;
                      _showSettings = false;
                      _selectedIndex = 0;
                    });
                  },
                  onProfilePressed: () {
                    setState(() {
                      _showProfile = true;
                      _showSettings = false;
                    });
                  },
                  onSettingsPressed: () {
                    setState(() {
                      _showProfile = false;
                      _showSettings = true;
                    });
                  },
                ),
                Expanded(
                  child: _buildContent(nurseName, theme),
                ),
              ],
            ),
          ),
        ],
      );
          },
        ),
      ),
    );
  }

  Widget _buildContent(String nurseName, AppThemeData theme) {
    if (_showProfile) {
      return const ProfilePage();
    }
    if (_showSettings) {
      return const SettingsPage();
    }

    switch (_selectedIndex) {
      case 0:
        return _isLoading
            ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(theme.buttonPrimary)))
            : _buildDashboard(nurseName, theme);
      case 1:
        return _buildPharmacyInventory();
      case 2:
        return _buildPharmacyPurchaseRequest();
      case 3:
        return _buildKitchenStaffSchedule();
      case 4:
        return _buildKitchenPurchaseRequest();
      default:
        return _buildDashboard(nurseName, theme);
    }
  }

  Widget _buildDashboard(String nurseName, AppThemeData theme) {
    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = Responsive.isMobile(context);

        if (isMobile) {
          return _MobileDashboard();
        } else {
          return _DesktopDashboard(nurseName, theme);
        }
      },
    );
  }

  /// Mobile dashboard with SliverAppBar layout
  Widget _MobileDashboard() {
    return Container(
      color: Colors.white,
      child: CustomScrollView(
        slivers: [
          // Header section (AppBar, Search, Profile)
          ...MobileDashboardHeader(
            onSearchTap: () {},
            onProfileTap: () {},
            onNotificationTap: () {},
          ).build(),

          // Welcome and Quick Actions section
          ...MobileWelcomeSection(
            onReadMoreTap: () {},
            onWardTap: () {},
            onNursesTap: () {},
            onPatientsTap: () {},
            onBedsTap: () {},
            onScheduleTap: () {},
          ).build(context),

          // Patient section
          ...MobilePatientSection(
            patients: [
              {'bed_number': 'ICU-01', 'patient_name': 'John Doe', 'ward': 'ICU', 'status': 'Critical'},
              {'bed_number': 'MW-12', 'patient_name': 'Jane Smith', 'ward': 'Medical Ward', 'status': 'Stable'},
            ],
            onViewAllTap: () {},
          ).build(context),

          // Bottom padding for nav bar
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }

  /// Desktop dashboard (original layout)
  Widget _DesktopDashboard(String nurseName, AppThemeData theme) {
    return Container(
      color: theme.pageBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.buttonPrimary, theme.buttonHover],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, $nurseName!',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Chief Nurse Dashboard',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_hospital_outlined,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Total PR',
                    value: (_pharmacyStats['total'] ?? 0).toString(),
                    subtitle: 'All requests',
                    icon: Icons.receipt_long_outlined,
                    bgColor: theme.isDark ? const Color(0xFF1A237E) : const Color(0xFFE8EAF6),
                    iconColor: const Color(0xFF3F51B5),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: StatCard(
                    title: 'Pending',
                    value: (_pharmacyStats['pending'] ?? 0).toString(),
                    subtitle: 'Awaiting review',
                    icon: Icons.access_time_outlined,
                    bgColor: theme.isDark ? const Color(0xFF4A2C00) : const Color(0xFFFFF3E0),
                    iconColor: const Color(0xFFF57F17),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: StatCard(
                    title: 'Approved',
                    value: (_pharmacyStats['approved'] ?? 0).toString(),
                    subtitle: 'Ready for procurement',
                    icon: Icons.check_circle_outline,
                    bgColor: theme.isDark ? const Color(0xFF1B4D3E) : const Color(0xFFE8F5E9),
                    iconColor: const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: StatCard(
                    title: 'Delivered',
                    value: (_pharmacyStats['delivered'] ?? 0).toString(),
                    subtitle: 'Completed orders',
                    icon: Icons.local_shipping_outlined,
                    bgColor: theme.isDark ? const Color(0xFF0D3B66) : const Color(0xFFE3F2FD),
                    iconColor: const Color(0xFF1976D2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: _buildPurchaseRequestOverviewCard(theme),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 1,
                  child: _buildCalendarWidget(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseRequestOverviewCard(AppThemeData theme) {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Purchase Requests',
            fontSize: 20,
            color: theme.textPrimary,
          ),
          const SizedBox(height: 20),

          // Pharmacy Section
          _buildPRSectionHeader('Pharmacy', Icons.local_pharmacy_outlined, const Color(0xFF1976D2), theme),
          const SizedBox(height: 12),
          _buildPRStatusRow('Total', (_pharmacyStats['total'] ?? 0).toString(), const Color(0xFF3F51B5), theme),
          _buildPRStatusRow('Pending', (_pharmacyStats['pending'] ?? 0).toString(), const Color(0xFFF57F17), theme),
          _buildPRStatusRow('Approved', (_pharmacyStats['approved'] ?? 0).toString(), const Color(0xFF2E7D32), theme),
          _buildPRStatusRow('Delivered', (_pharmacyStats['delivered'] ?? 0).toString(), const Color(0xFF1976D2), theme),

          const SizedBox(height: 20),
          Divider(color: theme.cardBorder, height: 1),
          const SizedBox(height: 20),

          // Kitchen Section
          _buildPRSectionHeader('Kitchen', Icons.restaurant_outlined, const Color(0xFFFF9800), theme),
          const SizedBox(height: 12),
          _buildPRStatusRow('Total', '0', const Color(0xFF3F51B5), theme),
          _buildPRStatusRow('Pending', '0', const Color(0xFFF57F17), theme),
          _buildPRStatusRow('Approved', '0', const Color(0xFF2E7D32), theme),
          _buildPRStatusRow('Delivered', '0', const Color(0xFF1976D2), theme),
        ],
      ),
    );
  }

  Widget _buildPRSectionHeader(String label, IconData icon, Color color, AppThemeData theme) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(icon, size: 18, color: color),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: theme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPRStatusRow(String label, String count, Color color, AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.textSecondary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacyInventory() {
    return const PharmacyInventoryPage();
  }

  Widget _buildPharmacyPurchaseRequest() {
    return const PharmacyPurchaseRequestPage();
  }

  Widget _buildKitchenStaffSchedule() {
    return const Center(child: Text('Kitchen Staff Schedule - Coming Soon'));
  }

  Widget _buildKitchenPurchaseRequest() {
    return const Center(child: Text('Kitchen Purchase Request - Coming Soon'));
  }

  // ==================== CALENDAR WIDGET ====================

  Widget _buildCalendarWidget() {
    return CardContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: () {
                  setState(() {
                    _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
                  });
                },
              ),
              Text(
                '${_getMonthName(_focusedDate.month)} ${_focusedDate.year}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: () {
                  setState(() {
                    _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    
    // Calculate days in month
    final daysInMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0).day;
    
    // Calculate first day of month (0 = Sunday, 1 = Monday, etc.)
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1).weekday % 7;
    
    // Calculate total slots needed (including empty slots before first day)
    final totalSlots = ((firstDayOfMonth + daysInMonth) / 7).ceil() * 7;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: days.map((day) => SizedBox(
            width: 32,
            child: Text(
              day,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 12),
        ...List.generate((totalSlots / 7).ceil(), (weekIndex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (dayIndex) {
                final slotIndex = weekIndex * 7 + dayIndex;
                final dayNum = slotIndex - firstDayOfMonth + 1;
                
                // Check if this slot is before the first day or after the last day
                if (dayNum < 1 || dayNum > daysInMonth) {
                  return const SizedBox(width: 32, height: 32);
                }
                
                final now = DateTime.now();
                final isToday = dayNum == now.day && 
                                 _focusedDate.month == now.month && 
                                 _focusedDate.year == now.year;
                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isToday ? const Color(0xFF2196F3) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$dayNum',
                      style: TextStyle(
                        fontSize: 12,
                        color: isToday ? Colors.white : Colors.black87,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String _getPageTitle() {
    if (_showProfile) return 'My Profile';
    if (_showSettings) return 'Settings';

    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Pharmacy Inventory';
      case 2:
        return 'Pharmacy Purchase Request';
      case 3:
        return 'Kitchen Staff Schedule';
      case 4:
        return 'Kitchen Purchase Request';
      default:
        return 'Dashboard';
    }
  }
}
