import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

/// TechCare branded SliverAppBar for mobile screens
/// 
/// Features:
/// - Logo + TECHCARE title
/// - Notification bell icon with badge
/// - Profile/Account icon (mobile only)
/// - Collapsible sliver behavior
class TechCareSliverAppBar extends StatelessWidget {
  final String title;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final int notificationCount;
  final Widget? logo;
  final List<Widget>? actions;
  final bool pinned;
  final bool floating;
  final double expandedHeight;

  // Optional for notification dropdown
  final List<Widget>? notificationDropdownItems;

  const TechCareSliverAppBar({
    super.key,
    this.title = 'TECHCARE',
    this.onNotificationTap,
    this.onProfileTap,
    this.notificationCount = 0,
    this.logo,
    this.actions,
    this.pinned = true,
    this.floating = false,
    this.expandedHeight = 80,
    this.notificationDropdownItems,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        // Check if app bar is collapsed (scroll offset is significant)
        final isCollapsed = constraints.scrollOffset > 30;

        return SliverAppBar(
          pinned: pinned,
          floating: floating,
          expandedHeight: expandedHeight,
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 10, right: 16, top: 24, bottom: 12),
            title: Row(
              children: [
                // Logo image - hidden when collapsed
                if (!isCollapsed)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/logos/logo2.png',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (!isCollapsed) const SizedBox(width: 5),
                // TECHCARE title - always visible
                Text(
                  'TECHCARE',
                  style: TextStyle(
                    fontSize: isCollapsed ? 18 : 18,
                    fontWeight: FontWeight.bold,
                    color: theme.buttonPrimary,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
      actions: [
        // Notification Icon
        if (notificationDropdownItems != null)
          PopupMenuButton<String>(
            offset: const Offset(0, 50),
            color: Colors.transparent,
            elevation: 0,
            padding: EdgeInsets.zero,
            child: _NotificationBell(
              count: notificationCount,
              onTap: null, // Let PopupMenuButton handle the tap
            ),
            itemBuilder: (context) => notificationDropdownItems!
                .map((w) => PopupMenuItem<String>(
                      enabled: false,
                      padding: EdgeInsets.zero,
                      child: w,
                    ))
                .toList(),
          )
        else
          _NotificationBell(
            count: notificationCount,
            onTap: onNotificationTap,
          ),
        const SizedBox(width: 12),
        // Profile Icon (mobile only)
        if (Responsive.isMobile(context))
          _ProfileButton(
            onTap: onProfileTap,
          ),
        if (Responsive.isMobile(context)) const SizedBox(width: 16),
        ...?actions,
      ],
        );
      },
    );
  }
}

/// Notification bell with badge
class _NotificationBell extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const _NotificationBell({this.count = 0, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.cardBackground.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.notifications_outlined,
              color: theme.textPrimary,
              size: 30,
            ),
            if (count > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Center(
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Profile/Account button (mobile only)
class _ProfileButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _ProfileButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.cardBackground.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.person_outlined,
          color: theme.textPrimary,
          size: 30,
        ),
      ),
    );
  }
}
