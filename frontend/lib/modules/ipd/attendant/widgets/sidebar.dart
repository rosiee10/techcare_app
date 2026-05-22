import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/base_sidebar.dart';

class IpdNurseSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const IpdNurseSidebar({
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
            SidebarMenuItem(index: 1, icon: Icons.hotel_outlined, title: 'Patient Care'),
            SidebarMenuItem(index: 2, icon: Icons.medication_outlined, title: 'Medication Admin'),
            SidebarMenuItem(index: 3, icon: Icons.monitor_heart_outlined, title: 'Vital Signs'),
          ],
        ),
        SidebarSection(
          title: 'RECORDS',
          items: [
            SidebarMenuItem(index: 4, icon: Icons.note_outlined, title: 'Nursing Notes'),
            SidebarMenuItem(index: 5, icon: Icons.assessment_outlined, title: 'Reports'),
          ],
        ),
      ],
    );
  }
}
