import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/provider/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/settings_profile/mobile/mobile_account_page.dart';
import '../providers/chief_nurse_provider.dart';
import '../services/chief_nurse_service.dart';
import '../widgets/homepage/mobile_dashboard_header.dart';
import '../widgets/homepage/mobile_welcome_section.dart';
import '../widgets/homepage/mobile_patient_section.dart';

/// Chief Nurse mobile dashboard page with responsive layout
class MobileDashboardPage extends StatefulWidget {
  const MobileDashboardPage({super.key});

  @override
  State<MobileDashboardPage> createState() => _MobileDashboardPageState();
}

class _MobileDashboardPageState extends State<MobileDashboardPage> {
  final ChiefNurseService _chiefNurseService = ChiefNurseService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _patients = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      setState(() => _isLoading = true);
      await _chiefNurseService.getDashboardStats();

      // Sample patients data - replace with actual API call
      _patients = [
        {'bed_number': 'ICU-01', 'patient_name': 'John Doe', 'ward': 'ICU', 'status': 'Critical'},
        {'bed_number': 'MW-12', 'patient_name': 'Jane Smith', 'ward': 'Medical Ward', 'status': 'Stable'},
        {'bed_number': 'SW-05', 'patient_name': 'Bob Johnson', 'ward': 'Surgical Ward', 'status': 'Recovering'},
      ];

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
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
            patients: _patients,
            onViewAllTap: () {},
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
