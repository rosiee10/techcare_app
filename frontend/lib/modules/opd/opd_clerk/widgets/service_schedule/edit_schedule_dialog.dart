import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../models/service_schedule_model.dart';

/// Edit Schedule Dialog with per-day time pickers
/// Allows setting different hours for each day of the week
class EditScheduleDialog extends StatefulWidget {
  final ServiceScheduleModel service;
  final Function(Map<String, DailyHours?>, List<bool>, String)? onSave;

  const EditScheduleDialog({
    super.key,
    required this.service,
    this.onSave,
  });

  @override
  State<EditScheduleDialog> createState() => _EditScheduleDialogState();
}

class _EditScheduleDialogState extends State<EditScheduleDialog> {
  late Map<String, _DaySchedule> _schedules;
  late String _selectedColor;

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final List<String> _dayLabels = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  final List<Map<String, dynamic>> _colorOptions = [
    {'name': 'Blue', 'color': const Color(0xFF2563EB), 'hex': '#2563EB'},
    {'name': 'Green', 'color': const Color(0xFF22C55E), 'hex': '#22C55E'},
    {'name': 'Purple', 'color': const Color(0xFFA855F7), 'hex': '#A855F7'},
    {'name': 'Pink', 'color': const Color(0xFFEC4899), 'hex': '#EC4899'},
    {'name': 'Cyan', 'color': const Color(0xFF06B6D4), 'hex': '#06B6D4'},
    {'name': 'Orange', 'color': const Color(0xFFF97316), 'hex': '#F97316'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeSchedules();
    _selectedColor = widget.service.colorHex;
  }

  void _initializeSchedules() {
    final service = widget.service;
    _schedules = {};

    // Initialize schedules from service data
    for (int i = 0; i < _days.length; i++) {
      final day = _days[i];
      final dayHours = service.dailyHours[day];
      final isOpen = service.weeklySchedule[i];

      if (dayHours != null) {
        _schedules[day] = _DaySchedule(
          isOpen: isOpen,
          openTime: _parseTime(dayHours.open),
          closeTime: _parseTime(dayHours.close),
        );
      } else {
        // Use default hours from service.hours
        final defaultHours = _parseDefaultHours(service.hours);
        _schedules[day] = _DaySchedule(
          isOpen: isOpen,
          openTime: defaultHours.open,
          closeTime: defaultHours.close,
        );
      }
    }
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      // Parse "07:00 AM" format
      final parts = timeStr.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);

      if (parts.length > 1 && parts[1] == 'PM' && hour != 12) {
        hour += 12;
      } else if (parts.length > 1 && parts[1] == 'AM' && hour == 12) {
        hour = 0;
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return const TimeOfDay(hour: 7, minute: 0);
    }
  }

