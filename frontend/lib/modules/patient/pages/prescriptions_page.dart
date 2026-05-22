import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/api_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/reusable_widgets/card_container.dart';
import '../../../core/reusable_widgets/section_header.dart';
import '../../../core/utils/logger.dart';

class PrescriptionsPage extends StatefulWidget {
  const PrescriptionsPage({super.key});

  @override
  State<PrescriptionsPage> createState() => _PrescriptionsPageState();
}

class _PrescriptionsPageState extends State<PrescriptionsPage> {
  bool _isLoading = true;
  List<dynamic> _prescriptions = [];
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    await _fetchPrescriptions();
  }

  Future<void> _fetchPrescriptions() async {
    if (_token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/patient/prescriptions/'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _prescriptions = data['prescriptions'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      AppLogger.error('Error fetching prescriptions', tag: 'PrescriptionsPage', error: e);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Container(
      color: theme.pageBackground,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'My Prescriptions',
            fontSize: 24,
            color: theme.textPrimary,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(theme.buttonPrimary),
                    ),
                  )
                : _prescriptions.isEmpty
                    ? _buildEmptyState(theme)
                    : _buildPrescriptionsList(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medication_outlined,
            size: 80,
            color: theme.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'No Prescriptions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have no active prescriptions at this time',
            style: TextStyle(
              fontSize: 14,
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionsList(AppThemeData theme) {
    return ListView.builder(
      itemCount: _prescriptions.length,
      itemBuilder: (context, index) {
        final prescription = _prescriptions[index];
        return _buildPrescriptionCard(prescription, theme);
      },
    );
  }

  Widget _buildPrescriptionCard(Map<String, dynamic> prescription, AppThemeData theme) {
    final status = prescription['status'] ?? 'Active';
    final statusColor = _getStatusColor(status, theme);

    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.medication_liquid_outlined,
                  color: Color(0xFF9C27B0),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prescription['medication_name'] ?? 'Unknown Medication',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Prescribed: ${prescription['prescribed_date'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: theme.cardBorder),
          const SizedBox(height: 12),
          _buildPrescriptionDetailRow('Doctor', prescription['doctor_name'] ?? 'N/A', theme),
          _buildPrescriptionDetailRow('Dosage', prescription['dosage'] ?? 'N/A', theme),
          _buildPrescriptionDetailRow('Frequency', prescription['frequency'] ?? 'N/A', theme),
          _buildPrescriptionDetailRow('Duration', prescription['duration'] ?? 'N/A', theme),
          if (prescription['instructions'] != null && prescription['instructions'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.isDark ? const Color(0xFF4D3A1B) : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFFFF9800),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Instructions: ${prescription['instructions']}',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrescriptionDetailRow(String label, String value, AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: theme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status, AppThemeData theme) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF9C27B0);
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'cancelled':
        return theme.error;
      case 'expired':
      default:
        return theme.textMuted;
    }
  }
}
