import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../models/room_model.dart';

/// Reusable RoomTable Widget
/// Displays room data in a table format
/// Implements clean code with separation of concerns
class RoomTable extends StatelessWidget {
  final List<Room> rooms;
  final Function(Room room)? onEdit;
  final Function(Room room)? onToggleStatus;
  final Function(Room room)? onDelete;

  const RoomTable({
    super.key,
    required this.rooms,
    this.onEdit,
    this.onToggleStatus,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Column(
      children: [
        _TableHeader(theme: theme),
        Expanded(
          child: rooms.isEmpty
              ? _EmptyState(theme: theme)
              : ListView.builder(
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    return _RoomTableRow(
                      room: rooms[index],
                      isLast: index == rooms.length - 1,
                      onEdit: onEdit,
                      onToggleStatus: onToggleStatus,
                      onDelete: onDelete,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Table Header Component
class _TableHeader extends StatelessWidget {
  final AppThemeData theme;

  const _TableHeader({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Row(
        children: [
          _HeaderCell('CODE', flex: 2),
          _HeaderCell('ROOM NAME', flex: 4),
          _HeaderCell('FLOOR', flex: 2),
          _HeaderCell('SERVICE', flex: 2),
          _HeaderCell('QUEUE PREFIX', flex: 2),
          _HeaderCell('ASSIGNED DOCTOR', flex: 4),
          _HeaderCell('STATUS', flex: 2),
          _HeaderCell('ACTIONS', flex: 3),
        ],
      ),
    );
  }
}

/// Header Cell Component
class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;

  const _HeaderCell(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }
}

/// Room Table Row Component
class _RoomTableRow extends StatelessWidget {
  final Room room;
  final bool isLast;
  final Function(Room room)? onEdit;
  final Function(Room room)? onToggleStatus;
  final Function(Room room)? onDelete;

  const _RoomTableRow({
    required this.room,
    required this.isLast,
    this.onEdit,
    this.onToggleStatus,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          left: const BorderSide(color: Color(0xFFE5E7EB)),
          right: const BorderSide(color: Color(0xFFE5E7EB)),
          bottom: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        borderRadius: isLast 
            ? const BorderRadius.vertical(bottom: Radius.circular(8)) 
            : null,
      ),
      child: Row(
        children: [
          _DataCell(room.code, flex: 2, fontWeight: FontWeight.w500),
          _DataCell(room.name, flex: 4),
          _DataCell(room.floor, flex: 2, color: theme.textSecondary),
          _ServiceCell(room.service, flex: 2),
          _QueuePrefixCell(room.queuePrefix, flex: 2),
          _DataCell(room.doctor, flex: 4, color: theme.textSecondary),
          _StatusCell(room, flex: 2),
          _ActionsCell(
            room: room,
            flex: 3,
            onEdit: onEdit,
            onToggleStatus: onToggleStatus,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }
}

/// Data Cell Component
class _DataCell extends StatelessWidget {
  final String text;
  final int flex;
  final Color? color;
  final FontWeight? fontWeight;

  const _DataCell(
    this.text, {
    this.flex = 1,
    this.color,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: fontWeight ?? FontWeight.normal,
          color: color ?? theme.textPrimary,
        ),
      ),
    );
  }
}

/// Service Cell Component with color coding
class _ServiceCell extends StatelessWidget {
  final String service;
  final int flex;

  const _ServiceCell(this.service, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    final color = _getServiceColor(service);

    return Expanded(
      flex: flex,
      child: Text(
        service,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  static Color _getServiceColor(String service) {
    switch (service) {
      case 'FAMED':
        return const Color(0xFF2563EB);
      case 'PEDIA':
        return const Color(0xFF22C55E);
      case 'DENTAL':
        return const Color(0xFF06B6D4);
      case 'SURGERY':
        return const Color(0xFFA855F7);
      case 'OBGYN':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

/// Queue Prefix Cell Component
class _QueuePrefixCell extends StatelessWidget {
  final String prefix;
  final int flex;

  const _QueuePrefixCell(this.prefix, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        prefix,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF2563EB),
        ),
      ),
    );
  }
}

/// Status Cell Component
class _StatusCell extends StatelessWidget {
  final Room room;
  final int flex;

  const _StatusCell(this.room, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: room.isOpen 
              ? const Color(0xFFDCFCE7) 
              : const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          room.status,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: room.isOpen 
                ? const Color(0xFF22C55E) 
                : const Color(0xFFEF4444),
          ),
        ),
      ),
    );
  }
}

/// Actions Cell Component
class _ActionsCell extends StatelessWidget {
  final Room room;
  final int flex;
  final Function(Room room)? onEdit;
  final Function(Room room)? onToggleStatus;
  final Function(Room room)? onDelete;

  const _ActionsCell({
    required this.room,
    this.flex = 1,
    this.onEdit,
    this.onToggleStatus,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Row(
        children: [
          _IconActionButton(
            icon: Icons.edit,
            color: const Color(0xFF2563EB),
            tooltip: 'Edit',
            onPressed: () => onEdit?.call(room),
          ),
          const SizedBox(width: 8),
          _IconActionButton(
            icon: room.isOpen ? Icons.close : Icons.check,
            color: room.isOpen 
                ? const Color(0xFFEF4444) 
                : const Color(0xFF22C55E),
            tooltip: room.isOpen ? 'Close' : 'Open',
            onPressed: () => onToggleStatus?.call(room),
          ),
          const SizedBox(width: 8),
          _IconActionButton(
            icon: Icons.delete,
            color: Colors.grey,
            tooltip: 'Delete',
            onPressed: () => onDelete?.call(room),
          ),
        ],
      ),
    );
  }
}

/// Icon Action Button Component
class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onPressed;

  const _IconActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      color: color,
      tooltip: tooltip,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
    );
  }
}

/// Empty State Component
class _EmptyState extends StatelessWidget {
  final AppThemeData theme;

  const _EmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Image.asset(
              'assets/images/empty2.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.cardBackground,
                    borderRadius: BorderRadius.circular(60),
                    border: Border.all(color: theme.cardBorder, width: 2),
                  ),
                  child: Icon(
                    Icons.meeting_room_outlined,
                    size: 60,
                    color: theme.textSecondary,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No rooms configured',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Click "Add Room" to create your first room',
            style: TextStyle(
              fontSize: 14,
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
