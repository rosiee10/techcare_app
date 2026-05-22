import 'package:flutter/material.dart';
import '../../core/utils/responsive.dart';
import '../../core/reusable_widgets/logo_carousel_loading.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/contact_service.dart';

class ContactSection extends StatefulWidget {
  const ContactSection({super.key});

  @override
  State<ContactSection> createState() => _ContactSectionState();
}

class _ContactSectionState extends State<ContactSection> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Call backend API
      final result = await ContactService.submitMessage(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty 
            ? null 
            : _phoneController.text.trim(),
        message: _messageController.text.trim(),
      );

      setState(() {
        _isLoading = false;
        _isSuccess = result['success'];
      });

      if (!result['success'] && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to send message'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Reset form after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isSuccess = false;
            if (result['success']) {
              _nameController.clear();
              _emailController.clear();
              _phoneController.clear();
              _messageController.clear();
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 60 : 80,
        horizontal: isMobile ? 20 : 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isMobile || isTablet
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLeftSection(isMobile || isTablet),
                    const SizedBox(height: 40),
                    _buildContactForm(isMobile || isTablet),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildLeftSection(false),
                    ),
                    const SizedBox(width: 60),
                    Expanded(
                      flex: 2,
                      child: _buildContactForm(false),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLeftSection(bool isMobile) {
    final contactDetails = [
      _buildContactDetail(
        icon: Icons.location_on_outlined,
        title: 'Visit Us',
        content: 'Sitio Matco, Panalsalan, Plaridel,\nMisamis Occidental, Philippines',
        isMobile: isMobile,
        onTap: () => _openMap(),
        isClickable: true,
      ),
      _buildFacebookDetail(isMobile),
      _buildContactDetail(
        icon: Icons.email_outlined,
        title: 'Email Us',
        content: 'pch.plaridel@gmail.com\nplaridel_misocc@yahoo.com',
        isMobile: isMobile,
      ),
      _buildContactDetail(
        icon: Icons.access_time_outlined,
        title: 'Office Hours',
        content: 'Mon-Fri: 8:00 AM - 5:00 PM\nSat: 8:00 AM - 12:00 PM',
        isMobile: isMobile,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome message
        Text(
          "Let's Talk",
          style: TextStyle(
            fontSize: isMobile ? 32 : 40,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1976D2),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "We'd love to hear from you. Whether you have a question about our system, need technical support, or just want to say hello - our team is ready to help.",
          style: TextStyle(
            fontSize: isMobile ? 16 : 18,
            color: Colors.grey[600],
            height: 1.6,
          ),
        ),
        const SizedBox(height: 40),

        // Contact details - use grid on tablet, column on mobile/desktop
        if (!isMobile && !Responsive.isMobile(context) && Responsive.isTablet(context))
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: contactDetails,
          )
        else
          Column(
            children: contactDetails
                .map((detail) => Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: detail,
                    ))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildContactDetail({
    required IconData icon,
    required String title,
    required String content,
    required bool isMobile,
    VoidCallback? onTap,
    bool isClickable = false,
  }) {
    final contentWidget = Column(
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
        const SizedBox(height: 4),
        Text(
          content,
          style: TextStyle(
            fontSize: isMobile ? 14 : 15,
            color: isClickable ? const Color(0xFF1976D2) : Colors.grey[600],
            height: 1.5,
          ),
        ),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1976D2).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF1976D2),
            size: isMobile ? 24 : 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: isClickable
              ? InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: contentWidget,
                  ),
                )
              : contentWidget,
        ),
      ],
    );
  }

  Widget _buildFacebookDetail(bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1877F2).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.facebook,
            color: const Color(0xFF1877F2),
            size: isMobile ? 24 : 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: () => _openFacebook(),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Facebook',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Plaridel Community Hospital',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 15,
                      color: const Color(0xFF1877F2),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openMap() {
    // Open Google Maps with PCH location
    final url = Uri.encodeFull(
      'https://www.google.com/maps/search/?api=1&query=Sitio+Matco,+Panalsalan,+Plaridel,+Misamis+Occidental,+Philippines+7209',
    );
    _launchUrl(url);
  }

  void _openFacebook() {
    const url = 'https://www.facebook.com/profile.php?id=100089548985190';
    _launchUrl(url);
  }

  void _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildContactForm(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFFF0F7FF),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF1976D2).withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1976D2).withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1976D2),
                            const Color(0xFF2196F3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1976D2).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.message_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Send us a Message',
                            style: TextStyle(
                              fontSize: isMobile ? 22 : 26,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1976D2),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "We'd love to hear from you!",
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 15,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Name field
                _buildEnhancedTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'John Doe',
                  icon: Icons.person_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email field
                _buildEnhancedTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'john@example.com',
                  icon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone field (optional)
                _buildEnhancedTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: '+63 9XX XXX XXXX (Optional)',
                  icon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                // Message field
                _buildEnhancedTextField(
                  controller: _messageController,
                  label: 'Your Message',
                  hint: 'Tell us how we can help you...',
                  icon: Icons.chat_bubble_rounded,
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your message';
                    }
                    if (value.length < 10) {
                      return 'Message must be at least 10 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Submit button with gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isSuccess
                          ? [Colors.green[600]!, Colors.green[500]!]
                          : [
                              const Color(0xFF1976D2),
                              const Color(0xFF2196F3),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _isSuccess
                            ? Colors.green.withOpacity(0.4)
                            : const Color(0xFF1976D2).withOpacity(0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isLoading || _isSuccess ? null : _submitForm,
                    icon: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : _isSuccess
                            ? const Icon(Icons.check_circle)
                            : const Icon(Icons.send_rounded),
                    label: Text(
                      _isLoading
                          ? 'Sending...'
                          : _isSuccess
                              ? 'Message Sent!'
                              : 'Send Message',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 50),
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile ? 18 : 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const LogoCarouselLoading(size: 70),
                    const SizedBox(height: 20),
                    Text(
                      'Sending your message...',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1976D2),
              size: 20,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red[400]!, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red[400]!, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 15,
          ),
          floatingLabelStyle: const TextStyle(
            color: Color(0xFF1976D2),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
