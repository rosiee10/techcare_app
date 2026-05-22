import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/section_title.dart';
import '../../../../core/theme/app_theme.dart';
import 'stat_card_mobile.dart';

/// Mobile stats section widget for Chief Nurse
class MobileStatsSection {
  final int totalAdmitted;
  final int criticalPatients;
  final int availableBeds;
  final int nursesOnDuty;

  const MobileStatsSection({
    required this.totalAdmitted,
    required this.criticalPatients,
    required this.availableBeds,
    required this.nursesOnDuty,
  });

  List<Widget> build(BuildContext context) {
    final theme = AppTheme.of(context);

    final stats = [
      StatCardMobile(
        value: totalAdmitted.toString(),
        label: 'Total',
        sublabel: 'All requests',
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFF3F51B5),
      ),
      StatCardMobile(
        value: criticalPatients.toString(),
        label: 'Pending',
        sublabel: 'Awaiting review',
        icon: Icons.access_time_outlined,
        color: const Color(0xFFF57F17),
      ),
      StatCardMobile(
        value: availableBeds.toString(),
        label: 'Approved',
        sublabel: 'Ready for procurement',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF2E7D32),
      ),
      StatCardMobile(
        value: nursesOnDuty.toString(),
        label: 'Delivered',
        sublabel: 'Completed orders',
        icon: Icons.local_shipping_outlined,
        color: const Color(0xFF1976D2),
      ),
    ];

    return [
      // Stats Section Title
      SliverToBoxAdapter(
        child: Column(
          children: [
            const SizedBox(height: 24),
            SectionTitle(
              title: 'Purchase Requests',
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),

      // Stats Grid (2 cards per row)
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        sliver: SliverToBoxAdapter(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
              final spacing = 12.0;
              final childWidth = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: stats.map((stat) => SizedBox(
                  width: childWidth,
                  child: stat,
                )).toList(),
              );
            },
          ),
        ),
      ),
      const SliverToBoxAdapter(
        child: SizedBox(height: 16),
      ),
    ];
  }
}
