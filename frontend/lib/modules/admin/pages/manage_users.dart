import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/manage_users_provider.dart';
import '../models/user_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/reusable_widgets/logo_carousel_loading.dart';
import '../../../core/widgets/table/index.dart';
import '../widgets/manage_user/user_form_dialog.dart';
import '../widgets/manage_user/view_user_dialog.dart';
import '../widgets/manage_user/search_filter_bar.dart';

/// Manage Users Page - Complete user management interface
/// Follows OOP principles with clean separation of concerns
/// Uses Provider for state management
class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load users when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManageUsersProvider>().loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Consumer<ManageUsersProvider>(
      builder: (context, provider, child) {
        return Container(
          color: theme.pageBackground,
          child: Column(
            children: [
              // Unified Top Row - Title/Stats | Search | Create Button wrapped in card
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: theme.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.cardBorder, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: theme.cardShadow.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Left: Title and Stats
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MANAGE USER',
                            style: theme.titleStyle.copyWith(fontSize: 20),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${provider.totalUsers} TOTAL | ${provider.activeUsers} ACTIVE',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      
                      // Center: Search Bar (expanded)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: theme.pageBackground,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: theme.cardBorder),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: provider.updateSearchQuery,
                              style: TextStyle(color: theme.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Search by name, username, or role...',
                                hintStyle: TextStyle(color: theme.textMuted),
                                prefixIcon: Icon(Icons.search, color: theme.textMuted),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Role Filter
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: theme.cardBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.cardBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: provider.selectedRole,
                            isExpanded: false,
                            icon: Icon(Icons.arrow_drop_down, color: theme.textSecondary, size: 20),
                            dropdownColor: theme.cardBackground,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            items: ['All Roles', 'ADMIN', 'DOCTOR', 'NURSE', 'OPD_CLERK', 'PHARMACY'].map((item) {
                              return DropdownMenuItem<String>(
                                value: item,
                                child: Text(
                                  item,
                                  style: TextStyle(color: theme.textPrimary),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) => provider.updateRoleFilter(value!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // Status Filter
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: theme.cardBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.cardBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: provider.selectedStatus,
                            isExpanded: false,
                            icon: Icon(Icons.arrow_drop_down, color: theme.textSecondary, size: 20),
                            dropdownColor: theme.cardBackground,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            items: ['All Status', 'Active', 'Inactive'].map((item) {
                              return DropdownMenuItem<String>(
                                value: item,
                                child: Text(
                                  item,
                                  style: TextStyle(color: theme.textPrimary),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) => provider.updateStatusFilter(value!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      ElevatedButton.icon(
                        onPressed: _showCreateUserDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Create Account'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.buttonPrimary,
                          foregroundColor: theme.buttonPrimaryText,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Content Section
              Expanded(
                child: provider.isLoading
                    ? _buildLoadingState(theme)
                    : provider.errorMessage != null
                        ? _buildErrorState(provider, theme)
                        : _buildUserTable(provider, theme),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build loading state
  Widget _buildLoadingState(AppThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Loading users...', style: TextStyle(color: theme.textMuted)),
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(ManageUsersProvider provider, AppThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.textMuted),
          const SizedBox(height: 16),
          Text(
            provider.errorMessage!,
            style: TextStyle(color: theme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => provider.loadUsers(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.buttonPrimary,
              foregroundColor: theme.buttonPrimaryText,
            ),
          ),
        ],
      ),
    );
  }

  /// Build user table using ModernTable
  Widget _buildUserTable(ManageUsersProvider provider, AppThemeData theme) {
    if (provider.users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: theme.textMuted),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(fontSize: 16, color: theme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(fontSize: 14, color: theme.textMuted),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: ModernTable(
        columns: const [
          TableColumn(label: 'USER', flex: 3),
          TableColumn(label: 'USERNAME', flex: 2),
          TableColumn(label: 'ROLE', flex: 2),
          TableColumn(label: 'LAST LOGIN', flex: 2),
          TableColumn(label: 'STATUS', flex: 2),
          TableColumn(label: 'ACTIONS', flex: 3),
        ],
        rows: provider.users.map((user) {
          return ModernTableRow(
            cells: [
              // User with Avatar
              ModernTableCell(
                flex: 3,
                child: Row(
                  children: [
                    TableAvatar(initials: user.initials),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TableTextCell(
                        primaryText: user.fullName,
                        secondaryText: user.email,
                      ),
                    ),
                  ],
                ),
              ),
              // Username
              ModernTableCell(
                flex: 2,
                child: Text(user.username),
              ),
              // Role Badge
              ModernTableCell(
                flex: 2,
                child: StatusBadge(status: user.role),
              ),
              // Last Login
              ModernTableCell(
                flex: 2,
                child: Text((user.lastLogin ?? 'Never').toString()),
              ),
              // Status Badge
              ModernTableCell(
                flex: 2,
                child: StatusBadge(
                  status: user.isActive ? 'Active' : 'Inactive',
                ),
              ),
              // Actions
              ModernTableCell(
                flex: 3,
                child: Row(
                  children: [
                    TableActionButton(
                      icon: Icons.visibility,
                      label: 'View',
                      onPressed: () => _showViewUserDialog(user, provider),
                    ),
                    TableIconButton(
                      icon: Icons.toggle_on,
                      onPressed: () => _toggleUserStatus(user, provider),
                      tooltip: user.isActive ? 'Deactivate' : 'Activate',
                      color: user.isActive ? theme.success : theme.error,
                    ),
                    TableIconButton(
                      icon: Icons.key,
                      onPressed: () => _resetUserPassword(user, provider),
                      tooltip: 'Reset Password',
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
          rowsPerPage: provider.itemsPerPage,
          totalItems: provider.totalFilteredUsers,
          onPageChanged: provider.goToPage,
          onRowsPerPageChanged: (rows) {
            if (rows != null) provider.changeItemsPerPage(rows);
          },
        ),
      ),
    );
  }

  /// Show create user dialog
  void _showCreateUserDialog() {
    showDialog(
      context: context,
      builder: (context) => const UserFormDialog(),
    );
  }

  /// Show view user dialog
  void _showViewUserDialog(UserModel user, ManageUsersProvider provider) async {
    final verified = await _showAdminPasswordDialog(provider);
    if (verified && mounted) {
      showDialog(
        context: context,
        builder: (context) => ViewUserDialog(user: user),
      );
    }
  }

  /// Show admin password verification dialog
  Future<bool> _showAdminPasswordDialog(ManageUsersProvider provider) async {
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    bool isVerifying = false;

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (isVerifying) {
              return const AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LogoCarouselLoading(),
                    SizedBox(height: 16),
                    Text(
                      'Verifying...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.security, color: Color(0xFF1976D2)),
                  SizedBox(width: 12),
                  Text('Admin Verification'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Please enter your admin password to view user details.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Admin Password',
                      hintText: 'Enter your password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility : Icons.visibility_off,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final password = passwordController.text.trim();
                    if (password.isEmpty) {
                      await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange),
                              SizedBox(width: 12),
                              Text('Password Required'),
                            ],
                          ),
                          content: const Text('Please enter your admin password.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                      return;
                    }
                    
                    setState(() {
                      isVerifying = true;
                    });
                    
                    // Verify password against backend
                    final isValid = await provider.verifyAdminPassword(password);
                    
                    if (!mounted) return;
                    
                    if (!isValid) {
                      setState(() {
                        isVerifying = false;
                      });
                      await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Row(
                            children: [
                              Icon(Icons.error, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Incorrect Password'),
                            ],
                          ),
                          content: const Text('The password you entered is incorrect. Please try again.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                      return;
                    }
                    
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Verify'),
                ),
              ],
            );
          },
        );
      },
    ) ?? false;
  }

  /// Show edit user dialog
  void _showEditUserDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => UserFormDialog(user: user),
    );
  }

  /// Toggle user status
  Future<void> _toggleUserStatus(UserModel user, ManageUsersProvider provider) async {
    // First verify admin password
    final verified = await _showAdminPasswordDialog(provider);
    if (!verified || !mounted) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user.isActive ? 'Deactivate' : 'Activate'} User'),
        content: Text(
          'Are you sure you want to ${user.isActive ? 'deactivate' : 'activate'} ${user.fullName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isActive ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(user.isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final result = await provider.toggleUserStatus(user.id, !user.isActive);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Icon(
              result['success'] ? Icons.check_circle : Icons.error,
              color: result['success'] ? Colors.green : Colors.red,
              size: 48,
            ),
            content: Text(result['message']),
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

  /// Reset user password
  Future<void> _resetUserPassword(UserModel user, ManageUsersProvider provider) async {
    // First verify admin password
    final verified = await _showAdminPasswordDialog(provider);
    if (!verified || !mounted) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.key, color: Color(0xFFFF9800)),
            SizedBox(width: 12),
            Text('Reset Password'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to reset the password for ${user.fullName}?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'New Password:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Pch@2026',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'User will be required to change password on next login.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.key, size: 18),
            label: const Text('Reset Password'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final result = await provider.resetUserPassword(user.id);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Icon(
              result['success'] ? Icons.check_circle : Icons.error,
              color: result['success'] ? Colors.green : Colors.red,
              size: 48,
            ),
            content: Text(result['message']),
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

  // Delete functionality removed to maintain full audit trail
  // Users should be deactivated instead of deleted to preserve transaction history
}
