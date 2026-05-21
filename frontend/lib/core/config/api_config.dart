import 'package:flutter/foundation.dart';

/// Environment configuration
enum AppEnvironment {
  development,
  developmentHotspot,
  staging,
  production,
}

/// API Configuration - Dynamically configures API URLs based on platform and environment
class ApiConfig {
  // Current environment - change this to switch between dev/staging/production
  static const AppEnvironment environment = AppEnvironment.development;

  // Base URLs for different environments
  static const Map<AppEnvironment, Map<String, String>> _baseUrls = {
    AppEnvironment.development: {
      'web': 'http://localhost:8000',
      'android': 'http://10.0.2.2:8000',
      'ios': 'http://127.0.0.1:8000',
    },
    AppEnvironment.developmentHotspot: {
      'web': 'http://localhost:8000',
      'android': 'http://192.168.8.154:8000',
      'ios': 'http://10.42.197.128:8000',
    },
    AppEnvironment.staging: {
      'web': 'https://staging-api.techcare.com',
      'android': 'https://staging-api.techcare.com',
      'ios': 'https://staging-api.techcare.com',
    },
    AppEnvironment.production: {
      'web': 'https://api.techcare.com',
      'android': 'https://api.techcare.com',
      'ios': 'https://api.techcare.com',
    },
  };

  /// Get the appropriate base URL based on platform and environment
  static String get baseUrl {
    final urls = _baseUrls[environment]!;
    
    if (kIsWeb) {
      return urls['web']!;
    } else if (defaultTargetPlatform.toString() == 'TargetPlatform.android') {
      return urls['android']!;
    } else if (defaultTargetPlatform.toString() == 'TargetPlatform.iOS') {
      return urls['ios']!;
    } else {
      // Fallback to development
      return urls['web']!;
    }
  }

  /// Get media URL for images and files
  static String get mediaUrl => baseUrl;

  /// Build full media URL for images
  static String buildMediaUrl(String relativePath) {
    if (relativePath.startsWith('http')) {
      return relativePath;
    }
    return '$mediaUrl$relativePath';
  }
  
  // API endpoints
  static String get authBase => '$baseUrl/api/auth';
  static String get contactBase => '$baseUrl/api/contact';
  static String get patientBase => '$baseUrl/api/patients';
  static String get opdBase => '$baseUrl/api/opd';
  
  // Auth endpoints
  static String get login => '$authBase/login/';
  static String get register => '$authBase/register/';
  static String get logout => '$authBase/logout/';
  static String get refresh => '$authBase/refresh/';
  static String get verify => '$authBase/verify/';
  
  // Contact endpoints
  static String get contactSubmit => '$contactBase/submit/';
  static String get contactMessages => '$contactBase/messages/';
  static String get contactStats => '$contactBase/stats/';
  static String get contactBulkUpdate => '$contactBase/bulk-update/';
  
  // Patient endpoints
  static String get patientList => '$patientBase/';
  static String get patientRegister => '$patientBase/register/';
  static String get patientPhotoUpload => '$patientBase/photo/upload/';
  static String patientDetail(String hospitalId) => '$patientBase/$hospitalId/';
  
  // OPD endpoints
  static String get roomList => '$opdBase/rooms/';
  static String roomDetail(int roomId) => '$opdBase/rooms/$roomId/';
  static String get opdServiceList => '$opdBase/services/';
  
  // Auth endpoints
  static String get doctorsList => '$authBase/doctors/list/';
  
  // Helper to build URL with ID
  static String contactMessageDetail(int id) => '$contactBase/messages/$id/';

  // Pharmacy endpoints
  static String get pharmacyBase => '$baseUrl/api/pharmacy';
  static String get pharmacyMedicines => '$pharmacyBase/medicines/';
  static String get pharmacySuppliers => '$pharmacyBase/suppliers/';
  static String get pharmacyLocations => '$pharmacyBase/locations/';
  static String get pharmacyStockBatches => '$pharmacyBase/stock-batches/';
  static String get pharmacyInventoryBalances => '$pharmacyBase/inventory-balances/';
  static String get pharmacyPurchaseRequests => '$pharmacyBase/purchase-requests/';
  static String get pharmacyChargeSlips => '$pharmacyBase/charge-slips/';
  static String get pharmacyDispenseReceipts => '$pharmacyBase/dispense-receipts/';
  static String get pharmacyDashboardStats => '$pharmacyBase/dashboard-stats/';
  static String get pharmacyLowStockAlerts => '$pharmacyBase/low-stock-alerts/';
  static String get pharmacyExpiryAlerts => '$pharmacyBase/expiry-alerts/';
  static String get pharmacyDispense => '$pharmacyBase/dispense/';
  static String get pharmacyReports => '$pharmacyBase/reports/';

  // Pharmacy notification endpoints
  static String get pharmacyNotifications => '$pharmacyBase/notifications/';
  static String get pharmacyNotificationsGenerate => '$pharmacyBase/notifications/generate/';
  static String get pharmacyNotificationsUnreadCount => '$pharmacyBase/notifications/unread-count/';
  static String get pharmacyNotificationsMarkRead => '$pharmacyBase/notifications/mark-read/';
  static String pharmacyNotificationDismiss(int id) => '$pharmacyBase/notifications/$id/dismiss/';

  // Helper to build pharmacy URLs with ID
  static String pharmacyMedicineDetail(int id) => '$pharmacyBase/medicines/$id/';
  static String pharmacyStockBatchDetail(int id) => '$pharmacyBase/stock-batches/$id/';
}
