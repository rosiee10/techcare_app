import 'package:flutter/material.dart';
import '../../../core/reusable_widgets/base_sidebar.dart';

class PatientSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const PatientSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final sections = const [
      SidebarSection(
        title: 'OVERVIEW',
        items: [
          SidebarMenuItem(index: 0, icon: Icons.dashboard_outlined, title: 'Dashboard'),
        ],
      ),
      SidebarSection(
        title: 'MY HEALTH',
        items: [
          SidebarMenuItem(index: 1, icon: Icons.folder_open_outlined, title: 'My Records'),
          SidebarMenuItem(index: 2, icon: Icons.calendar_month_outlined, title: 'Appointments'),
          SidebarMenuItem(index: 3, icon: Icons.biotech_outlined, title: 'Lab Results'),
          SidebarMenuItem(index: 4, icon: Icons.medication_outlined, title: 'Prescriptions'),
        ],
      ),
    ];

    return BaseSidebar(
      selectedIndex: selectedIndex,
      onItemSelected: onItemSelected,
      sections: sections,
      logoAssetPath: 'assets/logos/logo.png',
    );
  }
}
