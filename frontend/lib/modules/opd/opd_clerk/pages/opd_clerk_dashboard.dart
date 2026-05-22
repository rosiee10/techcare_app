import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/base_sidebar.dart';
import '../../../../core/reusable_widgets/mobile_bottom_nav.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/reusable_widgets/card_container.dart';
import '../../../../core/reusable_widgets/stat_card.dart';
import '../../../../core/reusable_widgets/section_header.dart';
import '../../../shared/settings_profile/pages/profile_page.dart';
import '../../../shared/settings_profile/pages/settings_page.dart';
import '../../../shared/widgets/dashboard_theme_wrapper.dart';
import '../../../shared/appbar/appbar_header.dart';
import 'dashboard_page.dart';
import 'patient_list_page.dart';
import 'register_patient_page.dart';
import 'room_assignment_page.dart';
import 'service_schedule_page.dart';
import 'queue_monitor_page.dart';
import 'tv_board_page.dart';
import '../../shared/pages/patient_profile_page.dart';

class OpdClerkDashboard extends StatefulWidget {
  final int? initialIndex;
  
  const OpdClerkDashboard({super.key, this.initialIndex});

  @override
  State<OpdClerkDashboard> createState() => _OpdClerkDashboardState();
}

class _OpdClerkDashboardState extends State<OpdClerkDashboard> {
  late int _selectedIndex;
  bool _showProfile = false;
  bool _showSettings = false;
  bool _showPatientProfile = false;
  String? _selectedPatientHospitalId;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex ?? 0;
  }

  final List<SidebarSection> _sections = const [
    SidebarSection(
      title: 'OVERVIEW',
      items: [
        SidebarMenuItem(index: 0, icon: Icons.dashboard_outlined, title: 'Dashboard'),
      ],
    ),
    SidebarSection(
      title: 'PATIENT',
      items: [
        SidebarMenuItem(index: 1, icon: Icons.people_outline, title: 'Patient List'),
        SidebarMenuItem(index: 2, icon: Icons.person_add_outlined, title: 'Register Patient'),
        SidebarMenuItem(index: 3, icon: Icons.meeting_room_outlined, title: 'Room Assignment'),
        SidebarMenuItem(index: 4, icon: Icons.schedule_outlined, title: 'Service Schedule'),
      ],
    ),
    SidebarSection(
      title: 'QUEUE',
      items: [
        SidebarMenuItem(index: 5, icon: Icons.monitor_outlined, title: 'Queue Monitor'),
        SidebarMenuItem(index: 6, icon: Icons.tv_outlined, title: 'TV Board Preview'),
      ],
    ),
  ];

  // Mobile bottom nav items (simplified for mobile)
  // Order: Home, Queue, Patients, Schedule, Rooms
  final List<NavItem> _mobileNavItems = const [
    NavItem(icon: Icons.dashboard_outlined, label: 'Home'),
    NavItem(icon: Icons.monitor_outlined, label: 'Queue'),
    NavItem(icon: Icons.people_outline, label: 'Patients'),
    NavItem(icon: Icons.schedule_outlined, label: 'Schedule'),
    NavItem(icon: Icons.meeting_room_outlined, label: 'Rooms'),
  ];

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
      _showProfile = false;
      _showSettings = false;
      _showPatientProfile = false;
      _selectedPatientHospitalId = null;
    });
  }

  void _onProfileTap() {
    setState(() {
      _showProfile = true;
      _showSettings = false;
    });
  }

  void _onSettingsTap() {
    setState(() {
      _showSettings = true;
      _showProfile = false;
    });
  }

  void _viewPatientProfile(String hospitalId) {
    setState(() {
      _showPatientProfile = true;
      _selectedPatientHospitalId = hospitalId;
      _showProfile = false;
      _showSettings = false;
    });
  }

  void _closePatientProfile() {
    setState(() {
      _showPatientProfile = false;
      _selectedPatientHospitalId = null;
    });
  }

  Widget _buildContent() {
    if (_showProfile) {
      return const ProfilePage();
    }
    if (_showSettings) {
      return const SettingsPage();
    }
    if (_showPatientProfile && _selectedPatientHospitalId != null) {
      return PatientProfilePage(
        hospitalId: _selectedPatientHospitalId!,
        onBack: _closePatientProfile,
      );
    }

    // Desktop sidebar mapping: Dashboard(0), PatientList(1), Register(2), RoomAssignment(3), Schedule(4), Queue(5), TVBoard(6)
    // Mobile nav mapping: Home(0), Queue(1), Patients(2), Schedule(3), Rooms(4)
    // The sidebar is used on desktop/web, mobile nav is used on mobile
    switch (_selectedIndex) {
      // Desktop sidebar indices
      case 0:
        return const DashboardPage();
      case 1:
        return PatientListPage(
          onRegisterPatientPressed: () => Navigator.pushNamed(context, '/opd-clerk/register'),
          onViewPatient: (hospitalId) => _viewPatientProfile(hospitalId),
        );
      case 2:
        return const RegisterPatientPage();
      case 3:
        return const RoomAssignmentPage();
      case 4:
        return const ServiceSchedulePage();
      case 5:
        return const QueueMonitorPage();
      case 6:
        return const TvBoardPage();
      default:
        return const DashboardPage();
    }
  }

  String _getPageTitle() {
    if (_showProfile) return 'Profile';
    if (_showSettings) return 'Settings';
    if (_showPatientProfile) return 'Patient Profile';

    // Desktop sidebar mapping: Dashboard(0), PatientList(1), Register(2), RoomAssignment(3), Schedule(4), Queue(5), TVBoard(6)
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Patient List';
      case 2:
        return 'Register Patient';
      case 3:
        return 'Room Assignment';
      case 4:
        return 'Service Schedule';
      case 5:
        return 'Queue Monitor';
      case 6:
        return 'TV Board Preview';
      default:
        return 'Dashboard';
    }
  }

  /// Build desktop layout with sidebar
  Widget _buildDesktopLayout(AppThemeData theme) {
    return Row(
      children: [
        BaseSidebar(
          selectedIndex: _selectedIndex,
          onItemSelected: _onItemSelected,
          sections: _sections,
          logoAssetPath: 'assets/logos/logo.png',
        ),
        Expanded(
          child: Column(
            children: [
              AppBarHeader(
                currentPage: _getPageTitle(),
                breadcrumbs: _showPatientProfile ? [
                  BreadcrumbItem(
                    title: 'Patient List',
                    onTap: () {
                      setState(() {
                        _showPatientProfile = false;
                        _selectedPatientHospitalId = null;
                        _selectedIndex = 1;
                      });
                    },
                  ),
                ] : null,
                onHomePressed: () {
                  setState(() {
                    _selectedIndex = 0;
                    _showProfile = false;
                    _showSettings = false;
                    _showPatientProfile = false;
                    _selectedPatientHospitalId = null;
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
                    _showSettings = true;
                    _showProfile = false;
                  });
                },
              ),
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build mobile layout with bottom nav
  Widget _buildMobileLayout(AppThemeData theme) {
    return Column(
      children: [
        // Main content (DashboardPage has its own SliverAppBar)
        Expanded(
          child: _buildContent(),
        ),
        // Bottom navigation
        MobileBottomNav(
          selectedIndex: _selectedIndex < 5 ? _selectedIndex : 0,
          onTabChange: _onItemSelected,
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

    return DashboardThemeWrapper(
      child: WillPopScope(
        onWillPop: () async {
          // Prevent back button from exiting the dashboard
          // Only allow logout to exit
          return false;
        },
        child: Scaffold(
          backgroundColor: theme.pageBackground,
          body: LayoutBuilder(
            builder: (context, constraints) {
              // Use mobile layout for screens narrower than 800px
              final isMobile = constraints.maxWidth < 800;
              
              if (isMobile) {
                return _buildMobileLayout(theme);
              } else {
                return _buildDesktopLayout(theme);
              }
            },
          ),
        ),
      ),
    );
  }
}
