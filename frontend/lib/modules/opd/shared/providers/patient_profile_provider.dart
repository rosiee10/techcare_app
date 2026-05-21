import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/services/auth_service.dart';
import '../../opd_clerk/data/models/patient_model.dart';
import '../../opd_clerk/providers/patient_list_provider.dart';

/// Provider for managing patient profile state
class PatientProfileProvider extends ChangeNotifier {
  final String hospitalId;
  final PatientListProvider _patientProvider;
  
  PatientModel? _patient;
  bool _isLoading = true;
  bool _showVisitHistory = false;
  String? _editingBirthDate;
  
  // Address state for edit dialog
  String? _dialogProvinceCode;
  String? _dialogCityCode;
  String? _dialogBarangayCode;
  bool _dialogAddressLoaded = false;
  
  // Field controllers for edit mode
  final Map<String, TextEditingController> _fieldControllers = {};

  PatientProfileProvider({
    required this.hospitalId,
    PatientListProvider? patientProvider,
  }) : _patientProvider = patientProvider ?? PatientListProvider() {
    _loadPatient();
  }

  // Getters
  PatientModel? get patient => _patient;
  bool get isLoading => _isLoading;
  bool get showVisitHistory => _showVisitHistory;
  String? get editingBirthDate => _editingBirthDate;
  String? get dialogProvinceCode => _dialogProvinceCode;
  String? get dialogCityCode => _dialogCityCode;
  String? get dialogBarangayCode => _dialogBarangayCode;
  bool get dialogAddressLoaded => _dialogAddressLoaded;
  Map<String, TextEditingController> get fieldControllers => _fieldControllers;

  /// Load patient data
  Future<void> _loadPatient() async {
    try {
      await _patientProvider.loadPatients();
      PatientModel? patient;
      try {
        patient = _patientProvider.patients.firstWhere(
          (p) => p.hospitalId == hospitalId,
        );
      } catch (e) {
        patient = null;
      }
      _patient = patient;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle visit history view
  void toggleVisitHistory() {
    _showVisitHistory = !_showVisitHistory;
    notifyListeners();
  }

  void setShowVisitHistory(bool value) {
    _showVisitHistory = value;
    notifyListeners();
  }

  /// Set editing birth date
  void setEditingBirthDate(String? date) {
    _editingBirthDate = date;
    notifyListeners();
  }

  /// Set address codes for edit dialog
  void setDialogAddressCodes({
    String? provinceCode,
    String? cityCode,
    String? barangayCode,
  }) {
    _dialogProvinceCode = provinceCode ?? _dialogProvinceCode;
    _dialogCityCode = cityCode ?? _dialogCityCode;
    _dialogBarangayCode = barangayCode ?? _dialogBarangayCode;
    notifyListeners();
  }

  void markDialogAddressLoaded() {
    _dialogAddressLoaded = true;
    notifyListeners();
  }

  void resetDialogAddressState() {
    _dialogProvinceCode = null;
    _dialogCityCode = null;
    _dialogBarangayCode = null;
    _dialogAddressLoaded = false;
    notifyListeners();
  }

  /// Get or create field controller
  TextEditingController getFieldController(String key, String initialValue) {
    if (!_fieldControllers.containsKey(key)) {
      _fieldControllers[key] = TextEditingController(text: initialValue);
    }
    return _fieldControllers[key]!;
  }

  /// Get display name with middle initial
  String getDisplayNameWithInitial() {
    if (_patient == null) return '';
    final middleInitial = _patient!.middleName != null && _patient!.middleName!.isNotEmpty
        ? ' ${_patient!.middleName![0].toUpperCase()}'
        : '';
    final ext = _patient!.extension != null && _patient!.extension!.isNotEmpty
        ? ' ${_patient!.extension}'
        : '';
    return '${_patient!.lastName}, ${_patient!.firstName}$middleInitial$ext';
  }

  /// Refresh patient data
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    await _loadPatient();
  }

  /// Update patient information
  Future<http.Response> updatePatient(String patientId, Map<String, dynamic> updateData) async {
    try {
      final token = await AuthService().getAccessToken();
      final url = Uri.parse('${ApiConstants.baseUrl}/api/patients/$patientId/');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        // Refresh patient data after successful update
        await refresh();
      }

      return response;
    } catch (e) {
      throw Exception('Failed to update patient: $e');
    }
  }

  @override
  void dispose() {
    for (var controller in _fieldControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
