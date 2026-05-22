import 'package:flutter/material.dart';
import '../models/address_models.dart';
import '../services/address_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/logger.dart';

class PhilippineAddressDropdown extends StatefulWidget {
  final String label;
  final String? selectedRegionCode;
  final String? selectedProvinceCode;
  final String? selectedCityCode;
  final String? selectedBarangayCode;
  final Function(String? regionCode, String? regionName)? onRegionChanged;
  final Function(String? provinceCode, String? provinceName)? onProvinceChanged;
  final Function(String? cityCode, String? cityName)? onCityChanged;
  final Function(String? barangayCode, String? barangayName)? onBarangayChanged;
  final bool showRegion;
  final bool showProvince;
  final bool showCity;
  final bool showBarangay;
  final bool isRequired;
  final Widget? barangayTrailing;
  // Error states for validation
  final bool provinceError;
  final bool cityError;
  final bool barangayError;

  const PhilippineAddressDropdown({
    super.key,
    this.label = 'Address',
    this.selectedRegionCode,
    this.selectedProvinceCode,
    this.selectedCityCode,
    this.selectedBarangayCode,
    this.onRegionChanged,
    this.onProvinceChanged,
    this.onCityChanged,
    this.onBarangayChanged,
    this.showRegion = true,
    this.showProvince = true,
    this.showCity = true,
    this.showBarangay = true,
    this.isRequired = false,
    this.barangayTrailing,
    this.provinceError = false,
    this.cityError = false,
    this.barangayError = false,
  });

  @override
  State<PhilippineAddressDropdown> createState() => _PhilippineAddressDropdownState();
}

class _PhilippineAddressDropdownState extends State<PhilippineAddressDropdown> {
  final AddressService _addressService = AddressService();
  
  List<Region> _regions = [];
  List<Province> _provinces = [];
  List<City> _cities = [];
  List<Barangay> _barangays = [];
  
  String? _selectedRegionCode;
  String? _selectedProvinceCode;
  String? _selectedCityCode;
  String? _selectedBarangayCode;
  
  bool _isLoadingRegions = false;
  bool _isLoadingProvinces = false;
  bool _isLoadingCities = false;
  bool _isLoadingBarangays = false;

  @override
  void initState() {
    super.initState();
    _selectedRegionCode = widget.selectedRegionCode;
    _selectedProvinceCode = widget.selectedProvinceCode;
    _selectedCityCode = widget.selectedCityCode;
    _selectedBarangayCode = widget.selectedBarangayCode;
    _loadInitialData();
  }

  @override
  void didUpdateWidget(PhilippineAddressDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Force rebuild when error states change from parent
    if (oldWidget.provinceError != widget.provinceError ||
        oldWidget.cityError != widget.cityError ||
        oldWidget.barangayError != widget.barangayError) {
      setState(() {});
    }
  }

  Future<void> _loadInitialData() async {
    if (widget.showRegion) {
      await _loadRegions();
    } else {
      // Load all provinces if region dropdown is hidden
      await _loadProvinces(null);
    }
  }

  Future<void> _loadRegions() async {
    setState(() => _isLoadingRegions = true);
    try {
      _regions = await _addressService.fetchRegions();
    } catch (e) {
      AppLogger.error('Error loading regions', tag: 'AddressDropdown', error: e);
    }
    setState(() => _isLoadingRegions = false);
    
    if (_selectedRegionCode != null) {
      _loadProvinces(_selectedRegionCode);
    }
  }

  Future<void> _loadProvinces(String? regionCode) async {
    setState(() => _isLoadingProvinces = true);
    _provinces = await _addressService.fetchProvinces(regionCode: regionCode);
    setState(() => _isLoadingProvinces = false);
    
    if (_selectedProvinceCode != null) {
      _loadCities(_selectedProvinceCode);
    }
  }

  Future<void> _loadCities(String? provinceCode) async {
    setState(() => _isLoadingCities = true);
    _cities = await _addressService.fetchCities(provinceCode: provinceCode);
    setState(() => _isLoadingCities = false);
    
    if (_selectedCityCode != null) {
      _loadBarangays(_selectedCityCode);
    }
  }

