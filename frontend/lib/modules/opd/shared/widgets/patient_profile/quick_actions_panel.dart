import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/provider/auth_provider.dart';
import '../../providers/patient_profile_provider.dart';

/// Quick actions panel showing role-specific action buttons
class QuickActionsPanel extends StatelessWidget {
  final VoidCallback? onMedicalRecordsPressed;
  final VoidCallback? onPrescribePressed;
  final VoidCallback? onVitalsPressed;
  final VoidCallback? onLabOrderPressed;

  const QuickActionsPanel({
    super.key,
    this.onMedicalRecordsPressed,
    this.onPrescribePressed,
    this.onVitalsPressed,
    this.onLabOrderPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.role?.toUpperCase();
    
    final isDoctor = userRole == 'DOCTOR';
    final isNurse = userRole == 'NURSE';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ActionButton(
              label: 'Visit History',
              icon: Icons.history,
              onPressed: () {
                context.read<PatientProfileProvider>().setShowVisitHistory(true);
              },
              isPrimary: true,
              compact: true,
            ),
            _ActionButton(
              label: 'Medical Records',
              icon: Icons.description_outlined,
              onPressed: onMedicalRecordsPressed ?? () {},
              isPrimary: false,
              compact: true,
            ),
            if (isDoctor)
              _ActionButton(
                label: 'Prescribe',
                icon: Icons.medical_services_outlined,
                onPressed: onPrescribePressed ?? () {},
                isPrimary: false,
                compact: true,
              ),
            if (isNurse || isDoctor)
              _ActionButton(
                label: 'Vitals',
                icon: Icons.favorite_outline,
                onPressed: onVitalsPressed ?? () {},
                isPrimary: false,
                compact: true,
              ),
            if (isDoctor)
              _ActionButton(
                label: 'Lab Order',
                icon: Icons.biotech_outlined,
                onPressed: onLabOrderPressed ?? () {},
                isPrimary: false,
                compact: true,
              ),
          ],
        ),
      ],
    );
  }
}

/// Compact action button for quick actions
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool compact;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
    this.compact = false,
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
        color: !isPrimary ? theme.buttonPrimary.withOpacity(0.08) : null,
        borderRadius: BorderRadius.circular(10),
        border: !isPrimary
            ? Border.all(
                color: theme.buttonPrimary.withOpacity(0.3),
                width: 1.5,
              )
            : null,
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: theme.buttonPrimary.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: compact
                ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
                : const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
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
