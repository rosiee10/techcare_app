import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'form_fields.dart';
import 'address_section.dart';

class EmergencyContactSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController contactController;
  final TextEditingController purokController;
  final String? selectedProvinceCode;
  final String? selectedCityCode;
  final String? selectedBarangayCode;
  final String selectedRelationship;
  final bool nameError;
  final bool relationshipError;
  final bool contactError;
  final bool provinceError;
  final bool cityError;
  final bool barangayError;
  final Function(String) onRelationshipChanged;
  final Function(String?, String?) onProvinceChanged;
  final Function(String?, String?) onCityChanged;
  final Function(String?, String?) onBarangayChanged;
  final String? Function(String?)? phoneValidator;
  final List<TextInputFormatter>? phoneInputFormatters;

  const EmergencyContactSection({
    super.key,
    required this.nameController,
    required this.contactController,
    required this.purokController,
    this.selectedProvinceCode,
    this.selectedCityCode,
    this.selectedBarangayCode,
    required this.selectedRelationship,
    this.nameError = false,
    this.relationshipError = false,
    this.contactError = false,
    this.provinceError = false,
    this.cityError = false,
    this.barangayError = false,
    required this.onRelationshipChanged,
    required this.onProvinceChanged,
    required this.onCityChanged,
    required this.onBarangayChanged,
    this.phoneValidator,
    this.phoneInputFormatters,
  });

  static const List<String> relationships = [
    'Mother', 'Father', 'Spouse', 'Brother', 'Sister', 'Son', 'Daughter',
    'Grandparent', 'Relative', 'Guardian', 'Friend', 'Other'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'EMERGENCY CONTACT'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: nameController,
                label: 'Name',
                hint: 'Enter emergency contact name',
                isRequired: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppDropdown(
                label: 'Relationship',
                hint: 'Select relationship',
                isRequired: true,
                value: selectedRelationship,
                items: relationships,
                hasError: relationshipError,
                onChanged: (value) => onRelationshipChanged(value ?? ''),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: contactController,
          label: 'Contact Number',
          hint: '09XXXXXXXXX',
          isRequired: true,
          keyboardType: TextInputType.phone,
          inputFormatters: phoneInputFormatters,
          validator: phoneValidator,
        ),
        const SizedBox(height: 16),
        AddressSection(
          title: 'Emergency Contact Address',
          selectedProvinceCode: selectedProvinceCode,
          selectedCityCode: selectedCityCode,
          selectedBarangayCode: selectedBarangayCode,
          provinceError: provinceError,
          cityError: cityError,
          barangayError: barangayError,
          purokController: purokController,
          onProvinceChanged: onProvinceChanged,
          onCityChanged: onCityChanged,
          onBarangayChanged: onBarangayChanged,
        ),
      ],
    );
  }
}
