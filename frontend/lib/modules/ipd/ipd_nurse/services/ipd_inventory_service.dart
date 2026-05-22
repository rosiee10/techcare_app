import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/api_config.dart';
import '../../../../core/services/auth_service.dart';

class IpdInventoryService {
  final String baseUrl = ApiConfig.baseUrl;
  final AuthService _authService = AuthService();

  // Get auth headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ==================== PATIENT SEARCH ====================
  
  /// Search for IPD patients by name or hospital ID
  Future<Map<String, dynamic>> searchPatients(String query) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/ipd/requests/patients/search/?q=$query'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to search patients: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error searching patients: $e');
    }
  }

  /// Get patient details with admission info
  Future<Map<String, dynamic>> getPatientDetail(int patientId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/ipd/requests/patients/$patientId/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get patient details: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting patient details: $e');
    }
  }

  // ==================== DISPENSING SHEET ====================

  /// Create a new dispensing sheet
  Future<Map<String, dynamic>> createDispensingSheet({
    required int patientId,
    int? admissionId,
    required List<Map<String, dynamic>> items,
    required String requestedByName,
  }) async {
    try {
      final user = await _authService.getCurrentUser();
      final headers = await _getHeaders();

      final body = {
        'patient': patientId,
        'admission': admissionId,
        'requested_by': user?['user_id'],
        'requested_by_name': requestedByName,
        'items': items.map((item) => {
          'date_requested': item['date'],
          'medicine_id': item['medicine_id'], // USE medicine_id
          'dosage': item['dosage'],
          'quantity': int.tryParse(item['qty']?.toString() ?? '1') ?? 1,
        }).toList(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/ipd/requests/dispensing/create/'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create dispensing sheet: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating dispensing sheet: $e');
    }
  }

  /// Get list of dispensing sheets
  Future<Map<String, dynamic>> getDispensingSheets({
    String? status,
    int? nurseId,
  }) async {
    try {
      final headers = await _getHeaders();
      
      String url = '$baseUrl/api/ipd/requests/dispensing/';
      final params = <String>[];
      
      if (status != null && status != 'All Status') params.add('status=$status');
      if (nurseId != null) params.add('nurse_id=$nurseId');
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get dispensing sheets: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting dispensing sheets: $e');
    }
  }

  /// Get dispensing sheet detail (includes items)
  Future<Map<String, dynamic>> getDispensingSheetDetail(int dispensingId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/ipd/requests/dispensing/$dispensingId/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get dispensing sheet detail: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting dispensing sheet detail: $e');
    }
  }

  // ==================== CART FORM ====================

  /// Create a new cart form
  Future<Map<String, dynamic>> createCartForm({
    required int patientId,
    int? admissionId,
    required List<Map<String, dynamic>> items,
    required String requestedByName,
    String? trail,
  }) async {
    try {
      final user = await _authService.getCurrentUser();
      final headers = await _getHeaders();

      final body = {
        'patient': patientId,
        'admission': admissionId,
        'requested_by': user?['user_id'],
        'requested_by_name': requestedByName,
        'trail': trail,
        'items': items.map((item) => {
          'date_taken': item['date_taken'],
          'medicine_id': item['medicine_id'],
          'drug_name': item['drug_name'],
          'quantity': int.tryParse(item['quantity']?.toString() ?? '1') ?? 1,
          'administered_by': item['administered_by'],
        }).toList(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/ipd/requests/cart/create/'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create cart form: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating cart form: $e');
    }
  }

  /// Get list of cart forms
  Future<Map<String, dynamic>> getCartForms({
    String? status,
    int? nurseId,
  }) async {
    try {
      final headers = await _getHeaders();
      
      String url = '$baseUrl/api/ipd/requests/cart/';
      final params = <String>[];
      
      if (status != null) params.add('status=$status');
      if (nurseId != null) params.add('nurse_id=$nurseId');
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get cart forms: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting cart forms: $e');
    }
  }

  // ==================== INVENTORY ====================

  /// Get IPD Nurse Cart Inventory (Location 2)
  Future<Map<String, dynamic>> getInventory({
    String? query,
    String? category,
  }) async {
    try {
      final headers = await _getHeaders();
      
      String url = '$baseUrl/api/ipd/requests/inventory/';
      final params = <String>[];
      
      if (query != null && query.isNotEmpty) params.add('q=$query');
      if (category != null && category != 'All') params.add('category=$category');
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get inventory: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting inventory: $e');
    }
  }

  /// Get Main Pharmacy Inventory (Location 1) for Dispensing Sheets
  Future<Map<String, dynamic>> getPharmacyInventory({
    String? query,
  }) async {
    try {
      final headers = await _getHeaders();
      
      String url = '$baseUrl/api/ipd/requests/inventory/pharmacy/';
      if (query != null && query.isNotEmpty) {
        url += '?q=$query';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get pharmacy inventory: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting pharmacy inventory: $e');
    }
  }

  /// Confirm dispensing of a sheet
  Future<Map<String, dynamic>> dispenseSheet(int dispensingId, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/ipd/requests/dispensing/$dispensingId/dispense/'),
        headers: headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to dispense sheet: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error dispensing sheet: $e');
    }
  }
}
