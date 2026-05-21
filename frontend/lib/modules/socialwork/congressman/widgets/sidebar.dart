import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/base_sidebar.dart';

class CongressmanSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const CongressmanSidebar({
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
          title: 'ASSISTANCE',
          items: [
            SidebarMenuItem(index: 1, icon: Icons.request_page_outlined, title: 'Assistance Requests'),
            SidebarMenuItem(index: 2, icon: Icons.approval_outlined, title: 'Approvals'),
            SidebarMenuItem(index: 3, icon: Icons.local_atm_outlined, title: 'Financial Aid'),
          ],
        ),
        SidebarSection(
          title: 'RECORDS',
          items: [
            SidebarMenuItem(index: 4, icon: Icons.history_outlined, title: 'Transaction History'),
            SidebarMenuItem(index: 5, icon: Icons.assessment_outlined, title: 'Reports'),
          ],
        ),
      ],
    );
  }
}
