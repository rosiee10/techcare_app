import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/provider/auth_provider.dart';
import '../../providers/patient_profile_provider.dart';

/// Visit history table widget showing patient visit records
class VisitHistoryTable extends StatelessWidget {
  final VoidCallback onBackPressed;
  final VoidCallback? onAddVisitPressed;

  const VisitHistoryTable({
    super.key,
    required this.onBackPressed,
    this.onAddVisitPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final provider = context.watch<PatientProfileProvider>();
    
    // Sample visit data - in production this would come from provider.patient!.visits or API
    final visits = _getSampleVisits();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, theme),
        const SizedBox(height: 16),
        _buildVisitCount(theme, visits.length),
        const SizedBox(height: 12),
        _buildTable(theme, visits),
        const SizedBox(height: 12),
        _buildFooter(theme, visits),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, AppThemeData theme) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.role?.toUpperCase();
    final isClerk = userRole == 'OPD CLERK' || userRole == 'CLERK';

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: onBackPressed,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        Text(
          'Visit History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            letterSpacing: 0.3,
          ),
        ),
        const Spacer(),
        if (isClerk && onAddVisitPressed != null)
          _AddVisitButton(theme: theme, onPressed: onAddVisitPressed!),
      ],
    );
  }

  Widget _buildVisitCount(AppThemeData theme, int count) {
    return Text(
      '($count visits)',
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildTable(AppThemeData theme, List<Map<String, String>> visits) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 300),
      child: SingleChildScrollView(
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2.5),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(1.5),
            3: FlexColumnWidth(3),
            4: FlexColumnWidth(2),
            5: FlexColumnWidth(1.2),
          },
          children: [
            _buildHeaderRow(theme),
            ...visits.map((visit) => _buildDataRow(visit, theme)),
          ],
        ),
      ),
    );
  }

  TableRow _buildHeaderRow(AppThemeData theme) {
    return TableRow(
      decoration: BoxDecoration(
        color: theme.buttonPrimary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      children: [
        _TableHeader(text: 'DATE', theme: theme),
        _TableHeader(text: 'QUEUE NO', theme: theme),
        _TableHeader(text: 'SERVICE', theme: theme),
        _TableHeader(text: 'CHIEF COMPLAINT', theme: theme),
        _TableHeader(text: 'DOCTOR', theme: theme),
        _TableHeader(text: 'STATUS', theme: theme),
      ],
    );
  }

  TableRow _buildDataRow(Map<String, String> visit, AppThemeData theme) {
    return TableRow(
      children: [
        _TableCell(text: visit['date']!, theme: theme, isDate: true),
        _TableCell(text: visit['queueNo']!, theme: theme),
        _TableCell(text: visit['service']!, theme: theme, isLink: true),
        _TableCell(text: visit['complaint']!, theme: theme),
        _TableCell(text: visit['doctor']!, theme: theme),
        _StatusCell(status: visit['status']!),
      ],
    );
  }

  Widget _buildFooter(AppThemeData theme, List<Map<String, String>> visits) {
    return Text(
      'Total visits: ${visits.length} • Last visit: ${visits.first['date']}',
      style: TextStyle(
        fontSize: 11,
        color: Colors.grey[500],
      ),
    );
  }

  List<Map<String, String>> _getSampleVisits() {
    return [
      {'date': 'Feb 26, 2026', 'queueNo': 'Q-001', 'service': 'FAMED', 'complaint': 'Lagnat 2 araw', 'doctor': 'Dr. Cruz', 'status': 'Done'},
      {'date': 'Jan 10, 2026', 'queueNo': 'V-088', 'service': 'FAMED', 'complaint': 'HTN follow-up', 'doctor': 'Dr. Cruz', 'status': 'Done'},
      {'date': 'Dec 05, 2025', 'queueNo': 'V-071', 'service': 'FAMED', 'complaint': 'Sakit ng tiyan', 'doctor': 'Dr. Cruz', 'status': 'Done'},
      {'date': 'Oct 14, 2025', 'queueNo': 'V-059', 'service': 'FAMED', 'complaint': 'Annual check-up', 'doctor': 'Dr. Cruz', 'status': 'Done'},
    ];
  }
}

/// Add visit button with gradient styling
class _AddVisitButton extends StatelessWidget {
  final AppThemeData theme;
  final VoidCallback onPressed;

  const _AddVisitButton({
    required this.theme,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.buttonPrimary,
              theme.buttonPrimary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.buttonPrimary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16, color: Colors.white),
            SizedBox(width: 4),
            Text(
              'Add Visit',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Table header cell
class _TableHeader extends StatelessWidget {
  final String text;
  final AppThemeData theme;

  const _TableHeader({required this.text, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: theme.buttonPrimary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Table data cell
class _TableCell extends StatelessWidget {
  final String text;
  final AppThemeData theme;
  final bool isDate;
  final bool isLink;

  const _TableCell({
    required this.text,
    required this.theme,
    this.isDate = false,
    this.isLink = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isDate ? FontWeight.w600 : FontWeight.w400,
          color: isLink ? theme.buttonPrimary : Colors.black87,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Status badge cell
class _StatusCell extends StatelessWidget {
  final String status;

  const _StatusCell({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDone = status.toLowerCase() == 'done';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDone ? Colors.green[50] : Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDone ? Colors.green[200]! : Colors.orange[200]!,
            width: 1,
          ),
        ),
        child: Text(
          status,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: isDone ? Colors.green[700] : Colors.orange[700],
          ),
        ),
      ),
    );
  }
}
