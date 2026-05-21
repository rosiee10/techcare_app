import 'package:flutter/material.dart';
import '../../../../../core/reusable_widgets/section_title.dart';
import '../../../../../core/theme/app_theme.dart';
import 'stat_card_mobile.dart';

/// Mobile stats section widget for Pharmacist
class MobileStatsSection {
  final int totalMedicines;
  final int lowStockCount;
  final int pendingDispensingSheets;
  final int pendingPrescriptions;

  const MobileStatsSection({
    required this.totalMedicines,
    required this.lowStockCount,
    required this.pendingDispensingSheets,
    required this.pendingPrescriptions,
  });

  List<Widget> build(BuildContext context) {
    final theme = AppTheme.of(context);

    return [
      // Stats Section Title
      SliverToBoxAdapter(
        child: Column(
          children: [
            const SizedBox(height: 24),
            SectionTitle(
              title: 'Overview',
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),

      // Stats List (one card per row)
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            StatCardMobile(
              value: totalMedicines.toString(),
              label: 'Medicines',
              sublabel: 'In inventory',
              icon: Icons.medication_outlined,
              color: const Color(0xFF2196F3),
            ),
            const SizedBox(height: 12),
            StatCardMobile(
              value: lowStockCount.toString(),
              label: 'Low Stock',
              sublabel: 'Needs reorder',
              icon: Icons.warning_amber_outlined,
              color: const Color(0xFFF57F17),
            ),
            const SizedBox(height: 12),
            StatCardMobile(
              value: pendingDispensingSheets.toString(),
              label: 'Pending Dispensing Sheets',
              sublabel: 'To dispense',
              icon: Icons.local_hospital_outlined,
              color: const Color(0xFF4CAF50),
            ),
            const SizedBox(height: 12),
            StatCardMobile(
              value: pendingPrescriptions.toString(),
              label: 'Pending Prescriptions',
              sublabel: 'To dispense',
              icon: Icons.receipt_outlined,
              color: theme.buttonPrimary,
            ),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    ];
  }
}