  ({TimeOfDay open, TimeOfDay close}) _parseDefaultHours(String hoursStr) {
    try {
      // Parse "07:00 AM - 05:00 PM" format
      final parts = hoursStr.split(' - ');
      if (parts.length == 2) {
        return (
          open: _parseTime(parts[0]),
          close: _parseTime(parts[1]),
        );
      }
    } catch (_) {}

    return (
      open: const TimeOfDay(hour: 7, minute: 0),
      close: const TimeOfDay(hour: 17, minute: 0),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _formatTime24(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _selectTime(BuildContext context, String day, bool isOpenTime) async {
    final schedule = _schedules[day]!;
    final initialTime = isOpenTime ? schedule.openTime : schedule.closeTime;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppTheme.of(context).cardBackground,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isOpenTime) {
          _schedules[day] = schedule.copyWith(openTime: picked);
        } else {
          _schedules[day] = schedule.copyWith(closeTime: picked);
        }
      });
    }
  }

  void _toggleDay(String day) {
    setState(() {
      final schedule = _schedules[day]!;
      _schedules[day] = schedule.copyWith(isOpen: !schedule.isOpen);
    });
  }

  void _save() {
    final dailyHours = <String, DailyHours?>{};

    for (final day in _days) {
      final schedule = _schedules[day]!;
      // Always save the hours, even if day is toggled off
      // The isOpen flag determines if it's shown as open in the grid
      dailyHours[day] = DailyHours(
        open: _formatTime(schedule.openTime),
        close: _formatTime(schedule.closeTime),
        formatted: '${_formatTime(schedule.openTime)} - ${_formatTime(schedule.closeTime)}',
      );
    }

    widget.onSave?.call(dailyHours, _getWeeklyScheduleFromToggles(), _selectedColor);
    Navigator.of(context).pop();
  }

  /// Get weekly schedule boolean array from toggle states
  List<bool> _getWeeklyScheduleFromToggles() {
    return _days.map((day) => _schedules[day]!.isOpen).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: theme.cardBackground,
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Schedule - ${widget.service.name}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: theme.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: theme.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Color Theme Selection
            Text(
              'Color Theme',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colorOptions.map((colorOption) {
                final isSelected = _selectedColor == colorOption['hex'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = colorOption['hex'] as String),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? colorOption['color'] as Color : (colorOption['color'] as Color).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: colorOption['color'] as Color, width: 2)
                          : Border.all(color: Colors.transparent),
                    ),
                    child: Text(
                      colorOption['name'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : colorOption['color'] as Color,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Divider(color: theme.cardBorder),
            const SizedBox(height: 16),

            // Column headers
            Row(
              children: [
                SizedBox(width: 80, child: Text('Day', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textSecondary))),
                SizedBox(width: 100, child: Text('Open', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textSecondary))),
                SizedBox(width: 100, child: Text('Close', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textSecondary))),
                const Spacer(),
                SizedBox(width: 60, child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textSecondary))),
              ],
            ),
            const SizedBox(height: 8),
            Divider(color: theme.cardBorder),

            // Day rows
            ..._days.asMap().entries.map((entry) {
              final index = entry.key;
              final day = entry.value;
              final dayLabel = _dayLabels[index];
              final schedule = _schedules[day]!;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    // Day label
                    SizedBox(
                      width: 80,
                      child: Text(
                        dayLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: schedule.isOpen ? theme.textPrimary : theme.textSecondary,
                        ),
                      ),
                    ),
                    // Open time
                    SizedBox(
                      width: 100,
                      child: GestureDetector(
                        onTap: schedule.isOpen ? () => _selectTime(context, day, true) : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: schedule.isOpen ? theme.cardBorder : theme.cardBorder.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(8),
                            color: schedule.isOpen ? theme.pageBackground : theme.pageBackground.withOpacity(0.5),
                          ),
                          child: Text(
                            _formatTime(schedule.openTime),
                            style: TextStyle(
                              fontSize: 13,
                              color: schedule.isOpen ? theme.textPrimary : theme.textSecondary.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Close time
                    SizedBox(
                      width: 100,
                      child: GestureDetector(
                        onTap: schedule.isOpen ? () => _selectTime(context, day, false) : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: schedule.isOpen ? theme.cardBorder : theme.cardBorder.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(8),
                            color: schedule.isOpen ? theme.pageBackground : theme.pageBackground.withOpacity(0.5),
                          ),
                          child: Text(
                            _formatTime(schedule.closeTime),
                            style: TextStyle(
                              fontSize: 13,
                              color: schedule.isOpen ? theme.textPrimary : theme.textSecondary.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Toggle switch
                    SizedBox(
                      width: 60,
                      child: Switch(
                        value: schedule.isOpen,
                        onChanged: (_) => _toggleDay(day),
                        activeColor: _getColor(widget.service.colorHex),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),
            Divider(color: theme.cardBorder),
            const SizedBox(height: 16),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: theme.textSecondary),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.buttonPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Save Schedule',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  }

  Color _getColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.blue;
    }
  }
}

/// Internal class to track day schedule state
class _DaySchedule {
  final bool isOpen;
  final TimeOfDay openTime;
  final TimeOfDay closeTime;

  _DaySchedule({
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
  });

  _DaySchedule copyWith({
    bool? isOpen,
    TimeOfDay? openTime,
    TimeOfDay? closeTime,
  }) {
    return _DaySchedule(
      isOpen: isOpen ?? this.isOpen,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }
}
