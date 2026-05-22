import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/base_sidebar.dart';

class OpdNurseSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const OpdNurseSidebar({
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
            SidebarMenuItem(index: 1, icon: Icons.people_outline, title: 'Patient Queue'),
            SidebarMenuItem(index: 2, icon: Icons.assignment_outlined, title: 'Patient List'),
            SidebarMenuItem(index: 3, icon: Icons.medical_services_outlined, title: 'Vital Signs'),
          ],
        ),
        SidebarSection(
          title: 'REFERENCE',
          items: [
            SidebarMenuItem(index: 4, icon: Icons.science_outlined, title: 'Lab Availability'),
            SidebarMenuItem(index: 5, icon: Icons.medication_outlined, title: 'Medicine Stock'),
          ],
        ),
      ],
    );
  }
}
