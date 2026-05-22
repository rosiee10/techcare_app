import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/provider/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/logout_config.dart';

class BreadcrumbItem {
  final String title;
  final VoidCallback? onTap;

  const BreadcrumbItem({
    required this.title,
    this.onTap,
  });
}

class AppBarHeader extends StatelessWidget {
  final String currentPage;
  final List<BreadcrumbItem>? breadcrumbs;
  final VoidCallback? onHomePressed;
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onProfilePressed;
  final VoidCallback? onSettingsPressed;

  final int notificationCount;

  const AppBarHeader({
    super.key,
    required this.currentPage,
    this.breadcrumbs,
    this.onHomePressed,
    this.onNotificationPressed,
    this.onProfilePressed,
    this.onSettingsPressed,
    this.notificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = AppTheme.of(context);

    return Column(
      children: [
        // Top Header Bar
        Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: theme.headerBackground,
            border: Border(
              bottom: BorderSide(color: theme.cardBorder, width: 1),
            ),
          ),
          child: Row(
            children: [
              // Hospital Logo
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(1),
                child: ClipOval(
                  child: Image.asset(
                    'assets/logos/pchlogo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.local_hospital,
                        color: theme.buttonPrimary,
                        size: 40,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Hospital Name
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Plaridel Community Hospital',
                    style: theme.sectionHeaderStyle.copyWith(
                      color: theme.headerText,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'Integrated Hospital Management System',
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Notification Bell
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications_outlined, color: theme.headerText),
                    onPressed: onNotificationPressed ?? () {},
                  ),
                  if (notificationCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          notificationCount > 99 ? '99+' : notificationCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              // User Profile
              PopupMenuButton<String>(
                offset: const Offset(0, 55),
                color: theme.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 3,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth:180,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.buttonPrimary,
                      radius: 18,
                      child: Text(
                        authProvider.fullName?.substring(0, 1).toUpperCase() ?? 'A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          authProvider.fullName ?? 'Administrator',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.headerText,
                          ),
                        ),
                        Text(
                          authProvider.userData?['email'] ?? 'admin@techcare.com',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_drop_down, color: theme.textMuted, size: 20),
                  ],
                ),
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'profile',
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    child: Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 15,
                        color: theme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'settings',
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 15,
                        color: theme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem<String>(
                    value: 'logout',
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    child: Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 15,
                        color: theme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'logout') {
                    _handleLogout(context, authProvider);
                  } else if (value == 'profile') {
                    onProfilePressed?.call();
                  } else if (value == 'settings') {
                    onSettingsPressed?.call();
                  }
                },
              ),
            ],
          ),
        ),
        
        // Breadcrumb Navigation Bar
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: theme.headerBackground,
            border: Border(
              bottom: BorderSide(color: theme.cardBorder, width: 1),
            ),
          ),
          child: Row(
            children: _buildBreadcrumbs(theme),
          ),
        ),
      ],
    );
  }

  IconData _getPageIcon(String page) {
    switch (page) {
      case 'Dashboard':
        return Icons.dashboard_outlined;
      case 'User Management':
        return Icons.people_outline;
      case 'Patient List':
        return Icons.assignment_outlined;
      case 'Reports & Analytics':
        return Icons.assessment_outlined;
      case 'Audit Log':
        return Icons.history_outlined;
      case 'Backup & Restore':
        return Icons.backup_outlined;
      case 'Security Settings':
        return Icons.security_outlined;
      case 'System Settings':
        return Icons.settings_outlined;
      case 'Patient Profile':
        return Icons.person_outline;
      case 'Register Patient':
        return Icons.person_add_outlined;
      case 'Service Schedule':
        return Icons.schedule_outlined;
      case 'Room Assignment':
        return Icons.meeting_room_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  List<Widget> _buildBreadcrumbs(AppThemeData theme) {
    final List<Widget> items = [];
    
    // Home Icon
    items.add(
      IconButton(
        icon: Icon(Icons.home_outlined, size: 20, color: theme.buttonPrimary),
        onPressed: onHomePressed ?? () {},
      ),
    );
    items.add(const SizedBox(width: 4));
    
    // Breadcrumb items
    if (breadcrumbs != null && breadcrumbs!.isNotEmpty) {
      for (final breadcrumb in breadcrumbs!) {
        items.add(Icon(Icons.chevron_right, size: 16, color: theme.textMuted));
        items.add(const SizedBox(width: 4));
        items.add(
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: breadcrumb.onTap,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  breadcrumb.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: breadcrumb.onTap != null ? theme.buttonPrimary : theme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        );
        items.add(const SizedBox(width: 4));
      }
    }
    
    // Current Page
    items.add(Icon(Icons.chevron_right, size: 16, color: theme.textMuted));
    items.add(const SizedBox(width: 4));
    items.add(
      Row(
        children: [
          Icon(_getPageIcon(currentPage), size: 18, color: theme.buttonPrimary),
          const SizedBox(width: 8),
          Text(
            currentPage,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.buttonPrimary,
            ),
          ),
        ],
      ),
    );
    
    return items;
  }

  Future<void> _handleLogout(BuildContext context, AuthProvider authProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true && context.mounted) {
      // Use centralized logout configuration for platform-specific routing
      await LogoutConfig.logoutAndNavigate(Navigator.of(context));
    }
  }
}
