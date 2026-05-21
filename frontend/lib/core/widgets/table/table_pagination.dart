import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Modern table pagination component
class ModernTablePagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int rowsPerPage;
  final int totalItems;
  final Function(int) onPageChanged;
  final Function(int?) onRowsPerPageChanged;

  const ModernTablePagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.rowsPerPage,
    required this.totalItems,
    required this.onPageChanged,
    required this.onRowsPerPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border(
          top: BorderSide(color: theme.cardBorder),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Rows per page dropdown
          _buildRowsPerPageSelector(theme),
          
          // Pagination info
          _buildPaginationInfo(theme),
          
          // Page navigation
          _buildPageNavigation(theme),
        ],
      ),
    );
  }

  Widget _buildRowsPerPageSelector(AppThemeData theme) {
    return Row(
      children: [
        Text(
          'Rows per page:',
          style: TextStyle(
            fontSize: 13,
            color: theme.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: theme.cardBorder),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: rowsPerPage,
              isDense: true,
              icon: Icon(Icons.keyboard_arrow_down, size: 16, color: theme.textMuted),
              style: TextStyle(color: theme.textPrimary, fontSize: 13),
              dropdownColor: theme.cardBackground,
              items: [10, 20, 50, 100]
                  .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text('$value'),
                      ))
                  .toList(),
              onChanged: onRowsPerPageChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationInfo(AppThemeData theme) {
    final startItem = (currentPage - 1) * rowsPerPage + 1;
    final endItem = currentPage * rowsPerPage > totalItems 
        ? totalItems 
        : currentPage * rowsPerPage;
    
    return Text(
      '$startItem-$endItem of $totalItems',
      style: TextStyle(
        fontSize: 13,
        color: theme.textSecondary,
      ),
    );
  }

  Widget _buildPageNavigation(AppThemeData theme) {
    return Row(
      children: [
        IconButton(
          onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
          icon: Icon(
            Icons.chevron_left,
            color: currentPage > 1 ? theme.textPrimary : theme.textMuted,
          ),
          splashRadius: 20,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: theme.buttonPrimary,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$currentPage',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        IconButton(
          onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
          icon: Icon(
            Icons.chevron_right,
            color: currentPage < totalPages ? theme.textPrimary : theme.textMuted,
          ),
          splashRadius: 20,
        ),
      ],
    );
  }
}
