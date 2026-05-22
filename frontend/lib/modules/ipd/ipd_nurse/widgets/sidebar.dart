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
          title: 'MAIN MENU',
          items: [
            SidebarMenuItem(index: 0, icon: Icons.monitor_heart_outlined, title: 'Dashboard'),
            SidebarMenuItem(index: 1, icon: Icons.people_outline, title: 'Patient Monitoring'),
            SidebarMenuItem(index: 2, icon: Icons.inventory_2_outlined, title: 'Inventory'),
            SidebarMenuItem(index: 3, icon: Icons.description_outlined, title: 'Request'),
          ],
        ),
      ],
    );
  }
}
