import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/base_sidebar.dart';

class LabStaffSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const LabStaffSidebar({
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
          title: 'LABORATORY',
          items: [
            SidebarMenuItem(index: 1, icon: Icons.science_outlined, title: 'Test Requests'),
            SidebarMenuItem(index: 2, icon: Icons.edit_note_outlined, title: 'Results Entry'),
            SidebarMenuItem(index: 3, icon: Icons.inventory_outlined, title: 'Lab Inventory'),
          ],
        ),
        SidebarSection(
          title: 'REPORTS',
          items: [
            SidebarMenuItem(index: 4, icon: Icons.assessment_outlined, title: 'Lab Reports'),
          ],
        ),
      ],
    );
  }
}
