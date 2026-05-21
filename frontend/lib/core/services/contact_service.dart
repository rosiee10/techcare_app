import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/session_manager.dart';

class ContactService {
  /// Submit contact form message (public endpoint - no auth required)
  static Future<Map<String, dynamic>> submitMessage({
    required String fullName,
    required String email,
    String? phone,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.contactSubmit),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'phone': phone,
          'message': message,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Message sent successfully!',
          'data': data,
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? error['error'] ?? 'Failed to send message',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }
}
