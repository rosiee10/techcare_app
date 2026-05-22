import 'package:flutter/material.dart';
import '../../../core/reusable_widgets/buttons.dart';
import '../../../core/reusable_widgets/page_title.dart';
import '../../../core/utils/colors.dart';

/// Left side of forgot password modal containing the form
class ForgotPasswordFormSide extends StatelessWidget {
  final TextEditingController usernameController;
  final bool isLoading;
  final VoidCallback onSendCode;
  final VoidCallback onBack;

  const ForgotPasswordFormSide({
    super.key,
    required this.usernameController,
    required this.isLoading,
    required this.onSendCode,
    required this.onBack,
  });

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
                    title: 'Forgot Password?',
                    subtitle: 'Enter your username or email',
                    addShadow: false,
                  ),
                  const SizedBox(height: 32),
                  _buildUsernameField(),
                  const SizedBox(height: 24),
                  _buildSendCodeButton(),
                  const SizedBox(height: 16),
                  _buildBackToLogin(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: usernameController,
      enabled: !isLoading,
      decoration: InputDecoration(
        hintText: 'Username or Email',
        hintStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFFAAAAAA),
        ),
        prefixIcon: const Icon(
          Icons.person_outline,
          color: Color(0xFF666666),
          size: 20,
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
    );
  }

  Widget _buildSendCodeButton() {
    return GradientButton(
      text: 'Send Verification Code',
      onPressed: isLoading ? null : onSendCode,
      height: 48,
    );
  }

  Widget _buildBackToLogin() {
    return Center(
      child: TextButton(
        onPressed: isLoading ? null : onBack,
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
    );
  }
}
