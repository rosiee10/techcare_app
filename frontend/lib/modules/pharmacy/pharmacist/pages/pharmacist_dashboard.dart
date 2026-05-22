import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/utils/responsive.dart';
import '../../../../core/provider/auth_provider.dart';
import '../../../../core/reusable_widgets/stat_card.dart';
import '../../../../core/reusable_widgets/card_container.dart';
import '../../../../core/reusable_widgets/section_header.dart';
import '../../../../core/theme/app_theme.dart';
import '../services/pharmacy_service.dart';
import '../widgets/sidebar.dart';
import '../../../shared/appbar/appbar_header.dart';
import '../../../shared/settings_profile/pages/profile_page.dart';
import '../../../shared/settings_profile/pages/settings_page.dart';
import 'inventory_page.dart';
import 'inventory_carts_page.dart';
import 'ipd_dispensing_sheet_page.dart';
import 'ipd_pharmacy_billing_page.dart';
import 'opd_charge_slip_page.dart';
import 'purchase_request_page.dart';
import 'forecasting_page.dart';
import 'reports_page.dart';
import '../widgets/notifications/pharmacist_notification_dropdown.dart';
import '../../../../core/reusable_widgets/mobile_bottom_nav.dart';
import '../../../shared/widgets/dashboard_theme_wrapper.dart';
import '../widgets/homepage/mobile_dashboard_header.dart';
import '../widgets/homepage/mobile_welcome_section.dart';
import '../widgets/homepage/mobile_stats_section.dart';
import '../widgets/homepage/mobile_prescription_section.dart';
import '../widgets/homepage/mobile_dispensing_sheet_section.dart';

class PharmacistDashboard extends StatelessWidget {
  const PharmacistDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardThemeWrapper(
      child: _PharmacistDashboardContent(),
    );
  }
}

class _PharmacistDashboardContent extends StatefulWidget {
  const _PharmacistDashboardContent();

  @override
  State<_PharmacistDashboardContent> createState() => _PharmacistDashboardState();
}

