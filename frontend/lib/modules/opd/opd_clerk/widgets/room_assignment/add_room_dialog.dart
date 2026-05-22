import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/config/api_config.dart';
import '../../../../../core/services/auth_service.dart';
import '../../models/room_model.dart';
import '../../models/service_model.dart';
import 'service_dropdown_field.dart';

/// Reusable AddRoomDialog Widget
/// Follows Single Responsibility Principle - only handles room creation
class AddRoomDialog extends StatefulWidget {
  final Function(Room room)? onSave;

  const AddRoomDialog({super.key, this.onSave});

  @override
  State<AddRoomDialog> createState() => _AddRoomDialogState();
}

class _AddRoomDialogState extends State<AddRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _queuePrefixController = TextEditingController();

  String _selectedFloor = 'Ground';
  String _selectedService = '-- Select --';
  String _selectedDoctor = '-- Select --';
  String _selectedDoctorId = '';
  String _selectedStatus = 'Open';

  List<Service> _services = [];
  List<Map<String, dynamic>> _doctors = [];
  bool _isLoadingServices = true;
  bool _isLoadingDoctors = true;

  static const List<String> _floors = ['Ground', '1st', '2nd', '3rd', '4th'];
  static const List<String> _statuses = ['Open', 'Closed'];

  @override
  void initState() {
    super.initState();
    _loadServices();
    _loadDoctors();
  }

  Future<void> _loadServices() async {
    try {
      final authService = AuthService();
      final token = await authService.getAccessToken();
      
      if (token == null) {
        setState(() {
          _isLoadingServices = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConfig.opdServiceList),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<Service> services = [];
        
        if (jsonData['success'] == true && jsonData['data'] != null) {
          for (var serviceJson in jsonData['data']) {
            services.add(Service.fromJson(serviceJson));
          }
        }
        
        setState(() {
          _services = services;
          _isLoadingServices = false;
        });
      } else {
        setState(() {
          _isLoadingServices = false;
        });
        _showError('Failed to load services');
      }
    } catch (e) {
      setState(() {
        _isLoadingServices = false;
      });
      _showError('Error loading services: $e');
    }
  }

  Future<void> _loadDoctors() async {
    try {
      final authService = AuthService();
      final token = await authService.getAccessToken();
      
      if (token == null) {
        setState(() {
          _isLoadingDoctors = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConfig.doctorsList),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<Map<String, dynamic>> doctors = [];
        
        if (jsonData['success'] == true && jsonData['data'] != null) {
          for (var doctorJson in jsonData['data']) {
            doctors.add({
              'id': doctorJson['id'],
              'name': doctorJson['name'],
              'username': doctorJson['username'],
            });
          }
        }
        
        setState(() {
          _doctors = doctors;
          _isLoadingDoctors = false;
        });
      } else {
        setState(() {
          _isLoadingDoctors = false;
        });
        _showError('Failed to load doctors');
      }
    } catch (e) {
      setState(() {
        _isLoadingDoctors = false;
      });
      _showError('Error loading doctors: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _queuePrefixController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedService == '-- Select --') {
      _showError('Please select a service');
      return;
    }
    if (_selectedDoctor == '-- Select --') {
      _showError('Please select a doctor');
      return;
    }

    final room = Room(
      id: '',
      code: _codeController.text.trim(),
      name: _nameController.text.trim(),
      floor: _selectedFloor,
      service: _selectedService,
      queuePrefix: _queuePrefixController.text.trim(),
      doctor: _selectedDoctorId,
      status: _selectedStatus,
    );

    widget.onSave?.call(room);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 24),
              _buildFormFields(theme),
              const SizedBox(height: 24),
              _buildButtons(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Add New Room',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: theme.textPrimary,
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.close, color: theme.textSecondary),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildFormFields(AppThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ValidatedTextField(
                label: 'Room Code',
                controller: _codeController,
                hint: 'e.g. R6-FM',
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ValidatedTextField(
                label: 'Room Name',
                controller: _nameController,
                hint: 'e.g. Room 6 - FAMED',
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _DropdownField(
                label: 'Floor',
                value: _selectedFloor,
                items: _floors,
                onChanged: (v) => setState(() => _selectedFloor = v!),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ServiceDropdownField(
                label: 'Service',
                value: _selectedService,
                services: _services,
                isLoading: _isLoadingServices,
                onChanged: (v) => setState(() => _selectedService = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ValidatedTextField(
                label: 'Queue Prefix',
                controller: _queuePrefixController,
                hint: '',
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _isLoadingDoctors
                  ? Container(
                      height: 56,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : _DoctorDropdownField(
                      label: 'Assigned Doctor',
                      value: _selectedDoctor,
                      doctors: _doctors,
                      onChanged: (doctorName) {
                        if (doctorName != null && doctorName != '-- Select --') {
                          // Find the doctor ID from the name
                          final doctor = _doctors.firstWhere(
                            (d) => d['name'] == doctorName,
                            orElse: () => {},
                          );
                          setState(() {
                            _selectedDoctor = doctorName;
                            _selectedDoctorId = doctor['id']?.toString() ?? '';
                          });
                        } else {
                          setState(() {
                            _selectedDoctor = '-- Select --';
                            _selectedDoctorId = '';
                          });
                        }
                      },
                    ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _DropdownField(
          label: 'Status',
          value: _selectedStatus,
          items: _statuses,
          onChanged: (v) => setState(() => _selectedStatus = v!),
        ),
      ],
    );
  }

  Widget _buildButtons(AppThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: theme.textSecondary),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Save Room',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// Validated Text Field Component
class _ValidatedTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;

  const _ValidatedTextField({
    required this.label,
    required this.controller,
    required this.hint,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
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
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}

/// Dropdown Field Component
class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              items: items.map((item) => DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 14,
                    color: item == '-- Select --' 
                        ? Colors.grey[400] 
                        : theme.textPrimary,
                  ),
                ),
              )).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

/// Doctor Dropdown Field Widget
class _DoctorDropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<Map<String, dynamic>> doctors;
  final ValueChanged<String?> onChanged;

  const _DoctorDropdownField({
    required this.label,
    required this.value,
    required this.doctors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    
    // Create dropdown items with "-- Select --" as first option
    final List<String> items = ['-- Select --'];
    items.addAll(doctors.map((doctor) => doctor['name'] as String).toList());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              items: items.map((item) => DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: item == '-- Select --' ? Colors.grey[400] : null,
                  ),
                ),
              )).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
