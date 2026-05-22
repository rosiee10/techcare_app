import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../utils/logger.dart';
import '../services/session_manager.dart';

class PatientService {
  // Get all patients
  Future<Map<String, dynamic>> getPatients({
    String? search,
    String? status,
  }) async {
    try {
      final token = await _getAccessToken();
      
      // Debug: Check if token exists
      if (token == null) {
        AppLogger.warning('No access token found in SharedPreferences', tag: 'PatientService');
        return {
          'success': false,
          'message': 'Unauthorized - No token found. Please login again.',
          'patients': []
        };
      }

      String url = ApiConfig.patientList;
      
      // Add query parameters
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (status != null && status.isNotEmpty && status != 'All Status') {
        queryParams['status'] = status;
      }

      if (queryParams.isNotEmpty) {
        final uri = Uri.parse(url);
        url = uri.replace(queryParameters: queryParams).toString();
      }

      AppLogger.apiRequest('GET', url);
      
      // Build headers with authentication
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      
      AppLogger.debug('Token found: ${token.substring(0, 20)}...', tag: 'PatientService');
      AppLogger.debug('Request URL: $url', tag: 'PatientService');
      AppLogger.debug('Request headers: $headers', tag: 'PatientService');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      AppLogger.debug('Response status: ${response.statusCode}', tag: 'PatientService');
      AppLogger.debug('Response body: ${response.body}', tag: 'PatientService');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          AppLogger.apiResponse(url, response.statusCode);
          
          return {
            'success': true,
            'patients': data['results'] ?? data['patients'] ?? [],
            'total': data['count'] ?? (data['patients'] as List?)?.length ?? 0,
            'message': 'Patients loaded successfully'
          };
        } catch (e) {
          AppLogger.error('Invalid JSON response from patients endpoint', error: e);
          return {
            'success': false,
            'message': 'Invalid response format from server',
            'patients': []
          };
        }
      } else if (response.statusCode == 401) {
        // Handle session expiration
        await SessionManager().checkAndHandleExpiration(response);
        return {
          'success': false,
          'message': 'Session expired. Please login again',
          'patients': []
        };
      } else if (response.statusCode == 404) {
        AppLogger.warning('Patients endpoint not found (404) - using mock data', tag: 'PatientService');
        return {
          'success': false,
          'message': 'Using mock data',
          'patients': []
        };
      } else {
        try {
          final error = jsonDecode(response.body);
          return {
            'success': false,
            'message': error['error'] ?? 'Failed to load patients',
            'patients': []
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Server error: ${response.statusCode}',
            'patients': []
          };
        }
      }
    } catch (e) {
      AppLogger.error('Error loading patients', error: e);
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
        'patients': []
      };
    }
  }

  // Get single patient
  Future<Map<String, dynamic>> getPatient(String hospitalId) async {
    try {
      final token = await _getAccessToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Unauthorized - No token found',
        };
      }

      final url = ApiConfig.patientDetail(hospitalId);
      AppLogger.apiRequest('GET', url);
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.apiResponse(url, response.statusCode);
        
        return {
          'success': true,
          'patient': data,
          'message': 'Patient loaded successfully'
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load patient',
        };
      }
    } catch (e) {
      AppLogger.error('Error loading patient', error: e);
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Update patient information
  Future<dynamic> updatePatient(String hospitalId, Map<String, dynamic> updateData) async {
    try {
      final token = await _getAccessToken();
      if (token == null) {
        throw Exception('Unauthorized - No token found');
      }

      final url = '${ApiConfig.baseUrl}/api/patients/$hospitalId/';
      AppLogger.apiRequest('PATCH', url);
      
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updateData),
      );

      AppLogger.apiResponse(url, response.statusCode);
      return response;
    } catch (e) {
      AppLogger.error('Error updating patient', error: e);
      throw Exception('Error updating patient: $e');
    }
  }

  // Get access token from shared preferences
  Future<String?> _getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('access_token');
    } catch (e) {
      return null;
    }
  }
}
