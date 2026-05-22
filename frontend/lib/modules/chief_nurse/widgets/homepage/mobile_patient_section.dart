import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/section_title.dart';
import '../../../../core/theme/app_theme.dart';
import 'patient_card_mobile.dart';

/// Mobile patient section widget for Chief Nurse
class MobilePatientSection {
  final List<Map<String, dynamic>> patients;
  final VoidCallback? onViewAllTap;

  const MobilePatientSection({
    required this.patients,
    this.onViewAllTap,
  });

  List<Widget> build(BuildContext context) {
    return [
      // Patient Section Title
      SliverToBoxAdapter(
        child: Column(
          children: [
            const SizedBox(height: 24),
            SectionTitle(
              title: 'Ward Patients',
              actionLabel: 'View All',
              onActionTap: onViewAllTap ?? () {},
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),

      // Patient List
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == patients.length) {
                return const SizedBox(height: 24);
              }

              final item = patients[index];
              return Padding(
                padding: EdgeInsets.only(bottom: index < patients.length - 1 ? 10 : 0),
                child: PatientCardMobile(
                  bedNumber: item['bed_number'] ?? 'B-000',
                  patientName: item['patient_name'] ?? 'Unknown',
                  ward: item['ward'] ?? 'General',
                  status: item['status'] ?? 'Stable',
                  statusColor: _getStatusColor(item['status'] ?? 'Stable'),
                ),
              );
            },
            childCount: patients.length + 1,
          ),
        ),
      ),
    ];
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'critical':
        return const Color(0xFFE53935);
      case 'stable':
        return const Color(0xFF4CAF50);
      case 'recovering':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}
