import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/base_sidebar.dart';

class SocialWorkerSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const SocialWorkerSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BaseSidebar(
      selectedIndex: selectedIndex,
      onItemSelected: onItemSelected,
      sections: const [
        SidebarSection(
          title: 'OVERVIEW',
          items: [
            SidebarMenuItem(index: 0, icon: Icons.dashboard_outlined, title: 'Dashboard'),
          ],
        ),
        SidebarSection(
          title: 'CASE MANAGEMENT',
          items: [
            SidebarMenuItem(index: 1, icon: Icons.people_outline, title: 'Client Cases'),
            SidebarMenuItem(index: 2, icon: Icons.support_outlined, title: 'Assistance Programs'),
            SidebarMenuItem(index: 3, icon: Icons.family_restroom_outlined, title: 'Family Support'),
          ],
        ),
        SidebarSection(
          title: 'RECORDS',
          items: [
            SidebarMenuItem(index: 4, icon: Icons.folder_outlined, title: 'Case Files'),
            SidebarMenuItem(index: 5, icon: Icons.assessment_outlined, title: 'Reports'),
          ],
        ),
      ],
    );
  }
}
