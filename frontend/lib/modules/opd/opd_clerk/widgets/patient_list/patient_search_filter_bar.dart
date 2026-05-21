import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

class PatientSearchFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String selectedStatus;
  final Function(String) onSearchChanged;
  final Function(String?) onStatusChanged;

  const PatientSearchFilterBar({
    super.key,
    required this.searchController,
    required this.selectedStatus,
    required this.onSearchChanged,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Row(
      children: [
        // Search Bar
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: theme.pageBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.cardBorder),
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: TextStyle(color: theme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by hospital ID, name, or contact...',
                hintStyle: TextStyle(color: theme.textMuted),
                prefixIcon: Icon(Icons.search, color: theme.textMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        
        // Status Filter
        _buildStatusDropdown(theme),
      ],
    );
  }

  Widget _buildStatusDropdown(AppThemeData theme) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.pageBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedStatus,
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down, color: theme.textMuted),
          style: TextStyle(color: theme.textPrimary, fontSize: 14),
          dropdownColor: theme.cardBackground,
          items: ['All Status', 'Outpatient', 'Inpatient', 'Emergency', 'Discharged']
              .map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  ))
              .toList(),
          onChanged: onStatusChanged,
        ),
      ),
    );
  }
}
