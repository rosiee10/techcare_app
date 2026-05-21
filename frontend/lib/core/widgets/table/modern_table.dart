import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Modern table wrapper with consistent styling and enhanced design
class ModernTable extends StatelessWidget {
  final List<TableColumn> columns;
  final List<Widget> rows;
  final Widget? pagination;
  final double borderRadius;
  final bool showShadow;

  const ModernTable({
    super.key,
    required this.columns,
    required this.rows,
    this.pagination,
    this.borderRadius = 12,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: theme.cardBorder, width: 1),
        boxShadow: showShadow ? [
          BoxShadow(
            color: theme.cardShadow.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Column(
          children: [
            // Table Header
            ModernTableHeader(columns: columns),
            
            // Table Rows
            Expanded(
              child: rows.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.builder(
                      itemCount: rows.length,
                      itemBuilder: (context, index) => rows[index],
                    ),
            ),
            
            // Pagination (if provided)
            if (pagination != null) pagination!,
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: theme.textMuted),
          const SizedBox(height: 12),
          Text(
            'No data available',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Table column definition
class TableColumn {
  final String label;
  final int flex;
  final TextAlign alignment;

  const TableColumn({
    required this.label,
    this.flex = 1,
    this.alignment = TextAlign.left,
  });
}

/// Modern table header with enhanced styling
class ModernTableHeader extends StatelessWidget {
  final List<TableColumn> columns;

  const ModernTableHeader({
    super.key,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: theme.pageBackground,
        border: Border(
          bottom: BorderSide(color: theme.cardBorder, width: 1),
        ),
      ),
      child: Row(
        children: columns.map((column) {
          return Expanded(
            flex: column.flex,
            child: Text(
              column.label,
              textAlign: column.alignment,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: theme.textMuted,
                letterSpacing: 0.3,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Modern table row with enhanced hover effects
class ModernTableRow extends StatefulWidget {
  final List<Widget> cells;
  final VoidCallback? onTap;
  final bool isHoverable;

  const ModernTableRow({
    super.key,
    required this.cells,
    this.onTap,
    this.isHoverable = true,
  });

  @override
  State<ModernTableRow> createState() => _ModernTableRowState();
}

class _ModernTableRowState extends State<ModernTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: _isHovered && widget.isHoverable 
                ? theme.pageBackground.withOpacity(0.5)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(color: theme.cardBorder.withOpacity(0.3), width: 1),
            ),
          ),
          child: Row(
            children: widget.cells,
          ),
        ),
      ),
    );
  }
}

/// Table cell wrapper
class ModernTableCell extends StatelessWidget {
  final Widget child;
  final int flex;
  final TextAlign alignment;

  const ModernTableCell({
    super.key,
    required this.child,
    this.flex = 1,
    this.alignment = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: _getAlignment(),
        child: child,
      ),
    );
  }

  AlignmentGeometry _getAlignment() {
    switch (alignment) {
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }
}
