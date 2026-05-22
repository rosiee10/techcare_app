import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/welcome_banner_card.dart';
import '../../../../core/reusable_widgets/quick_actions_grid.dart';
import '../../../../core/theme/app_theme.dart';

/// Mobile welcome and quick actions section for Chief Nurse
class MobileWelcomeSection {
  final VoidCallback? onReadMoreTap;
  final VoidCallback? onWardTap;
  final VoidCallback? onNursesTap;
  final VoidCallback? onPatientsTap;
  final VoidCallback? onBedsTap;
  final VoidCallback? onScheduleTap;

  const MobileWelcomeSection({
    this.onReadMoreTap,
    this.onWardTap,
    this.onNursesTap,
    this.onPatientsTap,
    this.onBedsTap,
    this.onScheduleTap,
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
              title: 'Chief Nurse Dashboard',
              message: 'Manage IPD wards and nursing operations efficiently.',
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
              icon: Icons.local_hospital_outlined,
              label: 'Wards',
              color: theme.buttonPrimary,
              onTap: onWardTap ?? () {},
            ),
            QuickActionItem(
              icon: Icons.assignment_ind_outlined,
              label: 'Nurses',
              color: const Color(0xFF00BCD4),
              onTap: onNursesTap ?? () {},
            ),
            QuickActionItem(
              icon: Icons.people_outline,
              label: 'Patients',
              color: const Color(0xFF4CAF50),
              onTap: onPatientsTap ?? () {},
            ),
            QuickActionItem(
              icon: Icons.bed_outlined,
              label: 'Beds',
              color: const Color(0xFF9C27B0),
              onTap: onBedsTap ?? () {},
            ),
            QuickActionItem(
              icon: Icons.calendar_month_outlined,
              label: 'Schedule',
              color: const Color(0xFFFF9800),
              onTap: onScheduleTap ?? () {},
            ),
          ],
        ),
      ),
    ];
  }
}
