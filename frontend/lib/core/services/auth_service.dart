import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';
import '../services/session_manager.dart';
import '../config/api_config.dart';

class AuthService {
  // Use centralized config
  static String get baseUrl => ApiConfig.authBase;
  
  // Login user
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      AppLogger.apiRequest('POST', '$baseUrl/login/');
      final response = await http.post(
        Uri.parse('$baseUrl/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Store tokens and user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access']);
        await prefs.setString('refresh_token', data['refresh']);
        await prefs.setString('user_data', jsonEncode(data['user']));
        
        return {
          'success': true,
          'user': data['user'],
          'message': 'Login successful'
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Login failed'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}'
      };
    }
  }
  
  // Get current user
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      
      if (userData != null) {
        return jsonDecode(userData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  // Get access token
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }
  
  // Get refresh token
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }
  
  // Refresh access token
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await getRefreshToken();
      
      if (refreshToken == null) {
        return false;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access']);
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // Verify admin password for secure operations
  Future<Map<String, dynamic>> verifyAdminPassword(String password) async {
    try {
      final token = await getAccessToken();
      final currentUser = await getCurrentUser();
      
      if (token == null || currentUser == null) {
        return {
          'success': false,
          'message': 'Not authenticated'
        };
      }
      
      // Re-login with current username and provided password to verify
      final response = await http.post(
        Uri.parse('$baseUrl/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': currentUser['username'],
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Password verified'
        };
      } else {
        return {
          'success': false,
          'message': 'Incorrect password'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Verification failed: ${e.toString()}'
      };
    }
  }

  // Change password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final accessToken = await getAccessToken();
      
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }
      
      AppLogger.apiRequest('POST', '$baseUrl/change-password/');
      final response = await http.post(
        Uri.parse('$baseUrl/change-password/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );
      
      AppLogger.apiResponse('$baseUrl/change-password/', response.statusCode);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Update user data if must_change_pw was updated
        if (data['user'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', jsonEncode(data['user']));
        }
        
        return {
          'success': true,
          'message': data['message'] ?? 'Password changed successfully',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Failed to change password',
        };
      }
    } catch (e) {
      AppLogger.error('Change password error', tag: 'AuthService', error: e);
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }
  
  // Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_data');
  }
  
  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null;
  }
  
  // Get user profile from backend
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final token = await getAccessToken();
      
      if (token == null) {
        return null;
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/profile/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshToken();
        if (refreshed) {
          return getUserProfile(); // Retry with new token
        } else {
          // Only logout if refresh fails
          await logout();
        }
      }
      
      return null;
    } catch (e) {
      AppLogger.error('getUserProfile error', tag: 'AuthService', error: e);
      return null;
    }
  }
  
  // Create new user (Admin only)
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    try {
      final token = await getAccessToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated'
        };
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/users/create/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(userData),
      );
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
          'user_id': data['user_id']
        };
      } else {
        // Handle HTML error pages (Django errors)
        if (response.body.trim().startsWith('<') || response.body.trim().startsWith('<!DOCTYPE')) {
          return {
            'success': false,
            'message': 'Server error (HTTP ${response.statusCode}). Please check if Django server is running.'
          };
        }
        try {
          final error = jsonDecode(response.body);
          return {
            'success': false,
            'message': error['error'] ?? 'Failed to create user (HTTP ${response.statusCode})'
          };
        } catch (jsonError) {
          return {
            'success': false,
            'message': 'Failed to create user (HTTP ${response.statusCode}): ${response.body.substring(0, 100)}'
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}'
      };
    }
  }
  
  // Get all users (Admin only)
  Future<List<dynamic>?> getAllUsers() async {
    try {
      final token = await getAccessToken();
      
      if (token == null) {
        return null;
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/users/list/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['users'];
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get users with proper response format (Admin only)
  Future<Map<String, dynamic>> getUsers() async {
    try {
      final token = await getAccessToken();
      
      print('DEBUG: Getting users...');
      print('DEBUG: Token exists: ${token != null}');
      
      if (token == null) {
        print('DEBUG: No token found');
        return {
          'success': false,
          'message': 'Not authenticated - please login again',
          'users': []
        };
      }
      
      final url = '$baseUrl/users/list/';
      print('DEBUG: Calling API: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'users': data['users'] ?? [],
          'message': 'Users loaded successfully'
        };
      } else if (response.statusCode == 401) {
        print('DEBUG: Token expired, attempting refresh...');
        // Token expired, try to refresh
        final refreshed = await refreshToken();
        if (refreshed) {
          print('DEBUG: Token refreshed, retrying...');
          return getUsers(); // Retry with new token
        }
        print('DEBUG: Token refresh failed');
        return {
          'success': false,
          'message': 'Authentication failed - please login again',
          'users': []
        };
      } else {
        try {
          final error = jsonDecode(response.body);
          return {
            'success': false,
            'message': error['error'] ?? 'Failed to load users (${response.statusCode})',
            'users': []
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Failed to load users (${response.statusCode}): ${response.body}',
            'users': []
          };
        }
      }
    } catch (e) {
      print('DEBUG: Exception in getUsers: $e');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
        'users': []
      };
    }
  }

  // Update user (Admin only)
  Future<Map<String, dynamic>> updateUser(int userId, Map<String, dynamic> userData) async {
    try {
      final token = await getAccessToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated'
        };
      }
      
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/update/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(userData),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'User updated successfully',
          'user': data['user']
        };
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshToken();
        if (refreshed) {
          return updateUser(userId, userData); // Retry with new token
        }
        return {
          'success': false,
          'message': 'Authentication failed'
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Failed to update user'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}'
      };
    }
  }

  // Delete user (Admin only)
  Future<Map<String, dynamic>> deleteUser(int userId) async {
    try {
      final token = await getAccessToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated'
        };
      }
      
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId/delete/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'User deleted successfully'
        };
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshToken();
        if (refreshed) {
          return deleteUser(userId); // Retry with new token
        }
        return {
          'success': false,
          'message': 'Authentication failed'
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Failed to delete user'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}'
      };
    }
  }

  // Update own profile
  Future<Map<String, dynamic>> updateOwnProfile(Map<String, dynamic> profileData) async {
    try {
      final token = await getAccessToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated'
        };
      }
      
      AppLogger.apiRequest('POST', '$baseUrl/profile/update/');
      final response = await http.post(
        Uri.parse('$baseUrl/profile/update/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(profileData),
      );
      
      AppLogger.apiResponse('$baseUrl/profile/update/', response.statusCode);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Update stored user data
        if (data['user'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', jsonEncode(data['user']));
        }
        
        return {
          'success': true,
          'message': data['message'] ?? 'Profile updated successfully',
          'user': data['user']
        };
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshToken();
        if (refreshed) {
          return updateOwnProfile(profileData); // Retry with new token
        }
        return {
          'success': false,
          'message': 'Authentication failed'
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Failed to update profile'
        };
      }
    } catch (e) {
      AppLogger.error('Update profile error', tag: 'AuthService', error: e);
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}'
      };
    }
  }

  // Update user profile (user_profile table)
  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      final token = await getAccessToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated'
        };
      }
      
      // Remove null values
      final data = Map<String, dynamic>.from(profileData);
      data.removeWhere((key, value) => value == null);
      
      AppLogger.apiRequest('POST', '$baseUrl/profile/update-full/', data: data);
      final response = await http.post(
        Uri.parse('$baseUrl/profile/update-full/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
      
      AppLogger.apiResponse('$baseUrl/profile/update-full/', response.statusCode);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Profile updated successfully',
          'profile': responseData['profile'],
        };
      } else if (response.statusCode == 401) {
        final refreshed = await refreshToken();
        if (refreshed) {
          return updateUserProfile(profileData);
        }
        return {
          'success': false,
          'message': 'Authentication failed'
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Failed to update profile'
        };
      }
    } catch (e) {
      AppLogger.error('Update user profile error', tag: 'AuthService', error: e);
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}'
      };
    }
  }

  // Reset user password to default (Admin only)
  Future<Map<String, dynamic>> resetUserPassword(int userId) async {
    try {
      final token = await getAccessToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated'
        };
      }
      
      AppLogger.apiRequest('POST', '$baseUrl/users/$userId/reset-password/');
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/reset-password/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      AppLogger.apiResponse('$baseUrl/users/$userId/reset-password/', response.statusCode);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Password reset to Pch@2026 successfully'
        };
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshToken();
        if (refreshed) {
          return resetUserPassword(userId); // Retry with new token
        }
        return {
          'success': false,
          'message': 'Authentication failed'
        };
      } else {
        // Check if response is HTML (error page)
        if (response.body.trim().startsWith('<')) {
          return {
            'success': false,
            'message': 'Server error: The endpoint returned an HTML page (status ${response.statusCode}). Please check if the backend endpoint exists.'
          };
        }
        try {
          final error = jsonDecode(response.body);
          return {
            'success': false,
            'message': error['error'] ?? 'Failed to reset password (status ${response.statusCode})'
          };
        } catch (jsonError) {
          return {
            'success': false,
            'message': 'Failed to reset password: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}'
          };
        }
      }
    } catch (e) {
      AppLogger.error('Reset password error', tag: 'AuthService', error: e);
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}'
      };
    }
  }

  // Upload profile photo
  Future<Map<String, dynamic>> uploadProfilePhoto(List<int> photoBytes, String filename) async {
    try {
      final token = await getAccessToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated'
        };
      }
      
      AppLogger.apiRequest('POST', '$baseUrl/profile/photo/');
      
      // Create multipart request for file upload
      final uri = Uri.parse('$baseUrl/profile/photo/');
      final request = http.MultipartRequest('POST', uri);
      
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add file with explicit content type
      request.files.add(http.MultipartFile.fromBytes(
        'photo',
        photoBytes,
        filename: filename,
        contentType: MediaType('image', 'jpeg'),
      ));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      AppLogger.apiResponse('$baseUrl/profile/photo/', response.statusCode);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Photo uploaded successfully',
          'photo_url': data['photo_url']
        };
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshToken();
        if (refreshed) {
          return uploadProfilePhoto(photoBytes, filename); // Retry with new token
        }
        return {
          'success': false,
          'message': 'Authentication failed'
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Failed to upload photo'
        };
      }
    } catch (e) {
      AppLogger.error('Upload profile photo error', tag: 'AuthService', error: e);
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}'
      };
    }
  }

  // Delete profile photo
  Future<Map<String, dynamic>> deleteProfilePhoto() async {
    try {
      final token = await getAccessToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated'
        };
      }
      
      AppLogger.apiRequest('DELETE', '$baseUrl/profile/photo/delete/');
      final response = await http.delete(
        Uri.parse('$baseUrl/profile/photo/delete/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      AppLogger.apiResponse('$baseUrl/profile/photo/delete/', response.statusCode);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Photo deleted successfully'
        };
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshToken();
        if (refreshed) {
          return deleteProfilePhoto(); // Retry with new token
        }
        return {
          'success': false,
          'message': 'Authentication failed'
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Failed to delete photo'
        };
      }
    } catch (e) {
      AppLogger.error('Delete profile photo error', tag: 'AuthService', error: e);
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}'
      };
    }
  }

  // Check if user exists by username or email
  Future<Map<String, dynamic>> checkUserExists(String usernameOrEmail) async {
    try {
      AppLogger.apiRequest('POST', '$baseUrl/password-reset/verify-user/');
      final response = await http.post(
        Uri.parse('$baseUrl/password-reset/verify-user/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': usernameOrEmail.contains('@') ? null : usernameOrEmail,
          'email': usernameOrEmail.contains('@') ? usernameOrEmail : null,
        }),
      );
      
      AppLogger.apiResponse('$baseUrl/password-reset/verify-user/', response.statusCode);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'exists': data['exists'] ?? false,
          'email': data['email'],
          'message': data['message'] ?? 'User verification complete'
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'exists': false,
          'message': error['error'] ?? 'Verification failed'
        };
      }
    } catch (e) {
      AppLogger.error('Check user exists error', tag: 'AuthService', error: e);
      return {
        'success': false,
        'exists': false,
        'message': 'Connection error: ${e.toString()}'
      };
    }
  }

  // Request password reset OTP
  Future<Map<String, dynamic>> requestPasswordReset(String usernameOrEmail) async {
    try {
      AppLogger.apiRequest('POST', '$baseUrl/password-reset/request/');
      final response = await http.post(
        Uri.parse('$baseUrl/password-reset/request/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': usernameOrEmail.contains('@') ? null : usernameOrEmail,
          'email': usernameOrEmail.contains('@') ? usernameOrEmail : null,
        }),
      );
      
      AppLogger.apiResponse('$baseUrl/password-reset/request/', response.statusCode);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'OTP sent successfully',
          'email': data['email']
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Failed to send OTP'
        };
      }
    } catch (e) {
      AppLogger.error('Request password reset error', tag: 'AuthService', error: e);
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}'
      };
    }
  }

  // Verify OTP and reset password
  Future<Map<String, dynamic>> verifyOtpAndResetPassword({
    required String username,
    required String otpCode,
    required String newPassword,
  }) async {
    try {
      AppLogger.apiRequest('POST', '$baseUrl/password-reset/verify/');
      final response = await http.post(
        Uri.parse('$baseUrl/password-reset/verify/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'otp_code': otpCode,
          'new_password': newPassword,
        }),
      );
      
      AppLogger.apiResponse('$baseUrl/password-reset/verify/', response.statusCode);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Password reset successfully'
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Failed to reset password'
        };
      }
    } catch (e) {
      AppLogger.error('Verify OTP error', tag: 'AuthService', error: e);
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}'
      };
    }
  }
}
