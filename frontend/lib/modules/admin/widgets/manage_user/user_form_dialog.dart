import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/manage_users_provider.dart';
import '../../models/user_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/reusable_widgets/logo_carousel_loading.dart';
import '../../../../core/utils/colors.dart';

/// User Form Dialog for creating and editing users
/// Follows OOP principles with proper validation and security
class UserFormDialog extends StatefulWidget {
  final UserModel? user; // Null for create, populated for edit

  const UserFormDialog({super.key, this.user});

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _middlenameController = TextEditingController();
  final _extnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();
  
  int _currentStep = 0;

  String _selectedRole = 'DOCTOR';
  String? _selectedDeployment;
  String? _selectedNurseType; // RN or ATTENDANT for IPD/BOTH deployments
  bool _isActive = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureAdminPassword = true;

  final List<String> _roles = [
    'ADMIN',
    'DOCTOR',
    'NURSE',
    'CHIEF NURSE',
    'CLERK',
    'STAFF',
    'SOCIAL WORK',
    'MAYORS OFFICE',
    'CONGRESSMAN',
    'PHARMACIST',
    'CASHIER',
    'ICD CODER',
  ];
  final List<String> _extNames = ['', 'Jr.', 'Sr.', 'II', 'III', 'IV'];
  
  /// Get deployment options based on selected role
  List<String> _getDeploymentOptions() {
    switch (_selectedRole) {
      case 'DOCTOR':
      case 'NURSE':
        return ['OPD', 'IPD', 'BOTH'];
      case 'CHIEF NURSE':
        return ['IPD'];
      case 'STAFF':
        return ['LAB', 'X-RAY', 'BILLING', 'KITCHEN', 'CSD'];
      case 'CLERK':
        return ['OPD', 'CSD'];
      default:
        return [];
    }
  }
  
  /// Check if deployment should be shown for selected role
  bool _shouldShowDeployment() {
    return ['DOCTOR', 'NURSE', 'CHIEF NURSE', 'STAFF', 'CLERK'].contains(_selectedRole);
  }
  
  /// Check if nurse type selection should be shown
  /// Shows when: NURSE role is selected AND deployment is IPD or BOTH
  bool _shouldShowNurseTypeSelection() {
    return _selectedRole == 'NURSE' && 
           (_selectedDeployment == 'IPD' || _selectedDeployment == 'BOTH');
  }
  
  /// Get available nurse types based on deployment
  List<String> _getNurseTypeOptions() {
    if (_selectedDeployment == 'IPD' || _selectedDeployment == 'BOTH') {
      return ['RN', 'ATTENDANT'];
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _loadUserData();
    } else {
      // Set default password for new users
      _passwordController.text = 'Pch@2026';
    }
  }

