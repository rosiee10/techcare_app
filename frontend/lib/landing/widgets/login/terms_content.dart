import 'package:flutter/material.dart';

/// Reusable Terms and Conditions content widget
class TermsContent extends StatelessWidget {
  const TermsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            'Introduction',
            'Welcome to TechCare - Plaridel Community Hospital Management System. '
            'By accessing and using this system, you agree to comply with and be bound by the following terms and conditions.',
          ),
          _buildSection(
            'User Responsibilities',
            '• You are responsible for maintaining the confidentiality of your login credentials.\n'
            '• You must not share your account with any other person.\n'
            '• You agree to notify the system administrator immediately of any unauthorized use of your account.\n'
            '• You are responsible for all activities that occur under your account.',
          ),
          _buildSection(
            'Data Privacy and Security',
            '• All patient data is confidential and protected under the Data Privacy Act.\n'
            '• You must handle all patient information in accordance with HIPAA and local privacy regulations.\n'
            '• Unauthorized disclosure of patient information is strictly prohibited.\n'
            '• You agree to use the system only for legitimate healthcare purposes.',
          ),
          _buildSection(
            'System Usage',
            '• The system must be used only for authorized hospital operations.\n'
            '• Any attempt to breach security or access unauthorized areas is prohibited.\n'
            '• You must log out after each session to protect patient data.\n'
            '• Misuse of the system may result in account suspension or legal action.',
          ),
          _buildSection(
            'Compliance',
            '• You agree to comply with all hospital policies and procedures.\n'
            '• You must follow all applicable healthcare regulations and standards.\n'
            '• Regular training and updates on system usage are mandatory.',
          ),
          _buildSection(
            'Limitation of Liability',
            'The hospital and system administrators are not liable for any damages arising from system use, '
            'including but not limited to data loss, unauthorized access, or system downtime.',
          ),
          _buildSection(
            'Changes to Terms',
            'These terms and conditions may be updated periodically. Continued use of the system constitutes '
            'acceptance of any changes.',
          ),
          const SizedBox(height: 20),
          const Text(
            'Last Updated: March 2026',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF999999),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2196F3),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF333333),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
