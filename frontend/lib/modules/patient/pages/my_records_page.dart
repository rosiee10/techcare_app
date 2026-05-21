import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/api_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/reusable_widgets/card_container.dart';
import '../../../core/reusable_widgets/section_header.dart';
import '../../../core/utils/logger.dart';

class MyRecordsPage extends StatefulWidget {
  const MyRecordsPage({super.key});

  @override
  State<MyRecordsPage> createState() => _MyRecordsPageState();
}

class _MyRecordsPageState extends State<MyRecordsPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _patientProfile;
  List<dynamic> _emergencyContacts = [];
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    await _fetchPatientProfile();
  }

  Future<void> _fetchPatientProfile() async {
    if (_token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/patient/profile/'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _patientProfile = data['patient'];
          _emergencyContacts = data['emergency_contacts'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      AppLogger.error('Error fetching patient profile', tag: 'MyRecordsPage', error: e);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(theme.buttonPrimary),
        ),
      );
    }

    return Container(
      color: theme.pageBackground,
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'My Medical Records',
              fontSize: 24,
              color: theme.textPrimary,
            ),
            const SizedBox(height: 24),

            // Patient Information Card
            CardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline, color: theme.buttonPrimary, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow('Hospital ID', _patientProfile?['hospital_id'] ?? 'N/A', theme),
                  _buildInfoRow('Name', '${_patientProfile?['lastname'] ?? ''}, ${_patientProfile?['firstname'] ?? ''} ${_patientProfile?['middlename'] ?? ''}', theme),
                  _buildInfoRow('Birthdate', _patientProfile?['birthdate'] ?? 'N/A', theme),
                  _buildInfoRow('Gender', _patientProfile?['gender'] ?? 'N/A', theme),
                  _buildInfoRow('Civil Status', _patientProfile?['civil_status'] ?? 'N/A', theme),
                  _buildInfoRow('Religion', _patientProfile?['religion'] ?? 'N/A', theme),
                  _buildInfoRow('Contact Number', _patientProfile?['contact_number'] ?? 'N/A', theme),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Address Information
            CardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.home_outlined, color: theme.buttonPrimary, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Address Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow('Purok/Street', _patientProfile?['purok'] ?? 'N/A', theme),
                  _buildInfoRow('Barangay', _patientProfile?['barangay'] ?? 'N/A', theme),
                  _buildInfoRow('City/Municipality', _patientProfile?['city_municipal'] ?? 'N/A', theme),
                  _buildInfoRow('Province', _patientProfile?['province'] ?? 'N/A', theme),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Emergency Contacts
            CardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.emergency_outlined, color: theme.error, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Emergency Contacts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_emergencyContacts.isEmpty)
                    Text(
                      'No emergency contacts on record',
                      style: TextStyle(color: theme.textSecondary),
                    )
                  else
                    ..._emergencyContacts.map((contact) => _buildEmergencyContactCard(contact, theme)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: theme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactCard(Map<String, dynamic> contact, AppThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.isDark ? const Color(0xFF4A1515) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            contact['contact_name'] ?? 'Unknown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Relationship: ${contact['relationship'] ?? 'N/A'}',
            style: TextStyle(
              fontSize: 13,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Contact: ${contact['contact_number'] ?? 'N/A'}',
            style: TextStyle(
              fontSize: 13,
              color: theme.textSecondary,
            ),
          ),
          if (contact['barangay'] != null || contact['city_municipal'] != null)
            Text(
              'Address: ${contact['purok'] ?? ''}, ${contact['barangay'] ?? ''}, ${contact['city_municipal'] ?? ''}, ${contact['province'] ?? ''}',
              style: TextStyle(
                fontSize: 13,
                color: theme.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
