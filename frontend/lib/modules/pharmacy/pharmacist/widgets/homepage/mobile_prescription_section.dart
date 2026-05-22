import 'package:flutter/material.dart';
import '../../../../../core/reusable_widgets/section_title.dart';
import '../../../../../core/theme/app_theme.dart';
import 'prescription_card_mobile.dart';

/// Mobile prescription section widget for Pharmacist
class MobilePrescriptionSection {
  final List<Map<String, dynamic>> prescriptions;
  final VoidCallback? onViewAllTap;

  const MobilePrescriptionSection({
    required this.prescriptions,
    this.onViewAllTap,
  });

  List<Widget> build(BuildContext context) {
    return [
      // Prescription Section Title
      SliverToBoxAdapter(
        child: Column(
          children: [
            const SizedBox(height: 24),
            SectionTitle(
              title: 'Pending Prescriptions',
              actionLabel: 'View All',
              onActionTap: onViewAllTap ?? () {},
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),

      // Prescription List
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == prescriptions.length) {
                return const SizedBox(height: 24);
              }

              final item = prescriptions[index];
              return Padding(
                padding: EdgeInsets.only(bottom: index < prescriptions.length - 1 ? 10 : 0),
                child: PrescriptionCardMobile(
                  rxNumber: item['rx_number'] ?? 'RX-000',
                  patientName: item['patient_name'] ?? 'Unknown',
                  medicineCount: item['medicine_count'] ?? 0,
                  status: item['status'] ?? 'Pending',
                  statusColor: _getStatusColor(item['status'] ?? 'Pending'),
                ),
              );
            },
            childCount: prescriptions.length + 1,
          ),
        ),
      ),
    ];
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ready':
        return const Color(0xFF4CAF50);
      case 'pending':
        return const Color(0xFFFF9800);
      case 'dispensed':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}
