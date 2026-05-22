import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

class PatientTableHeader extends StatelessWidget {
  const PatientTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardBackground.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          _buildHeaderCell('HOSPITAL ID', flex: 2),
          _buildHeaderCell('PATIENT NAME', flex: 3),
          _buildHeaderCell('AGE / SEX', flex: 1),
          _buildHeaderCell('LAST VISIT', flex: 2),
          _buildHeaderCell('STATUS', flex: 2),
          _buildHeaderCell('ACTION', flex: 2),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }
}
