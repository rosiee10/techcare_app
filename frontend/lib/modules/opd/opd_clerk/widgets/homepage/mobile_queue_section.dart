import 'package:flutter/material.dart';
import '../../../../../core/reusable_widgets/section_title.dart';
import '../../providers/dashboard_provider.dart';
import 'queue_card_mobile.dart';

/// Mobile queue section widget
class MobileQueueSection {
  final List<QueueItem> queueItems;
  final VoidCallback? onViewAllTap;

  const MobileQueueSection({
    required this.queueItems,
    this.onViewAllTap,
  });

  List<Widget> build(BuildContext context) {
    return [
      // Queue Section Title
      SliverToBoxAdapter(
        child: Column(
          children: [
            const SizedBox(height: 24),
            SectionTitle(
              title: 'Today\'s Queue',
              actionLabel: 'View All',
              onActionTap: onViewAllTap ?? () {},
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),

      // Queue List
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == queueItems.length) {
                return const SizedBox(height: 24);
              }

              final item = queueItems[index];
              return Padding(
                padding: EdgeInsets.only(bottom: index < queueItems.length - 1 ? 10 : 0),
                child: QueueCardMobile(
                  queueNumber: item.queueNumber,
                  patientName: item.patientName,
                  room: item.room,
                  status: item.status,
                  statusColor: _parseColor(item.statusColor),
                ),
              );
            },
            childCount: queueItems.length + 1,
          ),
        ),
      ),
    ];
  }

  Color _parseColor(String colorString) {
    final hexString = colorString.replaceFirst('0x', '');
    return Color(int.parse(hexString, radix: 16));
  }
}
