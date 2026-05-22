import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../modules/shared/settings_profile/widgets/photo_viewer_widget.dart';
import '../../../opd_clerk/data/models/patient_model.dart';
import '../../providers/patient_profile_provider.dart';
import 'patient_info_dialog.dart';

/// Patient profile card widget showing avatar, name, ID, status, and action buttons
class PatientProfileCard extends StatelessWidget {
  final PatientModel patient;
  final String displayName;
  final VoidCallback? onFullInfoPressed;

  const PatientProfileCard({
    super.key,
    required this.patient,
    required this.displayName,
    this.onFullInfoPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAvatar(context, theme),
            const SizedBox(height: 16),
            _buildName(theme),
            const SizedBox(height: 8),
            _buildHospitalIdAndStatus(theme),
            const SizedBox(height: 8),
            _buildQueueStatusLabel(theme),
            const SizedBox(height: 16),
            _buildEndQueueButton(theme),
            const SizedBox(height: 20),
            _buildFullInfoButton(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, AppThemeData theme) {
    return Center(
      child: GestureDetector(
        onTap: patient.photoUrl != null && patient.photoUrl!.isNotEmpty
            ? () => _viewPhoto(context)
            : null,
        child: Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: theme.buttonPrimary.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.buttonPrimary.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: Container(
              color: patient.photoUrl == null || patient.photoUrl!.isEmpty
                  ? theme.buttonPrimary.withOpacity(0.15)
                  : null,
              child: patient.photoUrl != null && patient.photoUrl!.isNotEmpty
                  ? Image.network(
                      patient.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildInitialsFallback(theme),
                    )
                  : _buildInitialsFallback(theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialsFallback(AppThemeData theme) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.buttonPrimary.withOpacity(0.1),
              theme.buttonPrimary.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            patient.initials,
            style: TextStyle(
              color: theme.buttonPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 30,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  void _viewPhoto(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoViewerWidget(
          photoUrl: patient.photoUrl!,
          userName: patient.fullName,
        ),
      ),
    );
  }

  Widget _buildName(AppThemeData theme) {
    return Text(
      displayName,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: theme.buttonPrimary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildHospitalIdAndStatus(AppThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          patient.hospitalId,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.buttonPrimary.withOpacity(0.9),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.buttonPrimary.withOpacity(0.2),
                theme.buttonPrimary.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.buttonPrimary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            patient.status,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: theme.buttonPrimary,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQueueStatusLabel(AppThemeData theme) {
    return Text(
      'QUEUE STATUS :',
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: theme.buttonPrimary.withOpacity(0.8),
      ),
    );
  }

  Widget _buildEndQueueButton(AppThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFEF5350),
                  const Color(0xFFE53935),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE53935).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'END QUEUE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPatientInfoDialog(BuildContext context) {
    final provider = context.read<PatientProfileProvider>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PatientInfoDialog(
          patient: patient,
          provider: provider,
        );
      },
    );
  }

  Widget _buildFullInfoButton(BuildContext context, AppThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onFullInfoPressed ?? () => _showPatientInfoDialog(context),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.buttonPrimary.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.buttonPrimary.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_outline,
                  color: theme.buttonPrimary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Full Info',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.buttonPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable action button widget
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(
                colors: [
                  theme.buttonPrimary,
                  theme.buttonPrimary.withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: !isPrimary ? Colors.white.withOpacity(0.9) : null,
        borderRadius: BorderRadius.circular(10),
        border: !isPrimary
            ? Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1.5,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isPrimary ? Colors.white : theme.buttonPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isPrimary ? Colors.white : theme.buttonPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
