import 'package:flutter/material.dart';
import '../../core/utils/platform_detector.dart';
import 'splash_screen.dart';
import 'landing_page.dart';
import 'mobile_home_page.dart';

class PlatformRouterPage extends StatefulWidget {
  const PlatformRouterPage({super.key});

  @override
  State<PlatformRouterPage> createState() => _PlatformRouterPageState();
}

class _PlatformRouterPageState extends State<PlatformRouterPage> {
  @override
  void initState() {
    super.initState();
    _routeBasedOnPlatform();
  }

  void _routeBasedOnPlatform() {
    if (PlatformDetector.isMobileApp) {
      // For mobile: Show splash screen for 3 seconds, then navigate to mobile home
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/mobile-home');
      });
    } else {
      // For web: Navigate immediately to landing page
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show splash screen for mobile, simple loading for web
    if (PlatformDetector.isMobileApp) {
      return const SplashScreen();
    } else {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.blue[600]!,
            ),
          ),
        ),
      );
    }
  }
}
