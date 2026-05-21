import 'package:flutter/material.dart';
import 'modern_table.dart';
import 'table_widgets.dart';

/// Helper class for quickly building tables
/// Simplifies table creation with builder pattern
class TableBuilder {
  final List<TableColumn> columns;
  final List<Map<String, dynamic>> data;
  final Widget Function(Map<String, dynamic>, int)? rowBuilder;
  final Widget Function(dynamic)? cellBuilder;
  final Widget? pagination;
  final double borderRadius;
  final bool showShadow;

  TableBuilder({
    required this.columns,
    required this.data,
    this.rowBuilder,
    this.cellBuilder,
    this.pagination,
    this.borderRadius = 12,
    this.showShadow = true,
  });

  /// Build the table with custom row builder
  ModernTable build() {
    return ModernTable(
      columns: columns,
      rows: data.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;

        if (rowBuilder != null) {
          return rowBuilder!(item, index);
        }

        // Default row builder
        return ModernTableRow(
          cells: columns.map((column) {
            final value = item[column.label.toLowerCase()] ?? '';
            return ModernTableCell(
              flex: column.flex,
              child: cellBuilder?.call(value) ?? Text(value.toString()),
            );
          }).toList(),
        );
      }).toList(),
      pagination: pagination,
      borderRadius: borderRadius,
      showShadow: showShadow,
    );
  }
}

/// Quick table creation helper
class SimpleTable extends StatelessWidget {
  final List<TableColumn> columns;
  final List<ModernTableRow> rows;
  final Widget? pagination;

  const SimpleTable({
    super.key,
    required this.columns,
    required this.rows,
    this.pagination,
  });

  @override
  Widget build(BuildContext context) {
    return ModernTable(
      columns: columns,
      rows: rows,
      pagination: pagination,
    );
  }
}

/// Table row builder helper
class TableRowBuilder {
  static ModernTableRow simple({
    required List<String> cells,
    VoidCallback? onTap,
  }) {
    return ModernTableRow(
      cells: cells
          .map((cell) => ModernTableCell(child: Text(cell)))
          .toList(),
      onTap: onTap,
    );
  }

  static ModernTableRow withAvatar({
    required String initials,
    required String primaryText,
    required String secondaryText,
    required List<Widget> actions,
    VoidCallback? onTap,
  }) {
    return ModernTableRow(
      cells: [
        ModernTableCell(
          child: Row(
            children: [
              TableAvatar(initials: initials),
              const SizedBox(width: 12),
              Expanded(
                child: TableTextCell(
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                ),
              ),
            ],
          ),
        ),
        ModernTableCell(
          child: Row(children: actions),
        ),
      ],
      onTap: onTap,
    );
  }

  static ModernTableRow withStatus({
    required String id,
    required String name,
    required String status,
    required List<Widget> actions,
    VoidCallback? onTap,
  }) {
    return ModernTableRow(
      cells: [
        ModernTableCell(child: Text(id)),
        ModernTableCell(child: Text(name)),
        ModernTableCell(child: StatusBadge(status: status)),
        ModernTableCell(child: Row(children: actions)),
      ],
      onTap: onTap,
    );
  }
}

/// Table cell builder helper
class TableCellBuilder {
  static Widget text(String value, {TextStyle? style}) {
    return Text(value, style: style);
  }

  static Widget badge(String status, {bool showDot = true}) {
    return StatusBadge(status: status, showDot: showDot);
  }

  static Widget avatar(String initials, {double size = 36}) {
    return TableAvatar(initials: initials, size: size);
  }

  static Widget idBadge(String id, {String? subtitle}) {
    return TableIdBadge(id: id, subtitle: subtitle);
  }

  static Widget textCell(String primary, {String? secondary}) {
    return TableTextCell(
      primaryText: primary,
      secondaryText: secondary,
    );
  }

  static Widget actionButton(
    IconData icon,
    String label, {
    required VoidCallback onPressed,
    Color? color,
  }) {
    return TableActionButton(
      icon: icon,
      label: label,
      onPressed: onPressed,
      color: color,
    );
  }

  static Widget iconButton(
    IconData icon, {
    required VoidCallback onPressed,
    Color? color,
    String? tooltip,
  }) {
    return TableIconButton(
      icon: icon,
      onPressed: onPressed,
      color: color,
      tooltip: tooltip,
    );
  }
}
