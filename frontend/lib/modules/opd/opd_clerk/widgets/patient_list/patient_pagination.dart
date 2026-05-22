import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

class PatientPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int rowsPerPage;
  final Function(int) onPageChanged;
  final Function(int?) onRowsPerPageChanged;
  final int totalItems;

  const PatientPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.rowsPerPage,
    required this.onPageChanged,
    required this.onRowsPerPageChanged,
    required this.totalItems,
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
          Row(
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
          ),

          // Pagination info
          Text(
            '${(currentPage - 1) * rowsPerPage + 1}-${currentPage * rowsPerPage > totalItems ? totalItems : currentPage * rowsPerPage} of $totalItems',
            style: TextStyle(
              fontSize: 13,
              color: theme.textSecondary,
            ),
          ),

          // Page navigation
          Row(
            children: [
              IconButton(
                onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
                icon: Icon(Icons.chevron_left, color: currentPage > 1 ? theme.textPrimary : theme.textMuted),
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
                icon: Icon(Icons.chevron_right, color: currentPage < totalPages ? theme.textPrimary : theme.textMuted),
                splashRadius: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
