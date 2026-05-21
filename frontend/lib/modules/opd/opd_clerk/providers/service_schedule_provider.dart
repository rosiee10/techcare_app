import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/api_config.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/session_manager.dart';
import '../../../../core/utils/logger.dart';
import '../models/service_schedule_model.dart';
import '../models/service_schedule_model.dart' show DailyHours;

/// Provider for Service Schedule State Management
class ServiceScheduleProvider extends ChangeNotifier {
  // State
  List<ServiceScheduleModel> _services = [];
  bool _isLoading = false;
  String? _error;
  int _currentDayIndex = DateTime.now().weekday == 7 ? -1 : DateTime.now().weekday - 1; // 0=MON, 5=SAT, -1=SUNDAY (closed)

  // Timer for auto-refreshing status every 30 seconds
  Timer? _refreshTimer;

  // Getters
  List<ServiceScheduleModel> get services => List.unmodifiable(_services);
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentDayIndex => _currentDayIndex;

  /// Calculate if service is currently open based on schedule and current time
  bool _isServiceCurrentlyOpen(ServiceScheduleModel service) {
    final now = DateTime.now();
    final currentDayIndex = now.weekday - 1; // 0=MON, 5=SAT

    // Check if service is scheduled for today
    if (currentDayIndex < 0 || currentDayIndex >= service.weeklySchedule.length) {
      return false;
    }

    // If not scheduled for today, it's closed
    if (!service.weeklySchedule[currentDayIndex]) {
      return false;
    }

    // Parse hours (format: "07:00 AM - 05:00 PM")
    return _isWithinHours(service.hours, now);
  }

  /// Check if current time is within service hours
  bool _isWithinHours(String hours, DateTime now) {
    try {
      final parts = hours.split(' - ');
      if (parts.length != 2) return false;

      final startTime = _parseTime(parts[0].trim());
      final endTime = _parseTime(parts[1].trim());

      if (startTime == null || endTime == null) return false;

      final currentMinutes = now.hour * 60 + now.minute;

      return currentMinutes >= startTime && currentMinutes < endTime;
    } catch (e) {
      return false;
    }
  }

  /// Parse time string (e.g., "07:00 AM") to minutes from midnight
  int? _parseTime(String timeStr) {
    try {
      final isPM = timeStr.toUpperCase().contains('PM');
      final isAM = timeStr.toUpperCase().contains('AM');

      final timeOnly = timeStr.replaceAll(RegExp(r'\s*(AM|PM|am|pm)\s*'), '');
      final timeParts = timeOnly.split(':');

      if (timeParts.length < 2) return null;

      var hours = int.tryParse(timeParts[0]) ?? 0;
      final minutes = int.tryParse(timeParts[1]) ?? 0;

      // Convert to 24-hour format
      if (isPM && hours != 12) hours += 12;
      if (isAM && hours == 12) hours = 0;

      return hours * 60 + minutes;
    } catch (e) {
      return null;
    }
  }

  /// Recalculate isOpenToday for all services based on current time
  void _recalculateTodayStatus() {
    final now = DateTime.now();
    _services = _services.map((service) {
      final isCurrentlyOpen = _isServiceCurrentlyOpen(service);
      return service.copyWith(isOpenToday: isCurrentlyOpen);
    }).toList();
  }

  /// Load services from backend API
  Future<void> loadServices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await AuthService().getAccessToken();

