import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/base_sidebar.dart';

class IpdDoctorSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const IpdDoctorSidebar({
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
            SidebarMenuItem(index: 1, icon: Icons.hotel_outlined, title: 'Patient Rounds'),
            SidebarMenuItem(index: 2, icon: Icons.people_outline, title: 'Admission List'),
            SidebarMenuItem(index: 3, icon: Icons.medication_outlined, title: 'Orders'),
          ],
        ),
        SidebarSection(
          title: 'MANAGEMENT',
          items: [
            SidebarMenuItem(index: 4, icon: Icons.exit_to_app_outlined, title: 'Discharge Planning'),
            SidebarMenuItem(index: 5, icon: Icons.assessment_outlined, title: 'Reports'),
          ],
        ),
      ],
    );
  }
}
