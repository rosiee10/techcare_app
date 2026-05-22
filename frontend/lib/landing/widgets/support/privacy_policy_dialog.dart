import 'package:flutter/material.dart';
import '../../../core/utils/responsive.dart';

class PrivacyPolicyDialog {
  static void show(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: isMobile ? MediaQuery.of(context).size.width * 0.9 : 700,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: EdgeInsets.all(isMobile ? 20 : 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Privacy Policy',
                      style: TextStyle(
                        fontSize: isMobile ? 22 : 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2196F3),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Last Updated: March 29, 2026',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        title: '1. Introduction',
                        content: 'Plaridel Community Hospital ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our TechCare Hospital Management System.',
                        isMobile: isMobile,
                      ),
                      _buildSection(
                        title: '2. Information We Collect',
                        content: 'We collect information that you provide directly to us, including:\n\n• Personal identification information (name, employee ID, contact details)\n• Medical and health information (for patient records)\n• Login credentials and authentication data\n• Usage data and system logs\n• Department and role information',
                        isMobile: isMobile,
                      ),
                      _buildSection(
                        title: '3. How We Use Your Information',
                        content: 'We use the collected information to:\n\n• Provide and maintain hospital management services\n• Process and manage patient records\n• Facilitate communication between departments\n• Ensure system security and prevent fraud\n• Comply with legal and regulatory requirements\n• Improve our services and user experience',
                        isMobile: isMobile,
                      ),
                      _buildSection(
                        title: '4. Data Security',
                        content: 'We implement appropriate technical and organizational security measures to protect your personal information, including:\n\n• Encryption of sensitive data\n• Secure authentication mechanisms\n• Regular security audits and updates\n• Access controls and user permissions\n• Secure data storage and backup systems',
                        isMobile: isMobile,
                      ),
                      _buildSection(
                        title: '5. Data Sharing and Disclosure',
                        content: 'We do not sell your personal information. We may share your information only:\n\n• With authorized hospital staff for legitimate medical purposes\n• When required by law or legal process\n• To protect the rights and safety of patients and staff\n• With your explicit consent',
                        isMobile: isMobile,
                      ),
                      _buildSection(
                        title: '6. Your Rights',
                        content: 'You have the right to:\n\n• Access your personal information\n• Request correction of inaccurate data\n• Request deletion of your data (subject to legal requirements)\n• Object to processing of your information\n• Withdraw consent at any time',
                        isMobile: isMobile,
                      ),
                      _buildSection(
                        title: '7. Data Retention',
                        content: 'We retain your information for as long as necessary to fulfill the purposes outlined in this policy, unless a longer retention period is required by law or for legitimate medical record-keeping purposes.',
                        isMobile: isMobile,
                      ),
                      _buildSection(
                        title: '8. Compliance',
                        content: 'Our system complies with:\n\n• Republic Act No. 10173 (Data Privacy Act of 2012)\n• Department of Health regulations\n• Healthcare data protection standards\n• Industry best practices for medical information security',
                        isMobile: isMobile,
                      ),
                      _buildSection(
                        title: '9. Contact Information',
                        content: 'For privacy-related questions or concerns, please contact:\n\nData Protection Officer\nPlaridel Community Hospital\nEmail: privacy@plaridelhospital.gov.ph\nPhone: +63 (044) 123-4567',
                        isMobile: isMobile,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildSection({
    required String title,
    required String content,
    required bool isMobile,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: isMobile ? 14 : 15,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
