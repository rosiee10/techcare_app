import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

/// Utility class to detect the platform the app is running on
class PlatformDetector {
  /// Check if running on web (browser)
  static bool get isWeb => kIsWeb;

  /// Check if running as a native mobile app (Android or iOS)
  static bool get isMobileApp {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (e) {
      return false;
    }
  }

  /// Check if running as Android app
  static bool get isAndroidApp {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid;
    } catch (e) {
      return false;
    }
  }

  /// Check if running as iOS app
  static bool get isIOSApp {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS;
    } catch (e) {
      return false;
    }
  }

  /// Check if running as desktop app
  static bool get isDesktopApp {
    if (kIsWeb) return false;
    try {
      return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    } catch (e) {
      return false;
    }
  }
}
