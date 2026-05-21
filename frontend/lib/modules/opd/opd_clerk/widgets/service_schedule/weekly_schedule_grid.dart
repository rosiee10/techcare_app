import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../models/service_schedule_model.dart';

/// Weekly Schedule Grid Widget
/// Displays services in a table with weekly availability checkboxes
class WeeklyScheduleGrid extends StatelessWidget {
  final List<ServiceScheduleModel> services;
  final int todayIndex; // 0=MON, 5=SAT
  final Function(String serviceId, int dayIndex)? onDayToggle;
  final Function(String serviceId)? onEdit;
  final Function(String serviceId)? onDelete;

  const WeeklyScheduleGrid({
    super.key,
    required this.services,
    this.todayIndex = 5,
    this.onDayToggle,
    this.onEdit,
    this.onDelete,
  });

  static const List<String> _dayHeaders = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.cardBorder),
      ),
      child: Column(
        children: [
          // Header row
          _buildHeaderRow(theme),
          // Divider
          Divider(color: theme.cardBorder, height: 1),
          // Service rows
          ...services.asMap().entries.map((entry) {
            final index = entry.key;
            final service = entry.value;
            return _buildServiceRow(theme, service, index == services.length - 1, index);
          }),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      decoration: BoxDecoration(
        color: theme.pageBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          // Service column
          _HeaderCell(
            text: 'SERVICE',
            width: 100,
            theme: theme,
          ),
          // Day columns with minimal spacing
          ..._dayHeaders.asMap().entries.map((entry) {
            final index = entry.key;
            final day = entry.value;
            final isToday = index == todayIndex;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: _HeaderCell(
                text: day,
                width: 125,
                theme: theme,
                isToday: isToday,
                center: true,
              ),
            );
          }),
          // Action column
          _HeaderCell(
            text: 'ACTION',
            width: 100,
            theme: theme,
            center: true,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceRow(AppThemeData theme, ServiceScheduleModel service, bool isLast, int rowIndex) {
    final color = _getColor(service.colorHex);
    final isEven = rowIndex % 2 == 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      decoration: BoxDecoration(
        color: isEven ? Colors.transparent : theme.pageBackground.withOpacity(0.5),
        border: Border(
          top: BorderSide(color: theme.cardBorder.withOpacity(0.5), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Service name
          SizedBox(
            width: 100,
            child: Text(
              service.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          // Day columns with compact time display
          ..._dayHeaders.asMap().entries.map((entry) {
            final dayIndex = entry.key;
            final dayName = entry.value;
            final isToday = dayIndex == todayIndex;
            // For today's column, use isOpenToday (active_today from backend)
            // For other days, use weeklySchedule (scheduled days)
            final isOpen = isToday ? service.isOpenToday : service.weeklySchedule[dayIndex];
            final hoursText = _getHoursForDay(service, dayIndex);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _DayCell(
                dayName: dayName,
                hoursText: hoursText,
                isOpen: isOpen,
                isToday: isToday,
                color: color,
                width: 120,
                onTap: onDayToggle != null
                    ? () => onDayToggle!(service.id, dayIndex)
                    : null,
              ),
            );
          }),
          // Action buttons - edit and delete icons
          SizedBox(
            width: 100,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Edit icon button
                  IconButton(
                    onPressed: onEdit != null ? () => onEdit!(service.id) : null,
                    icon: Icon(
                      Icons.edit,
                      size: 18,
                      color: theme.buttonPrimary,
                    ),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    tooltip: 'Edit Schedule',
                  ),
                  const SizedBox(width: 4),
                  // Delete icon button
                  IconButton(
                    onPressed: onDelete != null ? () => onDelete!(service.id) : null,
                    icon: const Icon(
                      Icons.delete,
                      size: 18,
                      color: Colors.red,
                    ),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    tooltip: 'Delete Service',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get hours text for a specific day - returns full format like "7:00AM - 5:00PM"
  String _getHoursForDay(ServiceScheduleModel service, int dayIndex) {
    if (dayIndex < 0 || dayIndex >= 6) return '';

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final day = days[dayIndex];

    // Check if day is open
    if (!service.weeklySchedule[dayIndex]) return 'Closed';

    // Get hours for this day
    final dayHours = service.dailyHours[day];
    if (dayHours != null && dayHours.formatted.isNotEmpty) {
      // Remove spaces in AM/PM for compact display: "7:00 AM - 5:00 PM" -> "7:00AM-5:00PM"
      return dayHours.formatted.replaceAll(' ', '');
    }

    // Fallback to service.hours
    if (service.hours.isNotEmpty) {
      return service.hours.replaceAll(' ', '');
    }

    return '';
  }

  Color _getColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.blue;
    }
  }
}

/// Header Cell Widget
class _HeaderCell extends StatelessWidget {
  final String text;
  final double width;
  final AppThemeData theme;
  final bool isToday;
  final bool center;

  const _HeaderCell({
    required this.text,
    required this.width,
    required this.theme,
    this.isToday = false,
    this.center = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: (center || width == double.infinity)
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          if (isToday)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.buttonPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'TODAY',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: theme.buttonPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Day Cell Widget - Shows hours and status for a day
class _DayCell extends StatelessWidget {
  final String dayName;
  final String hoursText;
  final bool isOpen;
  final bool isToday;
  final Color color;
  final double width;
  final VoidCallback? onTap;

  const _DayCell({
    required this.dayName,
    required this.hoursText,
    required this.isOpen,
    required this.color,
    this.isToday = false,
    this.width = 75,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: isOpen ? color.withOpacity(0.1) : theme.pageBackground.withOpacity(0.5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isToday ? color : (isOpen ? color.withOpacity(0.3) : theme.cardBorder),
            width: isToday ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hours text - ultra compact display
            if (hoursText != 'Closed' && hoursText.contains('-'))
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hoursText.split('-')[0],
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isOpen ? color : theme.textSecondary.withOpacity(0.4),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'to',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w500,
                      color: isOpen ? color.withOpacity(0.6) : theme.textSecondary.withOpacity(0.3),
                    ),
                  ),
                  Text(
                    hoursText.split('-')[1],
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isOpen ? color : theme.textSecondary.withOpacity(0.4),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            else
              Text(
                hoursText,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: isOpen ? color : theme.textSecondary.withOpacity(0.4),
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 3),
            // Checkmark indicator
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: isOpen ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: isOpen ? color : theme.cardBorder,
                  width: 1,
                ),
              ),
              child: isOpen
                  ? const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
