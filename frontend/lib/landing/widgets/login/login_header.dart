import 'package:flutter/material.dart';

/// Reusable header widget displaying dual logos and title information
class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDualLogos(),
        const SizedBox(height: 12),
        _buildTitle(),
        const SizedBox(height: 6),
        _buildSubtitle(),
        const SizedBox(height: 3),
        _buildDescription(),
      ],
    );
  }

  Widget _buildDualLogos() {
    return SizedBox(
      width: 170,
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LogoCircle(
            assetPath: 'assets/logos/logo.png',
            fallbackIcon: Icons.local_hospital,
          ),
          const SizedBox(width: 30),
          _LogoCircle(
            assetPath: 'assets/logos/pchlogo.png',
            fallbackIcon: Icons.business,
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'TECHCARE',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: Color(0xFF2196F3),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSubtitle() {
    return const Text(
      'Plaridel Community Hospital',
      style: TextStyle(
        fontSize: 13,
        color: Color(0xFF666666),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildDescription() {
    return const Text(
      'Login to Access',
      style: TextStyle(
        fontSize: 12,
        color: Color(0xFF999999),
      ),
    );
  }
}

/// Private widget for circular logo display
class _LogoCircle extends StatelessWidget {
  final String assetPath;
  final IconData fallbackIcon;

  const _LogoCircle({
    required this.assetPath,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              fallbackIcon,
              size: 40,
              color: const Color(0xFF2196F3),
            );
          },
        ),
      ),
    );
  }
}
