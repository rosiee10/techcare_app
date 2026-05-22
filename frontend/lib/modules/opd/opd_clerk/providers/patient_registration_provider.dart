import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/patient_service.dart';

class PatientRegistrationProvider extends ChangeNotifier {
  // Form key for validation
  final formKey = GlobalKey<FormState>();
  // Controllers
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController extensionController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController religionController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController purokController = TextEditingController();
  final TextEditingController emergencyNameController = TextEditingController();
  final TextEditingController emergencyContactController = TextEditingController();
  final TextEditingController emergencyPurokController = TextEditingController();

  // Patient Address
  String? selectedProvinceCode;
  String? selectedProvinceName;
  String? selectedCityCode;
  String? selectedCityName;
  String? selectedBarangayCode;
  String? selectedBarangayName;

  // Emergency Address
  String? emergencyProvinceCode;
  String? emergencyProvinceName;
  String? emergencyCityCode;
  String? emergencyCityName;
  String? emergencyBarangayCode;
  String? emergencyBarangayName;

  // Dropdown values
  String selectedGender = '';
  String selectedCivilStatus = '';
  String selectedRelationship = '';

  // Photo
  String? uploadedPhotoUrl;

  // Error states
  bool genderError = false;
  bool civilStatusError = false;
  bool provinceError = false;
  bool cityError = false;
  bool barangayError = false;
  bool emergencyNameError = false;
  bool emergencyRelationshipError = false;
  bool emergencyContactError = false;
  bool emergencyProvinceError = false;
  bool emergencyCityError = false;
  bool emergencyBarangayError = false;

  // Loading state
  bool isLoading = false;

  // Getters
  bool get hasErrors =>
      genderError ||
      civilStatusError ||
      provinceError ||
      cityError ||
      barangayError ||
      emergencyNameError ||
      emergencyRelationshipError ||
      emergencyContactError ||
      emergencyProvinceError ||
      emergencyCityError ||
      emergencyBarangayError;

  // Setters with error clearing
  void setGender(String value) {
    selectedGender = value;
    genderError = false;
    notifyListeners();
  }

  void setCivilStatus(String value) {
    selectedCivilStatus = value;
    civilStatusError = false;
    notifyListeners();
  }

  void setRelationship(String value) {
    selectedRelationship = value;
    emergencyRelationshipError = false;
    notifyListeners();
  }

  void setPhotoUrl(String? photoUrl) {
    print('DEBUG: setPhotoUrl called with photoUrl=$photoUrl');
    uploadedPhotoUrl = photoUrl;
    print('DEBUG: uploadedPhotoUrl is now=$uploadedPhotoUrl');
    notifyListeners();
  }

  void clearPhoto() {
    uploadedPhotoUrl = null;
    notifyListeners();
  }

  // Address setters
  void setPatientProvince(String? code, String? name) {
    selectedProvinceCode = code;
    selectedProvinceName = name;
    provinceError = false;
    notifyListeners();
  }

  void setPatientCity(String? code, String? name) {
    selectedCityCode = code;
    selectedCityName = name;
    cityError = false;
    notifyListeners();
  }

  void setPatientBarangay(String? code, String? name) {
    selectedBarangayCode = code;
    selectedBarangayName = name;
    barangayError = false;
    notifyListeners();
  }

  void setEmergencyProvince(String? code, String? name) {
    emergencyProvinceCode = code;
    emergencyProvinceName = name;
    emergencyProvinceError = false;
    notifyListeners();
  }

  void setEmergencyCity(String? code, String? name) {
    emergencyCityCode = code;
    emergencyCityName = name;
    emergencyCityError = false;
    notifyListeners();
  }

  void setEmergencyBarangay(String? code, String? name) {
    emergencyBarangayCode = code;
    emergencyBarangayName = name;
    emergencyBarangayError = false;
    notifyListeners();
  }

  // Validation
  bool validate() {
    genderError = selectedGender.isEmpty;
    civilStatusError = selectedCivilStatus.isEmpty;
    provinceError = selectedProvinceName == null || selectedProvinceName!.isEmpty;
    cityError = selectedCityName == null || selectedCityName!.isEmpty;
    barangayError = selectedBarangayName == null || selectedBarangayName!.isEmpty;
    emergencyNameError = emergencyNameController.text.isEmpty;
    emergencyRelationshipError = selectedRelationship.isEmpty;
    emergencyContactError = emergencyContactController.text.isEmpty;
    emergencyProvinceError = emergencyProvinceName == null || emergencyProvinceName!.isEmpty;
    emergencyCityError = emergencyCityName == null || emergencyCityName!.isEmpty;
    emergencyBarangayError = emergencyBarangayName == null || emergencyBarangayName!.isEmpty;

    notifyListeners();
    return !hasErrors;
  }

