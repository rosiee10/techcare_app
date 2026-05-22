import 'package:flutter/foundation.dart';
import '../services/chief_nurse_service.dart';

class ChiefNurseProvider with ChangeNotifier {
  final ChiefNurseService _chiefNurseService = ChiefNurseService();

  Map<String, dynamic> _stats = {};
  List<dynamic> _wards = [];
  List<dynamic> _nurses = [];
  List<dynamic> _patients = [];
  List<dynamic> _beds = [];
  List<dynamic> _schedules = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, dynamic> get stats => _stats;
  List<dynamic> get wards => _wards;
  List<dynamic> get nurses => _nurses;
  List<dynamic> get patients => _patients;
  List<dynamic> get beds => _beds;
  List<dynamic> get schedules => _schedules;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load dashboard stats
  Future<void> loadDashboardStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _chiefNurseService.getDashboardStats();

    if (result['success']) {
      _stats = result['stats'] ?? {};
    } else {
      _error = result['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load wards
  Future<void> loadWards() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _chiefNurseService.getWards();

    if (result['success']) {
      _wards = result['wards'] ?? [];
    } else {
      _error = result['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load nurse assignments
  Future<void> loadNurseAssignments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _chiefNurseService.getNurseAssignments();

    if (result['success']) {
      _nurses = result['nurses'] ?? [];
    } else {
      _error = result['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load patient status
  Future<void> loadPatientStatus() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _chiefNurseService.getPatientStatus();

    if (result['success']) {
      _patients = result['patients'] ?? [];
    } else {
      _error = result['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load beds
  Future<void> loadBeds({String? wardId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _chiefNurseService.getBeds(wardId: wardId);

    if (result['success']) {
      _beds = result['beds'] ?? [];
    } else {
      _error = result['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load nursing schedules
  Future<void> loadSchedules({String? date}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _chiefNurseService.getNursingSchedule(date: date);

    if (result['success']) {
      _schedules = result['schedules'] ?? [];
    } else {
      _error = result['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Clear data (used on logout)
  void clearData() {
    _stats = {};
    _wards = [];
    _nurses = [];
    _patients = [];
    _beds = [];
    _schedules = [];
    _error = null;
    notifyListeners();
  }
}
