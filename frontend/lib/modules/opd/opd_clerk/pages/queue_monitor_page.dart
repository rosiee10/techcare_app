import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/card_container.dart';
import '../../../../core/reusable_widgets/section_header.dart';
import '../../../../core/theme/app_theme.dart';

class QueueMonitorPage extends StatefulWidget {
  const QueueMonitorPage({super.key});

  @override
  State<QueueMonitorPage> createState() => _QueueMonitorPageState();
}

class _QueueMonitorPageState extends State<QueueMonitorPage> {
  final List<Map<String, dynamic>> _queue = [
    {'id': 'Q-001', 'name': 'Juan Cruz', 'age': '45', 'sex': 'M', 'service': 'General', 'status': 'in_progress', 'room': '101', 'waitTime': '00:05'},
    {'id': 'Q-002', 'name': 'Maria Santos', 'age': '32', 'sex': 'F', 'service': 'Pediatric', 'status': 'waiting', 'room': '-', 'waitTime': '00:15'},
    {'id': 'Q-003', 'name': 'Pedro Reyes', 'age': '28', 'sex': 'M', 'service': 'General', 'status': 'waiting', 'room': '-', 'waitTime': '00:25'},
    {'id': 'Q-004', 'name': 'Ana Garcia', 'age': '56', 'sex': 'F', 'service': 'Follow-up', 'status': 'waiting', 'room': '-', 'waitTime': '00:35'},
    {'id': 'Q-005', 'name': 'Jose Lim', 'age': '41', 'sex': 'M', 'service': 'General', 'status': 'waiting', 'room': '-', 'waitTime': '00:45'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsRow(theme),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: CardContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'Current Queue'),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _buildQueueList(theme),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _buildNowServing(theme),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _buildQueueStats(theme),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(AppThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            theme,
            'Total Waiting',
            '4',
            Icons.people_outline,
            const Color(0xFFFF9800),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            theme,
            'In Progress',
            '1',
            Icons.play_circle_outline,
            const Color(0xFF2196F3),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            theme,
            'Avg Wait Time',
            '12 min',
            Icons.timer_outlined,
            const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            theme,
            'Completed',
            '12',
            Icons.check_circle_outline,
            const Color(0xFF9C27B0),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(AppThemeData theme, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQueueList(AppThemeData theme) {
    return ListView.builder(
      itemCount: _queue.length,
      itemBuilder: (context, index) {
        final item = _queue[index];
        final isFirst = index == 0;
        final statusColor = _getStatusColor(item['status']);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isFirst ? statusColor.withOpacity(0.05) : theme.cardBackground.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isFirst ? statusColor.withOpacity(0.3) : theme.cardBorder,
              width: isFirst ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isFirst ? statusColor : theme.buttonPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isFirst ? Colors.white : theme.buttonPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item['age']} ${item['sex']} • ${item['service']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item['status'].toString().toUpperCase().replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Room ${item['room']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(Icons.timer_outlined, size: 16, color: theme.textSecondary),
                  const SizedBox(height: 2),
                  Text(
                    item['waitTime'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNowServing(AppThemeData theme) {
    final current = _queue.firstWhere((q) => q['status'] == 'in_progress', orElse: () => _queue.first);

    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Now Serving'),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Center(
                    child: Text(
                      '1',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  current['name'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Room ${current['room']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Complete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueStats(AppThemeData theme) {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Queue by Service'),
          const SizedBox(height: 16),
          _buildServiceStat(theme, 'General Consultation', 8, const Color(0xFF2196F3)),
          const SizedBox(height: 12),
          _buildServiceStat(theme, 'Pediatric', 4, const Color(0xFFFF9800)),
          const SizedBox(height: 12),
          _buildServiceStat(theme, 'Follow-up', 3, const Color(0xFF4CAF50)),
          const SizedBox(height: 12),
          _buildServiceStat(theme, 'Lab Review', 2, const Color(0xFF9C27B0)),
        ],
      ),
    );
  }

  Widget _buildServiceStat(AppThemeData theme, String service, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            service,
            style: TextStyle(
              fontSize: 13,
              color: theme.textPrimary,
            ),
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'waiting':
        return const Color(0xFFFF9800);
      case 'in_progress':
        return const Color(0xFF2196F3);
      case 'completed':
        return const Color(0xFF4CAF50);
      default:
        return Colors.grey;
    }
  }
}
