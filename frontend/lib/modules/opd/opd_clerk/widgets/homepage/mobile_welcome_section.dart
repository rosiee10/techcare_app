import 'package:flutter/material.dart';
import '../../../../../core/reusable_widgets/welcome_banner_card.dart';
import '../../../../../core/reusable_widgets/quick_actions_grid.dart';
import '../../../../../core/theme/app_theme.dart';

/// Mobile welcome and quick actions section
class MobileWelcomeSection {
  final VoidCallback? onReadMoreTap;
  final VoidCallback? onRegisterTap;
  final VoidCallback? onRoomTap;
  final VoidCallback? onScheduleTap;
  final VoidCallback? onQueueTap;
  final VoidCallback? onPatientTap;

  const MobileWelcomeSection({
    this.onReadMoreTap,
    this.onRegisterTap,
    this.onRoomTap,
    this.onScheduleTap,
    this.onQueueTap,
    this.onPatientTap,
  });

  List<Widget> build(BuildContext context) {
    final theme = AppTheme.of(context);

    return [
      // Welcome Banner
      SliverToBoxAdapter(
        child: Column(
          children: [
            const SizedBox(height: 20),
            WelcomeBannerCard(
              title: 'OPD Clerk Dashboard',
              message: 'Welcome! Manage your patients efficiently today.',
              actionLabel: 'Read more',
              onActionTap: onReadMoreTap ?? () {},
              imagePath: 'assets/images/opd1.png',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),

      // Quick Actions
      SliverToBoxAdapter(
        child: QuickActionsGrid(
          title: 'Quick Action',
          actions: [
            QuickActionItem(
              icon: Icons.person_outline,
              label: 'Patient',
              color: const Color(0xFF00BCD4),
              onTap: onPatientTap ?? () {},
            ),
            QuickActionItem(
              icon: Icons.person_add_outlined,
              label: 'Register',
              color: theme.buttonPrimary,
              onTap: onRegisterTap ?? () {},
            ),
            QuickActionItem(
              icon: Icons.meeting_room_outlined,
              label: 'Room',
              color: const Color(0xFF9C27B0),
              onTap: onRoomTap ?? () {},
            ),
            QuickActionItem(
              icon: Icons.schedule_outlined,
              label: 'Schedule',
              color: const Color(0xFF4CAF50),
              onTap: onScheduleTap ?? () {},
            ),
            QuickActionItem(
              icon: Icons.monitor_outlined,
              label: 'Queue',
              color: const Color(0xFFFF9800),
              onTap: onQueueTap ?? () {},
            ),
          ],
        ),
      ),
    ];
  }
}
