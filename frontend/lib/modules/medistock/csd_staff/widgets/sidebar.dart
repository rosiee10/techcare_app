import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/base_sidebar.dart';

class CsdStaffSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const CsdStaffSidebar({
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
          title: 'STERILIZATION',
          items: [
            SidebarMenuItem(index: 1, icon: Icons.clean_hands_outlined, title: 'Sterilization Queue'),
            SidebarMenuItem(index: 2, icon: Icons.verified_outlined, title: 'Quality Control'),
            SidebarMenuItem(index: 3, icon: Icons.inventory_outlined, title: 'Equipment Tracking'),
          ],
        ),
        SidebarSection(
          title: 'RECORDS',
          items: [
            SidebarMenuItem(index: 4, icon: Icons.history_outlined, title: 'Process Logs'),
            SidebarMenuItem(index: 5, icon: Icons.assessment_outlined, title: 'Reports'),
          ],
        ),
      ],
    );
  }
}
