import 'package:flutter/material.dart';
import '../../../../../core/reusable_widgets/section_title.dart';
import '../../../../../core/theme/app_theme.dart';
import 'dispensing_sheet_card_mobile.dart';

/// Mobile dispensing sheet section widget for Pharmacist
class MobileDispensingSheetSection {
  final List<Map<String, dynamic>> dispensingSheets;
  final VoidCallback? onViewAllTap;

  const MobileDispensingSheetSection({
    required this.dispensingSheets,
    this.onViewAllTap,
  });

  List<Widget> build(BuildContext context) {
    return [
      // Dispensing Sheet Section Title
      SliverToBoxAdapter(
        child: Column(
          children: [
            const SizedBox(height: 24),
            SectionTitle(
              title: 'Pending Dispensing Sheets',
              actionLabel: 'View All',
              onActionTap: onViewAllTap ?? () {},
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),

      // Dispensing Sheet List
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == dispensingSheets.length) {
                return const SizedBox(height: 24);
              }

              final item = dispensingSheets[index];
              return Padding(
                padding: EdgeInsets.only(bottom: index < dispensingSheets.length - 1 ? 10 : 0),
                child: DispensingSheetCardMobile(
                  documentNo: item['document_no'] ?? 'N/A',
                  patientName: item['patient_name'] ?? 'Unknown',
                  ward: item['ward'] ?? 'N/A',
                  status: item['status'] ?? 'Pending',
                  statusColor: _getStatusColor(item['status'] ?? 'Pending'),
                ),
              );
            },
            childCount: dispensingSheets.length + 1,
          ),
        ),
      ),
    ];
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'dispensed':
        return const Color(0xFF4CAF50);
      case 'pending':
        return const Color(0xFFFF9800);
      case 'in progress':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}
