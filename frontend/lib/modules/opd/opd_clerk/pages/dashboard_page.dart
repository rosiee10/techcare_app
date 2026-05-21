import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/reusable_widgets/card_container.dart';
import '../../../../core/reusable_widgets/stat_card.dart';
import '../../../../core/reusable_widgets/section_header.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../shared/settings_profile/mobile/mobile_account_page.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/homepage/mobile_dashboard_header.dart';
import '../widgets/homepage/mobile_welcome_section.dart';
import '../widgets/homepage/mobile_stats_section.dart';
import '../widgets/homepage/mobile_queue_section.dart';

/// Dashboard page with responsive mobile/desktop layouts
///
/// Mobile layout uses reusable widgets for:
/// - SliverAppBar with logo
/// - Search bar
/// - Profile header
/// - Welcome banner card
/// - Quick actions
/// - Visit queue cards
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        if (isMobile) {
          return _MobileDashboard();
        } else {
          return _DesktopDashboard();
        }
      },
    );
  }
}

/// Mobile dashboard with SliverAppBar layout using Provider
class _MobileDashboard extends ConsumerWidget {
  const _MobileDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final queueItems = ref.watch(queueItemsProvider);

    return Container(
      color: Colors.white,
      child: CustomScrollView(
        slivers: [
          // Header section (AppBar, Search, Profile)
          ...MobileDashboardHeader(
            onSearchTap: () {},
            onProfileTap: () {
              // Navigate to mobile account page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MobileAccountPage(),
                ),
              );
            },
            onNotificationTap: () {},
          ).build(),

          // Welcome and Quick Actions section
          ...MobileWelcomeSection(
            onReadMoreTap: () {},
            onRegisterTap: () {},
            onRoomTap: () {},
            onScheduleTap: () {},
            onQueueTap: () {},
          ).build(context),

          // Stats section
          ...MobileStatsSection(
            totalVisits: stats.totalVisits,
            queueWaiting: stats.queueWaiting,
            completed: stats.completed,
            activeRooms: stats.activeRooms,
          ).build(context),

          // Queue section
          ...MobileQueueSection(
            queueItems: queueItems,
            onViewAllTap: () {},
          ).build(context),

          // Bottom padding for nav bar
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }
}

/// Desktop dashboard (original layout)
class _DesktopDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeBanner(theme),
          const SizedBox(height: 24),
          _buildStatsRow(theme),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildVisitQueueTable(theme),
                    const SizedBox(height: 16),
                    _buildRecentAlerts(theme),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickActions(theme),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner(AppThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.buttonPrimary, theme.buttonPrimary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, Clerk!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.buttonPrimaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'OPD Clerk Dashboard',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.buttonPrimaryText.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.buttonPrimaryText.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.dashboard_outlined,
              size: 48,
              color: theme.buttonPrimaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(AppThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: "Today's Visits",
            value: '24',
            subtitle: 'Registered',
            icon: Icons.people_outline,
            bgColor: theme.buttonPrimary.withOpacity(0.1),
            iconColor: theme.buttonPrimary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: 'In Queue',
            value: '8',
            subtitle: 'Waiting',
            icon: Icons.queue_outlined,
            bgColor: const Color(0xFFFF9800).withOpacity(0.1),
            iconColor: const Color(0xFFFF9800),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: 'Completed',
            value: '12',
            subtitle: 'Done',
            icon: Icons.check_circle_outline,
            bgColor: const Color(0xFF4CAF50).withOpacity(0.1),
            iconColor: const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: 'Rooms Active',
            value: '5',
            subtitle: 'In Use',
            icon: Icons.meeting_room_outlined,
            bgColor: const Color(0xFF9C27B0).withOpacity(0.1),
            iconColor: const Color(0xFF9C27B0),
          ),
        ),
      ],
    );
  }

  Widget _buildVisitQueueTable(AppThemeData theme) {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: "Today's Visit Queue"),
          const SizedBox(height: 16),
          _buildTableHeader(theme),
          const SizedBox(height: 8),
          _buildQueueRow(theme, 'Q-001', 'Juan Cruz', '45 M', 'Room 101', 'In Progress', const Color(0xFF2196F3)),
          _buildQueueRow(theme, 'Q-002', 'Maria Santos', '32 F', 'Room 102', 'Waiting', const Color(0xFFFF9800)),
          _buildQueueRow(theme, 'Q-003', 'Pedro Reyes', '28 M', 'Room 103', 'Waiting', const Color(0xFFFF9800)),
          _buildQueueRow(theme, 'Q-004', 'Ana Garcia', '56 F', 'Room 104', 'Completed', const Color(0xFF4CAF50)),
        ],
      ),
    );
  }

  Widget _buildTableHeader(AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildHeaderCell('QUEUE', flex: 1),
          _buildHeaderCell('PATIENT', flex: 2),
          _buildHeaderCell('AGE/SEX', flex: 1),
          _buildHeaderCell('ROOM', flex: 1),
          _buildHeaderCell('STATUS', flex: 1),
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

  Widget _buildQueueRow(AppThemeData theme, String queue, String patient, String age, String room, String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.cardBorder.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              queue,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.buttonPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              patient,
              style: TextStyle(
                fontSize: 13,
                color: theme.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              age,
              style: TextStyle(
                fontSize: 13,
                color: theme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              room,
              style: TextStyle(
                fontSize: 13,
                color: theme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAlerts(AppThemeData theme) {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Recent Alerts'),
          const SizedBox(height: 16),
          _buildAlertItem(theme, Icons.warning_amber_rounded, 'Room 105 needs cleaning', '5 min ago', const Color(0xFFFF9800)),
          const SizedBox(height: 12),
          _buildAlertItem(theme, Icons.error_outline, 'Dr. Smith delayed by 15 min', '10 min ago', const Color(0xFFF44336)),
          const SizedBox(height: 12),
          _buildAlertItem(theme, Icons.info_outline, 'New patient registered', '15 min ago', const Color(0xFF2196F3)),
        ],
      ),
    );
  }

  Widget _buildAlertItem(AppThemeData theme, IconData icon, String message, String time, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(AppThemeData theme) {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Quick Actions'),
          const SizedBox(height: 16),
          _buildActionButton(theme, Icons.person_add_outlined, 'Register Patient', () {}),
          const SizedBox(height: 12),
          _buildActionButton(theme, Icons.meeting_room_outlined, 'Assign Room', () {}),
          const SizedBox(height: 12),
          _buildActionButton(theme, Icons.schedule_outlined, 'View Schedule', () {}),
          const SizedBox(height: 12),
          _buildActionButton(theme, Icons.monitor_outlined, 'Queue Monitor', () {}),
        ],
      ),
    );
  }

  Widget _buildActionButton(AppThemeData theme, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardBackground.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.buttonPrimary),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

