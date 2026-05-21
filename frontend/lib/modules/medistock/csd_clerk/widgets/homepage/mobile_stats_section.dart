import 'package:flutter/material.dart';
import 'stat_card_mobile.dart';

/// Mobile stats section for CSD Clerk dashboard
class MobileStatsSection {
  final int totalItems;
  final int lowStockItems;
  final int pendingRequests;
  final int kitchenRequests;

  const MobileStatsSection({
    this.totalItems = 18,
    this.lowStockItems = 3,
    this.pendingRequests = 2,
    this.kitchenRequests = 0,
  });

  List<Widget> build(BuildContext context) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Dashboard Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              // Stats Grid
              Row(
                children: [
                  Expanded(
                    child: StatCardMobile(
                      value: totalItems.toString(),
                      label: 'Total Items',
                      icon: Icons.inventory_2_outlined,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCardMobile(
                      value: lowStockItems.toString(),
                      label: 'Low Stock',
                      icon: Icons.warning_amber_outlined,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCardMobile(
                      value: pendingRequests.toString(),
                      label: 'Pending PR',
                      icon: Icons.request_page_outlined,
                      color: const Color(0xFF22C55E),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCardMobile(
                      value: kitchenRequests.toString(),
                      label: 'Kitchen PR',
                      icon: Icons.restaurant_outlined,
                      color: const Color(0xFFA855F7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ];
  }
}
