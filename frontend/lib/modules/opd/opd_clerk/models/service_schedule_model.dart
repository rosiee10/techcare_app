/// Daily hours for a specific day
class DailyHours {
  final String open;
  final String close;
  final String formatted;

  const DailyHours({
    required this.open,
    required this.close,
    required this.formatted,
  });

  factory DailyHours.fromJson(Map<String, dynamic> json) {
    return DailyHours(
      open: json['open'] ?? '',
      close: json['close'] ?? '',
      formatted: json['formatted'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'open': open,
      'close': close,
      'formatted': formatted,
    };
  }
}

/// Service Schedule Model
/// Represents a service with its weekly schedule and status
class ServiceScheduleModel {
  final String id;
  final String name;
  final String code;
  final String hours;
  final bool isOpenToday;
  final List<bool> weeklySchedule; // MON, TUE, WED, THU, FRI, SAT
  final String colorHex;
  final Map<String, DailyHours?> dailyHours; // Per-day schedule (Mon-Sat)
  final bool isActive; // Service active/inactive status
  final DateTime? updatedAt; // Last modified timestamp

  const ServiceScheduleModel({
    required this.id,
    required this.name,
    required this.code,
    required this.hours,
    required this.isOpenToday,
    required this.weeklySchedule,
    required this.colorHex,
    this.dailyHours = const {},
    this.isActive = true,
    this.updatedAt,
  });

  /// Create from JSON
  factory ServiceScheduleModel.fromJson(Map<String, dynamic> json) {
    // Parse daily_hours from backend
    final dailyHoursJson = json['daily_hours'] as Map<String, dynamic>?;
    final Map<String, DailyHours?> dailyHours = {};

    if (dailyHoursJson != null) {
      for (final day in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']) {
        final dayData = dailyHoursJson[day];
        if (dayData != null) {
          dailyHours[day] = DailyHours.fromJson(dayData as Map<String, dynamic>);
        } else {
          dailyHours[day] = null;
        }
      }
    }

    // Parse updated_at timestamp
    DateTime? updatedAt;
    if (json['updated_at'] != null) {
      try {
        updatedAt = DateTime.parse(json['updated_at'].toString());
      } catch (e) {
        updatedAt = null;
      }
    }

    return ServiceScheduleModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      hours: json['hours'] ?? '',
      isOpenToday: json['is_open_today'] ?? false,
      weeklySchedule: List<bool>.from(json['weekly_schedule'] ?? [false, false, false, false, false, false]),
      colorHex: json['color_hex'] ?? '#2196F3',
      dailyHours: dailyHours,
      isActive: json['is_active'] ?? true,
      updatedAt: updatedAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'hours': hours,
      'is_open_today': isOpenToday,
      'weekly_schedule': weeklySchedule,
      'color_hex': colorHex,
      'is_active': isActive,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  ServiceScheduleModel copyWith({
    String? id,
    String? name,
    String? code,
    String? hours,
    bool? isOpenToday,
    List<bool>? weeklySchedule,
    String? colorHex,
    Map<String, DailyHours?>? dailyHours,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return ServiceScheduleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      hours: hours ?? this.hours,
      isOpenToday: isOpenToday ?? this.isOpenToday,
      weeklySchedule: weeklySchedule ?? this.weeklySchedule,
      colorHex: colorHex ?? this.colorHex,
      dailyHours: dailyHours ?? this.dailyHours,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get formatted "last updated" text
  String getLastUpdatedText() {
    if (updatedAt == null) return 'Never';
    
    final now = DateTime.now();
    final difference = now.difference(updatedAt!);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return updatedAt!.toString().split(' ')[0];
    }
  }

  /// Check if service has varying hours per day
  bool get hasVaryingHours {
    if (dailyHours.isEmpty) return false;

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    String? firstHours;

    for (final day in days) {
      final dayHours = dailyHours[day];
      if (dayHours != null) {
        if (firstHours == null) {
          firstHours = dayHours.formatted;
        } else if (dayHours.formatted != firstHours) {
          return true;
        }
      }
    }
    return false;
  }

  /// Get hours for a specific day
  String getHoursForDay(int dayIndex) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    if (dayIndex < 0 || dayIndex >= days.length) return hours;

    final dayHours = dailyHours[days[dayIndex]];
    return dayHours?.formatted ?? hours;
  }

  /// Get color based on today's status
  String get statusText => isOpenToday ? 'Open' : 'Closed';

  /// Check if service is available on a specific day (0=MON, 5=SAT)
  bool isAvailableOnDay(int dayIndex) {
    if (dayIndex < 0 || dayIndex >= weeklySchedule.length) return false;
    return weeklySchedule[dayIndex];
  }
}

/// Service Status for Today's display
class ServiceStatus {
  final String serviceName;
  final String status;
  final String hours;
  final String colorHex;
  final bool isOpen;

  const ServiceStatus({
    required this.serviceName,
    required this.status,
    required this.hours,
    required this.colorHex,
    required this.isOpen,
  });
}
