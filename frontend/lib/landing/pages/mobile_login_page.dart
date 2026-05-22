import 'package:flutter/material.dart';
import '../../core/reusable_widgets/page_title.dart';
import '../../core/reusable_widgets/buttons.dart';
import '../../core/reusable_widgets/logo_carousel_loading.dart';
import 'package:provider/provider.dart';
import '../../core/provider/auth_provider.dart';
import '../../core/routes/app_routes.dart';
import '../widgets/login/error_dialog.dart';
import '../widgets/login/terms_dialog.dart';
import '../widgets/curved_background_container.dart';
import 'mobile_forgot_password_page.dart';

/// Unified mobile login page - Full-page login for mobile devices and mobile browser screen sizes
/// Used for both mobile app and responsive web on mobile/small screens
class MobileLoginPage extends StatefulWidget {
  const MobileLoginPage({super.key});

  @override
  State<MobileLoginPage> createState() => _MobileLoginPageState();
}

class _MobileLoginPageState extends State<MobileLoginPage> {
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

  void _handleTermsChanged(bool? value) {
    setState(() {
      _acceptedTerms = value ?? false;
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MobileForgotPasswordPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate back to mobile home when back button is pressed
        Navigator.of(context).pushReplacementNamed(AppRoutes.mobileHome);
        return false;
      },
      child: Scaffold(
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
            onBackPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.mobileHome),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Page Title with Subtitle
              const PageTitle(
                title: 'Welcome Back',
                subtitle: 'Login to access',
              ),
              const SizedBox(height: 20),
              
              // Username Field with Icon
              TextField(
                controller: _usernameController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: 'Username',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: Colors.grey[600],
                    size: 20,
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
              ),
              const SizedBox(height: 12),
              
              // Password Field with Icon
              TextField(
                controller: _passwordController,
                enabled: !_isLoading,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Password',
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
                    padding: const EdgeInsets.all(8),
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
              ),
              const SizedBox(height: 12),
              
              // Terms and Conditions Checkbox
              Row(
                children: [
                  Checkbox(
                    value: _acceptedTerms,
                    onChanged: _isLoading ? null : _handleTermsChanged,
                    activeColor: const Color(0xFF2196F3),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _isLoading ? null : () => TermsDialog.show(context),
                      child: RichText(
                        text: TextSpan(
                          text: 'I agree to the ',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                          children: [
                            TextSpan(
                              text: 'Terms and Conditions',
                              style: const TextStyle(
                                color: Color(0xFF2196F3),
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Login Button (Gradient Blue)
              GradientButton(
                text: 'Log In',
                onPressed: _acceptedTerms && !_isLoading ? _handleLogin : null,
                width: double.infinity,
              ),
              const SizedBox(height: 16),
              
              // Forgot Password Link (Centered)
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : _handleForgotPassword,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Color(0xFF2196F3),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Loading Overlay with Logo Carousel
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
