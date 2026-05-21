import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/colors.dart';
import '../../core/reusable_widgets/page_title.dart';
import '../../core/reusable_widgets/buttons.dart';
import '../widgets/dialogs/success_dialog.dart';
import '../widgets/dialogs/error_dialog.dart';
import '../widgets/curved_background_container.dart';
import '../../core/reusable_widgets/logo_carousel_loading.dart';
import 'mobile_verify_otp_page.dart';

class MobileForgotPasswordPage extends StatefulWidget {
  const MobileForgotPasswordPage({super.key});

  @override
  State<MobileForgotPasswordPage> createState() => _MobileForgotPasswordPageState();
}

class _MobileForgotPasswordPageState extends State<MobileForgotPasswordPage> {
  final _usernameController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const ErrorDialog(
          title: 'Required Field',
          message: 'Please enter your username or email',
          confirmText: 'OK',
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final checkResult = await _authService.checkUserExists(username);

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (!checkResult['exists']) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => ErrorDialog(
            title: 'Account Not Found',
            message: checkResult['message'],
            confirmText: 'Try Again',
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final result = await _authService.requestPasswordReset(username);

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        if (result['success']) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => SuccessDialog(
              title: 'Code Sent',
              message: result['message'],
              confirmText: 'Continue',
              onConfirm: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MobileVerifyOtpPage(
                      username: username,
                      maskedEmail: checkResult['email'] ?? result['email'] ?? '',
                    ),
                  ),
                );
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Page Title
                  const PageTitle(
                    title: 'Forgot Password?',
                    subtitle: 'Enter your username or email',
                  ),
                  const SizedBox(height: 20),
                  
                  // Username Field
                  TextField(
                    controller: _usernameController,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: 'Username or Email',
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
                  const SizedBox(height: 20),
                  
                  // Send Code Button
                  GradientButton(
                    text: 'Send Verification Code',
                    onPressed: _isLoading ? null : _requestOtp,
                    width: double.infinity,
                  ),
                  const SizedBox(height: 16),
                  
                  // Back to Login Link
                  Center(
                    child: TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'Back to Login',
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
              message: 'Sending verification code...',
            ),
        ],
      ),
    );
  }
}
