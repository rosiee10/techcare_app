import 'package:flutter/foundation.dart';
import '../services/patient_service.dart';

class PatientProvider with ChangeNotifier {
  final PatientService _patientService = PatientService();

  Map<String, dynamic>? _patientProfile;
  List<dynamic> _emergencyContacts = [];
  Map<String, dynamic> _stats = {};
  List<dynamic> _appointments = [];
  List<dynamic> _labResults = [];
  List<dynamic> _prescriptions = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, dynamic>? get patientProfile => _patientProfile;
  List<dynamic> get emergencyContacts => _emergencyContacts;
  Map<String, dynamic> get stats => _stats;
  List<dynamic> get appointments => _appointments;
  List<dynamic> get labResults => _labResults;
  List<dynamic> get prescriptions => _prescriptions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load patient profile
  Future<void> loadPatientProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _patientService.getPatientProfile();

    if (result['success']) {
      _patientProfile = result['patient'];
      _emergencyContacts = result['emergency_contacts'] ?? [];
    } else {
      _error = result['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load dashboard stats
  Future<void> loadDashboardStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _patientService.getDashboardStats();

    if (result['success']) {
      _stats = result['stats'] ?? {};
    } else {
      _error = result['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load appointments
  Future<void> loadAppointments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _patientService.getAppointments();

    if (result['success']) {
      _appointments = result['appointments'] ?? [];
    } else {
      _error = result['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load lab results
  Future<void> loadLabResults() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _patientService.getLabResults();

    if (result['success']) {
      _labResults = result['lab_results'] ?? [];
    } else {
      _error = result['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load prescriptions
  Future<void> loadPrescriptions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _patientService.getPrescriptions();

    if (result['success']) {
      _prescriptions = result['prescriptions'] ?? [];
    } else {
      _error = result['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Update profile
  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _patientService.updateProfile(profileData);

    if (result['success']) {
      // Reload profile after update
      await loadPatientProfile();
      return true;
    } else {
      _error = result['message'];
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear data (used on logout)
  void clearData() {
    _patientProfile = null;
    _emergencyContacts = [];
    _stats = {};
    _appointments = [];
    _labResults = [];
    _prescriptions = [];
    _error = null;
    notifyListeners();
  }
}
