import 'package:flutter/material.dart';
import '../../../../../core/reusable_widgets/section_title.dart';
import '../../../../../core/theme/app_theme.dart';
import 'stat_card_mobile.dart';

/// Mobile stats section widget
class MobileStatsSection {
  final int totalVisits;
  final int queueWaiting;
  final int completed;
  final int activeRooms;

  const MobileStatsSection({
    required this.totalVisits,
    required this.queueWaiting,
    required this.completed,
    required this.activeRooms,
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
              title: 'Today\'s Overview',
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
              value: totalVisits.toString(),
              label: 'Total Visits',
              sublabel: 'Today',
              icon: Icons.people_outline,
              color: theme.buttonPrimary,
            ),
            const SizedBox(height: 12),
            StatCardMobile(
              value: queueWaiting.toString(),
              label: 'Queue Waiting',
              sublabel: 'Patients in queue',
              icon: Icons.queue_outlined,
              color: const Color(0xFFFF9800),
            ),
            const SizedBox(height: 12),
            StatCardMobile(
              value: completed.toString(),
              label: 'Completed',
              sublabel: 'Total done today',
              icon: Icons.check_circle_outline,
              color: const Color(0xFF4CAF50),
            ),
            const SizedBox(height: 12),
            StatCardMobile(
              value: activeRooms.toString(),
              label: 'Active Rooms',
              sublabel: 'In use',
              icon: Icons.meeting_room_outlined,
              color: const Color(0xFF9C27B0),
            ),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    ];
  }
}
