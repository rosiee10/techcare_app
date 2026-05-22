import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/base_sidebar.dart';

class KitchenStaffSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const KitchenStaffSidebar({
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
          title: 'MEAL MANAGEMENT',
          items: [
            SidebarMenuItem(index: 1, icon: Icons.restaurant_menu_outlined, title: 'Meal Orders'),
            SidebarMenuItem(index: 2, icon: Icons.local_dining_outlined, title: 'Diet Plans'),
            SidebarMenuItem(index: 3, icon: Icons.delivery_dining_outlined, title: 'Meal Delivery'),
          ],
        ),
        SidebarSection(
          title: 'INVENTORY',
          items: [
            SidebarMenuItem(index: 4, icon: Icons.inventory_2_outlined, title: 'Food Inventory'),
            SidebarMenuItem(index: 5, icon: Icons.assessment_outlined, title: 'Reports'),
          ],
        ),
      ],
    );
  }
}
