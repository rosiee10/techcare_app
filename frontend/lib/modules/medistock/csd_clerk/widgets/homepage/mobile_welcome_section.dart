import 'package:flutter/material.dart';
import '../../../../../core/reusable_widgets/welcome_banner_card.dart';
import '../../../../../core/reusable_widgets/quick_actions_grid.dart';
import '../../../../../core/theme/app_theme.dart';

/// Mobile welcome and quick actions section for CSD Clerk
class MobileWelcomeSection {
  final VoidCallback? onReadMoreTap;
  final VoidCallback? onInventoryTap;
  final VoidCallback? onCartsTap;
  final VoidCallback? onRequestsTap;
  final VoidCallback? onKitchenTap;
  final VoidCallback? onReportsTap;

  const MobileWelcomeSection({
    this.onReadMoreTap,
    this.onInventoryTap,
    this.onCartsTap,
    this.onRequestsTap,
    this.onKitchenTap,
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
              title: 'Central Supply Dashboard',
              message: 'Manage inventory, supplies, and purchase requests efficiently.',
              actionLabel: 'Read more',
              onActionTap: onReadMoreTap ?? () {},
              imagePath: 'assets/images/opd1.png',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),

      // Quick Actions - 5 main buttons
      SliverToBoxAdapter(
        child: QuickActionsGrid(
          title: 'Quick Action',
          actions: [
            QuickActionItem(
              icon: Icons.inventory_2_outlined,
              label: 'Inventory',
              color: theme.buttonPrimary,
              onTap: onInventoryTap ?? () {},
            ),
            QuickActionItem(
              icon: Icons.shopping_cart_outlined,
              label: 'Carts',
              color: const Color(0xFF00BCD4),
              onTap: onCartsTap ?? () {},
            ),
            QuickActionItem(
              icon: Icons.request_page_outlined,
              label: 'Requests',
              color: const Color(0xFF4CAF50),
              onTap: onRequestsTap ?? () {},
            ),
            QuickActionItem(
              icon: Icons.restaurant_outlined,
              label: 'Kitchen',
              color: const Color(0xFFFF9800),
              onTap: onKitchenTap ?? () {},
            ),
            QuickActionItem(
              icon: Icons.bar_chart_outlined,
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
