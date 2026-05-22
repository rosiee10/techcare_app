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
import '../widgets/sidebar.dart';
import '../../shared/settings_profile/pages/change_password_page.dart';
import '../../shared/settings_profile/pages/profile_page.dart';
import '../../shared/settings_profile/pages/settings_page.dart';
import 'my_records_page.dart';
import 'appointments_page.dart';
import 'lab_results_page.dart';
import 'prescriptions_page.dart';

class PatientDashboard extends StatelessWidget {
  const PatientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardThemeWrapper(
      child: _PatientDashboardContent(),
    );
  }
}

class _PatientDashboardContent extends StatefulWidget {
  const _PatientDashboardContent();

  @override
  State<_PatientDashboardContent> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<_PatientDashboardContent> {
  int _selectedIndex = 0;
  bool _showProfile = false;
  bool _showSettings = false;
  bool _showChangePassword = false;

  // Dashboard data
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  Map<String, dynamic>? _patientProfile;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchData();
  }

  Future<void> _loadTokenAndFetchData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    await _fetchDashboardData();
    await _fetchPatientProfile();
  }

  Future<void> _fetchDashboardData() async {
    if (_token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/patient/dashboard/stats/'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _stats = data['stats'] ?? {};
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      AppLogger.error('Error fetching dashboard data', tag: 'PatientDashboard', error: e);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchPatientProfile() async {
    if (_token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/patient/profile/'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _patientProfile = data['patient'];
        });
      }
    } catch (e) {
      AppLogger.error('Error fetching patient profile', tag: 'PatientDashboard', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final patientName = _patientProfile != null
        ? '${_patientProfile!['firstname']} ${_patientProfile!['lastname']}'
        : authProvider.fullName ?? 'Patient';

    return Scaffold(
      body: Row(
        children: [
          // Left: Sidebar
          PatientSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedIndex = index;
                _showProfile = false;
                _showSettings = false;
                _showChangePassword = false;
              });
            },
          ),

          // Right: Header + Content
          Expanded(
            child: Column(
              children: [
                // Shared Header Component
                AppBarHeader(
                  currentPage: _getPageTitle(),
                  onHomePressed: () {
                    setState(() {
                      _showProfile = false;
                      _showSettings = false;
                      _showChangePassword = false;
                      _selectedIndex = 0;
                    });
                  },
                  onProfilePressed: () {
                    setState(() {
                      _showProfile = true;
                      _showSettings = false;
                      _showChangePassword = false;
                    });
                  },
                  onSettingsPressed: () {
                    setState(() {
                      _showProfile = false;
                      _showSettings = true;
                      _showChangePassword = false;
                    });
                  },
                ),

                // Main Content Area
                Expanded(
                  child: _buildContent(patientName, theme),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(String patientName, AppThemeData theme) {
    if (_showChangePassword) {
      return ChangePasswordPage(
        onBack: () => setState(() {
          _showChangePassword = false;
          _showProfile = true;
        }),
      );
    }
    if (_showProfile) {
      return ProfilePage(
        onChangePassword: () => setState(() {
          _showChangePassword = true;
          _showProfile = false;
        }),
      );
    }
    if (_showSettings) {
      return const SettingsPage();
    }

    switch (_selectedIndex) {
      case 0:
        return _buildDashboard(patientName, theme);
      case 1:
        return const MyRecordsPage();
      case 2:
        return const AppointmentsPage();
      case 3:
        return const LabResultsPage();
      case 4:
        return const PrescriptionsPage();
      default:
        return _buildDashboard(patientName, theme);
    }
  }

  Widget _buildDashboard(String patientName, AppThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: theme.pageBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Banner
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
                          'Welcome, $patientName!',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Patient Portal Dashboard',
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
                      Icons.favorite_outline,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Stat Cards
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Total Visits',
                    value: (_stats['total_visits'] ?? 0).toString(),
                    subtitle: 'Hospital visits',
                    icon: Icons.local_hospital_outlined,
                    bgColor: theme.sidebarActiveBackground,
                    iconColor: theme.buttonPrimary,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: StatCard(
                    title: 'Upcoming Appointments',
                    value: (_stats['upcoming_appointments'] ?? 0).toString(),
                    subtitle: 'Scheduled visits',
                    icon: Icons.calendar_today_outlined,
                    bgColor: theme.isDark ? const Color(0xFF1B4D3E) : const Color(0xFFE8F5E9),
                    iconColor: const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: StatCard(
                    title: 'Pending Lab Results',
                    value: (_stats['pending_lab_results'] ?? 0).toString(),
                    subtitle: 'Awaiting results',
                    icon: Icons.science_outlined,
                    bgColor: theme.isDark ? const Color(0xFF4D3A1B) : const Color(0xFFFFF3E0),
                    iconColor: const Color(0xFFFF9800),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: StatCard(
                    title: 'Active Prescriptions',
                    value: (_stats['active_prescriptions'] ?? 0).toString(),
                    subtitle: 'Current medications',
                    icon: Icons.medication_outlined,
                    bgColor: theme.isDark ? const Color(0xFF3D1B4D) : const Color(0xFFF3E5F5),
                    iconColor: const Color(0xFF9C27B0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Quick Actions Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Quick Actions
                Expanded(
                  flex: 1,
                  child: CardContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: 'Quick Actions',
                          fontSize: 20,
                          color: theme.textPrimary,
                        ),
                        const SizedBox(height: 16),
                        _buildQuickActionButton(
                          'View My Records',
                          Icons.folder_open_outlined,
                          () => setState(() => _selectedIndex = 1),
                          theme,
                        ),
                        const SizedBox(height: 12),
                        _buildQuickActionButton(
                          'My Appointments',
                          Icons.calendar_month_outlined,
                          () => setState(() => _selectedIndex = 2),
                          theme,
                        ),
                        const SizedBox(height: 12),
                        _buildQuickActionButton(
                          'Lab Results',
                          Icons.biotech_outlined,
                          () => setState(() => _selectedIndex = 3),
                          theme,
                        ),
                        const SizedBox(height: 12),
                        _buildQuickActionButton(
                          'Prescriptions',
                          Icons.medication_liquid_outlined,
                          () => setState(() => _selectedIndex = 4),
                          theme,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Right: Health Tips
                Expanded(
                  flex: 2,
                  child: CardContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.health_and_safety_outlined, color: theme.success, size: 24),
                            const SizedBox(width: 12),
                            SectionHeader(
                              title: 'Health Tips',
                              fontSize: 20,
                              color: theme.textPrimary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildHealthTip(
                          'Stay Hydrated',
                          'Drink at least 8 glasses of water daily to maintain good health.',
                          Icons.water_drop_outlined,
                          const Color(0xFF2196F3),
                          theme,
                        ),
                        const SizedBox(height: 12),
                        _buildHealthTip(
                          'Regular Exercise',
                          'Aim for at least 30 minutes of moderate exercise per day.',
                          Icons.fitness_center_outlined,
                          const Color(0xFF4CAF50),
                          theme,
                        ),
                        const SizedBox(height: 12),
                        _buildHealthTip(
                          'Healthy Sleep',
                          'Get 7-9 hours of quality sleep each night for optimal health.',
                          Icons.bedtime_outlined,
                          const Color(0xFF9C27B0),
                          theme,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, VoidCallback onTap, AppThemeData theme) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.sidebarHoverBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.buttonPrimary, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: theme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthTip(String title, String description, IconData icon, Color iconColor, AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.isDark ? iconColor.withOpacity(0.1) : iconColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    if (_showChangePassword) return 'Change Password';
    if (_showProfile) return 'My Profile';
    if (_showSettings) return 'Settings';

    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'My Records';
      case 2:
        return 'Appointments';
      case 3:
        return 'Lab Results';
      case 4:
        return 'Prescriptions';
      default:
        return 'Dashboard';
    }
  }
}
