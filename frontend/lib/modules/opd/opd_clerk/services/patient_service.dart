import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import '../../../../core/config/api_config.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/session_manager.dart';

class PatientService {
  static final PatientService _instance = PatientService._internal();
  factory PatientService() => _instance;
  PatientService._internal();

  // Patient API endpoints
  static String get _registerEndpoint => ApiConfig.patientRegister;
  static String get _listEndpoint => ApiConfig.patientList;
  static String get _photoUploadEndpoint => ApiConfig.patientPhotoUpload;
  static String get _updateEndpoint => '${ApiConfig.baseUrl}/api/patients';

  Future<Map<String, dynamic>> registerPatient({
    required Map<String, dynamic> patientData,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_registerEndpoint));

      // Add authentication token
      final token = await AuthService().getAccessToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add all text fields (including photo_url if provided)
      patientData.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          request.fields[key] = value.toString();
        }
      });

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var decodedResponse = jsonDecode(responseData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'data': decodedResponse,
          'message': 'Patient registered successfully',
        };
      } else if (response.statusCode == 401) {
        // Handle session expiration
        final httpResponse = http.Response(responseData, response.statusCode);
        await SessionManager().checkAndHandleExpiration(httpResponse);
        return {
          'success': false,
          'error': 'Session expired. Please login again',
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'error': decodedResponse['error'] ?? 'Failed to register patient',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getPatients() async {
    try {
      // Add authentication token
      final token = await AuthService().getAccessToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse(_listEndpoint),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('DEBUG PatientService.getPatients - Full response: $data');
        
        // Handle both 'data' and 'patients' keys
        final patientsList = data['data'] ?? data['patients'] ?? data;
        print('DEBUG PatientService.getPatients - Patients list: $patientsList');
        
        if (patientsList is List && patientsList.isNotEmpty) {
          print('DEBUG PatientService.getPatients - First patient keys: ${(patientsList[0] as Map).keys.toList()}');
          print('DEBUG PatientService.getPatients - First patient: ${patientsList[0]}');
        }
        
        return {
          'success': true,
          'data': data,
          'patients': patientsList is List ? patientsList : [patientsList],
        };
      } else if (response.statusCode == 401) {
        // Handle session expiration
        await SessionManager().checkAndHandleExpiration(response);
        return {
          'success': false,
          'error': 'Session expired. Please login again',
          'patients': [],
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch patients',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  Future<dynamic> updatePatient(String hospitalId, Map<String, dynamic> updateData) async {
    try {
      final token = await AuthService().getAccessToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final url = Uri.parse('$_updateEndpoint/$hospitalId/');
      print('DEBUG PatientService.updatePatient - URL: $url');
      print('DEBUG PatientService.updatePatient - Headers: $headers');
      print('DEBUG PatientService.updatePatient - Body: ${jsonEncode(updateData)}');
      
      final response = await http.patch(
        url,
        headers: headers,
        body: jsonEncode(updateData),
      );

      print('DEBUG PatientService.updatePatient - Response status: ${response.statusCode}');
      print('DEBUG PatientService.updatePatient - Response body: ${response.body}');
      
      return response;
    } catch (e) {
      throw Exception('Error updating patient: $e');
    }
  }

  Future<Map<String, dynamic>> uploadPatientPhoto(Uint8List photoBytes, String filename) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_photoUploadEndpoint));

      // Add authentication token
      final token = await AuthService().getAccessToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Determine content type from filename
      String contentType = 'image/jpeg';
      final ext = filename.toLowerCase().split('.').last;
      if (ext == 'png') {
        contentType = 'image/png';
      } else if (ext == 'gif') {
        contentType = 'image/gif';
      } else if (ext == 'webp') {
        contentType = 'image/webp';
      }

      // Add photo file with correct content type
      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          photoBytes,
          filename: filename,
          contentType: http_parser.MediaType.parse(contentType),
        ),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var decodedResponse = jsonDecode(responseData);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'photo_url': decodedResponse['photo_url'],
          'message': decodedResponse['message'] ?? 'Photo uploaded successfully',
        };
      } else {
        return {
          'success': false,
          'error': decodedResponse['error'] ?? 'Failed to upload photo',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }
}
