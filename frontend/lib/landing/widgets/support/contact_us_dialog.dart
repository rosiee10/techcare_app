import 'package:flutter/material.dart';
import '../../../core/utils/responsive.dart';

class ContactUsDialog {
  static void show(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: isMobile ? MediaQuery.of(context).size.width * 0.9 : 600,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: EdgeInsets.all(isMobile ? 20 : 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Contact Us',
                    style: TextStyle(
                      fontSize: isMobile ? 22 : 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2196F3),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildContactSection(
                        icon: Icons.location_on,
                        title: 'Address',
                        content: 'Plaridel Community Hospital\nPlaridel, Bulacan, Philippines',
                        isMobile: isMobile,
                      ),
                      const SizedBox(height: 20),
                      _buildContactSection(
                        icon: Icons.phone,
                        title: 'Phone',
                        content: '+63 (044) 123-4567\n+63 (044) 765-4321',
                        isMobile: isMobile,
                      ),
                      const SizedBox(height: 20),
                      _buildContactSection(
                        icon: Icons.email,
                        title: 'Email',
                        content: 'info@plaridelhospital.gov.ph\nsupport@techcare.ph',
                        isMobile: isMobile,
                      ),
                      const SizedBox(height: 20),
                      _buildContactSection(
                        icon: Icons.access_time,
                        title: 'Office Hours',
                        content: 'Monday - Friday: 8:00 AM - 5:00 PM\nSaturday: 8:00 AM - 12:00 PM\nSunday: Closed',
                        isMobile: isMobile,
                      ),
                      const SizedBox(height: 20),
                      _buildContactSection(
                        icon: Icons.support_agent,
                        title: 'Technical Support',
                        content: 'For technical issues with the system:\nEmail: techsupport@techcare.ph\nPhone: +63 (044) 999-8888',
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

  static Widget _buildContactSection({
    required IconData icon,
    required String title,
    required String content,
    required bool isMobile,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF2196F3),
            size: isMobile ? 24 : 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
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
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