  void _loadUserData() {
    final user = widget.user!;
    _usernameController.text = user.username;
    _firstnameController.text = user.firstname;
    _lastnameController.text = user.lastname;
    _middlenameController.text = user.middlename ?? '';
    _extnameController.text = user.extname ?? '';
    _emailController.text = user.email;
    _contactController.text = user.contactNo ?? '';
    _selectedRole = user.role;
    _selectedDeployment = user.deployment;
    _isActive = user.isActive;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _firstnameController.dispose();
    _lastnameController.dispose();
    _middlenameController.dispose();
    _extnameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.user != null;
    final theme = AppTheme.of(context);

    return Dialog(
      backgroundColor: theme.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
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
                  Icon(
                    isEdit ? Icons.edit : Icons.person_add,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEdit ? 'Edit User' : 'Create New Account',
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

            // Step Indicator
            Container(
              color: theme.isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Row(
                children: [
                  // Step 1
                  Expanded(
                    child: _buildStepIndicator(
                      stepNumber: 1,
                      title: 'Personal Info',
                      isActive: _currentStep == 0,
                      isCompleted: _currentStep > 0,
                      theme: theme,
                    ),
                  ),
                  // Connector
                  Container(
                    width: 40,
                    height: 2,
                    color: _currentStep > 0 ? AppColors.primaryBlue : Colors.grey.shade300,
                  ),
                  // Step 2
                  Expanded(
                    child: _buildStepIndicator(
                      stepNumber: 2,
                      title: 'Account Settings',
                      isActive: _currentStep == 1,
                      isCompleted: false,
                      theme: theme,
                    ),
                  ),
                ],
              ),
            ),

            // Step Content
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _currentStep == 0 
                    ? _buildPersonalInfoTab(theme)
                    : _buildAccountSettingsTab(theme, isEdit),
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
                border: Border(top: BorderSide(color: theme.cardBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_currentStep == 1) ...[
                    TextButton(
                      onPressed: _isLoading ? null : () => setState(() => _currentStep = 0),
                      child: const Text('Back'),
                    ),
                    const SizedBox(width: 16),
                  ],
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  if (_currentStep == 0)
                    ElevatedButton(
                      onPressed: _isLoading 
                        ? null 
                        : () {
                            if (_formKey.currentState?.validate() ?? false) {
                              setState(() => _currentStep = 1);
                            }
                          },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: const Text('Next'),
                    )
                  else
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(isEdit ? 'Save Changes' : 'Create Account'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator({
    required int stepNumber,
    required String title,
    required bool isActive,
    required bool isCompleted,
    required AppThemeData theme,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted || isActive ? AppColors.primaryBlue : Colors.grey.shade300,
          ),
          child: Center(
            child: isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 18)
              : Text(
                  '$stepNumber',
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? AppColors.primaryBlue : theme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoTab(AppThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _lastnameController,
                  label: 'Last Name',
                  required: true,
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _firstnameController,
                  label: 'First Name',
                  required: true,
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _middlenameController,
                  label: 'Middle Name',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdownField(
                  label: 'Ext. Name',
                  value: _extnameController.text.isEmpty ? null : _extnameController.text,
                  items: _extNames,
                  onChanged: (value) {
                    setState(() {
                      _extnameController.text = value ?? '';
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _contactController,
            label: 'Contact No.',
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (!RegExp(r'^[0-9+\-\s()]+$').hasMatch(value)) {
                  return 'Invalid phone number';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            required: true,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Required';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                return 'Invalid email format';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettingsTab(AppThemeData theme, bool isEdit) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _usernameController,
                  label: 'Username',
                  required: true,
                  enabled: !isEdit,
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdownField(
                  label: 'Role',
                  value: _selectedRole,
                  items: _roles,
                  required: true,
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                      if (!_shouldShowDeployment()) {
                        _selectedDeployment = null;
                      } else if (_selectedDeployment != null) {
                        final validOptions = _getDeploymentOptions();
                        if (!validOptions.contains(_selectedDeployment)) {
                          _selectedDeployment = null;
                        }
                      }
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!isEdit)
            _buildTextField(
              controller: _passwordController,
              label: 'Password',
              required: false,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          if (!isEdit) const SizedBox(height: 16),
          if (_shouldShowDeployment())
            _buildDropdownField(
              label: 'Deployment',
              value: _selectedDeployment,
              items: _getDeploymentOptions(),
              onChanged: (value) {
                setState(() {
                  _selectedDeployment = value;
                  if (!_shouldShowNurseTypeSelection()) {
                    _selectedNurseType = null;
                  }
                });
              },
            ),
          if (_shouldShowDeployment()) const SizedBox(height: 16),
          if (_shouldShowNurseTypeSelection())
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryBlue),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.primaryBlue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'IPD deployment requires nurse type selection',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildDropdownField(
                  label: 'Nurse Type',
                  value: _selectedNurseType,
                  items: _getNurseTypeOptions(),
                  required: true,
                  onChanged: (value) {
                    setState(() {
                      _selectedNurseType = value;
                    });
                  },
                ),
              ],
            ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isActive
                  ? (theme.isDark ? const Color(0xFF1B4D2A) : const Color(0xFFE8F5E9))
                  : (theme.isDark ? const Color(0xFF4D1B1B) : const Color(0xFFFFEBEE)),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isActive
                    ? (theme.isDark ? const Color(0xFF4CAF50) : const Color(0xFF4CAF50))
                    : (theme.isDark ? const Color(0xFFF44336) : const Color(0xFFF44336)),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isActive ? Icons.check_circle : Icons.cancel,
                  color: _isActive ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Status',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.textPrimary,
                        ),
                      ),
                      Text(
                        _isActive
                            ? 'Active accounts can log in'
                            : 'Inactive accounts cannot log in',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                  activeColor: const Color(0xFF4CAF50),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryBlue,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    bool obscureText = false,
    bool enabled = true,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    final theme = AppTheme.of(context);
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      style: TextStyle(color: theme.textPrimary),
      decoration: InputDecoration(
        labelText: '$label${required ? ' *' : ''}',
        labelStyle: TextStyle(color: theme.textSecondary),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryBlue),
        ),
        filled: true,
        fillColor: enabled ? theme.inputBackground : theme.cardBackground,
      ),
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    bool required = false,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = AppTheme.of(context);
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: theme.cardBackground,
      style: TextStyle(color: theme.textPrimary),
      decoration: InputDecoration(
        labelText: '$label${required ? ' *' : ''}',
        labelStyle: TextStyle(color: theme.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryBlue),
        ),
        filled: true,
        fillColor: theme.inputBackground,
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item, style: TextStyle(color: theme.textPrimary)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  /// Show success dialog
  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600], size: 28),
            const SizedBox(width: 12),
            const Text('Success', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// Show error dialog
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red[600], size: 28),
            const SizedBox(width: 12),
            const Text('Error', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// Show admin password verification dialog
  Future<String?> _showAdminPasswordDialog() async {
    final adminPasswordController = TextEditingController();
    bool obscurePassword = true;
    bool isVerifying = false;
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Stack(
          children: [
            AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.security, color: Colors.red, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Security Verification',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Verify your identity',
                          style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your admin password to confirm account creation',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: adminPasswordController,
                    obscureText: obscurePassword,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Admin Password',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                    onSubmitted: (_) {
                      if (adminPasswordController.text.isNotEmpty) {
                        Navigator.pop(context, adminPasswordController.text);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isVerifying ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isVerifying
                      ? null
                      : () {
                          if (adminPasswordController.text.isEmpty) {
                            return;
                          }
                          setState(() {
                            isVerifying = true;
                          });
                          Future.delayed(const Duration(milliseconds: 500), () {
                            Navigator.pop(context, adminPasswordController.text);
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: isVerifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Verify & Create'),
                ),
              ],
            ),
            LogoCarouselLoadingOverlay(
              isLoading: isVerifying,
              message: 'Verifying...',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // For new users, show admin password verification dialog first
    if (widget.user == null) {
      final adminPassword = await _showAdminPasswordDialog();
      
      if (adminPassword == null || adminPassword.isEmpty) {
        // User cancelled
        return;
      }
      
      // Store admin password for later use
      _adminPasswordController.text = adminPassword;
    }

    setState(() {
      _isLoading = true;
    });

    final userData = {
      'username': _usernameController.text.trim(),
      'firstname': _firstnameController.text.trim(),
      'lastname': _lastnameController.text.trim(),
      'middlename': _middlenameController.text.trim().isEmpty ? null : _middlenameController.text.trim(),
      'extname': _extnameController.text.trim().isEmpty ? null : _extnameController.text.trim(),
      'email': _emailController.text.trim(),
      'contact_no': _contactController.text.trim().isEmpty ? null : _contactController.text.trim(),
      'user_role': _selectedRole,
      'deployment': _selectedDeployment,
      'sub_role': _selectedNurseType, // RN or ATTENDANT for nurses, null for others
      'is_active': _isActive,
    };

    // Add password and admin password verification for new users
    if (widget.user == null) {
      // Use default password if field is empty
      userData['password'] = _passwordController.text.isEmpty 
          ? 'Pch@2026' 
          : _passwordController.text;
      
      // Add admin password for verification
      userData['admin_password'] = _adminPasswordController.text;
    }

    final provider = context.read<ManageUsersProvider>();
    final result = widget.user == null
        ? await provider.createUser(userData)
        : await provider.updateUser(widget.user!.id, userData);

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (result['success']) {
        Navigator.pop(context);
        // Show success dialog
        _showSuccessDialog(context, result['message'] ?? 'Account created successfully!');
      } else {
        // Show error dialog
        _showErrorDialog(context, result['message'] ?? 'Failed to create account');
      }
    }
  }
}
