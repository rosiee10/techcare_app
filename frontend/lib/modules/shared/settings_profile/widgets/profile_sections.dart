import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import 'profile_form_fields.dart' as form_fields;
import 'section_card.dart';

class DemographicsSection extends StatelessWidget {
  final bool isEditing;
  final bool isMobile;

  const DemographicsSection({
    super.key,
    required this.isEditing,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {
        return SectionCard(
          title: 'Demographics',
          icon: Icons.assignment_ind_outlined,
          iconColor: const Color(0xFFE91E63),
          iconBgColor: const Color(0xFFFCE4EC),
          child: Column(
            children: [
              if (isMobile) ...[
                form_fields.ProfileFormFields.buildDropdownField(
                  label: 'Gender',
                  value: provider.selectedGender,
                  items: provider.genderOptions,
                  onChanged: isEditing ? provider.updateGender : null,
                  enabled: isEditing,
                  context: context,
                ),
                const SizedBox(height: 16),
                form_fields.ProfileFormFields.buildDatePickerField(
                  label: 'Birthdate',
                  controller: provider.birthdateController,
                  enabled: isEditing,
                  context: context,
                  onDateSelected: (_) {},
                ),
                const SizedBox(height: 16),
                form_fields.ProfileFormFields.buildDropdownField(
                  label: 'Civil Status',
                  value: provider.selectedCivilStatus,
                  items: provider.civilStatusOptions,
                  onChanged: isEditing ? provider.updateCivilStatus : null,
                  enabled: isEditing,
                  context: context,
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: form_fields.ProfileFormFields.buildDropdownField(
                        label: 'Gender',
                        value: provider.selectedGender,
                        items: provider.genderOptions,
                        onChanged: isEditing ? provider.updateGender : null,
                        enabled: isEditing,
                        context: context,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: form_fields.ProfileFormFields.buildDatePickerField(
                        label: 'Birthdate',
                        controller: provider.birthdateController,
                        enabled: isEditing,
                        context: context,
                        onDateSelected: (_) {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                form_fields.ProfileFormFields.buildDropdownField(
                  label: 'Civil Status',
                  value: provider.selectedCivilStatus,
                  items: provider.civilStatusOptions,
                  onChanged: isEditing ? provider.updateCivilStatus : null,
                  enabled: isEditing,
                  context: context,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class AddressSection extends StatelessWidget {
  final bool isEditing;
  final bool isMobile;

  const AddressSection({
    super.key,
    required this.isEditing,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {
        return SectionCard(
          title: 'Address',
          icon: Icons.location_on_outlined,
          iconColor: const Color(0xFF4CAF50),
          iconBgColor: const Color(0xFFE8F5E9),
          child: Column(
            children: [
              form_fields.ProfileFormFields.buildEditableField(
                label: 'Street Address',
                controller: provider.streetAddressController,
                enabled: isEditing,
                context: context,
              ),
              const SizedBox(height: 16),
              if (isMobile) ...[
                form_fields.ProfileFormFields.buildDropdownField(
                  label: 'Province',
                  value: provider.selectedProvince,
                  items: provider.provinces.map((p) => p.name).toList(),
                  onChanged: isEditing ? provider.updateProvince : null,
                  enabled: isEditing,
                  context: context,
                ),
                const SizedBox(height: 16),
                form_fields.ProfileFormFields.buildDropdownField(
                  label: 'City/Municipality',
                  value: provider.selectedCity,
                  items: provider.cities.map((c) => c.name).toList(),
                  onChanged: isEditing ? provider.updateCity : null,
                  enabled: isEditing && provider.cities.isNotEmpty,
                  context: context,
                ),
                const SizedBox(height: 16),
                form_fields.ProfileFormFields.buildDropdownField(
                  label: 'Barangay',
                  value: provider.selectedBarangay,
                  items: provider.barangays.map((b) => b.name).toList(),
                  onChanged: isEditing ? provider.updateBarangay : null,
                  enabled: isEditing && provider.barangays.isNotEmpty,
                  context: context,
                ),
                const SizedBox(height: 16),
                form_fields.ProfileFormFields.buildEditableField(
                  label: 'ZIP Code',
                  controller: provider.zipCodeController,
                  enabled: isEditing,
                  keyboardType: TextInputType.number,
                  context: context,
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: form_fields.ProfileFormFields.buildDropdownField(
                        label: 'Province',
                        value: provider.selectedProvince,
                        items: provider.provinces.map((p) => p.name).toList(),
                        onChanged: isEditing ? provider.updateProvince : null,
                        enabled: isEditing,
                        context: context,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: form_fields.ProfileFormFields.buildDropdownField(
                        label: 'City/Municipality',
                        value: provider.selectedCity,
                        items: provider.cities.map((c) => c.name).toList(),
                        onChanged: isEditing ? provider.updateCity : null,
                        enabled: isEditing && provider.cities.isNotEmpty,
                        context: context,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: form_fields.ProfileFormFields.buildDropdownField(
                        label: 'Barangay',
                        value: provider.selectedBarangay,
                        items: provider.barangays.map((b) => b.name).toList(),
                        onChanged: isEditing ? provider.updateBarangay : null,
                        enabled: isEditing && provider.barangays.isNotEmpty,
                        context: context,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: form_fields.ProfileFormFields.buildEditableField(
                        label: 'ZIP Code',
                        controller: provider.zipCodeController,
                        enabled: isEditing,
                        keyboardType: TextInputType.number,
                        context: context,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class EmergencyContactSection extends StatelessWidget {
  final bool isEditing;
  final bool isMobile;

  const EmergencyContactSection({
    super.key,
    required this.isEditing,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {
        return SectionCard(
          title: 'Emergency Contact',
          icon: Icons.emergency_outlined,
          iconColor: const Color(0xFFC62828),
          iconBgColor: const Color(0xFFFFEBEE),
          child: Column(
            children: [
              form_fields.ProfileFormFields.buildEditableField(
                label: 'Contact Name',
                controller: provider.emergencyNameController,
                enabled: isEditing,
                context: context,
              ),
              const SizedBox(height: 16),
              if (isMobile) ...[
                form_fields.ProfileFormFields.buildEditableField(
                  label: 'Contact Number',
                  controller: provider.emergencyNumberController,
                  enabled: isEditing,
                  keyboardType: TextInputType.phone,
                  context: context,
                ),
                const SizedBox(height: 16),
                form_fields.ProfileFormFields.buildDropdownField(
                  label: 'Relationship',
                  value: provider.selectedRelationship,
                  items: provider.relationshipOptions,
                  onChanged: isEditing ? provider.updateRelationship : null,
                  enabled: isEditing,
                  context: context,
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: form_fields.ProfileFormFields.buildEditableField(
                        label: 'Contact Number',
                        controller: provider.emergencyNumberController,
                        enabled: isEditing,
                        keyboardType: TextInputType.phone,
                        context: context,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: form_fields.ProfileFormFields.buildDropdownField(
                        label: 'Relationship',
                        value: provider.selectedRelationship,
                        items: provider.relationshipOptions,
                        onChanged: isEditing ? provider.updateRelationship : null,
                        enabled: isEditing,
                        context: context,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