class _PharmacistDashboardState extends State<_PharmacistDashboardContent>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _showProfile = false;
  bool _showSettings = false;

  // Mobile bottom nav items for Pharmacy - 6 items
  final List<NavItem> _mobileNavItems = const [
    NavItem(icon: Icons.dashboard_outlined, label: 'Home'),
    NavItem(icon: Icons.medication_outlined, label: 'Inventory'),
    NavItem(icon: Icons.local_hospital_outlined, label: 'Dispensing'),
    NavItem(icon: Icons.receipt_long_outlined, label: 'Charge Slip'),
    NavItem(icon: Icons.shopping_cart_outlined, label: 'Purchase'),
    NavItem(icon: Icons.assessment_outlined, label: 'Reports'),
  ];
  final PharmacyService _pharmacyService = PharmacyService();

  // Dynamic stats
  bool _isLoading = true;
  Map<String, dynamic> _dashboardStats = {};
  String _userName = 'Pharmacist';
  List<Map<String, dynamic>> _prescriptions = [];
  List<Map<String, dynamic>> _dispensingSheets = [];
  
  // Track read notifications locally at the dashboard level for instant UI updates
  final Set<String> _readNotificationIds = {};

  // For deep linking from notifications
  Map<String, dynamic>? _pendingActionData;

  // Selected date for notification filtering
  DateTime _selectedNotifDate = DateTime.now();

  // Calendar state
  DateTime _focusedDate = DateTime.now();

  Timer? _refreshTimer;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchDashboardStats();
    _loadUserName();
    _startRefreshTimer();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshIfOnDashboard(silent: true);
    });
  }

  void _refreshIfOnDashboard({bool silent = false}) {
    if (_selectedIndex != 0 || _showProfile || _showSettings) return;
    // Debounce: don't refresh more than once every 5 seconds
    if (_lastRefreshTime != null &&
        DateTime.now().difference(_lastRefreshTime!) < const Duration(seconds: 5)) {
      return;
    }
    _fetchDashboardStats(silent: silent);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshIfOnDashboard(silent: true);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _fetchDashboardStats({bool silent = false}) async {
    try {
      if (!silent) setState(() => _isLoading = true);
      _lastRefreshTime = DateTime.now();
      final stats = await _pharmacyService.getDashboardStats();
      
      // Fetch actual OPD prescriptions for pending prescriptions
      final opdPrescriptions = await _pharmacyService.getOpdPrescriptions();
      
      // Map OPD prescriptions to display format
      final pendingPrescriptions = opdPrescriptions
          .map((rx) => {
                'rx_number': 'RX-${rx['rx_id']?.toString() ?? '000'}',
                'patient_name': rx['patient_name'] ?? 'Unknown',
                'medicine_count': 1,
                'status': 'Pending',
              })
          .toList()
          .take(3) // Show top 3 pending prescriptions
          .toList();
      
      // Get pending dispensing sheets from dashboard stats
      final pendingDispensingSheets = (stats['pending_dispensing_sheets'] as List?)
          ?.map((sheet) => {
                'document_no': sheet['document_no'] ?? 'N/A',
                'patient_name': sheet['patient_name'] ?? 'Unknown',
                'ward': sheet['ward'] ?? 'N/A',
                'status': sheet['status'] ?? 'Pending',
              })
          .toList()
          .take(3) // Show top 3 pending dispensing sheets
          .toList() ?? [];
      
      setState(() {
        _dashboardStats = stats;
        _prescriptions = pendingPrescriptions;
        _dispensingSheets = pendingDispensingSheets;
        if (!silent) _isLoading = false;
      });
    } catch (e) {
      print('Error fetching dashboard data: $e');
      setState(() {
        if (!silent) _isLoading = false;
        _dashboardStats = {};
        _prescriptions = [];
        _dispensingSheets = [];
      });
    }
  }

  Future<void> _loadUserName() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userData;
    if (user != null) {
      setState(() {
        _userName = user['first_name'] ?? user['firstname'] ?? user['username'] ?? 'Pharmacist';
      });
    }
  }

  /// Build mobile layout with bottom navigation (matches OPD Clerk)
  Widget _buildMobileLayout(AppThemeData theme) {
    return Column(
      children: [
        // Main content (Dashboard has its own header)
        Expanded(
          child: _buildContent(),
        ),
        // Bottom navigation
        MobileBottomNav(
          selectedIndex: _selectedIndex,
          onTabChange: (index) {
            setState(() {
              _selectedIndex = index;
              _showProfile = false;
              _showSettings = false;
              _pendingActionData = null;
            });
            if (index == 0) {
              _refreshIfOnDashboard(silent: true);
            }
          },
          items: _mobileNavItems,
          backgroundColor: theme.cardBackground,
          activeColor: theme.buttonPrimary,
        ),
      ],
    );
  }

  /// Mobile dashboard content with full header (matches OPD Clerk)
  Widget _buildMobileDashboardContent() {
    // Calculate notification count
    final List<dynamic> pendingSheets = _dashboardStats['pending_dispensing_sheets'] ?? [];
    final List<dynamic> approvedPRs = _dashboardStats['approved_prs'] ?? [];
    final List<dynamic> lowStock = _dashboardStats['low_stock_alerts'] ?? [];
    final List<dynamic> expiry = _dashboardStats['expiry_alerts'] ?? [];
    final int unreadPending = pendingSheets.where((s) => !_readNotificationIds.contains('sheet_${s['document_no']}_${s['timestamp']}')).length;
    final int unreadApproved = approvedPRs.where((p) => !_readNotificationIds.contains('pr_${p['pr_no']}_${p['timestamp']}')).length;
    final int notificationCount = unreadPending + unreadApproved + lowStock.length + expiry.length;

    return Container(
      color: Colors.white,
      child: CustomScrollView(
        slivers: [
          // Full Header: AppBar + Search + Profile (like OPD Clerk)
          ...MobileDashboardHeader(
            notificationCount: notificationCount,
            onNotificationTap: () {
              // Show notification dropdown manually for web/mobile if needed
              showDialog(
                context: context,
                barrierColor: Colors.transparent,
                builder: (context) => StatefulBuilder(
                  builder: (context, setDialogState) {
                    return Stack(
                      children: [
                        Positioned(
                          top: 60,
                          right: 20,
                          child: PharmacistNotificationDropdown(
                            stats: _dashboardStats,
                            readIds: _readNotificationIds,
                            selectedDate: _selectedNotifDate,
                            onDateChanged: (date) {
                              setDialogState(() {
                                _selectedNotifDate = date;
                              });
                              setState(() {
                                _selectedNotifDate = date;
                              });
                            },
                            onMarkRead: (id) {
                              setDialogState(() {
                                _readNotificationIds.add(id);
                              });
                              setState(() {
                                _readNotificationIds.add(id);
                              });
                            },
                            onMarkAllRead: () {
                              setDialogState(() {
                                final List<dynamic> sheets = _dashboardStats['pending_dispensing_sheets'] ?? [];
                                final List<dynamic> prs = _dashboardStats['approved_prs'] ?? [];
                                for (var s in sheets) {
                                  _readNotificationIds.add('sheet_${s['document_no']}_${s['timestamp']}');
                                }
                                for (var p in prs) {
                                  _readNotificationIds.add('pr_${p['pr_no']}_${p['timestamp']}');
                                }
                              });
                              setState(() {
                                final List<dynamic> sheets = _dashboardStats['pending_dispensing_sheets'] ?? [];
                                final List<dynamic> prs = _dashboardStats['approved_prs'] ?? [];
                                for (var s in sheets) {
                                  _readNotificationIds.add('sheet_${s['document_no']}_${s['timestamp']}');
                                }
                                for (var p in prs) {
                                  _readNotificationIds.add('pr_${p['pr_no']}_${p['timestamp']}');
                                }
                              });
                            },
                            onNavigate: (index, data) {
                              setState(() {
                                _showProfile = false;
                                _showSettings = false;
                                _selectedIndex = index;
                                _pendingActionData = data;
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  }
                ),
              );
            },
            onSearchTap: () {},
            onProfileTap: () {
              setState(() {
                _showProfile = true;
                _showSettings = false;
              });
            },
          ).build(),
          // Welcome and Quick Actions section
          ...MobileWelcomeSection(
            onReadMoreTap: () {},
            onInventoryTap: () {
              setState(() {
                _selectedIndex = 1; // Navigate to Inventory
              });
            },
            onDispensingTap: () {
              setState(() {
                _selectedIndex = 2; // Navigate to Dispensing
              });
            },
            onPrescriptionTap: () {
              setState(() {
                _selectedIndex = 3; // Navigate to Charge Slip (Prescription)
              });
            },
            onPurchaseTap: () {
              setState(() {
                _selectedIndex = 4; // Navigate to Purchase
              });
            },
            onReportsTap: () {
              setState(() {
                _selectedIndex = 5; // Navigate to Reports
              });
            },
          ).build(context),
          // Stats section
          ...MobileStatsSection(
            totalMedicines: _dashboardStats['total_medicines'] ?? 0,
            lowStockCount: _dashboardStats['low_stock_count'] ?? 0,
            pendingDispensingSheets: (_dashboardStats['pending_dispensing_sheets'] as List?)?.length ?? 0,
            pendingPrescriptions: _dashboardStats['pending_prescriptions'] ?? 0,
          ).build(context),
          // Pending Dispensing Sheet section
          ...MobileDispensingSheetSection(
            dispensingSheets: _dispensingSheets,
            onViewAllTap: () {
              setState(() {
                _selectedIndex = 2; // Navigate to Dispensing
              });
            },
          ).build(context),
          // Prescription section
          ...MobilePrescriptionSection(
            prescriptions: _prescriptions,
            onViewAllTap: () {
              setState(() {
                _selectedIndex = 3; // Navigate to Charge Slip
              });
            },
          ).build(context),
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.pageBackground,
        body: ResponsiveBuilder(
          builder: (context, constraints) {
            final isMobile = Responsive.isMobile(context);

            if (isMobile) {
              return _buildMobileLayout(theme);
            }

            return Row(
              children: [
                // Left: Sidebar
                PharmacistSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() {
                _showProfile = false;
                _showSettings = false;
                _selectedIndex = index;
                _pendingActionData = null;
              });
              if (index == 0) {
                _refreshIfOnDashboard(silent: true);
              }
            },
          ),

          // Right: Header + Content
          Expanded(
            child: Column(
              children: [
                // Shared Header Component
                AppBarHeader(
                  currentPage: _getPageTitle(),
                  notificationCount: (() {
                    final List<dynamic> sheets = _dashboardStats['pending_dispensing_sheets'] as List? ?? [];
                    final List<dynamic> prs = _dashboardStats['approved_prs'] as List? ?? [];
                    final List<dynamic> lowStock = _dashboardStats['low_stock_alerts'] as List? ?? [];
                    final List<dynamic> expiry = _dashboardStats['expiry_alerts'] as List? ?? [];
                    
                    // Count unread sheets and PRs
                    final int unreadSheets = sheets.where((s) => !_readNotificationIds.contains('sheet_${s['document_no']}_${s['timestamp']}')).length;
                    final int unreadPrs = prs.where((p) => !_readNotificationIds.contains('pr_${p['pr_no']}_${p['timestamp']}')).length;
                    
                    // Alerts are always counted as they don't have a read state
                    return unreadSheets + unreadPrs + lowStock.length + expiry.length;
                  })(),
                  onNotificationPressed: () {
                    showDialog(
                      context: context,
                      barrierColor: Colors.transparent,
                      builder: (context) => StatefulBuilder(
                        builder: (context, setDialogState) {
                          return Stack(
                            children: [
                              Positioned(
                                top: 65, // Slightly lower than header
                                right: 24, // Align with typical padding
                                child: PharmacistNotificationDropdown(
                                  stats: _dashboardStats,
                                  readIds: _readNotificationIds,
                                  selectedDate: _selectedNotifDate,
                                  onDateChanged: (date) {
                                    setDialogState(() {
                                      _selectedNotifDate = date;
                                    });
                                    setState(() {
                                      _selectedNotifDate = date;
                                    });
                                  },
                                  onMarkRead: (id) {
                                    setDialogState(() {
                                      _readNotificationIds.add(id);
                                    });
                                    setState(() {
                                      _readNotificationIds.add(id);
                                    });
                                  },
                                  onMarkAllRead: () {
                                    setDialogState(() {
                                      final List<dynamic> sheets = _dashboardStats['pending_dispensing_sheets'] ?? [];
                                      final List<dynamic> prs = _dashboardStats['approved_prs'] ?? [];
                                      for (var s in sheets) {
                                        _readNotificationIds.add('sheet_${s['document_no']}_${s['timestamp']}');
                                      }
                                      for (var p in prs) {
                                        _readNotificationIds.add('pr_${p['pr_no']}_${p['timestamp']}');
                                      }
                                    });
                                    setState(() {
                                      final List<dynamic> sheets = _dashboardStats['pending_dispensing_sheets'] ?? [];
                                      final List<dynamic> prs = _dashboardStats['approved_prs'] ?? [];
                                      for (var s in sheets) {
                                        _readNotificationIds.add('sheet_${s['document_no']}_${s['timestamp']}');
                                      }
                                      for (var p in prs) {
                                        _readNotificationIds.add('pr_${p['pr_no']}_${p['timestamp']}');
                                      }
                                    });
                                  },
                                  onNavigate: (index, data) {
                                    setState(() {
                                      _showProfile = false;
                                      _showSettings = false;
                                      _selectedIndex = index;
                                      _pendingActionData = data;
                                    });
                                  },
                                ),
                              ),
                            ],
                          );
                        }
                      ),
                    );
                  },
                  onHomePressed: () {
                    setState(() {
                      _showProfile = false;
                      _showSettings = false;
                      _selectedIndex = 0;
                      _pendingActionData = null;
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

                // Main Content Area
                Expanded(
                  child: _buildContent(),
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

  Widget _buildContent() {
    if (_showProfile) {
      return const ProfilePage();
    }
    if (_showSettings) {
      return const SettingsPage();
    }
    // For mobile: only 6 nav items (indices 0-5)
    // For desktop sidebar: 9 items (indices 0-8)
    if (Responsive.isMobile(context)) {
      switch (_selectedIndex) {
        case 0:
          return _buildDashboard();
        case 1:
          return _buildInventory();
        case 2:
          return _buildIPDDispensingSheet();
        case 3:
          return _buildOPDChargeSlip();
        case 4:
          return _buildPurchaseRequest();
        case 5:
          return _buildReports();
        default:
          return _buildDashboard();
      }
    }
    
    // Desktop sidebar navigation (9 items)
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildInventory();
      case 2:
        return _buildInventoryCarts();
      case 3:
        return _buildIPDDispensingSheet();
      case 4:
        return _buildIPDPharmacyBilling();
      case 5:
        return _buildOPDChargeSlip();
      case 6:
        return _buildPurchaseRequest();
      case 7:
        return _buildForecasting();
      case 8:
        return _buildReports();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = Responsive.isMobile(context);

        if (isMobile) {
          return _MobileDashboard();
        } else {
          return _DesktopDashboard();
        }
      },
    );
  }

  /// Mobile dashboard - desktop responsive fallback (with full header)
  Widget _MobileDashboard() {
    // Calculate notification count correctly
    final List<dynamic> pendingSheets = _dashboardStats['pending_dispensing_sheets'] ?? [];
    final List<dynamic> approvedPRs = _dashboardStats['approved_prs'] ?? [];
    final List<dynamic> lowStock = _dashboardStats['low_stock_alerts'] ?? [];
    final List<dynamic> expiry = _dashboardStats['expiry_alerts'] ?? [];

    final int unreadSheets = pendingSheets.where((s) => !_readNotificationIds.contains('sheet_${s['document_no']}_${s['timestamp']}')).length;
    final int unreadPrs = approvedPRs.where((p) => !_readNotificationIds.contains('pr_${p['pr_no']}_${p['timestamp']}')).length;
    final int notificationCount = unreadSheets + unreadPrs + lowStock.length + expiry.length;

    return Container(
      color: Colors.white,
      child: RefreshIndicator(
        onRefresh: _fetchDashboardStats,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header section (AppBar, Search, Profile) - full header for desktop-responsive
            ...MobileDashboardHeader(
            notificationCount: notificationCount,
            onNotificationTap: () {
              // Show notification dropdown manually for web/mobile if needed
              showDialog(
                context: context,
                barrierColor: Colors.transparent,
                builder: (context) => StatefulBuilder(
                  builder: (context, setDialogState) {
                    return Stack(
                      children: [
                        Positioned(
                          top: 60,
                          right: 20,
                          child: PharmacistNotificationDropdown(
                            stats: _dashboardStats,
                            readIds: _readNotificationIds,
                            selectedDate: _selectedNotifDate,
                            onDateChanged: (date) {
                              setDialogState(() {
                                _selectedNotifDate = date;
                              });
                              setState(() {
                                _selectedNotifDate = date;
                              });
                            },
                            onMarkRead: (id) {
                              setDialogState(() {
                                _readNotificationIds.add(id);
                              });
                              setState(() {
                                _readNotificationIds.add(id);
                              });
                            },
                            onMarkAllRead: () {
                              setDialogState(() {
                                final List<dynamic> sheets = _dashboardStats['pending_dispensing_sheets'] ?? [];
                                final List<dynamic> prs = _dashboardStats['approved_prs'] ?? [];
                                for (var s in sheets) {
                                  _readNotificationIds.add('sheet_${s['document_no']}_${s['timestamp']}');
                                }
                                for (var p in prs) {
                                  _readNotificationIds.add('pr_${p['pr_no']}_${p['timestamp']}');
                                }
                              });
                              setState(() {
                                final List<dynamic> sheets = _dashboardStats['pending_dispensing_sheets'] ?? [];
                                final List<dynamic> prs = _dashboardStats['approved_prs'] ?? [];
                                for (var s in sheets) {
                                  _readNotificationIds.add('sheet_${s['document_no']}_${s['timestamp']}');
                                }
                                for (var p in prs) {
                                  _readNotificationIds.add('pr_${p['pr_no']}_${p['timestamp']}');
                                }
                              });
                            },
                            onNavigate: (index, data) {
                              setState(() {
                                _showProfile = false;
                                _showSettings = false;
                                _selectedIndex = index;
                                _pendingActionData = data;
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  }
                ),
              );
            },
            onSearchTap: () {},
            onProfileTap: () {},
          ).build(),

        // Welcome and Quick Actions section
        ...MobileWelcomeSection(
          onReadMoreTap: () {},
          onInventoryTap: () {
            setState(() {
              _selectedIndex = 1; // Navigate to Inventory
            });
          },
          onDispensingTap: () {
            setState(() {
              _selectedIndex = 2; // Navigate to Dispensing
            });
          },
          onPrescriptionTap: () {
            setState(() {
              _selectedIndex = 3; // Navigate to Charge Slip (Prescription)
            });
          },
          onPurchaseTap: () {
            setState(() {
              _selectedIndex = 4; // Navigate to Purchase
            });
          },
          onReportsTap: () {
            setState(() {
              _selectedIndex = 5; // Navigate to Reports
            });
          },
        ).build(context),

        // Stats section
        ...MobileStatsSection(
          totalMedicines: _dashboardStats['total_medicines'] ?? 0,
          lowStockCount: _dashboardStats['low_stock_count'] ?? 0,
          pendingDispensingSheets: (_dashboardStats['pending_dispensing_sheets'] as List?)?.length ?? 0,
          pendingPrescriptions: _dashboardStats['pending_prescriptions'] ?? 0,
        ).build(context),

        // Pending Dispensing Sheet section
        ...MobileDispensingSheetSection(
          dispensingSheets: _dispensingSheets,
          onViewAllTap: () {
            setState(() {
              _selectedIndex = 2; // Navigate to Dispensing
            });
          },
        ).build(context),

        // Prescription section
        ...MobilePrescriptionSection(
          prescriptions: _prescriptions,
          onViewAllTap: () {
            setState(() {
              _selectedIndex = 3; // Navigate to Charge Slip
            });
          },
        ).build(context),

            // Bottom padding for nav bar
            const SliverToBoxAdapter(
              child: SizedBox(height: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _DesktopDashboard() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isTablet = Responsive.isTablet(context);

    return RefreshIndicator(
      onRefresh: _fetchDashboardStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isTablet ? 20 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Banner
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isTablet ? 24 : 32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BCD4), Color(0xFF00ACC1)],
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
                          'Welcome, $_userName!',
                          style: TextStyle(
                            fontSize: isTablet ? 24 : 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pharmacist Dashboard',
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(isTablet ? 16 : 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.dashboard_outlined,
                      size: isTablet ? 48 : 60,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Stat Cards
            isTablet 
              ? GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 2.2,
                  children: [
                    StatCard(
                      title: 'Total Medicines',
                      value: '${_dashboardStats['total_medicines'] ?? 0}',
                      subtitle: 'In inventory',
                      icon: Icons.medication_outlined,
                      bgColor: const Color(0xFFE3F2FD),
                      iconColor: const Color(0xFF2196F3),
                    ),
                    StatCard(
                      title: 'Low Stock Items',
                      value: '${_dashboardStats['low_stock_count'] ?? 0}',
                      subtitle: 'Need reordering',
                      icon: Icons.warning_amber_outlined,
                      bgColor: const Color(0xFFFFF9C4),
                      iconColor: const Color(0xFFF57F17),
                    ),
                    StatCard(
                      title: 'Expiring Soon',
                      value: '${_dashboardStats['expiring_soon'] ?? 0}',
                      subtitle: 'Within 30 days',
                      icon: Icons.access_time_outlined,
                      bgColor: const Color(0xFFE8F5E9),
                      iconColor: const Color(0xFF2E7D32),
                    ),
                    StatCard(
                      title: 'Pending PRs',
                      value: '${_dashboardStats['pending_prs'] ?? 0}',
                      subtitle: 'Awaiting approval',
                      icon: Icons.pending_actions_outlined,
                      bgColor: const Color(0xFFF3E5F5),
                      iconColor: const Color(0xFF7B1FA2),
                    ),
                  ],
                )
              : IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Total Medicines',
                          value: '${_dashboardStats['total_medicines'] ?? 0}',
                          subtitle: 'In inventory',
                          icon: Icons.medication_outlined,
                          bgColor: const Color(0xFFE3F2FD),
                          iconColor: const Color(0xFF2196F3),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: StatCard(
                          title: 'Low Stock Items',
                          value: '${_dashboardStats['low_stock_count'] ?? 0}',
                          subtitle: 'Need reordering',
                          icon: Icons.warning_amber_outlined,
                          bgColor: const Color(0xFFFFF9C4),
                          iconColor: const Color(0xFFF57F17),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: StatCard(
                          title: 'Expiring Soon',
                          value: '${_dashboardStats['expiring_soon'] ?? 0}',
                          subtitle: 'Within 30 days',
                          icon: Icons.access_time_outlined,
                          bgColor: const Color(0xFFE8F5E9),
                          iconColor: const Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: StatCard(
                          title: 'Pending PRs',
                          value: '${_dashboardStats['pending_prs'] ?? 0}',
                          subtitle: 'Purchase requests awaiting approval',
                          icon: Icons.pending_actions_outlined,
                          bgColor: const Color(0xFFF3E5F5),
                          iconColor: const Color(0xFF7B1FA2),
                        ),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: 32),
            
            // Main Content Area
            if (isTablet) ...[
              _buildConsultationQueueTable(),
              const SizedBox(height: 24),
              _buildResultsInbox(),
              const SizedBox(height: 24),
              _buildCalendarWidget(),
            ] else 
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Consultation Queue Table
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildConsultationQueueTable(),
                        const SizedBox(height: 24),
                        _buildResultsInbox(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Right: Calendar
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

  Widget _buildInventory() {
    return Container(
      color: Colors.white,
      child: const InventoryPage(),
    );
  }

  Widget _buildInventoryCarts() {
    return Container(
      color: Colors.white,
      child: const InventoryCartsPage(),
    );
  }

  Widget _buildIPDDispensingSheet() {
    return Container(
      color: Colors.white,
      child: IpdDispensingSheetPage(
        pendingActionData: _pendingActionData,
        onActionCompleted: _fetchDashboardStats,
      ),
    );
  }

  Widget _buildIPDPharmacyBilling() {
    return Container(
      color: Colors.white,
      child: const IpdPharmacyBillingPage(),
    );
  }

  Widget _buildOPDChargeSlip() {
    return Container(
      color: Colors.white,
      child: const OpdChargeSlipPage(),
    );
  }

  Widget _buildPurchaseRequest() {
    return Container(
      color: Colors.white,
      child: PurchaseRequestPage(
        pendingActionData: _pendingActionData,
        onActionCompleted: _fetchDashboardStats,
      ),
    );
  }

  Widget _buildForecasting() {
    return Container(
      color: Colors.white,
      child: const ForecastingPage(),
    );
  }

  Widget _buildReports() {
    return Container(
      color: Colors.white,
      child: const SizedBox.expand(
        child: ReportsPage(),
      ),
    );
  }

  // Removed _buildDoctorStatCard - Now using reusable StatCard widget

  Widget _buildConsultationQueueTable() {
    final List<dynamic> pendingSheets = _dashboardStats['pending_dispensing_sheets'] ?? [];
    
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionHeader(title: 'Pending Dispensing Sheets'),
              Text(
                '${pendingSheets.length} pending',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (pendingSheets.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No pending dispensing sheets',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            )
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1.5),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(1.5),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  children: [
                    _buildTableHeader('DOC NO'),
                    _buildTableHeader('PATIENT'),
                    _buildTableHeader('WARD'),
                    _buildTableHeader('STATUS'),
                  ],
                ),
                ...pendingSheets.take(5).map((sheet) => _buildDispensingSheetRow(
                  sheet['document_no']?.toString() ?? 'N/A',
                  sheet['patient_name']?.toString() ?? 'Unknown',
                  sheet['ward']?.toString() ?? 'N/A',
                  sheet['status']?.toString() ?? 'Pending',
                )),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
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

  TableRow _buildDispensingSheetRow(String docNo, String patient, String ward, String status) {
    final statusColor = status == 'Pending' ? const Color(0xFFFF9800) : const Color(0xFF4CAF50);
    
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            docNo,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2563EB),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            patient,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            ward,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsInbox() {
    final List<dynamic> approvedPRs = _dashboardStats['approved_prs'] ?? [];
    final List<dynamic> lowStock = _dashboardStats['low_stock_alerts'] ?? [];
    final List<dynamic> expiry = _dashboardStats['expiry_alerts'] ?? [];
    
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Purchase Requests & Alerts'),
          const SizedBox(height: 16),
          
          // Approved PRs Section
          if (approvedPRs.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Approved Purchase Requests',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...approvedPRs.take(3).map((pr) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildAlertItem(
                'PR-${pr['pr_no'] ?? 'N/A'}',
                '${pr['item_count'] ?? 0} items',
                const Color(0xFF4CAF50),
              ),
            )),
            const SizedBox(height: 16),
          ],
          
          // Low Stock Alerts
          if (lowStock.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.warning_amber, size: 16, color: Colors.amber[700]),
                const SizedBox(width: 8),
                Text(
                  'Low Stock Alerts',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...lowStock.take(3).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildAlertItem(
                item['medicine_name']?.toString() ?? 'Unknown',
                'Stock: ${item['current_stock'] ?? 0}',
                const Color(0xFFF57F17),
              ),
            )),
            const SizedBox(height: 16),
          ],
          
          // Expiry Alerts
          if (expiry.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.red[700]),
                const SizedBox(width: 8),
                Text(
                  'Expiry Alerts',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...expiry.take(3).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildAlertItem(
                item['medicine_name']?.toString() ?? 'Unknown',
                'Expires: ${item['expiry_date'] ?? 'N/A'}',
                const Color(0xFFD32F2F),
              ),
            )),
          ],
          
          if (approvedPRs.isEmpty && lowStock.isEmpty && expiry.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No alerts or pending requests',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(String title, String subtitle, Color alertColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: alertColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            alertColor == const Color(0xFF4CAF50) ? Icons.check_circle_outline :
            alertColor == const Color(0xFFF57F17) ? Icons.inventory_2_outlined :
            Icons.event_busy_outlined,
            size: 20,
            color: alertColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

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
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Inventory';
      case 2:
        return 'Inventory Carts';
      case 3:
        return 'IPD Dispensing Sheet';
      case 4:
        return 'IPD Pharmacy Billing';
      case 5:
        return 'OPD Charge Slip';
      case 6:
        return 'Purchase Request';
      case 7:
        return 'Forecasting';
      case 8:
        return 'Reports';
      default:
        if (_showProfile) return 'My Profile';
        if (_showSettings) return 'Settings';
        return 'Dashboard';
    }
  }
}
