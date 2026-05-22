import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/base_sidebar.dart';

class CsdClerkSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const CsdClerkSidebar({
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
          title: '',
          items: [
            SidebarMenuItem(index: 0, icon: Icons.dashboard_outlined, title: 'Dashboard'),
            SidebarMenuItem(index: 1, icon: Icons.inventory_2_outlined, title: 'Inventory'),
            SidebarMenuItem(index: 2, icon: Icons.shopping_cart_outlined, title: 'Inventory Carts'),
            SidebarMenuItem(index: 3, icon: Icons.description_outlined, title: 'Purchase Request'),
            SidebarMenuItem(index: 4, icon: Icons.restaurant_outlined, title: 'Kitchen'),
            SidebarMenuItem(index: 5, icon: Icons.trending_up, title: 'Forecasting'),
            SidebarMenuItem(index: 6, icon: Icons.bar_chart, title: 'Reports'),
          ],
        ),
      ],
    );
  }
}
