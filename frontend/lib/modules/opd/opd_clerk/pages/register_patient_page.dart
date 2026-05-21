import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/reusable_widgets/logo_carousel_loading.dart';
import '../widgets/register_patient/form_fields.dart';
import '../widgets/register_patient/photo_capture_widget.dart';
import '../widgets/register_patient/address_section.dart';
import '../widgets/register_patient/emergency_contact_section.dart';
import '../providers/patient_registration_provider.dart';

class RegisterPatientPage extends StatelessWidget {
  const RegisterPatientPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PatientRegistrationProvider(),
      child: const _RegisterPatientView(),
    );
  }
}

class _RegisterPatientView extends StatelessWidget {
  const _RegisterPatientView();

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final provider = context.watch<PatientRegistrationProvider>();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: provider.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              _buildFormContent(context, theme, provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.buttonPrimary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Text(
        'Patient Registration Form',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildFormContent(BuildContext context, AppThemeData theme, PatientRegistrationProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPatientNameSection(theme, provider),
          const SizedBox(height: 32),
          _buildPersonalInfoSection(theme, provider),
          const SizedBox(height: 32),
          AddressSection(
            selectedProvinceCode: provider.selectedProvinceCode,
            selectedCityCode: provider.selectedCityCode,
            selectedBarangayCode: provider.selectedBarangayCode,
            provinceError: provider.provinceError,
            cityError: provider.cityError,
            barangayError: provider.barangayError,
            purokController: provider.purokController,
            onProvinceChanged: provider.setPatientProvince,
            onCityChanged: provider.setPatientCity,
            onBarangayChanged: provider.setPatientBarangay,
          ),
          const SizedBox(height: 32),
          EmergencyContactSection(
            nameController: provider.emergencyNameController,
            contactController: provider.emergencyContactController,
            purokController: provider.emergencyPurokController,
            selectedProvinceCode: provider.emergencyProvinceCode,
            selectedCityCode: provider.emergencyCityCode,
            selectedBarangayCode: provider.emergencyBarangayCode,
            selectedRelationship: provider.selectedRelationship,
            nameError: provider.emergencyNameError,
            relationshipError: provider.emergencyRelationshipError,
            contactError: provider.emergencyContactError,
            provinceError: provider.emergencyProvinceError,
            cityError: provider.emergencyCityError,
            barangayError: provider.emergencyBarangayError,
            onRelationshipChanged: provider.setRelationship,
            onProvinceChanged: provider.setEmergencyProvince,
            onCityChanged: provider.setEmergencyCity,
            onBarangayChanged: provider.setEmergencyBarangay,
            phoneValidator: _validatePhoneNumber,
            phoneInputFormatters: [PhoneNumberFormatter()],
          ),
          const SizedBox(height: 32),
          _buildActionButtons(context, provider),
        ],
      ),
    );
  }

  Widget _buildPatientNameSection(AppThemeData theme, PatientRegistrationProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'PATIENT NAME'),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  AppTextField(
                    controller: provider.lastNameController,
                    label: 'Last Name',
                    hint: 'Enter last name',
                    isRequired: true,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: provider.firstNameController,
                    label: 'First Name',
                    hint: 'Enter first name',
                    isRequired: true,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: provider.middleNameController,
                    label: 'Middle Name',
                    hint: 'Enter middle name',
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: provider.extensionController,
                    label: 'Extension (Jr./Sr./III)',
                    hint: 'Enter extension',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 1,
              child: PhotoCaptureWidget(
                photoUrl: provider.uploadedPhotoUrl,
                onPhotoUrlChanged: provider.setPhotoUrl,
                onClearPhoto: provider.clearPhoto,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection(AppThemeData theme, PatientRegistrationProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'PERSONAL INFORMATION'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AppDatePicker(
                controller: provider.dobController,
                label: 'Date of Birth',
                hint: 'mm/dd/yyyy',
                isRequired: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppDropdown(
                label: 'Gender',
                hint: 'Select gender',
                isRequired: true,
                value: provider.selectedGender,
                items: const ['Male', 'Female'],
                hasError: provider.genderError,
                onChanged: (value) => provider.setGender(value ?? ''),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppDropdown(
                label: 'Civil Status',
                hint: 'Select civil status',
                isRequired: true,
                value: provider.selectedCivilStatus,
                items: const ['Single', 'Married', 'Widowed', 'Separated', 'Annulled'],
                hasError: provider.civilStatusError,
                onChanged: (value) => provider.setCivilStatus(value ?? ''),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppTextField(
                controller: provider.religionController,
                label: 'Religion',
                hint: 'Enter religion',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: provider.contactController,
          label: 'Contact Number',
          hint: '09XXXXXXXXX',
          isRequired: true,
          keyboardType: TextInputType.phone,
          inputFormatters: [PhoneNumberFormatter()],
          validator: _validatePhoneNumber,
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, PatientRegistrationProvider provider) {
    final theme = AppTheme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: provider.reset,
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            side: BorderSide(color: theme.cardBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: provider.isLoading ? null : () => _registerPatient(context, provider),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.buttonPrimary,
            foregroundColor: theme.buttonPrimaryText,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: provider.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Register Patient'),
        ),
      ],
    );
  }

  Future<void> _registerPatient(BuildContext context, PatientRegistrationProvider provider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LogoCarouselLoadingOverlay(
        isLoading: true,
        message: 'Registering patient',
      ),
    );

    final result = await provider.registerPatient();

    if (context.mounted) {
      Navigator.of(context).pop();

      if (result['success'] == true) {
        _showSuccessDialog(context);
      } else {
        _showErrorDialog(context, result['error'] ?? 'Failed to register patient');
      }
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: const Text('Patient registered successfully!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length != 11) {
      return 'Phone number must be exactly 11 digits';
    }
    return null;
  }
}
