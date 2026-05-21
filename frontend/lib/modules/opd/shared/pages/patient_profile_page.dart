import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../opd_clerk/data/models/patient_model.dart';
import '../providers/patient_profile_provider.dart';
import '../widgets/patient_profile/patient_profile_card.dart';
import '../widgets/patient_profile/quick_actions_panel.dart';
import '../widgets/patient_profile/visit_history_table.dart';
import '../widgets/patient_profile/new_visit_dialog.dart';

/// Patient Profile Page - Main entry point
/// 
/// Clean architecture using:
/// - Provider for state management (PatientProfileProvider)
/// - Reusable widgets for UI components
/// - Separation of concerns
class PatientProfilePage extends StatelessWidget {
  final String hospitalId;
  final VoidCallback? onBack;

  const PatientProfilePage({
    super.key,
    required this.hospitalId,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PatientProfileProvider(hospitalId: hospitalId),
      child: _PatientProfileView(hospitalId: hospitalId, onBack: onBack),
    );
  }
}

class _PatientProfileView extends StatelessWidget {
  final String hospitalId;
  final VoidCallback? onBack;

  const _PatientProfileView({
    required this.hospitalId,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final provider = context.watch<PatientProfileProvider>();

    if (provider.isLoading) {
      return _LoadingView(theme: theme);
    }

    if (provider.patient == null) {
      return _ErrorView(onBack: onBack);
    }

    return _ProfileContent(
      patient: provider.patient!,
      onBack: onBack,
    );
  }
}

/// Loading state view
class _LoadingView extends StatelessWidget {
  final AppThemeData theme;

  const _LoadingView({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(color: theme.buttonPrimary),
    );
  }
}

/// Error/not found state view
class _ErrorView extends StatelessWidget {
  final VoidCallback? onBack;

  const _ErrorView({this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 48, color: theme.textMuted),
          const SizedBox(height: 16),
          Text(
            'Patient not found',
            style: TextStyle(color: theme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (onBack != null) {
                onBack!();
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Back to Patient List'),
          ),
        ],
      ),
    );
  }
}

/// Main profile content with two-column layout
class _ProfileContent extends StatelessWidget {
  final PatientModel patient;
  final VoidCallback? onBack;

  const _ProfileContent({
    required this.patient,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final provider = context.read<PatientProfileProvider>();

    return Container(
      color: theme.pageBackground,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Back Button
            _BackButton(onBack: onBack),
            // Main Content
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: _ProfileLayout(
                patient: patient,
                displayName: provider.getDisplayNameWithInitial(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Back button widget
class _BackButton extends StatelessWidget {
  final VoidCallback? onBack;

  const _BackButton({this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 32, top: 20, bottom: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.buttonPrimary,
                theme.buttonPrimary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: theme.buttonPrimary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (onBack != null) {
                  onBack!();
                } else {
                  Navigator.of(context).pop();
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Back to List',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two-column profile layout
class _ProfileLayout extends StatelessWidget {
  final PatientModel patient;
  final String displayName;

  const _ProfileLayout({
    required this.patient,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Patient Profile Card (25%)
        Expanded(
          flex: 1,
          child: _PatientInfoCard(
            patient: patient,
            displayName: displayName,
          ),
        ),
        const SizedBox(width: 24),
        // Right: Quick Actions (75%)
        Expanded(
          flex: 3,
          child: _QuickActionsSection(),
        ),
      ],
    );
  }
}

/// Patient info card wrapper
class _PatientInfoCard extends StatelessWidget {
  final PatientModel patient;
  final String displayName;

  const _PatientInfoCard({
    required this.patient,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    // Uses PatientProfileCard with default PatientInfoDialog
    return PatientProfileCard(
      patient: patient,
      displayName: displayName,
    );
  }
}

/// Quick actions section with conditional visit history overlay
class _QuickActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PatientProfileProvider>();

    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.topLeft,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: provider.showVisitHistory
            ? VisitHistoryTable(
                key: const ValueKey('visit_history'),
                onBackPressed: () => provider.setShowVisitHistory(false),
                onAddVisitPressed: () => _addVisit(context),
              )
            : QuickActionsPanel(
                key: const ValueKey('quick_actions'),
                onMedicalRecordsPressed: () => _showMedicalRecords(context),
                onPrescribePressed: () => _showPrescription(context),
                onVitalsPressed: () => _showVitals(context),
                onLabOrderPressed: () => _showLabOrder(context),
              ),
      ),
    );
  }

  void _addVisit(BuildContext context) {
    final patient = context.read<PatientProfileProvider>().patient;
    if (patient == null) return;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return NewVisitDialog(patient: patient);
      },
    );
  }

  void _showMedicalRecords(BuildContext context) {
    // TODO: Navigate to medical records
  }

  void _showPrescription(BuildContext context) {
    // TODO: Navigate to prescription
  }

  void _showVitals(BuildContext context) {
    // TODO: Navigate to vitals
  }

  void _showLabOrder(BuildContext context) {
    // TODO: Navigate to lab order
  }
}
