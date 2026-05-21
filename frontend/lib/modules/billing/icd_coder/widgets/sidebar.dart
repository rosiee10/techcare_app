import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/base_sidebar.dart';

class IcdCoderSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const IcdCoderSidebar({
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
          title: 'CODING',
          items: [
            SidebarMenuItem(index: 1, icon: Icons.queue_outlined, title: 'Coding Queue'),
            SidebarMenuItem(index: 2, icon: Icons.search_outlined, title: 'ICD-10 Lookup'),
            SidebarMenuItem(index: 3, icon: Icons.code_outlined, title: 'Diagnosis Codes'),
          ],
        ),
        SidebarSection(
          title: 'REPORTS',
          items: [
            SidebarMenuItem(index: 4, icon: Icons.assessment_outlined, title: 'Coding Reports'),
          ],
        ),
      ],
    );
  }
}
