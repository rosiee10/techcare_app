import 'dart:async';
import 'package:flutter/foundation.dart';

/// Debouncer to prevent rapid API calls
class RequestDebouncer {
  final Duration delay;
  Timer? _timer;
  final Map<String, DateTime> _lastRequestTime = {};

  RequestDebouncer({this.delay = const Duration(milliseconds: 500)});

  /// Check if enough time has passed since the last request with this key
  bool canMakeRequest(String key) {
    final now = DateTime.now();
    final lastTime = _lastRequestTime[key];

    if (lastTime == null) {
      _lastRequestTime[key] = now;
      return true;
    }

    final timeSinceLastRequest = now.difference(lastTime);
    if (timeSinceLastRequest >= delay) {
      _lastRequestTime[key] = now;
      return true;
    }

    return false;
  }

  /// Run a function with debouncing
  void run(String key, VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(delay, () {
      if (canMakeRequest(key)) {
        callback();
      }
    });
  }

  /// Clear debouncer
  void clear() {
    _timer?.cancel();
    _lastRequestTime.clear();
  }

  /// Dispose resources
  void dispose() {
    _timer?.cancel();
  }
}
