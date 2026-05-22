import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../data/models/patient_model.dart';

class PatientTableRow extends StatelessWidget {
  final PatientModel patient;
  final VoidCallback? onView;
  final VoidCallback? onVisit;

  const PatientTableRow({
    super.key,
    required this.patient,
    this.onView,
    this.onVisit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.cardBorder.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          // Hospital ID
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.hospitalId,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.buttonPrimary,
                  ),
                ),
                Text(
                  patient.patientId,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Patient Name with Avatar
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.buttonPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      patient.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.fullName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: theme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'DOB: ${patient.birthDate}',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Age/Sex
          Expanded(
            flex: 1,
            child: Text(
              patient.ageSexDisplay,
              style: TextStyle(
                fontSize: 12,
                color: theme.textSecondary,
              ),
            ),
          ),
          // Last Visit
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.lastVisit,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textPrimary,
                  ),
                ),
                Text(
                  patient.department,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Status Badge
          Expanded(
            flex: 2,
            child: _buildStatusBadge(patient.status, theme),
          ),
          // Actions
          Expanded(
            flex: 2,
            child: Row(
              children: [
                if (onView != null)
                  TextButton.icon(
                    onPressed: onView,
                    icon: Icon(Icons.visibility, size: 16, color: theme.buttonPrimary),
                    label: Text(
                      'View',
                      style: TextStyle(color: theme.buttonPrimary),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                if (onVisit != null)
                  TextButton.icon(
                    onPressed: onVisit,
                    icon: Icon(Icons.add, size: 16, color: theme.success),
                    label: Text(
                      'Visit',
                      style: TextStyle(color: theme.success),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, AppThemeData theme) {
    Color bgColor;
    Color textColor;
    
    switch (status.toLowerCase()) {
      case 'outpatient':
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1976D2);
        break;
      case 'inpatient':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFF57C00);
        break;
      case 'emergency':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFD32F2F);
        break;
      case 'discharged':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF388E3C);
        break;
      default:
        bgColor = theme.cardBackground;
        textColor = theme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}
