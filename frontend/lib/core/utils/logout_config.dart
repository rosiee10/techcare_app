import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'platform_detector.dart';

/// Centralized logout configuration
/// Handles platform-specific logout routing
class LogoutConfig {
  /// Get the logout route based on platform
  /// - Mobile app -> /login
  /// - Web/Mobile browser -> / (landing page)
  static String get logoutRoute {
    return PlatformDetector.isMobileApp ? '/login' : '/';
  }

  /// Perform logout and navigate to appropriate route
  /// 
  /// [navigator] - NavigatorState to handle navigation
  /// [clearStack] - whether to clear navigation stack (default: true)
  static Future<void> logoutAndNavigate(
    NavigatorState navigator, {
    bool clearStack = true,
  }) async {
    // Clear authentication tokens
    await AuthService().logout();

    // Navigate to platform-specific route
    final route = logoutRoute;

    if (clearStack) {
      navigator.pushNamedAndRemoveUntil(route, (route) => false);
    } else {
      navigator.pushReplacementNamed(route);
    }
  }

  /// Get logout destination label for UI display
  static String get logoutDestinationLabel {
    return PlatformDetector.isMobileApp ? 'Login' : 'Home';
  }
}
