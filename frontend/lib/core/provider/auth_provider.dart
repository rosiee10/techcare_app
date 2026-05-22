import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../utils/request_debouncer.dart';

class AuthProvider with ChangeNotifier {
  static final AuthProvider _instance = AuthProvider._internal();
  
  final AuthService _authService = AuthService();
  final RequestDebouncer _debouncer = RequestDebouncer(delay: const Duration(seconds: 2));
  
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _permissions;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _initialized = false;
  DateTime? _lastProfileRefresh;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get userData => _userData;
  Map<String, dynamic>? get userProfile => _userProfile;
  Map<String, dynamic>? get permissions => _permissions;
  
  String? get username => _userData?['username'];
  String? get fullName => _userData != null 
      ? '${_userData!['firstname']} ${_userData!['lastname']}'
      : null;
  String? get role => _userData?['user_role'] ?? _userData?['role'];
  String? get deployment => _userData?['deployment'];
  String? get subRole => _userData?['sub_role'];
  bool get mustChangePassword => _userData?['must_change_pw'] == true || _userData?['must_change_pw'] == 1;
  bool get isActive => _userData?['is_active'] == true || _userData?['is_active'] == 1;
  
  bool get isAdmin => role == 'ADMIN';
  bool get isDoctor => role == 'DOCTOR';
  bool get isNurse => role == 'NURSE';

  // Singleton factory
  factory AuthProvider() {
    return _instance;
  }

  AuthProvider._internal() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    if (_initialized) return;
    _initialized = true;
    await _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();
    
    final isAuth = await _authService.isAuthenticated();
    if (isAuth) {
      _userData = await _authService.getCurrentUser();
      _isAuthenticated = _userData != null;
      
      // Fetch full profile with permissions
      if (_isAuthenticated) {
        await refreshProfile();
      }
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    
    final result = await _authService.login(username, password);
    
    if (result['success']) {
      _userData = result['user'];
      _isAuthenticated = true;
      
      // Fetch permissions
      await refreshProfile();
    }
    
    _isLoading = false;
    notifyListeners();
    
    return result;
  }

  Future<void> refreshProfile() async {
    // Prevent rapid repeated calls within 2 seconds
    final now = DateTime.now();
    if (_lastProfileRefresh != null && 
        now.difference(_lastProfileRefresh!).inSeconds < 2) {
      return;
    }
    
    _lastProfileRefresh = now;
    
    try {
      final profile = await _authService.getUserProfile();
      if (profile != null) {
        _userData = profile['user'];
        _userProfile = profile['profile'];
        _permissions = profile['permissions'];
        notifyListeners();
      }
    } catch (e) {
      // Log error but don't logout on transient errors
      print('Error refreshing profile: $e');
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await _authService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    
    if (result['success']) {
      // Refresh user data to update must_change_pw flag
      _userData = await _authService.getCurrentUser();
      notifyListeners();
    }
    
    return result;
  }

  Future<void> logout() async {
    await _authService.logout();
    
    _userData = null;
    _permissions = null;
    _isAuthenticated = false;
    
    notifyListeners();
  }

  // Update user data (used after profile update)
  void updateUserData(Map<String, dynamic> userData) {
    _userData = userData;
    notifyListeners();
  }

  // Update user profile data (used after profile update)
  void updateUserProfile(Map<String, dynamic> userProfile) {
    _userProfile = userProfile;
    notifyListeners();
  }

  bool hasPermission(String permission) {
    return _permissions?[permission] == true;
  }

  bool canManageUsers() => hasPermission('can_manage_users');
  bool canViewPatients() => hasPermission('can_view_patients');
  bool canPrescribe() => hasPermission('can_prescribe');
  bool canDispenseMeds() => hasPermission('can_dispense_meds');
}
