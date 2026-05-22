import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/base_sidebar.dart';

class BillingStaffSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const BillingStaffSidebar({
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
            SidebarMenuItem(index: 2, icon: Icons.assignment_outlined, title: 'Claims Processing'),
            SidebarMenuItem(index: 3, icon: Icons.account_balance_outlined, title: 'Accounts'),
          ],
        ),
        SidebarSection(
          title: 'REPORTS',
          items: [
            SidebarMenuItem(index: 4, icon: Icons.assessment_outlined, title: 'Financial Reports'),
          ],
        ),
      ],
    );
  }
}
