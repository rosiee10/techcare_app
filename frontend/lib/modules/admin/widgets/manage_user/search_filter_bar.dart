import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../provider/manage_users_provider.dart';

/// Reusable search and filter bar widget for user management
class SearchFilterBar extends StatelessWidget {
  final ManageUsersProvider provider;

  const SearchFilterBar({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 20),
      margin: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.cardBorder),
      ),
      child: Row(
        children: [
          // Role Filter
          _buildFilterDropdown(
            value: provider.selectedRole,
            items: ['All Roles', 'ADMIN', 'DOCTOR', 'NURSE', 'OPD_CLERK', 'PHARMACY'],
            onChanged: (value) => provider.updateRoleFilter(value!),
            theme: theme,
          ),
          const SizedBox(width: 12),
          
          // Status Filter
          _buildFilterDropdown(
            value: provider.selectedStatus,
            items: ['All Status', 'Active', 'Inactive'],
            onChanged: (value) => provider.updateStatusFilter(value!),
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required AppThemeData theme,
  }) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.inputBackground,
        border: Border.all(color: theme.inputBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButton<String>(
        value: value,
        dropdownColor: theme.cardBackground,
        style: TextStyle(color: theme.textPrimary, fontSize: 13),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item, style: TextStyle(fontSize: 13, color: theme.textPrimary)),
          );
        }).toList(),
        onChanged: onChanged,
        underline: const SizedBox(),
        icon: Icon(Icons.arrow_drop_down, size: 20, color: theme.textSecondary),
      ),
    );
  }
}
