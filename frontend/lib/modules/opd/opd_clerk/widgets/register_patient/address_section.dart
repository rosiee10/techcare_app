import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../shared/address/address_module.dart';
import 'form_fields.dart';

class AddressSection extends StatelessWidget {
  final String? selectedProvinceCode;
  final String? selectedCityCode;
  final String? selectedBarangayCode;
  final bool provinceError;
  final bool cityError;
  final bool barangayError;
  final TextEditingController purokController;
  final Function(String?, String?) onProvinceChanged;
  final Function(String?, String?) onCityChanged;
  final Function(String?, String?) onBarangayChanged;
  final String title;
  final bool isRequired;

  const AddressSection({
    super.key,
    this.selectedProvinceCode,
    this.selectedCityCode,
    this.selectedBarangayCode,
    this.provinceError = false,
    this.cityError = false,
    this.barangayError = false,
    required this.purokController,
    required this.onProvinceChanged,
    required this.onCityChanged,
    required this.onBarangayChanged,
    this.title = 'ADDRESS',
    this.isRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: title),
        const SizedBox(height: 16),
        PhilippineAddressDropdown(
          label: '',
          showRegion: false,
          selectedProvinceCode: selectedProvinceCode,
          selectedCityCode: selectedCityCode,
          selectedBarangayCode: selectedBarangayCode,
          onProvinceChanged: onProvinceChanged,
          onCityChanged: onCityChanged,
          onBarangayChanged: onBarangayChanged,
          isRequired: isRequired,
          provinceError: provinceError,
          cityError: cityError,
          barangayError: barangayError,
          barangayTrailing: _buildPurokField(theme),
        ),
      ],
    );
  }

  Widget _buildPurokField(AppThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Purok / Street',
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: theme.pageBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextFormField(
            controller: purokController,
            style: TextStyle(color: theme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Enter purok or street',
              hintStyle: TextStyle(color: theme.textSecondary, fontSize: 14),
              filled: true,
              fillColor: theme.pageBackground,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.buttonPrimary, width: 1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
