import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../modules/shared/settings_profile/widgets/photo_viewer_widget.dart';
import '../../../../shared/address/widgets/address_dropdown.dart';
import '../../../../shared/address/services/address_service.dart';
import '../../../../shared/address/models/address_models.dart';
import '../../../opd_clerk/data/models/patient_model.dart';
import '../../providers/patient_profile_provider.dart';

/// Patient Information Dialog with view and edit modes
/// 
/// Features:
/// - View patient details in read-only mode
/// - Edit mode with form fields for all patient data
/// - Address dropdowns with Philippine geographic codes
/// - Emergency contact editing
/// - Save functionality with API integration
class PatientInfoDialog extends StatefulWidget {
  final PatientModel patient;
  final PatientProfileProvider? provider;

  const PatientInfoDialog({
    super.key,
    required this.patient,
    this.provider,
  });

  @override
  State<PatientInfoDialog> createState() => _PatientInfoDialogState();
}

class _PatientInfoDialogState extends State<PatientInfoDialog> {
  bool _isEditMode = false;
  String? _editingBirthDate;
  
  // Emergency contact address codes
  String? _emergencyProvinceCode;
  String? _emergencyCityCode;
  String? _emergencyBarangayCode;
  bool _hasInitiallyLoadedEmergencyAddress = false;
  
  // Patient address codes
  String? _dialogProvinceCode;
  String? _dialogCityCode;
  String? _dialogBarangayCode;
  bool _dialogAddressLoaded = false;
  
  // Field controllers
  final Map<String, TextEditingController> _fieldControllers = {};

