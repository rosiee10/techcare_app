import 'package:flutter/material.dart';
import '../../../../../core/reusable_widgets/welcome_banner_card.dart';
import '../../../../../core/reusable_widgets/quick_actions_grid.dart';
import '../../../../../core/theme/app_theme.dart';

/// Mobile welcome and quick actions section for Pharmacist
class MobileWelcomeSection {
  final VoidCallback? onReadMoreTap;
  final VoidCallback? onPrescriptionTap;
  final VoidCallback? onInventoryTap;
  final VoidCallback? onDispensingTap;
  final VoidCallback? onPurchaseTap;
  final VoidCallback? onReportsTap;

  const MobileWelcomeSection({
    this.onReadMoreTap,
    this.onPrescriptionTap,
    this.onInventoryTap,
    this.onDispensingTap,
    this.onPurchaseTap,
    this.onReportsTap,
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
              title: 'Pharmacy Dashboard',
              message: 'Manage prescriptions and inventory efficiently.',
              actionLabel: 'Read more',
              onActionTap: onReadMoreTap ?? () {},
              imagePath: 'assets/images/opd1.png',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),

      // Quick Actions - 5 main buttons like OPD Clerk
      SliverToBoxAdapter(
        child: QuickActionsGrid(
          title: 'Quick Action',
          actions: [
            QuickActionItem(
              icon: Icons.medication_outlined,
              label: 'Inventory',
              color: const Color(0xFF00BCD4),
              onTap: onInventoryTap ?? () {},
            ),
            QuickActionItem(
              icon: Icons.local_hospital_outlined,
              label: 'Dispensing',
              color: const Color(0xFF4CAF50),
              onTap: onDispensingTap ?? () {},
            ),
            QuickActionItem(
              icon: Icons.receipt_long_outlined,
              label: 'Prescription',
              color: theme.buttonPrimary,
              onTap: onPrescriptionTap ?? () {},
            ),
            QuickActionItem(
              icon: Icons.shopping_cart_outlined,
              label: 'Purchase',
              color: const Color(0xFFFF9800),
              onTap: onPurchaseTap ?? () {},
            ),
            QuickActionItem(
              icon: Icons.assessment_outlined,
              label: 'Reports',
              color: const Color(0xFF9C27B0),
              onTap: onReportsTap ?? () {},
            ),
          ],
        ),
      ),
    ];
  }
}
