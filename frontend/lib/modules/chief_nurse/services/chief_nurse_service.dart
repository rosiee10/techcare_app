import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/services/auth_service.dart';
import '../../../core/config/api_config.dart';
import '../../../core/utils/logger.dart';

class ChiefNurseService {
  final AuthService _authService = AuthService();

  // Get dashboard stats
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
        Uri.parse('${ApiConfig.baseUrl}/api/chief-nurse/dashboard/stats/'),
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
      AppLogger.error('Get dashboard stats error', tag: 'ChiefNurseService', error: e);
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Get wards
  Future<Map<String, dynamic>> getWards() async {
    try {
      final token = await _authService.getAccessToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/chief-nurse/wards/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'wards': data['wards'] ?? [],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Failed to fetch wards',
        };
      }
    } catch (e) {
      AppLogger.error('Get wards error', tag: 'ChiefNurseService', error: e);
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Get nurse assignments
  Future<Map<String, dynamic>> getNurseAssignments() async {
    try {
      final token = await _authService.getAccessToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/chief-nurse/nurses/assignments/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'nurses': data['nurses'] ?? [],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Failed to fetch nurse assignments',
        };
      }
    } catch (e) {
      AppLogger.error('Get nurse assignments error', tag: 'ChiefNurseService', error: e);
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Get patient status
  Future<Map<String, dynamic>> getPatientStatus() async {
    try {
      final token = await _authService.getAccessToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/chief-nurse/patients/status/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'patients': data['patients'] ?? [],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Failed to fetch patient status',
        };
      }
    } catch (e) {
      AppLogger.error('Get patient status error', tag: 'ChiefNurseService', error: e);
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Get beds
  Future<Map<String, dynamic>> getBeds({String? wardId}) async {
    try {
      final token = await _authService.getAccessToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      var url = '${ApiConfig.baseUrl}/api/chief-nurse/beds/';
      if (wardId != null) {
        url += '?ward_id=$wardId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'beds': data['beds'] ?? [],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Failed to fetch beds',
        };
      }
    } catch (e) {
      AppLogger.error('Get beds error', tag: 'ChiefNurseService', error: e);
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Get nursing schedule
  Future<Map<String, dynamic>> getNursingSchedule({String? date}) async {
    try {
      final token = await _authService.getAccessToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      var url = '${ApiConfig.baseUrl}/api/chief-nurse/nurses/schedule/';
      if (date != null) {
        url += '?date=$date';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'schedules': data['schedules'] ?? [],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Failed to fetch schedule',
        };
      }
    } catch (e) {
      AppLogger.error('Get nursing schedule error', tag: 'ChiefNurseService', error: e);
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }
}
