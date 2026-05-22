import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/provider/auth_provider.dart';
import '../../core/utils/colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/logger.dart';
import '../../core/reusable_widgets/logo_carousel_loading.dart';
import '../widgets/curved_background_container.dart';

/// Change Password Page for first-time login users
/// Users with must_change_pw=true are redirected here before accessing dashboard
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = context.read<AuthProvider>();
    
    try {
      final result = await authProvider.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;

      if (result['success']) {
        AppLogger.info('Password changed successfully', tag: 'ChangePasswordPage');
        
        final userRole = authProvider.role;
        final userDeployment = authProvider.deployment;
        
        final dashboardRoute = AppRoutes.getDashboardRouteForRole(
          userRole,
          deployment: userDeployment,
          subRole: authProvider.subRole,
        );
        
        Navigator.of(context).pushReplacementNamed(dashboardRoute);
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to change password';
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Error changing password', tag: 'ChangePasswordPage', error: e);
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.lock_reset,
            size: 48,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(height: 16),
          
          const Text(
            'Change Your Password',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          Text(
            'Please change your default password before accessing the system.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[700], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          
          TextFormField(
            controller: _currentPasswordController,
            obscureText: _obscureCurrentPassword,
            decoration: InputDecoration(
              labelText: 'Current Password',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscureCurrentPassword = !_obscureCurrentPassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Enter current password';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          
          TextFormField(
            controller: _newPasswordController,
            obscureText: _obscureNewPassword,
            decoration: InputDecoration(
              labelText: 'New Password',
              prefixIcon: const Icon(Icons.lock, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscureNewPassword = !_obscureNewPassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              helperText: 'Min 8 chars, 1 upper, 1 lower, 1 number',
              helperStyle: const TextStyle(fontSize: 11),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Enter new password';
              }
              if (value.length < 8) {
                return 'Min 8 characters';
              }
              if (!RegExp(r'[A-Z]').hasMatch(value)) {
                return 'Need 1 uppercase';
              }
              if (!RegExp(r'[a-z]').hasMatch(value)) {
                return 'Need 1 lowercase';
              }
              if (!RegExp(r'[0-9]').hasMatch(value)) {
                return 'Need 1 number';
              }
              if (value == _currentPasswordController.text) {
                return 'Must be different';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Confirm password';
              }
              if (value != _newPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          ElevatedButton(
            onPressed: _isLoading ? null : _handleChangePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Change Password',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    context.read<AuthProvider>().logout();
                    Navigator.of(context).pushReplacementNamed('/');
                  },
            child: const Text('Logout', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      body: Stack(
        children: [
          if (isMobile)
            // Mobile layout with curved background
            SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: CurvedBackgroundContainer(
                imagePath: 'assets/images/about/pch2.jpg',
                imageHeight: 280,
                overlapOffset: 50,
                showBackButton: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildFormContent(),
                ),
              ),
            )
          else
            // Tablet/Desktop layout with centered card
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/about/pch2.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 450),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: _buildFormContent(),
                  ),
                ),
              ),
            ),
          if (_isLoading)
            LogoCarouselLoadingOverlay(
              isLoading: _isLoading,
              message: 'Changing password...',
            ),
        ],
      ),
    );
  }
}
