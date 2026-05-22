import 'package:flutter/material.dart';
import '../../core/utils/responsive.dart';

class FooterWidget extends StatelessWidget {
  final VoidCallback? onHomePressed;
  final VoidCallback? onAboutPressed;
  final VoidCallback? onModulesPressed;
  final VoidCallback? onContactPressed;
  final VoidCallback? onContactUsPressed;
  final VoidCallback? onFAQsPressed;
  final VoidCallback? onPrivacyPolicyPressed;
  final VoidCallback? onTermsPressed;

  const FooterWidget({
    super.key,
    this.onHomePressed,
    this.onAboutPressed,
    this.onModulesPressed,
    this.onContactPressed,
    this.onContactUsPressed,
    this.onFAQsPressed,
    this.onPrivacyPolicyPressed,
    this.onTermsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    
    return Container(
      color: Colors.blue[700],
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 32 : 48,
        horizontal: isMobile ? 20 : 24,
      ),
      child: Column(
        children: [
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBrandingSection(isMobile),
                    const SizedBox(height: 32),
                    _FooterSection(
                      title: 'Quick Links',
                      links: const [
                        'Home',
                        'Modules',
                        'About Us',
                        'Contact',
                      ],
                      onLinkPressed: (link) {
                        switch (link) {
                          case 'Home':
                            onHomePressed?.call();
                            break;
                          case 'Modules':
                            onModulesPressed?.call();
                            break;
                          case 'About Us':
                            onAboutPressed?.call();
                            break;
                          case 'Contact':
                            onContactPressed?.call();
                            break;
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    _FooterSection(
                      title: 'Support',
                      links: const [
                        'Contact Us',
                        'FAQs',
                        'Privacy Policy',
                        'Terms & Conditions',
                      ],
                      onLinkPressed: (link) {
                        switch (link) {
                          case 'Contact Us':
                            onContactUsPressed?.call();
                            break;
                          case 'FAQs':
                            onFAQsPressed?.call();
                            break;
                          case 'Privacy Policy':
                            onPrivacyPolicyPressed?.call();
                            break;
                          case 'Terms & Conditions':
                            onTermsPressed?.call();
                            break;
                        }
                      },
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(child: _buildBrandingSection(isMobile)),
                    SizedBox(width: isTablet ? 24 : 48),
                    Expanded(
                      child: _FooterSection(
                        title: 'Quick Links',
                        links: const [
                          'Home',
                          'Modules',
                          'About Us',
                          'Contact',
                        ],
                        onLinkPressed: (link) {
                          switch (link) {
                            case 'Home':
                              onHomePressed?.call();
                              break;
                            case 'Modules':
                              onModulesPressed?.call();
                              break;
                            case 'About Us':
                              onAboutPressed?.call();
                              break;
                            case 'Contact':
                              onContactPressed?.call();
                              break;
                          }
                        },
                      ),
                    ),
                    SizedBox(width: isTablet ? 24 : 48),
                    Expanded(
                      child: _FooterSection(
                        title: 'Support',
                        links: const [
                          'Contact Us',
                          'FAQs',
                          'Privacy Policy',
                          'Terms & Conditions',
                        ],
                        onLinkPressed: (link) {
                          switch (link) {
                            case 'Contact Us':
                              onContactUsPressed?.call();
                              break;
                            case 'FAQs':
                              onFAQsPressed?.call();
                              break;
                            case 'Privacy Policy':
                              onPrivacyPolicyPressed?.call();
                              break;
                            case 'Terms & Conditions':
                              onTermsPressed?.call();
                              break;
                          }
                        },
                      ),
                    ),
                  ],
                ),
          SizedBox(height: isMobile ? 24 : 32),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            '© 2026 TECHCARE | Plaridel Community Hospital. All rights reserved.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: isMobile ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandingSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Image.asset(
                'assets/logos/logo.png',
                height: isMobile ? 40 : 50,
                width: isMobile ? 40 : 50,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.local_hospital,
                    color: Colors.blue,
                    size: isMobile ? 40 : 50,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'TECHCARE',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Image.asset(
                'assets/logos/pchlogo.png',
                height: isMobile ? 40 : 50,
                width: isMobile ? 40 : 50,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.local_hospital,
                    color: Colors.blue,
                    size: isMobile ? 40 : 50,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Plaridel Community Hospital',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 14 : 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Transforming healthcare through digital innovation and integrated solutions.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: isMobile ? 13 : 14,
          ),
        ),
      ],
    );
  }
}

class _FooterSection extends StatelessWidget {
  final String title;
  final List<String> links;
  final ValueChanged<String>? onLinkPressed;

  const _FooterSection({
    required this.title,
    required this.links,
    this.onLinkPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...links.map((link) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => onLinkPressed?.call(link),
                child: Text(
                  link,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            )),
      ],
    );
  }
}
