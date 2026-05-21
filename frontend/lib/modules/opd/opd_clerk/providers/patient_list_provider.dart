import 'package:flutter/material.dart';
import '../../../../core/services/patient_service.dart';
import '../../../../core/utils/logger.dart';
import '../data/models/patient_model.dart';

class PatientListProvider extends ChangeNotifier {
  // Services
  final PatientService _patientService = PatientService();

  // State
  List<PatientModel> _patients = [];
  List<PatientModel> _filteredPatients = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedStatus = 'All Status';
  int _currentPage = 1;
  int _rowsPerPage = 10;

  // Getters
  List<PatientModel> get patients => _filteredPatients;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedStatus => _selectedStatus;
  int get currentPage => _currentPage;
  int get rowsPerPage => _rowsPerPage;

  int get totalPatients => _patients.length;
  int get activePatients => _patients.where((p) => p.isActive).length;

  int get totalPages => (_filteredPatients.length / _rowsPerPage).ceil();
  List<PatientModel> get paginatedPatients {
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = startIndex + _rowsPerPage;
    if (startIndex >= _filteredPatients.length) return [];
    return _filteredPatients.sublist(
      startIndex,
      endIndex > _filteredPatients.length ? _filteredPatients.length : endIndex,
    );
  }

  // Load patients from API
  Future<void> loadPatients() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      AppLogger.info('Loading patients from API...', tag: 'PatientListProvider');
      
      final response = await _patientService.getPatients();
      
      if (response['success'] && (response['patients'] as List).isNotEmpty) {
        // API returned real data
        final patientsList = response['patients'] as List;
        AppLogger.info('Found ${patientsList.length} patients from API', tag: 'PatientListProvider');
        
        _patients = patientsList
            .map((json) => PatientModel.fromJson(json as Map<String, dynamic>))
            .toList();
        _applyFilters();
        AppLogger.info('Patients loaded successfully from API', tag: 'PatientListProvider');
      } else {
        // API failed - show error message
        _errorMessage = response['message'] ?? 'Failed to load patients from API';
        AppLogger.warning('API Error: $_errorMessage', tag: 'PatientListProvider');
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error loading patients: $e';
      AppLogger.error('Exception while loading patients', tag: 'PatientListProvider', error: e);
      notifyListeners();
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    _currentPage = 1;
    _applyFilters();
    notifyListeners();
  }

  void updateStatusFilter(String status) {
    _selectedStatus = status;
    _currentPage = 1;
    _applyFilters();
    notifyListeners();
  }

  void setPage(int page) {
    if (page < 1 || page > totalPages) return;
    _currentPage = page;
    notifyListeners();
  }

  void setRowsPerPage(int rows) {
    _rowsPerPage = rows;
    _currentPage = 1;
    notifyListeners();
  }

  void _applyFilters() {
    _filteredPatients = _patients.where((patient) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          patient.hospitalId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          patient.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          patient.patientId.contains(_searchQuery);

      // Status filter
      final matchesStatus = _selectedStatus == 'All Status' ||
          patient.status.toLowerCase() == _selectedStatus.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Update patient information
  Future<dynamic> updatePatient(String hospitalId, Map<String, dynamic> updateData) async {
    try {
      AppLogger.info('Updating patient $hospitalId', tag: 'PatientListProvider');
      
      final response = await _patientService.updatePatient(hospitalId, updateData);
      
      AppLogger.info('Patient $hospitalId updated successfully', tag: 'PatientListProvider');
      return response;
    } catch (e) {
      AppLogger.error('Error updating patient', tag: 'PatientListProvider', error: e);
      rethrow;
    }
  }

  // Mock data - replace with actual API
  List<PatientModel> _getMockPatients() {
    return [
      PatientModel(
        hospitalId: '00-00-01',
        patientId: '09171234567',
        lastName: 'dela Cruz',
        firstName: 'Juan',
        middleName: 'M.',
        age: 34,
        sex: 'Male',
        birthDate: '1991-05-15',
        lastVisit: 'Feb 26, 2026',
        department: 'FAMED',
        status: 'Outpatient',
        isActive: true,
      ),
      PatientModel(
        hospitalId: '00-00-02',
        patientId: '09171234568',
        lastName: 'Santos',
        firstName: 'Maria',
        middleName: 'L.',
        age: 28,
        sex: 'Female',
        birthDate: '1997-03-20',
        lastVisit: 'Mar 15, 2026',
        department: 'OPD',
        status: 'Inpatient',
        isActive: true,
      ),
      PatientModel(
        hospitalId: '00-00-03',
        patientId: '09171234569',
        lastName: 'Reyes',
        firstName: 'Pedro',
        middleName: 'A.',
        age: 45,
        sex: 'Male',
        birthDate: '1980-08-10',
        lastVisit: 'Jan 10, 2026',
        department: 'ER',
        status: 'Emergency',
        isActive: true,
      ),
    ];
  }
}
