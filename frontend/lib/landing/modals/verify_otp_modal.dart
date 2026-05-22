import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/responsive.dart';
import '../../core/reusable_widgets/logo_carousel_loading.dart';
import '../widgets/rightside_background.dart';
import '../widgets/forgot_password/verify_otp_form_side.dart';
import '../widgets/dialogs/success_dialog.dart';
import '../widgets/dialogs/error_dialog.dart';
import 'set_password_modal.dart';

/// OTP Verification Modal - Displays as a dialog overlay matching login modal design
class VerifyOtpModal extends StatefulWidget {
  final String username;
  final String maskedEmail;

  const VerifyOtpModal({
    super.key,
    required this.username,
    required this.maskedEmail,
  });

  @override
  State<VerifyOtpModal> createState() => _VerifyOtpModalState();
}

class _VerifyOtpModalState extends State<VerifyOtpModal> {
  final GlobalKey _formKey = GlobalKey();
  final _authService = AuthService();
  bool _isLoading = false;
  String _loadingMessage = 'Verifying...';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    super.dispose();
  }

  Future<bool> _handleVerifyOtp(String otp) async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Verifying...';
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
        // OTP verified successfully, show SetPasswordModal
        Navigator.pop(context);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => SetPasswordModal(
            username: widget.username,
            otpCode: otp,
            maskedEmail: widget.maskedEmail,
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
        return false;
      }
    }
    return false;
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Resending code...';
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
            title: 'Code Sent',
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
          ),
        );
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
                      VerifyOtpFormSide(
                        key: _formKey,
                        isLoading: _isLoading,
                        maskedEmail: widget.maskedEmail,
                        onVerifyOtp: _handleVerifyOtp,
                        onResendOtp: _resendOtp,
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
                      VerifyOtpFormSide(
                        key: _formKey,
                        isLoading: _isLoading,
                        maskedEmail: widget.maskedEmail,
                        onVerifyOtp: _handleVerifyOtp,
                        onResendOtp: _resendOtp,
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
                message: _loadingMessage,
              ),
          ],
        ),
      ),
    );
  }
}
