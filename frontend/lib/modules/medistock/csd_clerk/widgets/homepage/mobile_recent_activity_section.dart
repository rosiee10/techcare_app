import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

/// Mobile recent activity section for CSD Clerk dashboard
class MobileRecentActivitySection {
  const MobileRecentActivitySection();

  List<Widget> build(BuildContext context) {
    final theme = AppTheme.of(context);

    final activities = [
      {
        'title': 'Inventory Updated',
        'subtitle': 'Surgical Gloves stock adjusted',
        'time': '2 hours ago',
        'icon': Icons.inventory_2_outlined,
        'color': const Color(0xFF3B82F6),
      },
      {
        'title': 'Purchase Request Submitted',
        'subtitle': 'PR-2026-001 sent to Pharmacy',
        'time': '4 hours ago',
        'icon': Icons.request_page_outlined,
        'color': const Color(0xFF22C55E),
      },
      {
        'title': 'Low Stock Alert',
        'subtitle': 'Gauze Pads below threshold',
        'time': '6 hours ago',
        'icon': Icons.warning_amber_outlined,
        'color': const Color(0xFFF59E0B),
      },
      {
        'title': 'Kitchen Request Approved',
        'subtitle': 'Supply request processed',
        'time': '1 day ago',
        'icon': Icons.restaurant_outlined,
        'color': const Color(0xFFA855F7),
      },
    ];

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'View All',
                      style: TextStyle(
                        color: theme.buttonPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...activities.map((activity) => _buildActivityItem(activity)),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (activity['color'] as Color).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              activity['icon'] as IconData,
              color: activity['color'] as Color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity['subtitle'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            activity['time'] as String,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
