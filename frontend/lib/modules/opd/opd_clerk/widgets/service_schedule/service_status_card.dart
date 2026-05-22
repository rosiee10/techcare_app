import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../models/service_schedule_model.dart';

/// Service Status Card Widget
/// Displays a service with its today's status and hours
class ServiceStatusCard extends StatelessWidget {
  final ServiceScheduleModel service;
  final VoidCallback? onTap;

  const ServiceStatusCard({
    super.key,
    required this.service,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final statusColor = _getStatusColor(service.colorHex);
    final bgColor = statusColor.withOpacity(0.05);
    final borderColor = statusColor.withOpacity(0.3);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Service name and status row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    service.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                _StatusBadge(
                  isOpen: service.isOpenToday,
                  statusColor: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Hours or closed message
            Text(
              service.isOpenToday ? service.hours : 'Not available today',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: service.isOpenToday ? theme.textSecondary : statusColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.blue;
    }
  }
}

/// Status Badge Widget
class _StatusBadge extends StatelessWidget {
  final bool isOpen;
  final Color statusColor;

  const _StatusBadge({
    required this.isOpen,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? const Color(0xFF4CAF50).withOpacity(0.1) : statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isOpen ? 'Open' : 'Closed',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isOpen ? const Color(0xFF4CAF50) : statusColor,
        ),
      ),
    );
  }
}
