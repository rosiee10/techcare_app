import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dashboard statistics model
class DashboardStats {
  final int totalVisits;
  final int queueWaiting;
  final int completed;
  final int activeRooms;

  DashboardStats({
    required this.totalVisits,
    required this.queueWaiting,
    required this.completed,
    required this.activeRooms,
  });
}

/// Queue item model
class QueueItem {
  final String queueNumber;
  final String patientName;
  final String room;
  final String status;
  final String statusColor;

  QueueItem({
    required this.queueNumber,
    required this.patientName,
    required this.room,
    required this.status,
    required this.statusColor,
  });
}

/// Dashboard provider for managing state
class DashboardNotifier extends StateNotifier<DashboardStats> {
  DashboardNotifier()
      : super(
          DashboardStats(
            totalVisits: 24,
            queueWaiting: 8,
            completed: 12,
            activeRooms: 5,
          ),
        );

  void updateStats({
    int? totalVisits,
    int? queueWaiting,
    int? completed,
    int? activeRooms,
  }) {
    state = DashboardStats(
      totalVisits: totalVisits ?? state.totalVisits,
      queueWaiting: queueWaiting ?? state.queueWaiting,
      completed: completed ?? state.completed,
      activeRooms: activeRooms ?? state.activeRooms,
    );
  }

  void refreshStats() {
    // TODO: Fetch from API
    updateStats();
  }
}

/// Dashboard stats provider
final dashboardStatsProvider =
    StateNotifierProvider<DashboardNotifier, DashboardStats>(
  (ref) => DashboardNotifier(),
);

/// Queue items provider
final queueItemsProvider = StateProvider<List<QueueItem>>((ref) {
  return [
    QueueItem(
      queueNumber: 'Q-001',
      patientName: 'Juan Cruz',
      room: 'Room 101',
      status: 'In Progress',
      statusColor: '0xFF2196F3',
    ),
    QueueItem(
      queueNumber: 'Q-002',
      patientName: 'Maria Santos',
      room: 'Room 102',
      status: 'Waiting',
      statusColor: '0xFFFF9800',
    ),
    QueueItem(
      queueNumber: 'Q-003',
      patientName: 'Pedro Reyes',
      room: 'Room 103',
      status: 'Waiting',
      statusColor: '0xFFFF9800',
    ),
  ];
});