  @override
  void initState() {
    super.initState();
    // Load address codes immediately when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialAddressCodes();
    });
  }

  Future<void> _loadInitialAddressCodes() async {
    final patient = widget.patient;
    
    // Load patient address
    if (!_dialogAddressLoaded && patient.province != null && patient.province!.isNotEmpty) {
      _dialogAddressLoaded = true;
      await _loadAddressCodesFromDatabase(patient);
    }
    
    // Load emergency contact address
    if (!_hasInitiallyLoadedEmergencyAddress && patient.emergencyContact?.province != null) {
      _hasInitiallyLoadedEmergencyAddress = true;
      await _loadEmergencyContactAddressCodesFromDatabase(patient);
    }
  }

  @override
  void dispose() {
    for (var controller in _fieldControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final patient = widget.patient;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 800,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(theme, patient),
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildContent(theme, patient),
                ),
              ),
            ),
            // Save/Cancel buttons in edit mode
            if (_isEditMode)
              _buildEditActions(theme, patient),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppThemeData theme, PatientModel patient) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Patient Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.grey[800],
            ),
          ),
          Row(
            children: [
              if (!_isEditMode)
                IconButton(
                  icon: const Icon(Icons.edit),
                  color: Colors.grey[600],
                  onPressed: () {
                    setState(() {
                      _isEditMode = true;
                      _resetAddressState();
                    });
                  },
                  tooltip: 'Edit',
                  splashRadius: 24,
                ),
              if (!_isEditMode)
                const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.close),
                color: Colors.grey[600],
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close',
                splashRadius: 24,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _resetAddressState() {
    // Don't reset the codes when entering edit mode - they were already loaded in initState
    // Only reset if we need to reload (e.g., after save)
    _editingBirthDate = null;
  }

  Widget _buildContent(AppThemeData theme, PatientModel patient) {
    // Address codes are already loaded in initState
    // The PhilippineAddressDropdown will display the current saved address
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile Picture
        _buildProfilePicture(theme, patient),
        const SizedBox(height: 28),
        // Personal Info
        if (!_isEditMode)
          _buildViewModePersonalInfo(theme, patient)
        else
          _buildEditModePersonalInfo(theme, patient),
        const SizedBox(height: 32),
        // Emergency Contact
        _buildEmergencyContactSection(theme, patient),
      ],
    );
  }

  Widget _buildProfilePicture(AppThemeData theme, PatientModel patient) {
    return Center(
      child: GestureDetector(
        onTap: patient.photoUrl != null && patient.photoUrl!.isNotEmpty
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PhotoViewerWidget(
                      photoUrl: patient.photoUrl!,
                      userName: patient.fullName,
                    ),
                  ),
                );
              }
            : null,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.buttonPrimary,
              width: 3,
            ),
            image: patient.photoUrl != null && patient.photoUrl!.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(patient.photoUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
            color: patient.photoUrl == null || patient.photoUrl!.isEmpty
                ? theme.buttonPrimary.withOpacity(0.1)
                : null,
          ),
          child: patient.photoUrl == null || patient.photoUrl!.isEmpty
              ? Center(
                  child: Text(
                    patient.initials,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: theme.buttonPrimary,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildViewModePersonalInfo(AppThemeData theme, PatientModel patient) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoItem(theme, 'Last Name', patient.lastName),
              const SizedBox(height: 20),
              _buildInfoItem(theme, 'First Name', patient.firstName),
              const SizedBox(height: 20),
              _buildInfoItem(theme, 'Middle Name', patient.middleName ?? 'N/A'),
              const SizedBox(height: 20),
              _buildInfoItem(theme, 'Extension', patient.extension ?? 'N/A'),
              const SizedBox(height: 20),
              _buildInfoItem(theme, 'Hospital ID', patient.hospitalId),
              const SizedBox(height: 20),
              _buildInfoItem(theme, 'Date of Birth', patient.birthDate),
              const SizedBox(height: 20),
              _buildInfoItem(theme, 'Address', _formatAddress(patient.address)),
              const SizedBox(height: 20),
              _buildInfoItem(theme, 'Civil Status', patient.civilStatus ?? 'Not provided'),
            ],
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoItem(theme, 'Age', '${patient.age} years old'),
              const SizedBox(height: 20),
              _buildInfoItem(theme, 'Gender', patient.sex),
              const SizedBox(height: 20),
              _buildInfoItem(theme, 'Contact Number', patient.contactNumber ?? 'Not provided'),
              const SizedBox(height: 20),
              _buildInfoItem(theme, 'Religion', patient.religion ?? 'Not provided'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditModePersonalInfo(AppThemeData theme, PatientModel patient) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name Components
        Text(
          'NAME COMPONENTS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: theme.buttonPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildEditableField(theme, 'Last Name', patient.lastName, 'lastName'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildEditableField(theme, 'First Name', patient.firstName, 'firstName'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildEditableField(theme, 'Middle Name', patient.middleName ?? '', 'middleName'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildEditableField(theme, 'Extension', patient.extension ?? '', 'extension'),
            ),
          ],
        ),
        const SizedBox(height: 32),
        // Other Personal Info
        _buildDateOfBirthPicker(theme, patient.birthDate),
        const SizedBox(height: 16),
        _buildEditableField(theme, 'Contact Number', patient.contactNumber ?? '', 'contactNumber'),
        const SizedBox(height: 16),
        _buildCivilStatusDropdown(theme, patient.civilStatus ?? ''),
        const SizedBox(height: 16),
        _buildEditableField(theme, 'Religion', patient.religion ?? '', 'religion'),
        const SizedBox(height: 32),
        // Address Components
        Text(
          'ADDRESS COMPONENTS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: theme.buttonPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        _buildEditableField(theme, 'Purok', patient.purok ?? '', 'purok'),
        const SizedBox(height: 20),
        PhilippineAddressDropdown(
          label: '',
          selectedProvinceCode: _dialogProvinceCode,
          selectedCityCode: _dialogCityCode,
          selectedBarangayCode: _dialogBarangayCode,
          onProvinceChanged: (code, name) {
            setState(() {
              _dialogProvinceCode = code;
            });
          },
          onCityChanged: (code, name) {
            setState(() {
              _dialogCityCode = code;
            });
          },
          onBarangayChanged: (code, name) {
            setState(() {
              _dialogBarangayCode = code;
            });
          },
          showRegion: false,
          showProvince: true,
          showCity: true,
          showBarangay: true,
        ),
      ],
    );
  }

  Widget _buildEmergencyContactSection(AppThemeData theme, PatientModel patient) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EMERGENCY CONTACT',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: theme.buttonPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        if (!_isEditMode)
          _buildViewModeEmergencyContact(theme, patient)
        else
          _buildEditModeEmergencyContact(theme, patient),
      ],
    );
  }

  Widget _buildViewModeEmergencyContact(AppThemeData theme, PatientModel patient) {
    if (patient.emergencyContact == null) {
      return const Text(
        'Not provided',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoItem(theme, 'Name', patient.emergencyContact!.name ?? 'Not provided'),
              const SizedBox(height: 20),
              _buildInfoItem(theme, 'Relationship', patient.emergencyContact!.relationship ?? 'Not provided'),
            ],
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoItem(theme, 'Contact Number', patient.emergencyContact!.contactNumber ?? 'Not provided'),
              const SizedBox(height: 20),
              _buildInfoItem(theme, 'Address', patient.emergencyContact!.fullAddress),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditModeEmergencyContact(AppThemeData theme, PatientModel patient) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildEditableField(theme, 'Name', patient.emergencyContact?.name ?? '', 'emergencyContactName'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildRelationshipDropdown(theme, patient.emergencyContact?.relationship ?? ''),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildEditableField(theme, 'Contact Number', patient.emergencyContact?.contactNumber ?? '', 'emergencyContactNumber'),
        const SizedBox(height: 16),
        Text(
          'ADDRESS COMPONENTS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: theme.buttonPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        _buildEditableField(theme, 'Purok', patient.emergencyContact?.purok ?? '', 'emergencyContactPurok'),
        const SizedBox(height: 16),
        PhilippineAddressDropdown(
          label: '',
          selectedProvinceCode: _emergencyProvinceCode,
          selectedCityCode: _emergencyCityCode,
          selectedBarangayCode: _emergencyBarangayCode,
          onProvinceChanged: (code, name) {
            setState(() {
              _emergencyProvinceCode = code;
            });
          },
          onCityChanged: (code, name) {
            setState(() {
              _emergencyCityCode = code;
            });
          },
          onBarangayChanged: (code, name) {
            setState(() {
              _emergencyBarangayCode = code;
            });
          },
          showRegion: false,
          showProvince: true,
          showCity: true,
          showBarangay: true,
        ),
      ],
    );
  }

  Widget _buildEditActions(AppThemeData theme, PatientModel patient) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.buttonPrimary.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () {
              setState(() {
                _isEditMode = false;
                _fieldControllers.clear();
              });
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () async {
              await _saveChanges(patient);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.buttonPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            child: const Text(
              'Save Changes',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widgets

  Widget _buildInfoItem(AppThemeData theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: theme.buttonPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField(AppThemeData theme, String label, String initialValue, String fieldKey) {
    if (!_fieldControllers.containsKey(fieldKey)) {
      _fieldControllers[fieldKey] = TextEditingController(text: initialValue);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: theme.buttonPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _fieldControllers[fieldKey],
          decoration: InputDecoration(
            hintText: 'Enter $label',
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.buttonPrimary.withOpacity(0.3),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.buttonPrimary.withOpacity(0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.buttonPrimary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildCivilStatusDropdown(AppThemeData theme, String initialValue) {
    final civilStatusOptions = ['SINGLE', 'MARRIED', 'WIDOWED', 'SEPARATED', 'ANNULLED'];
    final normalizedInitialValue = initialValue.toUpperCase();

    if (!_fieldControllers.containsKey('civilStatus')) {
      _fieldControllers['civilStatus'] = TextEditingController(text: normalizedInitialValue);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Civil Status',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: theme.buttonPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: civilStatusOptions.contains(_fieldControllers['civilStatus']?.text)
              ? _fieldControllers['civilStatus']?.text
              : (civilStatusOptions.contains(normalizedInitialValue) ? normalizedInitialValue : null),
          hint: const Text('Select Civil Status'),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.buttonPrimary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          items: civilStatusOptions.map((status) {
            return DropdownMenuItem<String>(
              value: status,
              child: Text(status),
            );
          }).toList(),
          onChanged: (value) {
            _fieldControllers['civilStatus']?.text = value ?? '';
          },
        ),
      ],
    );
  }

  Widget _buildRelationshipDropdown(AppThemeData theme, String initialValue) {
    final relationshipOptions = [
      'MOTHER', 'FATHER', 'SPOUSE', 'BROTHER', 'SISTER',
      'SON', 'DAUGHTER', 'GRANDPARENT', 'RELATIVE',
      'GUARDIAN', 'FRIEND', 'OTHER'
    ];
    final normalizedInitialValue = initialValue.toUpperCase();

    if (!_fieldControllers.containsKey('emergencyContactRelationship')) {
      _fieldControllers['emergencyContactRelationship'] = TextEditingController(text: normalizedInitialValue);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Relationship',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: theme.buttonPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: relationshipOptions.contains(_fieldControllers['emergencyContactRelationship']?.text)
              ? _fieldControllers['emergencyContactRelationship']?.text
              : (relationshipOptions.contains(normalizedInitialValue) ? normalizedInitialValue : null),
          hint: const Text('Select Relationship'),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.buttonPrimary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          items: relationshipOptions.map((relationship) {
            return DropdownMenuItem<String>(
              value: relationship,
              child: Text(relationship),
            );
          }).toList(),
          onChanged: (value) {
            _fieldControllers['emergencyContactRelationship']?.text = value ?? '';
          },
        ),
      ],
    );
  }

  Widget _buildDateOfBirthPicker(AppThemeData theme, String initialDate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date of Birth',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: theme.buttonPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.tryParse(initialDate) ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              builder: (BuildContext context, Widget? child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: theme.buttonPrimary,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Colors.black87,
                    ),
                  ),
                  child: child ?? const SizedBox(),
                );
              },
            );
            if (picked != null) {
              setState(() {
                _editingBirthDate = picked.toString().split(' ')[0];
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.buttonPrimary.withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _editingBirthDate ?? initialDate,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: theme.buttonPrimary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Data Loading Methods

  Future<void> _loadAddressCodesFromDatabase(PatientModel patient) async {
    try {
      final addressService = AddressService();

      if (patient.province != null && patient.province!.isNotEmpty) {
        final provinces = await addressService.fetchProvinces();
        Province? matchingProvince;

        try {
          matchingProvince = provinces.firstWhere(
            (p) => p.name.toUpperCase() == patient.province!.toUpperCase(),
          );
        } catch (e) {
          matchingProvince = provinces.isNotEmpty ? provinces.first : null;
        }

        if (matchingProvince != null && mounted) {
          setState(() {
            _dialogProvinceCode = matchingProvince!.code;
          });

          if (patient.cityMunicipal != null && patient.cityMunicipal!.isNotEmpty) {
            final cities = await addressService.fetchCities(provinceCode: matchingProvince.code);
            City? matchingCity;

            try {
              matchingCity = cities.firstWhere(
                (c) => c.name.toUpperCase() == patient.cityMunicipal!.toUpperCase(),
              );
            } catch (e) {
              matchingCity = cities.isNotEmpty ? cities.first : null;
            }

            if (matchingCity != null && mounted) {
              setState(() {
                _dialogCityCode = matchingCity!.code;
              });

              if (patient.barangay != null && patient.barangay!.isNotEmpty) {
                final barangays = await addressService.fetchBarangays(cityCode: matchingCity.code);
                Barangay? matchingBarangay;

                try {
                  matchingBarangay = barangays.firstWhere(
                    (b) => b.name.toUpperCase() == patient.barangay!.toUpperCase(),
                  );
                } catch (e) {
                  matchingBarangay = barangays.isNotEmpty ? barangays.first : null;
                }

                if (matchingBarangay != null && mounted) {
                  setState(() {
                    _dialogBarangayCode = matchingBarangay!.code;
                  });
                }
              }
            }
          }
        }
      }
    } catch (e) {
      AppLogger.error('Error loading address codes', tag: 'PatientInfoDialog', error: e);
    }
  }

  Future<void> _loadEmergencyContactAddressCodesFromDatabase(PatientModel patient) async {
    if (patient.emergencyContact?.province == null) return;

    try {
      final addressService = AddressService();
      final provinces = await addressService.fetchProvinces();
      Province? matchingProvince;

      try {
        matchingProvince = provinces.firstWhere(
          (p) => p.name.toUpperCase() == patient.emergencyContact!.province!.toUpperCase(),
        );
      } catch (e) {
        matchingProvince = provinces.isNotEmpty ? provinces.first : null;
      }

      if (matchingProvince != null && mounted) {
        setState(() {
          _emergencyProvinceCode = matchingProvince!.code;
        });

        if (patient.emergencyContact?.cityMunicipal != null) {
          final cities = await addressService.fetchCities(provinceCode: matchingProvince.code);
          City? matchingCity;

          try {
            matchingCity = cities.firstWhere(
              (c) => c.name.toUpperCase() == patient.emergencyContact!.cityMunicipal!.toUpperCase(),
            );
          } catch (e) {
            matchingCity = cities.isNotEmpty ? cities.first : null;
          }

          if (matchingCity != null && mounted) {
            setState(() {
              _emergencyCityCode = matchingCity!.code;
            });

            if (patient.emergencyContact?.barangay != null) {
              final barangays = await addressService.fetchBarangays(cityCode: matchingCity.code);
              Barangay? matchingBarangay;

              try {
                matchingBarangay = barangays.firstWhere(
                  (b) => b.name.toUpperCase() == patient.emergencyContact!.barangay!.toUpperCase(),
                );
              } catch (e) {
                matchingBarangay = barangays.isNotEmpty ? barangays.first : null;
              }

              if (matchingBarangay != null && mounted) {
                setState(() {
                  _emergencyBarangayCode = matchingBarangay!.code;
                });
              }
            }
          }
        }
      }
    } catch (e) {
      AppLogger.error('Error loading emergency contact address codes', tag: 'PatientInfoDialog', error: e);
    }
  }

  // Save Method

  Future<void> _saveChanges(PatientModel patient) async {
    final provider = widget.provider;
    if (provider == null) {
      AppLogger.error('No provider provided to PatientInfoDialog', tag: 'PatientInfoDialog');
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.of(context).buttonPrimary),
                const SizedBox(height: 16),
                const Text('Saving changes...'),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Collect edited data
      final updateData = {
        'lastname': _fieldControllers['lastName']?.text ?? patient.lastName,
        'firstname': _fieldControllers['firstName']?.text ?? patient.firstName,
        'middlename': _fieldControllers['middleName']?.text ?? patient.middleName,
        'ext': _fieldControllers['extension']?.text ?? patient.extension,
        'birthdate': _editingBirthDate ?? patient.birthDate,
        'contact_number': _fieldControllers['contactNumber']?.text ?? patient.contactNumber,
        'civil_status': _fieldControllers['civilStatus']?.text ?? patient.civilStatus,
        'religion': _fieldControllers['religion']?.text ?? patient.religion,
        'purok': _fieldControllers['purok']?.text ?? patient.purok,
        'province': _dialogProvinceCode ?? patient.province,
        'city_municipal': _dialogCityCode ?? patient.cityMunicipal,
        'barangay': _dialogBarangayCode ?? patient.barangay,
        'emergency_contact': {
          'contact_name': _fieldControllers['emergencyContactName']?.text ?? patient.emergencyContact?.name,
          'relationship': _fieldControllers['emergencyContactRelationship']?.text ?? patient.emergencyContact?.relationship,
          'contact_number': _fieldControllers['emergencyContactNumber']?.text ?? patient.emergencyContact?.contactNumber,
          'purok': _fieldControllers['emergencyContactPurok']?.text ?? patient.emergencyContact?.purok,
          'province': _emergencyProvinceCode ?? patient.emergencyContact?.province,
          'city_municipal': _emergencyCityCode ?? patient.emergencyContact?.cityMunicipal,
          'barangay': _emergencyBarangayCode ?? patient.emergencyContact?.barangay,
        }
      };

      // Send to backend API via provider
      final response = await provider.updatePatient(patient.hospitalId, updateData);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (response.statusCode == 200) {
        // Show success message
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Success',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Patient information updated successfully',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close success dialog
                          Navigator.of(context).pop(); // Close patient info dialog
                          provider?.refresh(); // Reload patient data
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.of(context).buttonPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'OK',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      } else {
        throw Exception('Failed to update patient: ${response.statusCode}');
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to save changes: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  // Utility Methods

  String _formatAddress(String? address) {
    if (address == null || address.isEmpty) {
      return 'Not provided';
    }
    final parts = address.split(',').map((p) => p.trim().toUpperCase()).toList();
    return parts.join(', ');
  }
}
