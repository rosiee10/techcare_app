import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/footer_widget.dart';
import '../widgets/contact_section.dart';
import '../sections/hero_section.dart';
import '../sections/modules_section.dart';
import '../sections/about_section.dart';
import '../widgets/support/contact_us_dialog.dart';
import '../widgets/support/faqs_dialog.dart';
import '../widgets/support/privacy_policy_dialog.dart';
import '../widgets/login/terms_dialog.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _homeKey = GlobalKey();
  final GlobalKey _modulesKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();
  final GlobalKey _contactKey = GlobalKey();
  final GlobalKey<CustomAppBarState> _appBarKey = GlobalKey<CustomAppBarState>();
  String _activeSection = 'Home';
  bool _isMenuExpanded = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(GlobalKey key, String sectionName) {
    final context = key.currentContext;
    if (context != null) {
      setState(() {
        _activeSection = sectionName;
      });
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        key: _appBarKey,
        activeSection: _activeSection,
        onHomePressed: () => _scrollToSection(_homeKey, 'Home'),
        onModulesPressed: () => _scrollToSection(_modulesKey, 'Modules'),
        onAboutPressed: () => _scrollToSection(_aboutKey, 'About'),
        onContactPressed: () => _scrollToSection(_contactKey, 'Contact'),
        onLoginPressed: () {
          // Navigate to login page
        },
        onMenuToggle: (isExpanded) {
          setState(() {
            _isMenuExpanded = isExpanded;
          });
        },
      ),
      body: Column(
        children: [
          // Mobile menu (shown only on mobile when expanded)
          if (_appBarKey.currentState != null)
            _appBarKey.currentState!.buildMobileMenu(),
          // Main content
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  HeroSection(key: _homeKey),
                  const SizedBox(height: 80),
                  ModulesSection(key: _modulesKey),
                  const SizedBox(height: 80),
                  AboutSection(key: _aboutKey),
                  const SizedBox(height: 80),
                  ContactSection(key: _contactKey),
                  const SizedBox(height: 0),
                  FooterWidget(
                    onHomePressed: () => _scrollToSection(_homeKey, 'Home'),
                    onAboutPressed: () => _scrollToSection(_aboutKey, 'About'),
                    onModulesPressed: () => _scrollToSection(_modulesKey, 'Modules'),
                    onContactPressed: () => _scrollToSection(_contactKey, 'Contact'),
                    onContactUsPressed: () => ContactUsDialog.show(context),
                    onFAQsPressed: () => FAQsDialog.show(context),
                    onPrivacyPolicyPressed: () => PrivacyPolicyDialog.show(context),
                    onTermsPressed: () => TermsDialog.show(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
