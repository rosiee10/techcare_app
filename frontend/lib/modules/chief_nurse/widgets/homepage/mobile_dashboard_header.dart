import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/techcare_sliver_app_bar.dart';
import '../../../../core/reusable_widgets/techcare_search_bar.dart';
import 'profile_header_with_greeting.dart';

/// Mobile dashboard header section with AppBar, search, and profile for Chief Nurse
class MobileDashboardHeader {
  final VoidCallback? onSearchTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationTap;
  final TextEditingController? searchController;

  const MobileDashboardHeader({
    this.onSearchTap,
    this.onProfileTap,
    this.onNotificationTap,
    this.searchController,
  });

  List<Widget> build() {
    final controller = searchController ?? TextEditingController();

    return [
      // Sliver AppBar with TechCare logo
      TechCareSliverAppBar(
        notificationCount: 0,
        onNotificationTap: onNotificationTap,
        onProfileTap: onProfileTap,
      ),

      // Search Bar
      SliverToBoxAdapter(
        child: Column(
          children: [
            const SizedBox(height: 16),
            TechCareSearchBar(
              controller: controller,
              hintText: 'Search patients, nurses...',
              readOnly: false,
              onChanged: (value) {},
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),

      // Profile Header with Time-based Greeting
      SliverToBoxAdapter(
        child: ProfileHeaderWithGreeting(
          onTap: onProfileTap ?? () {},
        ),
      ),
    ];
  }
}
