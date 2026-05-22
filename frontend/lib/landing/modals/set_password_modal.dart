import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/responsive.dart';
import '../../core/reusable_widgets/buttons.dart';
import '../../core/reusable_widgets/page_title.dart';
import '../../core/reusable_widgets/logo_carousel_loading.dart';
import '../widgets/rightside_background.dart';
import '../widgets/dialogs/success_dialog.dart';
import '../widgets/dialogs/error_dialog.dart';

/// Set Password Modal - Displays as a dialog overlay for setting new password
class SetPasswordModal extends StatefulWidget {
  final String username;
  final String otpCode;
  final String maskedEmail;

  const SetPasswordModal({
    super.key,
    required this.username,
    required this.otpCode,
    required this.maskedEmail,
  });

  @override
  State<SetPasswordModal> createState() => _SetPasswordModalState();
}

class _SetPasswordModalState extends State<SetPasswordModal> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await _authService.verifyOtpAndResetPassword(
      username: widget.username,
      otpCode: widget.otpCode,
      newPassword: _newPasswordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (result['success']) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => SuccessDialog(
            title: 'Password Reset',
            message: result['message'],
            confirmText: 'Back to Login',
            onConfirm: () {
              Navigator.pop(context); // Close success dialog
              Navigator.pop(context); // Close set password modal
              Navigator.pop(context); // Close forgot password modal
              Navigator.pop(context); // Close verify OTP modal
            },
          ),
        );
      } else {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => ErrorDialog(
            title: 'Error',
            message: result['message'],
            confirmText: 'Try Again',
          ),
        );
      }
    }
  }

  void _handleClose() {
    Navigator.pop(context);
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a new password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least 1 uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least 1 lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least 1 number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: isMobile ? screenWidth * 0.9 : 800,
        height: isMobile ? screenHeight * 0.7 : 500,
        constraints: BoxConstraints(
          maxWidth: isMobile ? screenWidth * 0.95 : 800,
          maxHeight: isMobile ? screenHeight * 0.85 : 600,
        ),
        child: Stack(
          children: [
            isMobile
                ? Stack(
                    children: [
                      _buildFormContent(),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.black54),
                          onPressed: _handleClose,
                          tooltip: 'Close',
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      _buildFormContent(),
                      LoginBackgroundSide(
                        onClose: _handleClose,
                      ),
                    ],
                  ),
            // Loading overlay
            if (_isLoading)
              LogoCarouselLoadingOverlay(
                isLoading: _isLoading,
                message: 'Resetting password...',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    final isMobile = Responsive.isMobile(context);

    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        child: Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 0),
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PageTitle(
                      title: 'Set New Password',
                      subtitle: 'Enter your new password',
                      addShadow: false,
                    ),
                    const SizedBox(height: 32),
                    // New Password Field
                    _buildPasswordField(
                      controller: _newPasswordController,
                      hintText: 'New Password',
                      obscureText: _obscurePassword,
                      onToggleVisibility: _togglePasswordVisibility,
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 16),
                    // Confirm Password Field
                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      hintText: 'Confirm Password',
                      obscureText: _obscureConfirmPassword,
                      onToggleVisibility: _toggleConfirmPasswordVisibility,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    // Reset Password Button
                    GradientButton(
                      text: 'Reset Password',
                      onPressed: _isLoading ? null : _handleSetPassword,
                      height: 48,
                    ),
                    const SizedBox(height: 16),
                    // Back to Login
                    Center(
                      child: TextButton(
                        onPressed: _isLoading ? null : _handleClose,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        child: const Text(
                          'Back to Login',
                          style: TextStyle(
                            color: Color(0xFF2196F3),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_isLoading,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFFAAAAAA),
        ),
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: Color(0xFF666666),
          size: 20,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: const Color(0xFF666666),
            size: 20,
          ),
          onPressed: onToggleVisibility,
        ),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: validator,
    );
  }
}
