import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/reusable_widgets/card_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/service_schedule_model.dart';
import '../providers/service_schedule_provider.dart';
import '../widgets/service_schedule/service_status_card.dart';
import '../widgets/service_schedule/weekly_schedule_grid.dart';
import '../widgets/service_schedule/edit_schedule_dialog.dart';
import '../widgets/service_schedule/add_new_service_dialog.dart';
import '../widgets/room_assignment/result_dialog.dart';

/// Service Schedule Page - Weekly OPD service schedule and today's open/close status
class ServiceSchedulePage extends StatelessWidget {
  const ServiceSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ServiceScheduleProvider()..loadServices(),
      child: const _ServiceScheduleView(),
    );
  }
}

class _ServiceScheduleView extends StatefulWidget {
  const _ServiceScheduleView();

  @override
  State<_ServiceScheduleView> createState() => _ServiceScheduleViewState();
}

class _ServiceScheduleViewState extends State<_ServiceScheduleView>
    with WidgetsBindingObserver {
  Timer? _statusRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Refresh status every 30 seconds to auto-update open/closed status
    _statusRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      final provider = context.read<ServiceScheduleProvider>();
      provider.refreshTodayStatus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _statusRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh immediately when app becomes visible (time/date might have changed)
    if (state == AppLifecycleState.resumed) {
      final provider = context.read<ServiceScheduleProvider>();
      provider.refreshTodayStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final provider = context.watch<ServiceScheduleProvider>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and add button
          _PageHeader(theme: theme),
          const SizedBox(height: 24),
          // Content based on state
          Expanded(
            child: provider.isLoading
                ? _LoadingView(theme: theme)
                : provider.error != null
                    ? _ErrorView(error: provider.error!, onRetry: () => provider.loadServices())
                    : _ScheduleContent(provider: provider, theme: theme),
          ),
        ],
      ),
    );
  }
}

/// Page Header with title and add new service button
class _PageHeader extends StatelessWidget {
  final AppThemeData theme;

  const _PageHeader({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service Schedule',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Weekly OPD service schedule and today\'s open/close status',
              style: TextStyle(
                fontSize: 14,
                color: theme.textSecondary,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showAddServiceDialog(context),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add New Service'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.buttonPrimary,
            foregroundColor: theme.buttonPrimaryText,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  void _showAddServiceDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddNewServiceDialog(),
    );

    if (result != null && context.mounted) {
      // Create the service through the provider
      final success = await context.read<ServiceScheduleProvider>().createService(
        name: result['name'] as String,
        color: result['color'] as String,
        openingTime: result['openingTime'] as String,
        closingTime: result['closingTime'] as String,
        daysOpen: result['daysOpen'] as String,
      );

      if (success && context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: Text('Service "${result['name']}" added successfully'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}

/// Loading View
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

/// Error View
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  String _getErrorTitle() {
    if (error.contains('Session expired')) {
      return 'Session Expired';
    } else if (error.contains('Unauthorized')) {
      return 'Authentication Failed';
    } else if (error.contains('Connection') || error.contains('timeout')) {
      return 'Connection Error';
    } else if (error.contains('404')) {
      return 'Service Not Found';
    }
    return 'Error Loading Services';
  }

  String _getErrorMessage() {
    if (error.contains('Session expired')) {
      return 'Your session has expired. Please log in again.';
    } else if (error.contains('Unauthorized')) {
      return 'You are not authorized to access this resource.';
    } else if (error.contains('Connection') || error.contains('timeout')) {
      return 'Unable to connect to the server. Check your internet connection.';
    } else if (error.contains('404')) {
      return 'The service schedule endpoint was not found.';
    }
    return error;
  }

  IconData _getErrorIcon() {
    if (error.contains('Session expired')) {
      return Icons.lock_outline;
    } else if (error.contains('Connection') || error.contains('timeout')) {
      return Icons.cloud_off_outlined;
    } else if (error.contains('Unauthorized')) {
      return Icons.security_outlined;
    }
    return Icons.error_outline;
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getErrorIcon(), size: 48, color: theme.error),
          const SizedBox(height: 16),
          Text(
            _getErrorTitle(),
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _getErrorMessage(),
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textMuted, fontSize: 13),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Main Content with Today's Status and Weekly Grid
class _ScheduleContent extends StatelessWidget {
  final ServiceScheduleProvider provider;
  final AppThemeData theme;

  const _ScheduleContent({required this.provider, required this.theme});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today's Status Section
          _TodayStatusSection(
            services: provider.services,
            theme: theme,
          ),
          const SizedBox(height: 24),
          // Weekly Schedule Grid Section
          _WeeklyScheduleSection(
            services: provider.services,
            todayIndex: provider.currentDayIndex,
            onDayToggle: provider.toggleServiceDay,
            onEdit: (serviceId) => _showEditDialog(context, serviceId),
            onDelete: (serviceId) => _showDeleteDialog(context, serviceId),
            theme: theme,
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, String serviceId) {
    // Read fresh service data from provider right before opening dialog
    try {
      final service = provider.services.firstWhere((s) => s.id == serviceId);
      showDialog(
        context: context,
        builder: (context) => EditScheduleDialog(
          service: service,
          onSave: (dailyHours, weeklySchedule, colorHex) {
            provider.updateDailyHours(serviceId, dailyHours, weeklySchedule, colorHex);
          },
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteDialog(BuildContext context, String serviceId) {
    // Get service name for confirmation message
    try {
      final service = provider.services.firstWhere((s) => s.id == serviceId);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete "${service.name}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                print('[DEBUG] Calling deleteService for service: $serviceId');
                final success = await provider.deleteService(serviceId);
                print('[DEBUG] Delete result: $success');
                if (success && context.mounted) {
                  showSuccessDialog(
                    context,
                    title: 'Service Deleted',
                    message: 'Service "${service.name}" has been deleted successfully.',
                  );
                } else if (!success && context.mounted) {
                  showErrorDialog(
                    context,
                    title: 'Delete Failed',
                    message: 'Failed to delete service "${service.name}". Please try again.',
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Today's Status Section
class _TodayStatusSection extends StatelessWidget {
  final List<ServiceScheduleModel> services;
  final AppThemeData theme;

  const _TodayStatusSection({required this.services, required this.theme});

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TODAY\'S STATUS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: theme.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'Last Updated: ${services.isNotEmpty ? services.first.getLastUpdatedText() : 'Never'}',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 6,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return Stack(
                children: [
                  ServiceStatusCard(
                    service: service,
                    onTap: service.isActive
                        ? () {
                            context.read<ServiceScheduleProvider>().toggleTodayStatus(service.id);
                          }
                        : null,
                  ),
                  // Active/Inactive Badge
                  if (!service.isActive)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Inactive',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Weekly Schedule Section
class _WeeklyScheduleSection extends StatelessWidget {
  final List<ServiceScheduleModel> services;
  final int todayIndex;
  final Function(String, int)? onDayToggle;
  final Function(String)? onEdit;
  final Function(String)? onDelete;
  final AppThemeData theme;

  const _WeeklyScheduleSection({
    required this.services,
    required this.todayIndex,
    this.onDayToggle,
    this.onEdit,
    this.onDelete,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Schedule Grid',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Constrained height with scrolling for all services
          SizedBox(
            height: 320,
            child: SingleChildScrollView(
              child: WeeklyScheduleGrid(
                services: services,
                todayIndex: todayIndex,
                onDayToggle: onDayToggle,
                onEdit: onEdit,
                onDelete: onDelete,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
