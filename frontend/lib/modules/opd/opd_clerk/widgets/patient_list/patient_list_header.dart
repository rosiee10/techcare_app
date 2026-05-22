import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

class PatientListHeader extends StatelessWidget {
  final int totalPatients;
  final int activePatients;
  final VoidCallback onRegisterPatient;
  final TextEditingController? searchController;
  final String selectedStatus;
  final ValueChanged<String?>? onStatusChanged;
  final ValueChanged<String>? onSearchChanged;

  const PatientListHeader({
    super.key,
    required this.totalPatients,
    required this.activePatients,
    required this.onRegisterPatient,
    this.searchController,
    this.selectedStatus = 'All Status',
    this.onStatusChanged,
    this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 1200;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: theme.cardShadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isSmallScreen
          ? _buildResponsiveLayout(theme)
          : _buildDesktopLayout(theme),
    );
  }

  Widget _buildDesktopLayout(AppThemeData theme) {
    return Row(
      children: [
        // Left: Title and Description
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PATIENT LIST',
              style: theme.titleStyle.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              'All registered patients in the hospital registry',
              style: TextStyle(
                fontSize: 13,
                color: theme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(width: 48),
        // Center: Search Bar and Filter (Expanded)
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Search Bar
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.pageBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.cardBorder),
                    ),
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      style: TextStyle(color: theme.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search bar',
                        hintStyle: TextStyle(color: theme.textMuted, fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: theme.textMuted, size: 18),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Status Filter
              Container(
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
                    isExpanded: false,
                    icon: Icon(Icons.arrow_drop_down, color: theme.textSecondary, size: 18),
                    dropdownColor: theme.cardBackground,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    items: ['All Status', 'Active', 'Inactive'].map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(
                          item,
                          style: TextStyle(color: theme.textPrimary, fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: onStatusChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Right: Register Patient Button
        ElevatedButton.icon(
          onPressed: onRegisterPatient,
          icon: const Icon(Icons.person_add, size: 16),
          label: const Text('Register Patient'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.buttonPrimary,
            foregroundColor: theme.buttonPrimaryText,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveLayout(AppThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and Description
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PATIENT LIST',
                  style: theme.titleStyle.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  'All registered patients in the hospital registry   ',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textSecondary,
                  ),
                ),
               
              ],
            ),
            // Register Button (Top Right on Mobile)
            ElevatedButton.icon(
              onPressed: onRegisterPatient,
              icon: const Icon(Icons.person_add, size: 14),
              label: const Text('Register'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.buttonPrimary,
                foregroundColor: theme.buttonPrimaryText,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Search Bar
        SizedBox(
          height: 44,
          width: 300,
          child: Container(
            decoration: BoxDecoration(
              color: theme.pageBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.cardBorder),
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: TextStyle(color: theme.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search bar',
                hintStyle: TextStyle(color: theme.textMuted, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: theme.textMuted, size: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Status Filter
        Container(
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
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: theme.textSecondary, size: 18),
              dropdownColor: theme.cardBackground,
              style: TextStyle(
                fontSize: 13,
                color: theme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              items: ['All Status', 'Active', 'Inactive'].map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(color: theme.textPrimary, fontSize: 13),
                  ),
                );
              }).toList(),
              onChanged: onStatusChanged,
            ),
          ),
        ),
      ],
    );
  }
}
