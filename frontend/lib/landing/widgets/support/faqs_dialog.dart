import 'package:flutter/material.dart';
import '../../../core/utils/responsive.dart';

class FAQsDialog {
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
                      'Frequently Asked Questions',
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 28,
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
              const SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FAQItem(
                        question: 'What is TechCare?',
                        answer: 'TechCare is a comprehensive hospital management system designed for Plaridel Community Hospital. It integrates all hospital departments including OPD, IPD, Pharmacy, Laboratory, and more into one unified digital platform.',
                        isMobile: isMobile,
                      ),
                      _FAQItem(
                        question: 'How do I access the system?',
                        answer: 'Click the "Login" button on the homepage and enter your assigned username and password. If you haven\'t received your credentials, please contact the IT department.',
                        isMobile: isMobile,
                      ),
                      _FAQItem(
                        question: 'I forgot my password. What should I do?',
                        answer: 'Click on "Forgot Password?" on the login screen, or contact the IT department at techsupport@techcare.ph or call +63 (044) 999-8888 for assistance.',
                        isMobile: isMobile,
                      ),
                      _FAQItem(
                        question: 'What modules are available in TechCare?',
                        answer: 'TechCare includes:\n• OPDIGIMS - Outpatient Department Management\n• InPatient - Hospital Admission System\n• PharmaTrack - Pharmacy Inventory\n• MediStock - Central Supply Office\n• Labora-X - Laboratory & Radiology\n• Social Work - Patient Assistance\n• Hospital Billing System\n• AutoKMS - Kitchen Management',
                        isMobile: isMobile,
                      ),
                      _FAQItem(
                        question: 'Is my data secure?',
                        answer: 'Yes, TechCare uses industry-standard encryption and security measures to protect all patient and hospital data. We comply with the Data Privacy Act of 2012 and healthcare data protection standards.',
                        isMobile: isMobile,
                      ),
                      _FAQItem(
                        question: 'Can I access TechCare from my mobile device?',
                        answer: 'Yes, TechCare is fully responsive and can be accessed from any device with a web browser, including smartphones and tablets.',
                        isMobile: isMobile,
                      ),
                      _FAQItem(
                        question: 'Who can I contact for technical support?',
                        answer: 'For technical issues:\nEmail: techsupport@techcare.ph\nPhone: +63 (044) 999-8888\nOffice Hours: Monday-Friday, 8:00 AM - 5:00 PM',
                        isMobile: isMobile,
                      ),
                      _FAQItem(
                        question: 'How do I request new features or report bugs?',
                        answer: 'Please contact the IT department with your suggestions or bug reports. We continuously improve the system based on user feedback.',
                        isMobile: isMobile,
                      ),
                      _FAQItem(
                        question: 'What browsers are supported?',
                        answer: 'TechCare works best on modern browsers including Google Chrome, Mozilla Firefox, Microsoft Edge, and Safari. We recommend keeping your browser updated to the latest version.',
                        isMobile: isMobile,
                      ),
                      _FAQItem(
                        question: 'How often is the system updated?',
                        answer: 'We regularly update TechCare with new features, security patches, and improvements. Major updates are scheduled during off-peak hours to minimize disruption.',
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
}

class _FAQItem extends StatefulWidget {
  final String question;
  final String answer;
  final bool isMobile;

  const _FAQItem({
    required this.question,
    required this.answer,
    required this.isMobile,
  });

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: TextStyle(
                        fontSize: widget.isMobile ? 15 : 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF2196F3),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                widget.answer,
                style: TextStyle(
                  fontSize: widget.isMobile ? 14 : 15,
                  color: Colors.grey[700],
                  height: 1.6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
