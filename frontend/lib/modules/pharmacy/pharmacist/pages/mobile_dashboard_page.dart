import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/provider/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../shared/settings_profile/mobile/mobile_account_page.dart';
import '../services/pharmacy_service.dart';
import '../widgets/homepage/mobile_dashboard_header.dart';
import '../widgets/homepage/mobile_welcome_section.dart';
import '../widgets/homepage/mobile_stats_section.dart';
import '../widgets/homepage/mobile_prescription_section.dart';
import 'inventory_page.dart';
import 'inventory_carts_page.dart';
import 'ipd_dispensing_sheet_page.dart';
import 'ipd_pharmacy_billing_page.dart';
import 'opd_charge_slip_page.dart';
import 'purchase_request_page.dart';
import 'forecasting_page.dart';
import 'reports_page.dart';

/// Pharmacist mobile dashboard page with responsive layout
class MobileDashboardPage extends StatefulWidget {
  const MobileDashboardPage({super.key});

  @override
  State<MobileDashboardPage> createState() => _MobileDashboardPageState();
}

class _MobileDashboardPageState extends State<MobileDashboardPage> {
  final PharmacyService _pharmacyService = PharmacyService();
  bool _isLoading = true;
  Map<String, dynamic> _dashboardStats = {};
  List<Map<String, dynamic>> _prescriptions = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      setState(() => _isLoading = true);
      final stats = await _pharmacyService.getDashboardStats();
      
      // Fetch actual charge slips/prescriptions data
      final chargeSlips = await _pharmacyService.getChargeSlips();
      
      // Filter for pending prescriptions (not yet processed)
      final pendingPrescriptions = chargeSlips
          .where((slip) => slip['status'] != 'completed' && slip['status'] != 'processed')
          .map((slip) => {
                'rx_number': slip['charge_slip_number'] ?? slip['id']?.toString() ?? 'RX-000',
                'patient_name': slip['patient_name'] ?? 'Unknown',
                'medicine_count': slip['items']?.length ?? 0,
                'status': slip['status'] ?? 'Pending',
              })
          .toList()
          .take(5) // Show top 5 pending prescriptions
          .toList();
      
      setState(() {
        _dashboardStats = stats;
        _prescriptions = pendingPrescriptions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching dashboard data: $e');
      setState(() {
        _isLoading = false;
        // Use sample data as fallback
        _dashboardStats = {};
        _prescriptions = [];
      });
    }
  }

  void _navigateTo(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.buttonPrimary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Header section (AppBar, Search, Profile)
          ...MobileDashboardHeader(
            onSearchTap: () {},
            onProfileTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MobileAccountPage(),
                ),
              );
            },
            onNotificationTap: () {},
          ).build(),

          // Welcome and Quick Actions section - 5 main buttons like OPD Clerk
          ...MobileWelcomeSection(
            onReadMoreTap: () {},
            onPrescriptionTap: () => _navigateTo(const InventoryPage()),
            onInventoryTap: () => _navigateTo(const InventoryPage()),
            onDispensingTap: () => _navigateTo(const IpdDispensingSheetPage()),
            onPurchaseTap: () => _navigateTo(const PurchaseRequestPage()),
            onReportsTap: () => _navigateTo(const ReportsPage()),
          ).build(context),

          // Stats section
          ...MobileStatsSection(
            pendingPrescriptions: _dashboardStats['pending_prescriptions'] ?? 0,
            lowStockItems: _dashboardStats['low_stock_items'] ?? 0,
            dispensedToday: _dashboardStats['dispensed_today'] ?? 0,
            activeMedicines: _dashboardStats['active_medicines'] ?? 0,
          ).build(context),

          // Prescription section
          ...MobilePrescriptionSection(
            prescriptions: _prescriptions,
            onViewAllTap: () => _navigateTo(const InventoryPage()),
          ).build(context),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }
}
