import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/services/auth_service.dart';
import '../../../core/config/api_config.dart';
import '../../../core/utils/logger.dart';

class PatientService {
  final AuthService _authService = AuthService();

  // Get patient profile
  Future<Map<String, dynamic>> getPatientProfile() async {
    try {
      final token = await _authService.getAccessToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/patient/profile/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'patient': data['patient'],
          'emergency_contacts': data['emergency_contacts'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Failed to fetch profile',
        };
      }
    } catch (e) {
      AppLogger.error('Get patient profile error', tag: 'PatientService', error: e);
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Get patient dashboard stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final token = await _authService.getAccessToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/patient/dashboard/stats/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'stats': data['stats'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Failed to fetch stats',
        };
      }
    } catch (e) {
      AppLogger.error('Get dashboard stats error', tag: 'PatientService', error: e);
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Get patient appointments
  Future<Map<String, dynamic>> getAppointments() async {
    try {
      final token = await _authService.getAccessToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/patient/appointments/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'appointments': data['appointments'] ?? [],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Failed to fetch appointments',
        };
      }
    } catch (e) {
      AppLogger.error('Get appointments error', tag: 'PatientService', error: e);
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Get lab results
  Future<Map<String, dynamic>> getLabResults() async {
    try {
      final token = await _authService.getAccessToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/patient/lab-results/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'lab_results': data['lab_results'] ?? [],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Failed to fetch lab results',
        };
      }
    } catch (e) {
      AppLogger.error('Get lab results error', tag: 'PatientService', error: e);
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Get prescriptions
  Future<Map<String, dynamic>> getPrescriptions() async {
    try {
      final token = await _authService.getAccessToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/patient/prescriptions/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'prescriptions': data['prescriptions'] ?? [],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Failed to fetch prescriptions',
        };
      }
    } catch (e) {
      AppLogger.error('Get prescriptions error', tag: 'PatientService', error: e);
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Update patient profile (limited fields)
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final token = await _authService.getAccessToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/patient/profile/update/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(profileData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Profile updated successfully',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      AppLogger.error('Update profile error', tag: 'PatientService', error: e);
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }
}
