import 'package:flutter/material.dart';
import '../../../core/reusable_widgets/base_sidebar.dart';

class ChiefNurseSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const ChiefNurseSidebar({
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
          title: 'PHARMACY',
          items: [
            SidebarMenuItem(index: 1, icon: Icons.inventory_2_outlined, title: 'Inventory'),
            SidebarMenuItem(index: 2, icon: Icons.request_page_outlined, title: 'Purchase Request'),
          ],
        ),
        SidebarSection(
          title: 'KITCHEN',
          items: [
            SidebarMenuItem(index: 3, icon: Icons.schedule_outlined, title: 'Staff Schedule'),
            SidebarMenuItem(index: 4, icon: Icons.shopping_cart_outlined, title: 'Purchase Request'),
          ],
        ),
      ],
    );
  }
}