      // Add cache-busting query parameter to force fresh data
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(
        Uri.parse('${ApiConfig.opdServiceList}?t=$timestamp'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _services = (data['data'] as List)
              .map((json) => _serviceFromJson(json))
              .toList();
          if (data['current_day_index'] != null) {
            _currentDayIndex = data['current_day_index'];
          }
          // Use is_open_today from backend - don't recalculate on frontend
          // Backend already calculates this based on current time and active_today flag
          _isLoading = false;
          notifyListeners();

          // Start auto-refresh timer to update status every 30 seconds
          _startAutoRefreshTimer();

          AppLogger.info('Loaded ${_services.length} services', tag: 'ServiceSchedule');
        } else {
          throw Exception(data['error'] ?? 'Failed to load services');
        }
      } else if (response.statusCode == 401) {
        // Token expired - let SessionManager handle it
        AppLogger.warning('Session expired while loading services', tag: 'ServiceSchedule');
        await SessionManager().checkAndHandleExpiration(response);
        _error = 'Session expired. Please log in again.';
        _isLoading = false;
        notifyListeners();
        return;
      } else {
        throw Exception('Failed to load services: ${response.statusCode}');
      }
    } catch (e) {
      _error = 'Failed to load services: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Parse service JSON from backend
  ServiceScheduleModel _serviceFromJson(Map<String, dynamic> json) {
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
      id: json['id'].toString(),
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      hours: json['hours'] ?? '',
      isOpenToday: json['is_open_today'] ?? false,
      weeklySchedule: List<bool>.from(json['weekly_schedule'] ?? [false, false, false, false, false, false]),
      colorHex: json['color_hex'] ?? '#666666',
      dailyHours: dailyHours,
      isActive: json['is_active'] ?? true,
      updatedAt: updatedAt,
    );
  }

  /// Toggle service availability for a specific day
  Future<void> toggleServiceDay(String serviceId, int dayIndex) async {
    final index = _services.indexWhere((s) => s.id == serviceId);
    if (index == -1 || dayIndex < 0 || dayIndex >= 6) return;

    final service = _services[index];
    final newSchedule = List<bool>.from(service.weeklySchedule);
    newSchedule[dayIndex] = !newSchedule[dayIndex];

    // Calculate new today's status immediately (not just when toggling today)
    // This ensures Today's Status cards sync with weekly grid changes
    final newIsOpenToday = _isServiceCurrentlyOpen(
      service.copyWith(weeklySchedule: newSchedule),
    );

    // Update locally first for immediate feedback
    _services[index] = service.copyWith(
      weeklySchedule: newSchedule,
      isOpenToday: newIsOpenToday ?? service.isOpenToday,
    );
    notifyListeners();

    // Call API to persist changes
    try {
      final token = await AuthService().getAccessToken();
      final baseUrl = ApiConfig.baseUrl;

      // Convert newSchedule back to days_open string format
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      final openDays = <String>[];
      for (int i = 0; i < newSchedule.length; i++) {
        if (newSchedule[i]) openDays.add(days[i]);
      }
      final daysOpenStr = openDays.join(',');

      // Build request body
      final requestBody = {
        'id': int.parse(serviceId),
        'field': 'days_open',
        'value': daysOpenStr,
      };

      // If toggling today's status OFF, also disable active_today override
      if (dayIndex == _currentDayIndex && !newSchedule[dayIndex]) {
        requestBody['active_today'] = false;
      }

      await http.patch(
        Uri.parse('$baseUrl/api/patients/service-schedule/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );
      AppLogger.info('Updated schedule for ${service.name}', tag: 'ServiceSchedule');
    } catch (e) {
      // Revert on error
      AppLogger.error('Failed to update schedule for ${service.name}', tag: 'ServiceSchedule', error: e);
      _services[index] = service;
      notifyListeners();
    }
  }

  /// Update service hours (legacy - single hours for all days)
  Future<void> updateServiceHours(String serviceId, String newHours) async {
    final index = _services.indexWhere((s) => s.id == serviceId);
    if (index == -1) return;

    _services[index] = _services[index].copyWith(hours: newHours);
    notifyListeners();

    // TODO: Call API to persist changes
  }

  /// Update per-day hours and color for a service
  Future<void> updateDailyHours(String serviceId, Map<String, DailyHours?> newDailyHours, [List<bool>? newWeeklySchedule, String? colorHex]) async {
    final index = _services.indexWhere((s) => s.id == serviceId);
    if (index == -1) return;

    final service = _services[index];

    // Update local state
    _services[index] = service.copyWith(
      dailyHours: newDailyHours,
      weeklySchedule: newWeeklySchedule ?? service.weeklySchedule,
      colorHex: colorHex ?? service.colorHex,
    );
    notifyListeners();

    // Call API to persist changes
    try {
      final token = await AuthService().getAccessToken();
      final baseUrl = ApiConfig.baseUrl;

      // Build daily hours data for API
      final dailyHoursData = <String, Map<String, String>>{};
      newDailyHours.forEach((day, hours) {
        if (hours != null) {
          dailyHoursData[day] = {
            'open': hours.open,
            'close': hours.close,
          };
        }
      });

      // Update daily hours
      await http.patch(
        Uri.parse('$baseUrl/api/patients/service-schedule/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id': int.parse(serviceId),
          'field': 'daily_hours',
          'value': dailyHoursData,
        }),
      );

      // Update color theme if changed
      if (colorHex != null && colorHex != service.colorHex) {
        await http.patch(
          Uri.parse('$baseUrl/api/patients/service-schedule/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'id': int.parse(serviceId),
            'color_theme': colorHex,
          }),
        );
      }

      AppLogger.info('Updated daily hours and color for ${service.name}', tag: 'ServiceSchedule');
    } catch (e) {
      // Revert on error
      AppLogger.error('Failed to update daily hours for ${service.name}', tag: 'ServiceSchedule', error: e);
      _services[index] = service;
      notifyListeners();
    }
  }

  /// Toggle today's status - also updates weekly schedule for today
  Future<void> toggleTodayStatus(String serviceId) async {
    final index = _services.indexWhere((s) => s.id == serviceId);
    if (index == -1) return;

    final service = _services[index];
    final newIsOpenToday = !service.isOpenToday;

    // Also update the weekly schedule for today
    final newWeeklySchedule = List<bool>.from(service.weeklySchedule);
    if (_currentDayIndex >= 0 && _currentDayIndex < newWeeklySchedule.length) {
      newWeeklySchedule[_currentDayIndex] = newIsOpenToday;
    }

    _services[index] = service.copyWith(
      isOpenToday: newIsOpenToday,
      weeklySchedule: newWeeklySchedule,
    );
    notifyListeners();

    // Call API to persist changes using POST endpoint
    try {
      final token = await AuthService().getAccessToken();
      final baseUrl = ApiConfig.baseUrl;

      final response = await http.post(
        Uri.parse('$baseUrl/api/patients/service-schedule/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id': int.parse(serviceId),
          'active_today': newIsOpenToday,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          AppLogger.info('Toggled ${service.name} to ${newIsOpenToday ? "Open" : "Closed"}', tag: 'ServiceSchedule');
        }
      }
    } catch (e) {
      // Revert on error
      _services[index] = service;
      notifyListeners();
      AppLogger.error('Failed to toggle today status: $e', tag: 'ServiceSchedule');
    }
  }

  /// Refresh today's status by reloading from backend
  Future<void> refreshTodayStatus() async {
    // Reload services from backend to get updated is_open_today status
    // Backend calculates this based on current time and active_today flag
    await loadServices();
  }

  /// Add new service to local list only
  Future<void> addService(ServiceScheduleModel service) async {
    _services.add(service);
    notifyListeners();
  }

  /// Create new service via API - returns true on success, false on failure
  Future<bool> createService({
    required String name,
    required String color,
    required String openingTime,
    required String closingTime,
    required String daysOpen,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await AuthService().getAccessToken();

      final response = await http.post(
        Uri.parse('${ApiConfig.opdServiceList}create/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service': name,
          'service_label': name,
          'color_theme': color,
          'open_time': openingTime,
          'close_time': closingTime,
          'days_open': daysOpen,
        }),
      );

      if (response.statusCode == 201) {
        // Reload services to get the new one
        await loadServices();
        return true;
      } else {
        final errorData = json.decode(response.body);
        _error = errorData['error'] ?? 'Failed to create service';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error creating service: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete service (soft delete via API)
  Future<bool> deleteService(String serviceId) async {
    final index = _services.indexWhere((s) => s.id == serviceId);
    if (index == -1) return false;

    final service = _services[index];
    
    // Optimistically remove from local list
    _services.removeAt(index);
    notifyListeners();

    // Call API to persist deletion
    try {
      final token = await AuthService().getAccessToken();

      final serviceIdInt = int.parse(serviceId);
      final deleteUrl = '${ApiConfig.opdServiceList}$serviceIdInt/delete/';
      print('[DEBUG] Deleting service - URL: $deleteUrl, serviceId: $serviceId');

      final response = await http.delete(
        Uri.parse(deleteUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('[DEBUG] Delete response - Status: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          AppLogger.info('Deleted service ${service.name}', tag: 'ServiceSchedule');
          print('[DEBUG] Service deleted successfully');
          return true;
        }
      }
      
      // Revert on failure
      _services.insert(index, service);
      notifyListeners();
      print('[DEBUG] Delete failed - reverting');
      return false;
    } catch (e) {
      // Revert on error
      _services.insert(index, service);
      notifyListeners();
      AppLogger.error('Failed to delete service ${service.name}', tag: 'ServiceSchedule', error: e);
      print('[DEBUG] Exception in deleteService: $e');
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Mock data based on UI design - calculates initial status based on current time
  List<ServiceScheduleModel> _getMockServices() {
    final now = DateTime.now();
    final currentDayIndex = now.weekday == 7 ? -1 : now.weekday - 1; // -1 for Sunday (closed)

    final services = [
      ServiceScheduleModel(
        id: '1',
        name: 'FAMED',
        code: 'FAMED',
        hours: '07:00 AM - 05:00 PM',
        isOpenToday: true, // Will be recalculated below
        weeklySchedule: [true, true, true, true, true, true],
        colorHex: '#2196F3',
      ),
      ServiceScheduleModel(
        id: '2',
        name: 'PEDIA',
        code: 'PEDIA',
        hours: '08:00 AM - 12:00 PM',
        isOpenToday: false,
        weeklySchedule: [true, true, true, true, true, false],
        colorHex: '#4CAF50',
      ),
      ServiceScheduleModel(
        id: '3',
        name: 'DENTAL',
        code: 'DENTAL',
        hours: '08:00 AM - 12:00 PM',
        isOpenToday: false,
        weeklySchedule: [true, false, true, false, true, false],
        colorHex: '#00BCD4',
      ),
      ServiceScheduleModel(
        id: '4',
        name: 'SURGERY',
        code: 'SURGERY',
        hours: '07:00 AM - 12:00 PM',
        isOpenToday: false,
        weeklySchedule: [true, true, false, true, false, false],
        colorHex: '#9C27B0',
      ),
      ServiceScheduleModel(
        id: '5',
        name: 'OBGYN',
        code: 'OBGYN',
        hours: '08:00 AM - 05:00 PM',
        isOpenToday: true,
        weeklySchedule: [true, true, true, true, true, true],
        colorHex: '#E91E63',
      ),
    ];

    // Calculate actual open status based on current time (all closed on Sunday)
    return services.map((service) {
      if (currentDayIndex == -1) {
        // Sunday - all services closed
        return service.copyWith(isOpenToday: false);
      }
      final isScheduledToday = currentDayIndex >= 0 &&
          currentDayIndex < service.weeklySchedule.length &&
          service.weeklySchedule[currentDayIndex];
      final shouldBeOpen = isScheduledToday && _isWithinHours(service.hours, now);

      return service.copyWith(isOpenToday: shouldBeOpen);
    }).toList();
  }

  /// Start auto-refresh timer to update service status every 30 seconds
  void _startAutoRefreshTimer() {
    // Cancel existing timer if any
    _refreshTimer?.cancel();

    // Create new timer that fires every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      refreshTodayStatus();
    });
    AppLogger.debug('Auto-refresh timer started (30s interval)', tag: 'ServiceSchedule');
  }

  /// Stop the auto-refresh timer
  void stopAutoRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    AppLogger.debug('Auto-refresh timer stopped', tag: 'ServiceSchedule');
  }

  @override
  void dispose() {
    // Clean up timer when provider is disposed
    stopAutoRefreshTimer();
    AppLogger.debug('ServiceScheduleProvider disposed', tag: 'ServiceSchedule');
    super.dispose();
  }
}
