import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/base_sidebar.dart';

class CashierSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const CashierSidebar({
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
          title: 'BILLING',
          items: [
            SidebarMenuItem(index: 1, icon: Icons.receipt_outlined, title: 'Billing Queue'),
            SidebarMenuItem(index: 2, icon: Icons.payment_outlined, title: 'Payment Processing'),
            SidebarMenuItem(index: 3, icon: Icons.receipt_long_outlined, title: 'Receipts'),
          ],
        ),
        SidebarSection(
          title: 'REPORTS',
          items: [
            SidebarMenuItem(index: 4, icon: Icons.assessment_outlined, title: 'Daily Reports'),
            SidebarMenuItem(index: 5, icon: Icons.history_outlined, title: 'Transaction History'),
          ],
        ),
      ],
    );
  }
}
