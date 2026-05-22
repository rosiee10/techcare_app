import 'package:flutter/material.dart';
import '../../../core/reusable_widgets/base_sidebar.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const AdminSidebar({
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
          title: 'USER MANAGEMENT',
          items: [
            SidebarMenuItem(index: 1, icon: Icons.people_outline, title: 'Users'),
            SidebarMenuItem(index: 2, icon: Icons.admin_panel_settings_outlined, title: 'Roles & Permissions'),
            SidebarMenuItem(index: 3, icon: Icons.group_add_outlined, title: 'Create User'),
          ],
        ),
        SidebarSection(
          title: 'COMMUNICATION',
          items: [
            SidebarMenuItem(index: 7, icon: Icons.message_outlined, title: 'Contact Messages'),
          ],
        ),
        SidebarSection(
          title: 'SYSTEM',
          items: [
            SidebarMenuItem(index: 4, icon: Icons.settings_outlined, title: 'System Settings'),
            SidebarMenuItem(index: 5, icon: Icons.analytics_outlined, title: 'Analytics'),
            SidebarMenuItem(index: 6, icon: Icons.history_outlined, title: 'Audit Logs'),
          ],
        ),
      ],
    );
  }
}