  Future<void> _loadBarangays(String? cityCode) async {
    setState(() => _isLoadingBarangays = true);
    _barangays = await _addressService.fetchBarangays(cityCode: cityCode);
    setState(() => _isLoadingBarangays = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.label + (widget.isRequired ? ' *' : ''),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        // Row 1: Province + City (when no Region)
        if (widget.showProvince && !widget.showRegion)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Province',
                  value: _selectedProvinceCode,
                  items: _provinces.map((p) => DropdownMenuItem(
                    value: p.code,
                    child: Text(p.name.toUpperCase(), overflow: TextOverflow.ellipsis),
                  )).toList(),
                  isLoading: _isLoadingProvinces,
                  enabled: _provinces.isNotEmpty,
                  hasError: widget.provinceError,
                  onChanged: (value) {
                    setState(() {
                      _selectedProvinceCode = value;
                      _selectedCityCode = null;
                      _selectedBarangayCode = null;
                      _cities = [];
                      _barangays = [];
                    });
                    
                    final province = _provinces.firstWhere(
                      (p) => p.code == value,
                      orElse: () => Province(code: '', name: '', regionCode: ''),
                    );
                    widget.onProvinceChanged?.call(value, province.name);
                    
                    if (value != null) {
                      _loadCities(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  label: 'City/Municipality',
                  value: _selectedCityCode,
                  items: _cities.map((c) => DropdownMenuItem(
                    value: c.code,
                    child: Text(c.name.toUpperCase(), overflow: TextOverflow.ellipsis),
                  )).toList(),
                  isLoading: _isLoadingCities,
                  enabled: _selectedProvinceCode != null,
                  hasError: widget.cityError,
                  onChanged: (value) {
                    setState(() {
                      _selectedCityCode = value;
                      _selectedBarangayCode = null;
                      _barangays = [];
                    });
                    
                    final city = _cities.firstWhere(
                      (c) => c.code == value,
                      orElse: () => City(code: '', name: '', provinceCode: ''),
                    );
                    widget.onCityChanged?.call(value, city.name);
                    
                    if (value != null) {
                      _loadBarangays(value);
                    }
                  },
                ),
              ),
            ],
          ),
        if (!widget.showRegion && widget.showBarangay)
          const SizedBox(height: 12),
        // Row 2: Barangay + optional trailing widget (e.g., Purok text field)
        if (widget.showBarangay && !widget.showRegion)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Barangay',
                  value: _selectedBarangayCode,
                  items: _barangays.map((b) => DropdownMenuItem(
                    value: b.code,
                    child: Text(b.name.toUpperCase(), overflow: TextOverflow.ellipsis),
                  )).toList(),
                  isLoading: _isLoadingBarangays,
                  enabled: _selectedCityCode != null,
                  hasError: widget.barangayError,
                  onChanged: (value) {
                    setState(() => _selectedBarangayCode = value);
                    
                    final barangay = _barangays.firstWhere(
                      (b) => b.code == value,
                      orElse: () => Barangay(code: '', name: '', cityCode: ''),
                    );
                    widget.onBarangayChanged?.call(value, barangay.name);
                  },
                ),
              ),
              if (widget.barangayTrailing != null) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: widget.barangayTrailing!,
                ),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildTrailingWidget(Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label placeholder: 12px font height + 6px gap
        const SizedBox(height: 18),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required bool isLoading,
    bool enabled = true,
    bool hasError = false,
    required Function(String?) onChanged,
  }) {
    final theme = AppTheme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: hasError ? Colors.red : theme.buttonPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
          decoration: BoxDecoration(
            color: theme.pageBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasError ? Colors.red : Colors.transparent,
              width: hasError ? 1 : 0,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: theme.textSecondary),
              dropdownColor: theme.cardBackground,
              style: TextStyle(color: theme.textPrimary, fontSize: 14),
              hint: Text('Select $label', style: TextStyle(color: theme.textSecondary, fontSize: 14)),
              items: items,
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              'This field is required',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
