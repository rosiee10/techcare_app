import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/reusable_widgets/card_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/room_model.dart';
import '../providers/room_provider.dart';
import '../widgets/room_assignment/stat_card.dart';
import '../widgets/room_assignment/room_table.dart';
import '../widgets/room_assignment/add_room_dialog.dart';
import '../widgets/room_assignment/edit_room_dialog.dart';
import '../widgets/room_assignment/result_dialog.dart';

/// Room Assignment Page
/// Clean architecture using Provider pattern and reusable widgets
/// Implements OOP, DRY, and clean code principles
class RoomAssignmentPage extends StatelessWidget {
  const RoomAssignmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RoomProvider(),
      child: const _RoomAssignmentView(),
    );
  }
}

/// Main View Component - separates UI from state management
class _RoomAssignmentView extends StatelessWidget {
  const _RoomAssignmentView();

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StatsCardsRow(),
          const SizedBox(height: 24),
          Expanded(
            child: CardContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _TableHeaderWithSearch(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _RoomTableSection(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Page Header Component
class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Room / Station Assignment',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'OPD consultation rooms and their assigned doctors and services',
              style: TextStyle(
                fontSize: 14,
                color: theme.textSecondary,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showAddRoomDialog(context),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Room'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.buttonPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddRoomDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AddRoomDialog(
        onSave: (room) {
          final provider = context.read<RoomProvider>();
          provider.addRoom(room).then((success) {
            if (success && context.mounted) {
              _showSuccessDialog(context, room.name);
            }
          });
        },
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String roomName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text('Room "$roomName" has been added.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Horizontal Stats Cards Row Component
class _StatsCardsRow extends StatelessWidget {
  const _StatsCardsRow();

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    
    return Consumer<RoomProvider>(
      builder: (context, provider, _) {
        final stats = provider.stats;

        return Row(
          children: [
            Expanded(
              child: _StatsCard(
                icon: Icons.meeting_room,
                value: stats.totalRooms.toString(),
                label: 'Total Rooms',
                color: theme.info,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatsCard(
                icon: Icons.check_circle,
                value: stats.openRooms.toString(),
                label: 'Open',
                color: theme.success,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatsCard(
                icon: Icons.cancel,
                value: stats.closedRooms.toString(),
                label: 'Closed',
                color: theme.error,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatsCard(
                icon: Icons.medical_services,
                value: stats.totalServices.toString(),
                label: 'Services',
                color: theme.warning,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Individual Stats Card Component
class _StatsCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatsCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const Spacer(),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  color: theme.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: theme.textPrimary,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Table Header with Search Bar Component
class _TableHeaderWithSearch extends StatefulWidget {
  const _TableHeaderWithSearch();

  @override
  State<_TableHeaderWithSearch> createState() => _TableHeaderWithSearchState();
}

class _TableHeaderWithSearchState extends State<_TableHeaderWithSearch> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Consumer<RoomProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Room/Station Assignment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'OPD consultation rooms and their assigned doctors and services',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Room',
                      prefixIcon: Icon(Icons.search, color: theme.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.inputBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.inputBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.inputFocusBorder),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      provider.filterRooms(value);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => _showAddRoomDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.buttonPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Add room'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showAddRoomDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AddRoomDialog(
        onSave: (room) {
          final provider = context.read<RoomProvider>();
          provider.addRoom(room).then((success) {
            if (success && context.mounted) {
              showSuccessDialog(
                context,
                title: 'Room Added',
                message: 'Room "${room.name}" has been created successfully.',
              );
            }
          });
        },
      ),
    );
  }
}

/// Room Table Section using reusable RoomTable widget
class _RoomTableSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<RoomProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Text(
              'Error: ${provider.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        return RoomTable(
          rooms: provider.rooms,
          onEdit: (room) => _handleEdit(context, room),
          onToggleStatus: (room) => _handleToggleStatus(context, room),
          onDelete: (room) => _handleDelete(context, room),
        );
      },
    );
  }

  void _handleEdit(BuildContext context, Room room) {
    final provider = context.read<RoomProvider>();
    
    showDialog(
      context: context,
      builder: (dialogContext) => EditRoomDialog(
        room: room,
        onSave: (updatedRoom) {
          provider.updateRoom(updatedRoom).then((success) {
            if (success && context.mounted) {
              showSuccessDialog(
                context,
                title: 'Room Updated',
                message: 'Room "${updatedRoom.name}" has been updated successfully.',
              );
            }
          });
        },
      ),
    );
  }

  void _handleToggleStatus(BuildContext context, Room room) {
    final provider = context.read<RoomProvider>();
    provider.toggleRoomStatus(room.id);
  }

  void _handleDelete(BuildContext context, Room room) {
    // Get provider before showing dialog to avoid context issues
    final provider = context.read<RoomProvider>();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${room.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              print('[DEBUG] Calling deleteRoom for room: ${room.id}');
              provider.deleteRoom(room.id).then((success) {
                print('[DEBUG] Delete result: $success');
                if (success && context.mounted) {
                  showSuccessDialog(
                    context,
                    title: 'Room Deleted',
                    message: 'Room "${room.name}" has been deleted successfully.',
                  );
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
