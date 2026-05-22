import 'package:flutter/material.dart';
import '../../../core/reusable_widgets/page_title.dart';
import '../../../core/utils/colors.dart';

/// OTP Verification Form Side - OTP verification only (password reset handled separately)
class VerifyOtpFormSide extends StatefulWidget {
  final bool isLoading;
  final String maskedEmail;
  final Future<bool> Function(String) onVerifyOtp;
  final VoidCallback onResendOtp;

  const VerifyOtpFormSide({
    super.key,
    required this.isLoading,
    required this.maskedEmail,
    required this.onVerifyOtp,
    required this.onResendOtp,
  });

  @override
  State<VerifyOtpFormSide> createState() => _VerifyOtpFormSideState();
}

class _VerifyOtpFormSideState extends State<VerifyOtpFormSide> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String getOtp() {
    return _controllers.map((c) => c.text).join();
  }

  void _handleOtpChange(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    final otp = getOtp();
    if (otp.length == 6) {
      widget.onVerifyOtp(otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PageTitle(
                    title: 'Verify Code',
                    subtitle: 'Code sent to ${widget.maskedEmail}',
                    addShadow: false,
                  ),
                  const SizedBox(height: 24),
                  // Enter code label
                  Text(
                    'Enter 6-digit code',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // OTP 6 boxes
                  _buildOtpBoxes(),
                  const SizedBox(height: 24),
                  // Resend Code
                  Center(
                    child: TextButton(
                      onPressed: widget.isLoading ? null : widget.onResendOtp,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      child: const Text(
                        'Resend Code',
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
    );
  }

  Widget _buildOtpBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Container(
          width: 46,
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 3.5),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            enabled: !widget.isLoading,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
              ),
            ),
            onChanged: (value) => _handleOtpChange(index, value),
          ),
        );
      }),
    );
  }
}
