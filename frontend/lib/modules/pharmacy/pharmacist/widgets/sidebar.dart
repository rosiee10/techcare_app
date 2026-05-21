import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/base_sidebar.dart';

class PharmacistSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const PharmacistSidebar({
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
            SidebarMenuItem(index: 3, icon: Icons.description_outlined, title: 'IPD Dispensing Sheet'),
            SidebarMenuItem(index: 4, icon: Icons.attach_money, title: 'IPD Pharmacy Billing'),
            SidebarMenuItem(index: 5, icon: Icons.receipt_long_outlined, title: 'OPD Charge Slip'),
            SidebarMenuItem(index: 6, icon: Icons.request_page_outlined, title: 'Purchase Request'),
            SidebarMenuItem(index: 7, icon: Icons.trending_up, title: 'Forecasting'),
            SidebarMenuItem(index: 8, icon: Icons.bar_chart, title: 'Reports'),
          ],
        ),
      ],
    );
  }
}
