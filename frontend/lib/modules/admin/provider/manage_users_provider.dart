import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/logger.dart';
import '../models/user_model.dart';

/// Provider for managing user operations with state management
/// Follows OOP principles and separation of concerns
class ManageUsersProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  // State variables
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedRole = 'All Roles';
  String _selectedStatus = 'All Status';
  
  // Pagination variables
  int _currentPage = 1;
  int _itemsPerPage = 10;

  // Getters
  List<UserModel> get users => _getPaginatedUsers();
  List<UserModel> get allFilteredUsers => _filteredUsers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedRole => _selectedRole;
  String get selectedStatus => _selectedStatus;
  int get totalUsers => _users.length;
  int get activeUsers => _users.where((u) => u.isActive).length;
  int get currentPage => _currentPage;
  int get itemsPerPage => _itemsPerPage;
  int get totalPages => (_filteredUsers.length / _itemsPerPage).ceil();
  int get totalFilteredUsers => _filteredUsers.length;
  
  /// Get paginated users for current page
  List<UserModel> _getPaginatedUsers() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    
    if (startIndex >= _filteredUsers.length) {
      return [];
    }
    
    return _filteredUsers.sublist(
      startIndex,
      endIndex > _filteredUsers.length ? _filteredUsers.length : endIndex,
    );
  }
  
  /// Go to specific page
  void goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      _currentPage = page;
      notifyListeners();
    }
  }
  
  /// Go to next page
  void nextPage() {
    if (_currentPage < totalPages) {
      _currentPage++;
      notifyListeners();
    }
  }
  
  /// Go to previous page
  void previousPage() {
    if (_currentPage > 1) {
      _currentPage--;
      notifyListeners();
    }
  }
  
  /// Change items per page
  void changeItemsPerPage(int items) {
    _itemsPerPage = items;
    _currentPage = 1; // Reset to first page
    notifyListeners();
  }

  /// Load all users from the API
  Future<void> loadUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      AppLogger.info('Loading users...', tag: 'ManageUsersProvider');
      final response = await _authService.getUsers();
      
      AppLogger.info('Response received - success: ${response['success']}', tag: 'ManageUsersProvider');
      AppLogger.debug('Message: ${response['message']}', tag: 'ManageUsersProvider');
      
      if (response['success']) {
        final usersList = response['users'] as List;
        AppLogger.info('Found ${usersList.length} users', tag: 'ManageUsersProvider');
        
        _users = usersList
            .map((json) => UserModel.fromJson(json))
            .toList();
        _applyFilters();
        AppLogger.info('Users loaded successfully', tag: 'ManageUsersProvider');
      } else {
        _errorMessage = response['message'] ?? 'Failed to load users';
        AppLogger.error('Error - $_errorMessage', tag: 'ManageUsersProvider');
      }
    } catch (e) {
      _errorMessage = 'Error loading users: $e';
      AppLogger.error('Exception while loading users', tag: 'ManageUsersProvider', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new user
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    try {
      // Validate input
      final validation = _validateUserData(userData);
      if (!validation['valid']) {
        return {
          'success': false,
          'message': validation['message'],
        };
      }

      final response = await _authService.createUser(userData);
      
      if (response['success']) {
        await loadUsers(); // Reload users after creation
      }
      
      return response;
    } catch (e) {
      AppLogger.error('Error creating user', tag: 'ManageUsersProvider', error: e);
      return {
        'success': false,
        'message': 'Error creating user: $e',
      };
    }
  }

  /// Update an existing user
  Future<Map<String, dynamic>> updateUser(int userId, Map<String, dynamic> userData) async {
    try {
      // Validate input
      final validation = _validateUserData(userData, isUpdate: true);
      if (!validation['valid']) {
        return {
          'success': false,
          'message': validation['message'],
        };
      }

      final response = await _authService.updateUser(userId, userData);
      
      if (response['success']) {
        await loadUsers(); // Reload users after update
      }
      
      return response;
    } catch (e) {
      AppLogger.error('Error updating user', tag: 'ManageUsersProvider', error: e);
      return {
        'success': false,
        'message': 'Error updating user: $e',
      };
    }
  }

  /// Delete a user
  Future<Map<String, dynamic>> deleteUser(int userId) async {
    try {
      final response = await _authService.deleteUser(userId);
      
      if (response['success']) {
        await loadUsers(); // Reload users after deletion
      }
      
      return response;
    } catch (e) {
      AppLogger.error('Error deleting user', tag: 'ManageUsersProvider', error: e);
      return {
        'success': false,
        'message': 'Error deleting user: $e',
      };
    }
  }

  /// Toggle user active status
  Future<Map<String, dynamic>> toggleUserStatus(int userId, bool isActive) async {
    try {
      final response = await _authService.updateUser(userId, {'is_active': isActive});
      
      if (response['success']) {
        await loadUsers(); // Reload users after status change
      }
      
      return response;
    } catch (e) {
      AppLogger.error('Error toggling user status', tag: 'ManageUsersProvider', error: e);
      return {
        'success': false,
        'message': 'Error toggling user status: $e',
      };
    }
  }

  /// Reset user password to default (Pch@2026)
  Future<Map<String, dynamic>> resetUserPassword(int userId) async {
    try {
      final response = await _authService.resetUserPassword(userId);
      
      if (response['success']) {
        await loadUsers(); // Reload users after password reset
      }
      
      return response;
    } catch (e) {
      AppLogger.error('Error resetting user password', tag: 'ManageUsersProvider', error: e);
      return {
        'success': false,
        'message': 'Error resetting user password: $e',
      };
    }
  }

  /// Update search query and apply filters
  void updateSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  /// Update role filter and apply filters
  void updateRoleFilter(String role) {
    _selectedRole = role;
    _applyFilters();
  }

  /// Update status filter and apply filters
  void updateStatusFilter(String status) {
    _selectedStatus = status;
    _applyFilters();
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedRole = 'All Roles';
    _selectedStatus = 'All Status';
    _applyFilters();
  }

  /// Apply all active filters to the user list
  void _applyFilters() {
    _filteredUsers = _users.where((user) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          user.fullName.toLowerCase().contains(_searchQuery) ||
          user.username.toLowerCase().contains(_searchQuery) ||
          user.email.toLowerCase().contains(_searchQuery);

      // Role filter
      final matchesRole = _selectedRole == 'All Roles' || user.role == _selectedRole;

      // Status filter
      final matchesStatus = _selectedStatus == 'All Status' ||
          (_selectedStatus == 'Active' && user.isActive) ||
          (_selectedStatus == 'Inactive' && !user.isActive);

      return matchesSearch && matchesRole && matchesStatus;
    }).toList();

    notifyListeners();
  }

  /// Validate user data before submission
  /// Returns a map with 'valid' boolean and 'message' string
  Map<String, dynamic> _validateUserData(Map<String, dynamic> data, {bool isUpdate = false}) {
    // Required fields validation
    if (!isUpdate) {
      if (data['username'] == null || data['username'].toString().trim().isEmpty) {
        return {'valid': false, 'message': 'Username is required'};
      }
      if (data['password'] == null || data['password'].toString().trim().isEmpty) {
        return {'valid': false, 'message': 'Password is required'};
      }
    }

    if (data['firstname'] == null || data['firstname'].toString().trim().isEmpty) {
      return {'valid': false, 'message': 'First name is required'};
    }

    if (data['lastname'] == null || data['lastname'].toString().trim().isEmpty) {
      return {'valid': false, 'message': 'Last name is required'};
    }

    if (data['email'] == null || data['email'].toString().trim().isEmpty) {
      return {'valid': false, 'message': 'Email is required'};
    }

    if (data['user_role'] == null || data['user_role'].toString().trim().isEmpty) {
      return {'valid': false, 'message': 'Role is required'};
    }

    // Email format validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(data['email'].toString())) {
      return {'valid': false, 'message': 'Invalid email format'};
    }

    // Password strength validation (only for new users or password updates)
    if (!isUpdate && data['password'] != null) {
      final password = data['password'].toString();
      if (password.length < 8) {
        return {'valid': false, 'message': 'Password must be at least 8 characters'};
      }
      if (!password.contains(RegExp(r'[A-Z]'))) {
        return {'valid': false, 'message': 'Password must contain at least one uppercase letter'};
      }
      if (!password.contains(RegExp(r'[a-z]'))) {
        return {'valid': false, 'message': 'Password must contain at least one lowercase letter'};
      }
      if (!password.contains(RegExp(r'[0-9]'))) {
        return {'valid': false, 'message': 'Password must contain at least one number'};
      }
      if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
        return {'valid': false, 'message': 'Password must contain at least one special character'};
      }
    }

    // Contact number validation (if provided)
    if (data['contact_no'] != null && data['contact_no'].toString().isNotEmpty) {
      final contact = data['contact_no'].toString();
      if (!RegExp(r'^[0-9+\-\s()]+$').hasMatch(contact)) {
        return {'valid': false, 'message': 'Invalid contact number format'};
      }
    }

    return {'valid': true, 'message': 'Validation passed'};
  }

  /// Verify admin password for secure operations
  Future<bool> verifyAdminPassword(String password) async {
    try {
      final response = await _authService.verifyAdminPassword(password);
      return response['success'] ?? false;
    } catch (e) {
      AppLogger.error('Error verifying admin password', tag: 'ManageUsersProvider', error: e);
      return false;
    }
  }

  @override
  void dispose() {
    // Clean up resources
    super.dispose();
  }
}
