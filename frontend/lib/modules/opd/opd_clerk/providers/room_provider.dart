import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/room_model.dart';
import '../models/service_model.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/services/auth_service.dart';

/// RoomProvider - State Management for Room Assignment
/// Implements Provider pattern for clean state management
class RoomProvider extends ChangeNotifier {
  // Private state
  final List<Room> _allRooms = [];
  final List<Room> _filteredRooms = [];
  final List<Service> _services = [];
  bool _isLoading = false;
  String? _error;

  // Getters - Encapsulation
  List<Room> get rooms {
    // If there's an active filter, return filtered results (even if empty)
    // Otherwise return all rooms
    if (_filteredRooms.isNotEmpty || _isFiltering) {
      return List.unmodifiable(_filteredRooms);
    }
    return List.unmodifiable(_allRooms);
  }
  
  bool _isFiltering = false;
  List<Service> get services => List.unmodifiable(_services);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Computed properties - DRY principle (always use _allRooms for stats)
  RoomStats get stats => RoomStats.fromRooms(_allRooms, totalServices: _services.length);
  int get totalRooms => _allRooms.length;
  int get openRooms => _allRooms.where((r) => r.isOpen).length;
  int get closedRooms => _allRooms.where((r) => r.isClosed).length;

  RoomProvider() {
    _initializeRooms();
  }

  /// Initialize and load rooms and services
  Future<void> _initializeRooms() async {
    final authService = AuthService();
    final token = await authService.getAccessToken();
    if (token != null) {
      await Future.wait([
        loadRooms(),
        loadServices(),
      ]);
    }
  }

  /// Load services from API
  Future<void> loadServices() async {
    try {
      final authService = AuthService();
      final token = await authService.getAccessToken();
      if (token == null) {
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConfig.opdServiceList),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _services.clear();
          for (var serviceData in data['data']) {
            _services.add(Service.fromJson(serviceData));
          }
          notifyListeners();
        }
      }
    } catch (e) {
      // Silently handle service loading errors
      debugPrint('Error loading services: $e');
    }
  }

  /// Load rooms from API
  Future<void> loadRooms() async {
    _setLoading(true);
    try {
      final authService = AuthService();
      final token = await authService.getAccessToken();
      if (token == null) {
        _setError('Not authenticated');
        _setLoading(false);
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConfig.roomList),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _allRooms.clear();
          _filteredRooms.clear();
          for (var roomData in data['data']) {
            _allRooms.add(Room.fromJson(roomData));
          }
          _clearError();
        } else {
          _setError(data['error'] ?? 'Failed to load rooms');
        }
      } else {
        _setError('Failed to load rooms: ${response.statusCode}');
      }
    } catch (e) {
      _setError('Error loading rooms: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Add new room
  Future<bool> addRoom(Room room) async {
    _setLoading(true);
    try {
      final authService = AuthService();
      final token = await authService.getAccessToken();
      if (token == null) {
        _setError('Not authenticated');
        return false;
      }

      final response = await http.post(
        Uri.parse(ApiConfig.roomList),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(room.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          await loadRooms(); // Reload to get updated list
          _clearError();
          return true;
        }
      }
      _setError('Failed to add room');
      return false;
    } catch (e) {
      _setError('Error adding room: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update existing room
  Future<bool> updateRoom(Room updatedRoom) async {
    _setLoading(true);
    try {
      final authService = AuthService();
      final token = await authService.getAccessToken();
      if (token == null) {
        _setError('Not authenticated');
        return false;
      }

      final roomId = int.tryParse(updatedRoom.id);
      if (roomId == null) {
        _setError('Invalid room ID');
        return false;
      }

      final response = await http.put(
        Uri.parse(ApiConfig.roomDetail(roomId)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(updatedRoom.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          await loadRooms(); // Reload to get updated list
          _clearError();
          return true;
        }
      }
      _setError('Failed to update room');
      return false;
    } catch (e) {
      _setError('Error updating room: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Toggle room status (Open/Closed)
  Future<bool> toggleRoomStatus(String roomId) async {
    final index = _allRooms.indexWhere((r) => r.id == roomId);
    if (index == -1) return false;

    final room = _allRooms[index];
    final newStatus = room.isOpen ? 'Closed' : 'Open';
    
    // Optimistic update
    _allRooms[index] = room.copyWith(status: newStatus);
    notifyListeners();

    try {
      final authService = AuthService();
      final token = await authService.getAccessToken();
      if (token == null) {
        _allRooms[index] = room; // Revert
        notifyListeners();
        return false;
      }

      final roomIdInt = int.tryParse(roomId);
      if (roomIdInt == null) return false;

      final response = await http.put(
        Uri.parse(ApiConfig.roomDetail(roomIdInt)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        return true;
      }
      
      // Revert on error
      _allRooms[index] = room;
      notifyListeners();
      return false;
    } catch (e) {
      // Revert on error
      _allRooms[index] = room;
      notifyListeners();
      return false;
    }
  }

  /// Delete room
  Future<bool> deleteRoom(String roomId) async {
    _setLoading(true);
    try {
      final authService = AuthService();
      final token = await authService.getAccessToken();
      if (token == null) {
        _setError('Not authenticated');
        return false;
      }

      final roomIdInt = int.tryParse(roomId);
      if (roomIdInt == null) {
        _setError('Invalid room ID');
        return false;
      }

      final url = ApiConfig.roomDetail(roomIdInt);
      print('[DEBUG] Deleting room - URL: $url, roomId: $roomId, roomIdInt: $roomIdInt');
      
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('[DEBUG] Delete response - Status: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('[DEBUG] Delete response data: $data');
        if (data['success'] == true) {
          print('[DEBUG] Delete successful, reloading rooms');
          await loadRooms(); // Reload to get updated list
          _clearError();
          return true;
        }
      }
      _setError('Failed to delete room: ${response.statusCode}');
      return false;
    } catch (e) {
      print('[DEBUG] Exception in deleteRoom: $e');
      _setError('Error deleting room: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get room by ID
  Room? getRoomById(String id) {
    try {
      return _allRooms.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  // Private helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// Clear error manually
  void clearError() {
    _clearError();
    notifyListeners();
  }

  /// Filter rooms by search query (code or name)
  void filterRooms(String query) {
    if (query.isEmpty) {
      // If search is empty, clear filter
      _filteredRooms.clear();
      _isFiltering = false;
    } else {
      // Filter rooms by code or name (case-insensitive)
      _isFiltering = true;
      _filteredRooms.clear();
      final filtered = _allRooms.where((room) {
        final searchLower = query.toLowerCase();
        return room.code.toLowerCase().contains(searchLower) ||
               room.name.toLowerCase().contains(searchLower);
      }).toList();
      _filteredRooms.addAll(filtered);
    }
    notifyListeners();
  }
}
