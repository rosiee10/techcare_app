import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/services/session_manager.dart';
import '../../../../../core/config/api_config.dart';
import '../../../opd_clerk/data/models/patient_model.dart';

/// New OPD Visit Dialog
/// 
/// Shows a modal for creating a new visit with:
/// - Patient info header
/// - Consultation Service dropdown
/// - Chief Complaint text area
/// - Cancel and Create buttons
class NewVisitDialog extends StatefulWidget {
  final PatientModel patient;

  const NewVisitDialog({
    super.key,
    required this.patient,
  });

  @override
  State<NewVisitDialog> createState() => _NewVisitDialogState();
}

class _NewVisitDialogState extends State<NewVisitDialog> {
  String? _selectedService;
  final TextEditingController _chiefComplaintController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingServices = true;
  String? _servicesError;
  List<Map<String, dynamic>> _availableServices = [];

  @override
  void initState() {
    super.initState();
    _fetchAvailableServices();
  }

  Future<void> _fetchAvailableServices() async {
    try {
      final token = await AuthService().getAccessToken();
      final baseUrl = ApiConfig.baseUrl;

      final response = await http.get(
        Uri.parse('$baseUrl/api/patients/available-services/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Filter to show only services that are open today (is_open_today = true)
          final allServices = List<Map<String, dynamic>>.from(data['data']);
          final openServices = allServices
              .where((service) => service['is_open_today'] == true)
              .toList();
          
          setState(() {
            _availableServices = openServices;
            _isLoadingServices = false;
          });
        } else {
          setState(() {
            _servicesError = data['error'] ?? 'Failed to load services';
            _isLoadingServices = false;
          });
        }
      } else if (response.statusCode == 401) {
        // Token expired - SessionManager will handle showing dialog
        await SessionManager().checkAndHandleExpiration(response);
        setState(() {
          _servicesError = 'Session expired. Please log in again.';
          _isLoadingServices = false;
        });
      } else {
        setState(() {
          _servicesError = 'Failed to load services: ${response.statusCode}';
          _isLoadingServices = false;
        });
      }
    } catch (e) {
      setState(() {
        _servicesError = 'Error: $e';
        _isLoadingServices = false;
      });
    }
  }

  @override
  void dispose() {
    _chiefComplaintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return WillPopScope(
      onWillPop: () async => !_isLoading,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxWidth: 500),
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              // Patient Info
              _buildPatientInfo(),
              // Form Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Consultation Service
                    _buildConsultationServiceDropdown(theme),
                    const SizedBox(height: 20),
                    // Chief Complaint
                    _buildChiefComplaintField(theme),
                    const SizedBox(height: 24),
                    // Buttons
                    _buildButtons(theme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black12),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.add, color: Colors.grey[700], size: 20),
          const SizedBox(width: 8),
          Text(
            'New OPD Visit',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfo() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Patient',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.patient.fullName} · ${widget.patient.hospitalId} · ${widget.patient.age} y/o ${widget.patient.sex}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationServiceDropdown(AppThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Consultation Service ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              TextSpan(
                text: '*',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[400],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedService,
          hint: Text(
            '— Select —',
            style: TextStyle(color: Colors.grey[500]),
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              borderSide: BorderSide(color: theme.buttonPrimary, width: 1.5),
            ),
          ),
          items: _isLoadingServices
          ? <DropdownMenuItem<String>>[]
          : _servicesError != null
            ? <DropdownMenuItem<String>>[]
            : _availableServices.map((service) {
                return DropdownMenuItem<String>(
                  value: service['service_label'] as String,
                  child: Text(
                    service['service_label'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                );
              }).toList(),
          onChanged: _isLoadingServices || _servicesError != null
            ? null
            : (value) {
                setState(() {
                  _selectedService = value;
                });
              },
        ),
        if (_isLoadingServices)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text(
                  'Loading available services...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
        else if (_servicesError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[400], size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _servicesError!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[600],
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (_availableServices.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'No services available at this time.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChiefComplaintField(AppThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Chief Complaint ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              TextSpan(
                text: '*',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[400],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _chiefComplaintController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'e.g. Sakit ng ulo at lagnat ng 2 araw',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            contentPadding: const EdgeInsets.all(16),
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
              borderSide: BorderSide(color: theme.buttonPrimary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(AppThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _createVisit,
          icon: _isLoading 
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(Icons.print, size: 16),
          label: Text(
            _isLoading ? 'Creating...' : 'Create Visit & Print Queue Slip',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.buttonPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _createVisit() async {
    if (_selectedService == null || _chiefComplaintController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement API call to create visit
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visit created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create visit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
