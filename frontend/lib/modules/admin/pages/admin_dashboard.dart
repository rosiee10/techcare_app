import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/provider/auth_provider.dart';
import '../../../core/reusable_widgets/stat_card.dart';
import '../../../core/reusable_widgets/card_container.dart';
import '../../../core/reusable_widgets/section_header.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/logger.dart';
import '../../shared/widgets/dashboard_theme_wrapper.dart';
import '../widgets/sidebar.dart';
import '../../shared/appbar/appbar_header.dart';
import 'manage_users.dart';
import 'contact_messages.dart';
import '../../shared/settings_profile/pages/change_password_page.dart';
import '../../shared/settings_profile/pages/profile_page.dart';
import '../../shared/settings_profile/pages/settings_page.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardThemeWrapper(
      child: _AdminDashboardContent(),
    );
  }
}

class _AdminDashboardContent extends StatefulWidget {
  const _AdminDashboardContent();

  @override
  State<_AdminDashboardContent> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<_AdminDashboardContent> {
  int _selectedIndex = 0;
  bool _showProfile = false;
  bool _showSettings = false;
  bool _showChangePassword = false;
  
  // Dashboard data
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<dynamic> _recentActivity = [];
  List<dynamic> _alerts = [];
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchData();
  }

  Future<void> _loadTokenAndFetchData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    await _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    if (_token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/admin/dashboard/stats/'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _stats = data['stats'];
          _recentActivity = data['recent_activity'] ?? [];
          _alerts = data['alerts'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      AppLogger.error('Error fetching dashboard data', tag: 'AdminDashboard', error: e);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left: Sidebar
          AdminSidebar(
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
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
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
        return _buildDashboard();
      case 1:
        return const ManageUsersPage();
      case 2:
        return _buildPatientList();
      case 3:
        return _buildReports();
      case 4:
        return _buildAuditLog();
      case 5:
        return _buildBackup();
      case 6:
        return _buildSecurity();
      case 7:
        return const ContactMessagesPage();
      case 8:
        return _buildSystemSettings();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final theme = AppTheme.of(context);
    
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
                          'Welcome, ${authProvider.fullName ?? 'Administrator'}!',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'System Administration Dashboard',
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
                      Icons.dashboard_outlined,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Stat Cards - Using Real Data
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Total Users',
                    value: (_stats['total_users'] ?? 0).toString(),
                    subtitle: '${_stats['active_today'] ?? 0} active today',
                    icon: Icons.people_outline,
                    bgColor: theme.sidebarActiveBackground,
                    iconColor: theme.buttonPrimary,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: StatCard(
                    title: 'Total Patients',
                    value: (_stats['total_patients'] ?? 0).toString(),
                    subtitle: 'In database',
                    icon: Icons.favorite_outline,
                    bgColor: theme.isDark ? const Color(0xFF1B4D3E) : const Color(0xFFE8F5E9),
                    iconColor: const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: StatCard(
                    title: 'New Messages',
                    value: (_stats['new_messages'] ?? 0).toString(),
                    subtitle: 'Contact messages',
                    icon: Icons.message_outlined,
                    bgColor: theme.isDark ? const Color(0xFF4D3A1B) : const Color(0xFFFFF3E0),
                    iconColor: const Color(0xFFFF9800),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: StatCard(
                    title: 'System Uptime',
                    value: '99.8%',
                    subtitle: 'Last 30 days',
                    icon: Icons.trending_up,
                    bgColor: theme.isDark ? const Color(0xFF3D1B4D) : const Color(0xFFF3E5F5),
                    iconColor: const Color(0xFF9C27B0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Two Column Layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Recent Activity
                Expanded(
                  flex: 2,
                  child: CardContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: 'Recent Activity',
                          fontSize: 20,
                          color: theme.textPrimary,
                        ),
                        const SizedBox(height: 16),
                        if (_recentActivity.isEmpty)
                          Text('No recent activity', style: TextStyle(color: theme.textSecondary))
                        else
                          ..._recentActivity.map((activity) => _buildActivityItem(activity, theme)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Right: Alerts
                Expanded(
                  flex: 1,
                  child: CardContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: theme.error, size: 24),
                            const SizedBox(width: 12),
                            SectionHeader(
                              title: 'System Alerts',
                              fontSize: 20,
                              color: theme.textPrimary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_alerts.isEmpty)
                          Text('No alerts', style: TextStyle(color: theme.textSecondary))
                        else
                          ..._alerts.map((alert) => _buildAlertCard(
                            alert['message'],
                            alert['time'],
                            alert['type'] == 'warning' 
                              ? (theme.isDark ? const Color(0xFF4D4519) : const Color(0xFFFFF9C4))
                              : (theme.isDark ? const Color(0xFF1B4D2A) : const Color(0xFFE8F5E9)),
                            alert['type'] == 'warning' ? const Color(0xFFFBC02D) : const Color(0xFF4CAF50),
                            alert['type'] == 'warning' ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                            theme,
                          )),
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

  Widget _buildActivityItem(Map<String, dynamic> activity, AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.cardBorder),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: activity['status'] == 'new' ? theme.sidebarActiveBackground : theme.sidebarHoverBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              activity['type'] == 'contact_message' ? Icons.message : Icons.person,
              color: activity['status'] == 'new' ? theme.sidebarActiveText : theme.sidebarText,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'],
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity['description'],
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            activity['time'],
            style: TextStyle(
              fontSize: 12,
              color: theme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientList() {
    return const Center(child: Text('Patient List - Coming Soon'));
  }

  Widget _buildAuditLog() {
    return const Center(child: Text('Audit Log - Coming Soon'));
  }

  Widget _buildBackup() {
    return const Center(child: Text('Backup & Restore - Coming Soon'));
  }

  Widget _buildSecurity() {
    return const Center(child: Text('Security Settings - Coming Soon'));
  }

  // Removed _buildStatCard - Now using reusable StatCard widget

  Widget _buildAlertCard(
    String message,
    String time,
    Color bgColor,
    Color iconColor,
    IconData icon,
    AppThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: iconColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
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
        return 'Manage User';
      case 2:
        return 'Patient List';
      case 3:
        return 'Reports & Analytics';
      case 4:
        return 'Audit Log';
      case 5:
        return 'Backup & Restore';
      case 6:
        return 'Security Settings';
      case 7:
        return 'Contact Messages';
      case 8:
        return 'System Settings';
      default:
        return 'Dashboard';
    }
  }

  Widget _buildReports() {
    return const Center(
      child: Text('Reports - Coming Soon'),
    );
  }

  Widget _buildSystemSettings() {
    return const Center(
      child: Text('System Settings - Coming Soon'),
    );
  }
}
