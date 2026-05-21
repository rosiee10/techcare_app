import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/responsive.dart';
import '../../core/reusable_widgets/logo_carousel_loading.dart';
import '../widgets/rightside_background.dart';
import '../widgets/forgot_password/forgot_password_form_side.dart';
import 'verify_otp_modal.dart';
import '../widgets/dialogs/success_dialog.dart';
import '../widgets/dialogs/error_dialog.dart';

/// Forgot Password Modal - Displays as a dialog overlay matching login modal design
class ForgotPasswordModal extends StatefulWidget {
  const ForgotPasswordModal({super.key});

  @override
  State<ForgotPasswordModal> createState() => _ForgotPasswordModalState();
}

class _ForgotPasswordModalState extends State<ForgotPasswordModal> {
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

    // First, verify if user exists
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

      // User exists, now send OTP
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
                // Close success dialog
                Navigator.pop(context);
                // Close forgot password modal
                Navigator.pop(context);
                // Then open OTP modal
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => VerifyOtpModal(
                    username: username,
                    maskedEmail: checkResult['email'] ?? result['email'] ?? '',
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

  void _handleClose() {
    Navigator.pop(context);
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
                      ForgotPasswordFormSide(
                        usernameController: _usernameController,
                        isLoading: _isLoading,
                        onSendCode: _requestOtp,
                        onBack: _handleClose,
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
                      ForgotPasswordFormSide(
                        usernameController: _usernameController,
                        isLoading: _isLoading,
                        onSendCode: _requestOtp,
                        onBack: _handleClose,
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
                message: 'Sending code...',
              ),
          ],
        ),
      ),
    );
  }
}
