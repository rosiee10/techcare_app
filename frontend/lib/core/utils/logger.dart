import 'package:flutter/foundation.dart';

/// Centralized logging utility for TechCare frontend
/// Provides structured logging with proper error handling
class AppLogger {
  static const String _prefix = '[TechCare]';

  /// Log info messages
  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('$_prefix [INFO] ${tag != null ? '[$tag]' : ''} $message');
    }
  }

  /// Log error messages
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('$_prefix [ERROR] ${tag != null ? '[$tag]' : ''} $message');
      if (error != null) {
        debugPrint('$_prefix [ERROR] Exception: $error');
      }
      if (stackTrace != null) {
        debugPrint('$_prefix [ERROR] StackTrace: $stackTrace');
      }
    }
  }

  /// Log warning messages
  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('$_prefix [WARNING] ${tag != null ? '[$tag]' : ''} $message');
    }
  }

  /// Log debug messages (only in debug mode)
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('$_prefix [DEBUG] ${tag != null ? '[$tag]' : ''} $message');
    }
  }

  /// Log API requests
  static void apiRequest(String method, String endpoint, {Map<String, dynamic>? data}) {
    if (kDebugMode) {
      debugPrint('$_prefix [API] $method $endpoint');
      if (data != null) {
        debugPrint('$_prefix [API] Data: $data');
      }
    }
  }

  /// Log API responses
  static void apiResponse(String endpoint, int statusCode, {dynamic data}) {
    if (kDebugMode) {
      debugPrint('$_prefix [API] Response from $endpoint - Status: $statusCode');
      if (data != null) {
        debugPrint('$_prefix [API] Response data: $data');
      }
    }
  }
}
