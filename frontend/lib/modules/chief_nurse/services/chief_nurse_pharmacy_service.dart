import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/services/auth_service.dart';
import '../../../core/config/api_config.dart';
import '../../../core/utils/logger.dart';

/// Chief Nurse - Pharmacy Service
/// All pharmacy-related API calls for Chief Nurse
/// This is YOUR isolated service file - add new pharmacy features here!
class ChiefNursePharmacyService {
  final AuthService _authService = AuthService();

  // ==================== PHARMACY PURCHASE REQUESTS ====================

  /// Get all pharmacy purchase requests for Chief Nurse review
  /// Fetches from pharmacy database tables: pharmacy_purchase_requests & pharmacy_purchase_request_items
  Future<Map<String, dynamic>> getPharmacyPurchaseRequests() async {
    try {
      final token = await _authService.getAccessToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/chief-nurse/pharmacy/purchase-requests/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'purchaseRequests': data['purchase_requests'] ?? [],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Failed to fetch purchase requests',
        };
      }
    } catch (e) {
      AppLogger.error('Get pharmacy purchase requests error', tag: 'ChiefNursePharmacyService', error: e);
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  /// Approve or reject a pharmacy purchase request
  /// Updates the pr_status in pharmacy_purchase_requests table
  Future<Map<String, dynamic>> approvePurchaseRequest(
    String prId, {
    required String action, // 'APPROVED' or 'REJECTED'
    String? remarks,
    List<Map<String, dynamic>>? updatedItems, // For editing quantities
  }) async {
    try {
      final token = await _authService.getAccessToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final body = {
        'action': action,
        'remarks': remarks,
        'updated_items': updatedItems?.map((item) => {
          'pr_item_id': item['pr_item_id'],
          'approved_qty': item['approved_qty'] ?? item['qty_requested'],
          'unit_cost_estimate': item['unit_cost_estimate'] ?? 0.0,
        }).toList(),
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/chief-nurse/pharmacy/purchase-requests/$prId/approve/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Purchase request $action',
          'purchaseRequest': data['purchase_request'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Failed to $action purchase request',
        };
      }
    } catch (e) {
      AppLogger.error('Approve purchase request error', tag: 'ChiefNursePharmacyService', error: e);
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  /// Get pharmacy purchase request statistics for dashboard
  /// Counts: Pending, Approved, On Delivery, Delivered, Rejected
  Future<Map<String, dynamic>> getPharmacyPRStats() async {
    try {
      final token = await _authService.getAccessToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/chief-nurse/pharmacy/purchase-requests/stats/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'stats': data['stats'] ?? {
            'pending': 0,
            'approved': 0,
            'on_delivery': 0,
            'delivered': 0,
            'rejected': 0,
            'total': 0,
          },
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Failed to fetch stats',
        };
      }
    } catch (e) {
      AppLogger.error('Get pharmacy PR stats error', tag: 'ChiefNursePharmacyService', error: e);
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // ==================== PHARMACY DASHBOARD ====================

  /// Get pharmacy dashboard data for Chief Nurse
  Future<Map<String, dynamic>> getPharmacyDashboard() async {
    try {
      final token = await _authService.getAccessToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/chief-nurse/pharmacy/dashboard/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Failed to fetch pharmacy dashboard',
        };
      }
    } catch (e) {
      AppLogger.error('Get pharmacy dashboard error', tag: 'ChiefNursePharmacyService', error: e);
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // ==================== ADD NEW PHARMACY FEATURES BELOW ====================
  // 
  // Examples:
  // - Inventory management
  // - Medicine requests
  // - Stock monitoring
  // - etc.
  //
  // Add your new pharmacy API methods here!
}
