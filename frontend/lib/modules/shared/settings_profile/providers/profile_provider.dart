import 'package:flutter/material.dart';
import '../../address/models/address_models.dart';
import '../../address/services/address_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/utils/logger.dart';

class ProfileProvider extends ChangeNotifier {
  // State
  bool _isEditing = false;
  bool _isLoading = false;

  // Controllers
  late TextEditingController firstnameController;
  late TextEditingController lastnameController;
  late TextEditingController middlenameController;
  late TextEditingController nameExtController;
  late TextEditingController emailController;
  late TextEditingController contactController;
  late TextEditingController birthdateController;
  late TextEditingController streetAddressController;
  late TextEditingController zipCodeController;
  late TextEditingController emergencyNameController;
  late TextEditingController emergencyNumberController;

  // Dropdown values
  String? selectedGender;
  String? selectedCivilStatus;
  String? selectedProvince;
  String? selectedCity;
  String? selectedBarangay;
  String? selectedRelationship;

  // Address data
  List<Province> provinces = [];
  List<City> cities = [];
  List<Barangay> barangays = [];

  // Options
  final List<String> genderOptions = ['Male', 'Female', 'Other'];
  final List<String> civilStatusOptions = ['Single', 'Married', 'Divorced', 'Widowed'];
  final List<String> relationshipOptions = ['Spouse', 'Parent', 'Child', 'Sibling', 'Friend', 'Other'];

  // Getters
  bool get isEditing => _isEditing;
  bool get isLoading => _isLoading;

  ProfileProvider() {
    _initializeControllers();
  }

  void _initializeControllers() {
    firstnameController = TextEditingController();
    lastnameController = TextEditingController();
    middlenameController = TextEditingController();
    nameExtController = TextEditingController();
    emailController = TextEditingController();
    contactController = TextEditingController();
    birthdateController = TextEditingController();
    streetAddressController = TextEditingController();
    zipCodeController = TextEditingController();
    emergencyNameController = TextEditingController();
    emergencyNumberController = TextEditingController();
  }

  void initializeWithData(Map<String, dynamic>? userData, Map<String, dynamic>? profileData) {
    if (userData != null) {
      firstnameController.text = userData['firstname'] ?? '';
      lastnameController.text = userData['lastname'] ?? '';
      middlenameController.text = userData['middlename'] ?? '';
      nameExtController.text = userData['name_ext'] ?? '';
      emailController.text = userData['email'] ?? '';
      contactController.text = userData['contact_number'] ?? '';
    }

    if (profileData != null) {
      birthdateController.text = profileData['birthdate'] ?? '';
      streetAddressController.text = profileData['street_address'] ?? '';
      zipCodeController.text = profileData['zip_code'] ?? '';
      emergencyNameController.text = profileData['emergency_contact_name'] ?? '';
      emergencyNumberController.text = profileData['emergency_contact_number'] ?? '';

      selectedGender = profileData['gender'];
      selectedCivilStatus = profileData['civil_status'];
      selectedProvince = profileData['province'];
      selectedCity = profileData['city_municipal'];
      selectedBarangay = profileData['barangay'];
      selectedRelationship = profileData['emergency_contact_relationship'];
    }

    loadAddressData();
  }

  void toggleEditing() {
    _isEditing = !_isEditing;
    notifyListeners();
  }

  Future<void> loadAddressData() async {
    try {
      final addressService = AddressService();
      provinces = await addressService.fetchProvinces();
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error loading provinces: $e', tag: 'ProfileProvider');
    }
  }

  Future<void> loadCities(String provinceCode) async {
    try {
      final addressService = AddressService();
      cities = await addressService.fetchCities(provinceCode: provinceCode);
      selectedCity = null;
      selectedBarangay = null;
      barangays = [];
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error loading cities: $e', tag: 'ProfileProvider');
    }
  }

  Future<void> loadBarangays(String cityCode) async {
    try {
      final addressService = AddressService();
      barangays = await addressService.fetchBarangays(cityCode: cityCode);
      selectedBarangay = null;
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error loading barangays: $e', tag: 'ProfileProvider');
    }
  }

  void updateGender(String? value) {
    selectedGender = value;
    notifyListeners();
  }

  void updateCivilStatus(String? value) {
    selectedCivilStatus = value;
    notifyListeners();
  }

  void updateProvince(String? value) {
    if (value != null) {
      selectedProvince = value;
      final province = provinces.firstWhere((p) => p.name == value);
      loadCities(province.code);
    }
  }

  void updateCity(String? value) {
    if (value != null) {
      selectedCity = value;
      final city = cities.firstWhere((c) => c.name == value);
      loadBarangays(city.code);
    }
  }

  void updateBarangay(String? value) {
    selectedBarangay = value;
    notifyListeners();
  }

  void updateRelationship(String? value) {
    selectedRelationship = value;
    notifyListeners();
  }

  Future<Map<String, dynamic>> saveProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final authService = AuthService();
      final result = await authService.updateUserProfile({
        'firstname': firstnameController.text.trim(),
        'lastname': lastnameController.text.trim(),
        'middlename': middlenameController.text.trim().isEmpty ? null : middlenameController.text.trim(),
        'email': emailController.text.trim(),
        'contact_number': contactController.text.trim().isEmpty ? null : contactController.text.trim(),
        'gender': selectedGender,
        'birthdate': birthdateController.text.trim().isEmpty ? null : birthdateController.text.trim(),
        'civil_status': selectedCivilStatus,
        'street_address': streetAddressController.text.trim().isEmpty ? null : streetAddressController.text.trim(),
        'barangay': selectedBarangay,
        'city_municipal': selectedCity,
        'province': selectedProvince,
        'zip_code': zipCodeController.text.trim().isEmpty ? null : zipCodeController.text.trim(),
        'emergency_contact_name': emergencyNameController.text.trim().isEmpty ? null : emergencyNameController.text.trim(),
        'emergency_contact_number': emergencyNumberController.text.trim().isEmpty ? null : emergencyNumberController.text.trim(),
        'emergency_contact_relationship': selectedRelationship,
      });

      return result;
    } catch (e) {
      AppLogger.error('Error saving profile: $e', tag: 'ProfileProvider');
      rethrow;
    } finally {
      _isLoading = false;
      _isEditing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    firstnameController.dispose();
    lastnameController.dispose();
    middlenameController.dispose();
    nameExtController.dispose();
    emailController.dispose();
    contactController.dispose();
    birthdateController.dispose();
    streetAddressController.dispose();
    zipCodeController.dispose();
    emergencyNameController.dispose();
    emergencyNumberController.dispose();
    super.dispose();
  }
}