  // Reset form
  void reset() {
    lastNameController.clear();
    firstNameController.clear();
    middleNameController.clear();
    extensionController.clear();
    dobController.clear();
    religionController.clear();
    contactController.clear();
    purokController.clear();
    emergencyNameController.clear();
    emergencyContactController.clear();
    emergencyPurokController.clear();

    selectedProvinceCode = null;
    selectedProvinceName = null;
    selectedCityCode = null;
    selectedCityName = null;
    selectedBarangayCode = null;
    selectedBarangayName = null;

    emergencyProvinceCode = null;
    emergencyProvinceName = null;
    emergencyCityCode = null;
    emergencyCityName = null;
    emergencyBarangayCode = null;
    emergencyBarangayName = null;

    selectedGender = '';
    selectedCivilStatus = '';
    selectedRelationship = '';
    uploadedPhotoUrl = null;

    _clearErrors();
    notifyListeners();
  }

  void _clearErrors() {
    genderError = false;
    civilStatusError = false;
    provinceError = false;
    cityError = false;
    barangayError = false;
    emergencyNameError = false;
    emergencyRelationshipError = false;
    emergencyContactError = false;
    emergencyProvinceError = false;
    emergencyCityError = false;
    emergencyBarangayError = false;
  }

  bool hasValidationErrors = false;

  void _validateDropdowns() {
    hasValidationErrors = false;
    
    genderError = selectedGender.isEmpty;
    if (genderError) hasValidationErrors = true;
    
    civilStatusError = selectedCivilStatus.isEmpty;
    if (civilStatusError) hasValidationErrors = true;
    
    emergencyRelationshipError = selectedRelationship.isEmpty;
    if (emergencyRelationshipError) hasValidationErrors = true;
    
    provinceError = selectedProvinceName == null || selectedProvinceName!.isEmpty;
    if (provinceError) hasValidationErrors = true;
    
    cityError = selectedCityName == null || selectedCityName!.isEmpty;
    if (cityError) hasValidationErrors = true;
    
    barangayError = selectedBarangayName == null || selectedBarangayName!.isEmpty;
    if (barangayError) hasValidationErrors = true;
    
    emergencyProvinceError = emergencyProvinceName == null || emergencyProvinceName!.isEmpty;
    if (emergencyProvinceError) hasValidationErrors = true;
    
    emergencyCityError = emergencyCityName == null || emergencyCityName!.isEmpty;
    if (emergencyCityError) hasValidationErrors = true;
    
    emergencyBarangayError = emergencyBarangayName == null || emergencyBarangayName!.isEmpty;
    if (emergencyBarangayError) hasValidationErrors = true;
    
    notifyListeners();
  }

  // Registration
  Future<Map<String, dynamic>> registerPatient() async {
    // Validate form fields first
    final isValid = formKey.currentState?.validate() ?? false;
    
    // Validate dropdowns
    _validateDropdowns();
    
    if (!isValid || hasValidationErrors) {
      return {'success': false, 'error': 'Please fill in all required fields'};
    }

    isLoading = true;
    notifyListeners();

    try {
      final patientData = {
        'lastname': lastNameController.text,
        'firstname': firstNameController.text,
        'middlename': middleNameController.text,
        'ext': extensionController.text,
        'birthdate': dobController.text,
        'gender': selectedGender.toUpperCase(),
        'civil_status': selectedCivilStatus.toUpperCase(),
        'religion': religionController.text,
        'contact_number': contactController.text,
        'purok': purokController.text,
        'barangay': selectedBarangayName,
        'city_municipal': selectedCityName,
        'province': selectedProvinceName,
        'current_status': 'OUTPATIENT',
        'emergency_name': emergencyNameController.text,
        'emergency_relationship': selectedRelationship.toUpperCase(),
        'emergency_contact': emergencyContactController.text,
        'emergency_purok': emergencyPurokController.text,
        'emergency_barangay': emergencyBarangayName,
        'emergency_city': emergencyCityName,
        'emergency_province': emergencyProvinceName,
      };

      // Add photo URL if available
      if (uploadedPhotoUrl != null && uploadedPhotoUrl!.isNotEmpty) {
        patientData['photo_url'] = uploadedPhotoUrl;
      }

      final result = await PatientService().registerPatient(
        patientData: patientData,
      );

      isLoading = false;
      notifyListeners();

      if (result['success'] == true) {
        reset();
      }

      return result;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      return {'success': false, 'error': 'Error registering patient: $e'};
    }
  }

  @override
  void dispose() {
    lastNameController.dispose();
    firstNameController.dispose();
    middleNameController.dispose();
    extensionController.dispose();
    dobController.dispose();
    religionController.dispose();
    contactController.dispose();
    purokController.dispose();
    emergencyNameController.dispose();
    emergencyContactController.dispose();
    emergencyPurokController.dispose();
    super.dispose();
  }
}
