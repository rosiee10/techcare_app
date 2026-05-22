import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/reusable_widgets/page_title.dart';
import '../widgets/forgot_password/otp_digit_input.dart';
import '../widgets/dialogs/success_dialog.dart';
import '../widgets/dialogs/error_dialog.dart';
import '../widgets/curved_background_container.dart';
import '../../core/reusable_widgets/logo_carousel_loading.dart';
import 'mobile_set_password_page.dart';

class MobileVerifyOtpPage extends StatefulWidget {
  final String username;
  final String maskedEmail;

  const MobileVerifyOtpPage({
    super.key,
    required this.username,
    required this.maskedEmail,
  });

  @override
  State<MobileVerifyOtpPage> createState() => _MobileVerifyOtpPageState();
}

class _MobileVerifyOtpPageState extends State<MobileVerifyOtpPage> {
  final _authService = AuthService();
  bool _isLoading = false;
  late OtpDigitInputController _otpController;

  Future<bool> _handleVerifyOtp(String otp) async {
    setState(() {
      _isLoading = true;
    });

    final result = await _authService.verifyOtpAndResetPassword(
      username: widget.username,
      otpCode: otp,
      newPassword: '',
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
            title: 'Code Verified',
            message: 'Your code has been verified successfully',
            confirmText: 'Continue',
            onConfirm: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MobileSetPasswordPage(
                    username: widget.username,
                    otpCode: otp,
                    maskedEmail: widget.maskedEmail,
                  ),
                ),
              );
            },
          ),
        );
        return true;
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
        _otpController.clearOtp();
        return false;
      }
    }
    return false;
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _authService.requestPasswordReset(widget.username);

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (result['success']) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => SuccessDialog(
            title: 'Code Resent',
            message: result['message'],
            confirmText: 'OK',
            onConfirm: () => Navigator.pop(context),
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
            onConfirm: () => Navigator.pop(context),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Page Title
                  PageTitle(
                    title: 'Verify Code',
                    subtitle: 'Code sent to ${widget.maskedEmail}',
                  ),
                  const SizedBox(height: 28),
                  
                  // OTP Input
                  OtpDigitInput(
                    onOtpChanged: (otp) {
                      if (otp.length == 6) {
                        _handleVerifyOtp(otp);
                      }
                    },
                    isLoading: _isLoading,
                    onControllerReady: (controller) {
                      _otpController = controller;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Resend Code Link
                  Center(
                    child: TextButton(
                      onPressed: _isLoading ? null : _resendOtp,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'Resend Code',
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
              message: 'Resending code...',
            ),
        ],
      ),
    );
  }
}
