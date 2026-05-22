import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/provider/auth_provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/responsive.dart';
import 'forgot_password_modal.dart';
import '../pages/mobile_forgot_password_page.dart';
import '../widgets/login/login_form_side.dart';
import '../widgets/rightside_background.dart';
import '../widgets/login/error_dialog.dart';
import '../../core/services/auth_service.dart';
import '../../core/reusable_widgets/logo_carousel_loading.dart';

/// Main login modal dialog - Refactored for maintainability
class LoginModal extends StatefulWidget {
  const LoginModal({super.key});

  @override
  State<LoginModal> createState() => _LoginModalState();
}

class _LoginModalState extends State<LoginModal> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _handleTermsChanged(bool value) {
    setState(() {
      _acceptedTerms = value;
    });
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      ErrorDialog.show(context, 'Please enter username and password');
      return;
    }

    if (!_acceptedTerms) {
      setState(() {
        _isLoading = false;
      });
      ErrorDialog.show(context, 'Please accept the Terms and Conditions to continue');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.login(username, password);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      _handleSuccessfulLogin(result);
    } else {
      ErrorDialog.show(
        context,
        result['message'] ?? 'Login failed. Please try again.',
      );
    }
  }

  void _handleSuccessfulLogin(Map<String, dynamic> result) {
    Navigator.of(context).pop();

    final mustChangePassword = result['user']['must_change_pw'] == true;

    if (mustChangePassword) {
      Navigator.of(context).pushReplacementNamed('/change-password');
    } else {
      final userRole = result['user']['role'] as String?;
      final userDeployment = result['user']['deployment'] as String?;
      final userSubRole = result['user']['sub_role'] as String?;

      final dashboardRoute = AppRoutes.getDashboardRouteForRole(
        userRole,
        deployment: userDeployment,
        subRole: userSubRole,
      );
      Navigator.of(context).pushReplacementNamed(dashboardRoute);
    }
  }

  void _handleForgotPassword() {
    final isMobile = Responsive.isMobile(context);
    
    if (isMobile) {
      // Show full-page form on mobile
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MobileForgotPasswordPage(),
        ),
      );
    } else {
      // Show modal on tablet/desktop
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const ForgotPasswordModal(),
      );
    }
  }

  void _handleClose() {
    Navigator.of(context).pop();
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
        height: isMobile ? screenHeight * 0.8 : 500,
        constraints: BoxConstraints(
          maxWidth: isMobile ? screenWidth * 0.95 : 800,
          maxHeight: isMobile ? screenHeight * 0.9 : 600,
        ),
        child: Stack(
          children: [
            isMobile
                ? Stack(
                    children: [
                      LoginFormSide(
                        usernameController: _usernameController,
                        passwordController: _passwordController,
                        obscurePassword: _obscurePassword,
                        isLoading: _isLoading,
                        acceptedTerms: _acceptedTerms,
                        onTogglePasswordVisibility: _togglePasswordVisibility,
                        onLogin: _handleLogin,
                        onForgotPassword: _handleForgotPassword,
                        onTermsChanged: _handleTermsChanged,
                      ),
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
                      LoginFormSide(
                        usernameController: _usernameController,
                        passwordController: _passwordController,
                        obscurePassword: _obscurePassword,
                        isLoading: _isLoading,
                        acceptedTerms: _acceptedTerms,
                        onTogglePasswordVisibility: _togglePasswordVisibility,
                        onLogin: _handleLogin,
                        onForgotPassword: _handleForgotPassword,
                        onTermsChanged: _handleTermsChanged,
                      ),
                      LoginBackgroundSide(
                        onClose: _handleClose,
                      ),
                    ],
                  ),
            // Loading overlay
            if (_isLoading)
              LogoCarouselLoadingOverlay(
                isLoading: _isLoading,
                message: 'Logging in...',
              ),
          ],
        ),
      ),
    );
  }
}
