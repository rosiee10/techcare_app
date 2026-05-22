import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/reusable_widgets/techcare_search_bar.dart';
import '../../../../core/widgets/table/index.dart';
import '../providers/patient_list_provider.dart';
import '../widgets/patient_list/patient_list_header.dart';
import '../../shared/pages/patient_profile_page.dart';

class PatientListPage extends StatelessWidget {
  final VoidCallback? onRegisterPatientPressed;
  final Function(String)? onViewPatient;
  
  const PatientListPage({
    super.key,
    this.onRegisterPatientPressed,
    this.onViewPatient,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PatientListProvider()..loadPatients(),
      child: _PatientListView(
        onRegisterPatientPressed: onRegisterPatientPressed,
        onViewPatient: onViewPatient,
      ),
    );
  }
}

class _PatientListView extends StatefulWidget {
  final VoidCallback? onRegisterPatientPressed;
  final Function(String)? onViewPatient;
  
  const _PatientListView({
    this.onRegisterPatientPressed,
    this.onViewPatient,
  });

  @override
  State<_PatientListView> createState() => _PatientListViewState();
}

class _PatientListViewState extends State<_PatientListView> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final provider = context.watch<PatientListProvider>();
    final isMobile = Responsive.isMobile(context);

    if (isMobile) {
      return _buildMobileLayout(provider, theme, context);
    } else {
      return _buildDesktopLayout(provider, theme, context);
    }
  }

  Widget _buildMobileLayout(PatientListProvider provider, AppThemeData theme, BuildContext context) {
    return Container(
      color: Colors.white,
      child: CustomScrollView(
        slivers: [
          // SliverAppBar with title
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            expandedHeight: 56,
            toolbarHeight: 56,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                // Navigate back to OPD clerk dashboard instead of popping
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/opd/clerk/dashboard',
                  (route) => false,
                );
              },
            ),
            title: Text(
              'PATIENT LIST',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
            ),
            centerTitle: true,
          ),

          // Search and Filter Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                children: [
                  // Search Bar using TechCareSearchBar design
                  TechCareSearchBar(
                    controller: _searchController,
                    hintText: 'Search patients...',
                    onChanged: provider.updateSearchQuery,
                    margin: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  // Status Filter
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: provider.selectedStatus,
                            underline: const SizedBox(),
                            items: ['All Status', 'Active', 'Inactive']
                                .map((status) => DropdownMenuItem(
                                      value: status,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Text(status),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) provider.updateStatusFilter(value);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Patient List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            sliver: _buildMobilePatientListSliver(provider, theme, context),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(PatientListProvider provider, AppThemeData theme, BuildContext context) {
    return Container(
      color: theme.pageBackground,
      child: Column(
        children: [
          // Header Card with Title, Search, Status Filter, and Register Button
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
            child: PatientListHeader(
              totalPatients: provider.totalPatients,
              activePatients: provider.activePatients,
              onRegisterPatient: widget.onRegisterPatientPressed ?? () => _showRegisterPatientDialog(context),
              searchController: _searchController,
              selectedStatus: provider.selectedStatus,
              onSearchChanged: provider.updateSearchQuery,
              onStatusChanged: (value) {
                if (value != null) provider.updateStatusFilter(value);
              },
            ),
          ),

          const SizedBox(height: 16),

          // Patient Table
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _buildPatientTable(provider, theme, context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobilePatientListSliver(PatientListProvider provider, AppThemeData theme, BuildContext context) {
    if (provider.isLoading) {
      return SliverToBoxAdapter(child: _buildLoadingState(theme));
    }

    if (provider.errorMessage != null) {
      return SliverToBoxAdapter(child: _buildErrorState(provider, theme));
    }

    if (provider.patients.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyState(theme));
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == provider.paginatedPatients.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: _buildMobilePagination(provider, theme),
            );
          }

          final patient = provider.paginatedPatients[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildMobilePatientCard(patient, theme, context),
          );
        },
        childCount: provider.paginatedPatients.length + 1,
      ),
    );
  }

  Widget _buildMobilePatientCard(dynamic patient, AppThemeData theme, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with ID and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TableIdBadge(id: patient.hospitalId),
              StatusBadge(status: patient.status),
            ],
          ),
          const SizedBox(height: 12),

          // Patient Name with Avatar
          Row(
            children: [
              TableAvatar(
                initials: patient.initials,
                photoUrl: patient.photoUrl,
                userName: patient.fullName,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.fullName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'DOB: ${patient.birthDate}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Age/Sex and Last Visit
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Age / Sex',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      patient.ageSexDisplay.replaceAll('\n', ' / '),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Last Visit',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      patient.lastVisit,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      patient.department,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _viewPatient(context, patient.hospitalId),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    backgroundColor: theme.buttonPrimary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _addVisit(context, patient.hospitalId),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Visit'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    backgroundColor: theme.success,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobilePagination(PatientListProvider provider, AppThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${provider.currentPage} of ${provider.totalPages}',
            style: TextStyle(
              fontSize: 12,
              color: theme.textSecondary,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: provider.currentPage > 1
                    ? () => provider.setPage(provider.currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
                iconSize: 20,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
              ),
              IconButton(
                onPressed: provider.currentPage < provider.totalPages
                    ? () => provider.setPage(provider.currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
                iconSize: 20,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientTable(PatientListProvider provider, AppThemeData theme, BuildContext context) {
    if (provider.isLoading) {
      return _buildLoadingState(theme);
    }

    if (provider.errorMessage != null) {
      return _buildErrorState(provider, theme);
    }

    if (provider.patients.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ModernTable(
      columns: const [
        TableColumn(label: 'HOSPITAL ID', flex: 2),
        TableColumn(label: 'PATIENT NAME', flex: 3),
        TableColumn(label: 'AGE / SEX', flex: 1),
        TableColumn(label: 'LAST VISIT', flex: 2),
        TableColumn(label: 'STATUS', flex: 2),
        TableColumn(label: 'ACTION', flex: 2),
      ],
      rows: provider.paginatedPatients.map((patient) {
        return ModernTableRow(
          cells: [
            // Hospital ID
            ModernTableCell(
              flex: 2,
              child: TableIdBadge(
                id: patient.hospitalId,
              ),
            ),
            // Patient Name with Avatar
            ModernTableCell(
              flex: 3,
              child: Row(
                children: [
                  TableAvatar(
                    initials: patient.initials,
                    photoUrl: patient.photoUrl,
                    userName: patient.fullName,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TableTextCell(
                      primaryText: patient.fullName,
                      secondaryText: 'DOB: ${patient.birthDate}',
                    ),
                  ),
                ],
              ),
            ),
            // Age/Sex
            ModernTableCell(
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
            ModernTableCell(
              flex: 2,
              child: TableTextCell(
                primaryText: patient.lastVisit,
                secondaryText: patient.department,
              ),
            ),
            // Status Badge
            ModernTableCell(
              flex: 2,
              child: StatusBadge(status: patient.status),
            ),
            // Actions
            ModernTableCell(
              flex: 2,
              child: Row(
                children: [
                  TableActionButton(
                    icon: Icons.visibility,
                    label: 'View',
                    onPressed: () => _viewPatient(context, patient.hospitalId),
                  ),
                  TableActionButton(
                    icon: Icons.add,
                    label: 'Visit',
                    onPressed: () => _addVisit(context, patient.hospitalId),
                    color: theme.success,
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
      pagination: ModernTablePagination(
        currentPage: provider.currentPage,
        totalPages: provider.totalPages,
        rowsPerPage: provider.rowsPerPage,
        totalItems: provider.patients.length,
        onPageChanged: provider.setPage,
        onRowsPerPageChanged: (value) {
          if (value != null) provider.setRowsPerPage(value);
        },
      ),
    );
  }

  Widget _buildLoadingState(AppThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.buttonPrimary),
          const SizedBox(height: 16),
          Text(
            'Loading patients...',
            style: TextStyle(color: theme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(PatientListProvider provider, AppThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.error),
          const SizedBox(height: 16),
          Text(
            provider.errorMessage!,
            style: TextStyle(color: theme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: provider.loadPatients,
            child: const Text('Retry'),
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
          Icon(Icons.people_outline, size: 48, color: theme.textMuted),
          const SizedBox(height: 16),
          Text(
            'No patients found',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              color: theme.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showRegisterPatientDialog(BuildContext context) {
    Navigator.pushNamed(context, '/opd/clerk/dashboard', arguments: 2);
  }

  void _viewPatient(BuildContext context, String hospitalId) {
    if (widget.onViewPatient != null) {
      widget.onViewPatient!(hospitalId);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PatientProfilePage(hospitalId: hospitalId),
        ),
      );
    }
  }

  void _addVisit(BuildContext context, String hospitalId) {
    Navigator.pushNamed(
      context,
      '/opd-clerk/add-visit',
      arguments: hospitalId,
    );
  }
}
