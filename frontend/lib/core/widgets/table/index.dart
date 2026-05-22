/// Generic Table Design System
/// 
/// A comprehensive, reusable table library for all modules.
/// Use this for any list/table needs across the application.
/// 
/// Quick Start:
/// ```dart
/// import 'package:frontend/core/widgets/table/index.dart';
/// 
/// ModernTable(
///   columns: [
///     TableColumn(label: 'ID', flex: 1),
///     TableColumn(label: 'NAME', flex: 3),
///     TableColumn(label: 'STATUS', flex: 1),
///   ],
///   rows: items.map((item) => ModernTableRow(
///     cells: [
///       ModernTableCell(child: Text(item.id)),
///       ModernTableCell(child: Text(item.name)),
///       ModernTableCell(child: StatusBadge(status: item.status)),
///     ],
///   )).toList(),
/// )
/// ```

export 'modern_table.dart';
export 'table_pagination.dart';
export 'table_widgets.dart';
export 'table_builder.dart';
