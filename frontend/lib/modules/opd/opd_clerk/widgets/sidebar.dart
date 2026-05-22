import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/base_sidebar.dart';

class OpdClerkSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const OpdClerkSidebar({
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
          title: 'PATIENTS',
          items: [
            SidebarMenuItem(index: 1, icon: Icons.person_add_outlined, title: 'Registration'),
            SidebarMenuItem(index: 2, icon: Icons.assignment_outlined, title: 'Patient List'),
            SidebarMenuItem(index: 3, icon: Icons.schedule_outlined, title: 'Appointments'),
          ],
        ),
        SidebarSection(
          title: 'RECORDS',
          items: [
            SidebarMenuItem(index: 4, icon: Icons.folder_outlined, title: 'Medical Records'),
            SidebarMenuItem(index: 5, icon: Icons.receipt_outlined, title: 'Billing'),
          ],
        ),
      ],
    );
  }
}
