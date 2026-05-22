import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/reusable_widgets/page_title.dart';
import '../../core/reusable_widgets/buttons.dart';
import '../../core/reusable_widgets/logo_carousel_loading.dart';
import '../widgets/dialogs/success_dialog.dart';
import '../widgets/dialogs/error_dialog.dart';
import '../widgets/curved_background_container.dart';

class MobileSetPasswordPage extends StatefulWidget {
  final String username;
  final String otpCode;
  final String maskedEmail;

  const MobileSetPasswordPage({
    super.key,
    required this.username,
    required this.otpCode,
    required this.maskedEmail,
  });

  @override
  State<MobileSetPasswordPage> createState() => _MobileSetPasswordPageState();
}

class _MobileSetPasswordPageState extends State<MobileSetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
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
            message: 'Your password has been reset successfully',
            confirmText: 'Back to Login',
            onConfirm: () {
              Navigator.pop(context); // Close success dialog
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: CurvedBackgroundContainer(
          imagePath: 'assets/images/about/pch2.jpg',
          imageHeight: 280,
          overlapOffset: 50,
          showBackButton: true,
          onBackPressed: () => Navigator.pop(context),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Page Title
                const PageTitle(
                  title: 'Set New Password',
                  subtitle: 'Create a strong password',
                ),
                const SizedBox(height: 20),
                
                // New Password Field
                TextFormField(
                  controller: _newPasswordController,
                  enabled: !_isLoading,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'New Password',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      onPressed: _togglePasswordVisibility,
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[400]!, width: 1),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 12),
                
                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  enabled: !_isLoading,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: 'Confirm Password',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      onPressed: _toggleConfirmPasswordVisibility,
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[400]!, width: 1),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
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
                const SizedBox(height: 20),
                
                // Set Password Button
                GradientButton(
                  text: 'Set Password',
                  onPressed: _isLoading ? null : _handleSetPassword,
                  width: double.infinity,
                ),
              ],
            ),
          ),
        ),
      ),
      // Loading Overlay with Logo Carousel
      if (_isLoading)
        LogoCarouselLoadingOverlay(
          isLoading: _isLoading,
          message: 'Resetting password...',
        ),
    ],
  ),
);
  }
}
