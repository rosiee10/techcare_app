import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/base_sidebar.dart';

class XrayStaffSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const XrayStaffSidebar({
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
          title: 'IMAGING',
          items: [
            SidebarMenuItem(index: 1, icon: Icons.camera_alt_outlined, title: 'Imaging Requests'),
            SidebarMenuItem(index: 2, icon: Icons.upload_file_outlined, title: 'Image Upload'),
            SidebarMenuItem(index: 3, icon: Icons.medical_information_outlined, title: 'Reports'),
          ],
        ),
        SidebarSection(
          title: 'EQUIPMENT',
          items: [
            SidebarMenuItem(index: 4, icon: Icons.settings_outlined, title: 'Equipment Status'),
          ],
        ),
      ],
    );
  }
}
