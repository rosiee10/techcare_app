import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';
import '../utils/logout_config.dart';

/// Global Navigator key for showing dialogs from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Global session manager for handling token expiration across the app
class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  bool _isShowingDialog = false;

  /// Get navigator state for navigation
  NavigatorState? get _navigator => navigatorKey.currentState;
  BuildContext? get _context => navigatorKey.currentContext;

  /// Check if response is unauthorized (401)
  bool isUnauthorized(http.Response response) {
    return response.statusCode == 401;
  }

  /// Handle token expiration - show dialog and force logout
  Future<void> handleTokenExpiration() async {
    if (_isShowingDialog || _context == null || _navigator == null) return;

    _isShowingDialog = true;
    AppLogger.error('[SessionManager] Token expired, showing session expired dialog');

    await showDialog(
      context: _context!,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) => PopScope(
        canPop: false, // Prevent back button
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 28),
              SizedBox(width: 12),
              Text(
                'Session Expired',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          content: Text(
            'Your session has expired. Please log in again to continue.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                _isShowingDialog = false;
                
                // Use centralized logout configuration
                await LogoutConfig.logoutAndNavigate(_navigator!);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Check response and handle expiration if needed
  Future<bool> checkAndHandleExpiration(http.Response response) async {
    if (isUnauthorized(response)) {
      await handleTokenExpiration();
      return true; // Expiration was handled
    }
    return false; // No expiration
  }
}

/// Mixin for providers to handle session expiration
mixin SessionAwareProvider {
  Future<bool> handleAuthError(int statusCode) async {
    if (statusCode == 401) {
      await SessionManager().handleTokenExpiration();
      return true;
    }
    return false;
  }
}
