import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/api_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/reusable_widgets/card_container.dart';
import '../../../core/reusable_widgets/section_header.dart';
import '../../../core/utils/logger.dart';

class LabResultsPage extends StatefulWidget {
  const LabResultsPage({super.key});

  @override
  State<LabResultsPage> createState() => _LabResultsPageState();
}

class _LabResultsPageState extends State<LabResultsPage> {
  bool _isLoading = true;
  List<dynamic> _labResults = [];
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadLabResults();
  }

  Future<void> _loadLabResults() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    await _fetchLabResults();
  }

  Future<void> _fetchLabResults() async {
    if (_token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/patient/lab-results/'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _labResults = data['lab_results'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      AppLogger.error('Error fetching lab results', tag: 'LabResultsPage', error: e);
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
            title: 'Lab Results',
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
                : _labResults.isEmpty
                    ? _buildEmptyState(theme)
                    : _buildLabResultsList(theme),
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
            Icons.science_outlined,
            size: 80,
            color: theme.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'No Lab Results',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have no lab results on record',
            style: TextStyle(
              fontSize: 14,
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabResultsList(AppThemeData theme) {
    return ListView.builder(
      itemCount: _labResults.length,
      itemBuilder: (context, index) {
        final result = _labResults[index];
        return _buildLabResultCard(result, theme);
      },
    );
  }

  Widget _buildLabResultCard(Map<String, dynamic> result, AppThemeData theme) {
    final status = result['status'] ?? 'Pending';
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
                  color: const Color(0xFFFF9800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.biotech_outlined,
                  color: Color(0xFFFF9800),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result['test_name'] ?? 'Unknown Test',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Date: ${result['test_date'] ?? 'N/A'}',
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
          if (status.toLowerCase() == 'completed') ...[
            const SizedBox(height: 16),
            Divider(color: theme.cardBorder),
            const SizedBox(height: 12),
            _buildResultDetailRow('Result', result['result_value'] ?? 'N/A', theme),
            _buildResultDetailRow('Reference Range', result['reference_range'] ?? 'N/A', theme),
            _buildResultDetailRow('Reviewed By', result['reviewed_by'] ?? 'N/A', theme),
          ],
        ],
      ),
    );
  }

  Widget _buildResultDetailRow(String label, String value, AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
      case 'completed':
      case 'done':
        return const Color(0xFF4CAF50);
      case 'reviewed':
        return const Color(0xFF2196F3);
      case 'pending':
      default:
        return const Color(0xFFFF9800);
    }
  }
}
