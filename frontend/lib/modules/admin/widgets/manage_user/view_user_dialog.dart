import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/colors.dart';
import 'user_form_dialog.dart';

/// Dialog to view user details with option to edit
class ViewUserDialog extends StatelessWidget {
  final UserModel user;

  const ViewUserDialog({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Dialog(
      backgroundColor: theme.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'User Details',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // User Details Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar and Name Section
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: _getAvatarColor(user.id),
                            child: Text(
                              _getInitials(user.fullName),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user.fullName,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: theme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildRoleBadge(user.role, theme),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Details Section
                    _buildDetailSection('PERSONAL INFORMATION', [
                      _buildDetailRow('Email', user.email, theme),
                      _buildDetailRow('Username', user.username, theme),
                      _buildDetailRow(
                        'Contact Number',
                        user.contactNo ?? 'Not provided',
                        theme,
                      ),
                    ]),

                    const SizedBox(height: 24),

                    _buildDetailSection('ACCOUNT SETTINGS', [
                      _buildDetailRow('Role', _getRoleDisplayText(user.role), theme),
                      _buildDetailRow(
                        'Status',
                        user.isActive ? 'Active' : 'Inactive',
                        theme,
                        statusColor: user.isActive
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFF44336),
                      ),
                      _buildDetailRow(
                        'Last Login',
                        user.lastLogin != null
                            ? _formatDate(user.lastLogin!)
                            : 'Never',
                        theme,
                      ),
                    ]),
                  ],
                ),
              ),
            ),

            // Footer with Edit Button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
                border: Border(top: BorderSide(color: theme.cardBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Close',
                      style: TextStyle(color: theme.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => UserFormDialog(user: user),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, AppThemeData theme,
      {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: theme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: statusColor ?? theme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role, AppThemeData theme) {
    Color bgColor;
    Color textColor;
    String displayText;

    final isDark = theme.isDark;

    switch (role) {
      case 'ADMIN':
        bgColor = isDark ? const Color(0xFF1A365D) : const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1976D2);
        displayText = 'Admin';
        break;
      case 'DOCTOR':
        bgColor = isDark ? const Color(0xFF4D4519) : const Color(0xFFFFF9C4);
        textColor = const Color(0xFFF57F17);
        displayText = 'Doctor';
        break;
      case 'NURSE':
        bgColor = isDark ? const Color(0xFF1B4D2A) : const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        displayText = 'Nurse';
        break;
      case 'OPD_CLERK':
        bgColor = isDark ? const Color(0xFF1A365D) : const Color(0xFFE3F2FD);
        textColor = const Color(0xFF2196F3);
        displayText = 'OPD Clerk';
        break;
      default:
        bgColor = isDark ? const Color(0xFF374151) : Colors.grey[200]!;
        textColor = isDark ? const Color(0xFFE5E7EB) : Colors.grey[700]!;
        displayText = role;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _getRoleDisplayText(String role) {
    switch (role) {
      case 'ADMIN':
        return 'Administrator';
      case 'DOCTOR':
        return 'Doctor';
      case 'NURSE':
        return 'Nurse';
      case 'OPD_CLERK':
        return 'OPD Clerk';
      default:
        return role;
    }
  }

  String _getInitials(String fullName) {
    if (fullName.isEmpty) return '';
    final names = fullName.trim().split(' ');
    if (names.length == 1) {
      return names[0].substring(0, 1).toUpperCase();
    }
    return '${names[0][0]}${names[names.length - 1][0]}'.toUpperCase();
  }

  Color _getAvatarColor(int userId) {
    final colors = [
      const Color(0xFFFFA726),
      const Color(0xFF26A69A),
      const Color(0xFFAB47BC),
      const Color(0xFFEC407A),
      const Color(0xFF5C6BC0),
      const Color(0xFF42A5F5),
      const Color(0xFF66BB6A),
      const Color(0xFFFF7043),
    ];
    return colors[userId % colors.length];
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    }
  }
}
