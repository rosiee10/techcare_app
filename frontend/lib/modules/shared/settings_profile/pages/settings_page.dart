import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/provider/theme_provider.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/logger.dart';
import '../../../shared/widgets/dashboard_theme_wrapper.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  String _selectedLanguage = 'English';
  String? _token;
  SharedPreferences? _prefs;

  final Map<String, String> _languageMap = {
    'en': 'English',
    'fil': 'Filipino',
    'ceb': 'Bisaya',
  };
  final Map<String, String> _languageCodeMap = {
    'English': 'en',
    'Filipino': 'fil',
    'Bisaya': 'ceb',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _token = _prefs!.getString('auth_token');
    
    // Load from local storage first (offline support)
    setState(() {
      _notificationsEnabled = _prefs!.getBool('notifications_enabled') ?? true;
      _emailNotifications = _prefs!.getBool('email_notifications') ?? true;
      _pushNotifications = _prefs!.getBool('push_notifications') ?? true;
      _selectedLanguage = _prefs!.getString('language') ?? 'English';
    });

    // Then fetch from backend
    await _fetchSettingsFromBackend();
  }

  Future<void> _fetchSettingsFromBackend() async {
    if (_token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/accounts/settings/'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _notificationsEnabled = data['notifications_enabled'] ?? true;
          _emailNotifications = data['email_notifications'] ?? true;
          _pushNotifications = data['push_notifications'] ?? true;
          _selectedLanguage = _languageMap[data['language']] ?? 'English';
        });
        
        // Save to local storage
        await _saveToLocalStorage();
      }
    } catch (e) {
      AppLogger.error('Error fetching settings', tag: 'SettingsPage', error: e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveToLocalStorage() async {
    await _prefs!.setBool('notifications_enabled', _notificationsEnabled);
    await _prefs!.setBool('email_notifications', _emailNotifications);
    await _prefs!.setBool('push_notifications', _pushNotifications);
    await _prefs!.setString('language', _selectedLanguage);
  }

  Future<void> _saveSettingsToBackend() async {
    if (_token == null) return;

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/accounts/settings/update/'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'notifications_enabled': _notificationsEnabled,
          'email_notifications': _emailNotifications,
          'push_notifications': _pushNotifications,
          'language': _languageCodeMap[_selectedLanguage] ?? 'en',
        }),
      );

      if (response.statusCode == 200) {
        await _saveToLocalStorage();
      }
    } catch (e) {
      AppLogger.error('Error saving settings', tag: 'SettingsPage', error: e);
    }
  }

  void _updateSetting(String key, dynamic value) {
    setState(() {
      switch (key) {
        case 'notifications_enabled':
          _notificationsEnabled = value;
          break;
        case 'email_notifications':
          _emailNotifications = value;
          break;
        case 'push_notifications':
          _pushNotifications = value;
          break;
        case 'language':
          _selectedLanguage = value;
          break;
      }
    });
    _saveSettingsToBackend();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        slivers: [
          // SliverAppBar with white background
          SliverAppBar(
            pinned: true,
            floating: false,
            elevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            expandedHeight: 120,
            toolbarHeight: 56,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.white,
                padding: const EdgeInsets.only(top: 56, left: 24, right: 24, bottom: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.settings,
                        color: AppColors.primaryBlue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Customize your app experience',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            
            // Notifications Section
            _buildSectionCard(
              title: 'Notifications',
              icon: Icons.notifications_outlined,
              iconColor: const Color(0xFFFF9800),
              iconBgColor: const Color(0xFFFFF3E0),
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: 'Enable Notifications',
                    subtitle: 'Receive app notifications',
                    value: _notificationsEnabled,
                    onChanged: (value) => _updateSetting('notifications_enabled', value),
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    title: 'Email Notifications',
                    subtitle: 'Receive updates via email',
                    value: _emailNotifications,
                    enabled: _notificationsEnabled,
                    onChanged: (value) => _updateSetting('email_notifications', value),
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    title: 'Push Notifications',
                    subtitle: 'Receive alerts on your device',
                    value: _pushNotifications,
                    enabled: _notificationsEnabled,
                    onChanged: (value) => _updateSetting('push_notifications', value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Appearance Section
            _buildSectionCard(
              title: 'Appearance',
              icon: Icons.palette_outlined,
              iconColor: const Color(0xFF9C27B0),
              iconBgColor: const Color(0xFFF3E5F5),
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: 'Dark Mode',
                    subtitle: 'Use dark theme in dashboard',
                    value: context.watch<DashboardThemeProvider>().isDarkMode,
                    onChanged: (value) => context.read<DashboardThemeProvider>().setDarkMode(value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Language Section
            _buildSectionCard(
              title: 'Language',
              icon: Icons.language,
              iconColor: const Color(0xFF2196F3),
              iconBgColor: const Color(0xFFE3F2FD),
              child: InkWell(
                onTap: () => _showLanguageSelector(),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.translate,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'App Language',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedLanguage,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // About Section
            _buildSectionCard(
              title: 'About',
              icon: Icons.info_outline,
              iconColor: const Color(0xFF4CAF50),
              iconBgColor: const Color(0xFFE8F5E9),
              child: Column(
                children: [
                  _buildInfoTile(
                    icon: Icons.app_shortcut,
                    iconColor: AppColors.primaryBlue,
                    title: 'Version',
                    subtitle: 'TechCare v1.0.0',
                  ),
                  const Divider(height: 1),
                  _buildActionTile(
                    icon: Icons.description_outlined,
                    iconColor: const Color(0xFF4CAF50),
                    title: 'Terms of Service',
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _buildActionTile(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: const Color(0xFFFF9800),
                    title: 'Privacy Policy',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Support Section
            _buildSectionCard(
              title: 'Support',
              icon: Icons.help_outline,
              iconColor: const Color(0xFFE91E63),
              iconBgColor: const Color(0xFFFCE4EC),
              child: Column(
                children: [
                  _buildActionTile(
                    icon: Icons.support_agent,
                    iconColor: const Color(0xFF2196F3),
                    title: 'Help Center',
                    subtitle: 'Get help with using the app',
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _buildActionTile(
                    icon: Icons.feedback_outlined,
                    iconColor: const Color(0xFF9C27B0),
                    title: 'Send Feedback',
                    subtitle: 'Help us improve the app',
                    onTap: () {},
                  ),
                ],
              ),
            ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: AppColors.primaryBlue,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? Colors.grey[600] : Colors.grey,
      ),
      onTap: onTap,
    );
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Select Language',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: _selectedLanguage == 'English'
                    ? Icon(Icons.check, color: AppColors.primaryBlue)
                    : const SizedBox(width: 24),
                title: const Text('English'),
                onTap: () {
                  _updateSetting('language', 'English');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: _selectedLanguage == 'Filipino'
                    ? Icon(Icons.check, color: AppColors.primaryBlue)
                    : const SizedBox(width: 24),
                title: const Text('Filipino'),
                onTap: () {
                  _updateSetting('language', 'Filipino');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: _selectedLanguage == 'Bisaya'
                    ? Icon(Icons.check, color: AppColors.primaryBlue)
                    : const SizedBox(width: 24),
                title: const Text('Bisaya'),
                onTap: () {
                  _updateSetting('language', 'Bisaya');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
