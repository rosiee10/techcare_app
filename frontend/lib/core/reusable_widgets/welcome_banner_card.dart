import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Welcome banner card for dashboard
/// 
/// Features:
/// - Gradient background
/// - Title, subtitle, and description
/// - Optional action button
/// - Configurable colors and layout
class WelcomeBannerCard extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final IconData? icon;
  final String? imagePath;
  final Color? startColor;
  final Color? endColor;
  final EdgeInsets margin;
  final double borderRadius;

  const WelcomeBannerCard({
    super.key,
    this.title = '',
    required this.message,
    this.actionLabel,
    this.onActionTap,
    this.icon,
    this.imagePath,
    this.startColor,
    this.endColor,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final bgStart = startColor ?? theme.buttonPrimary;
    final bgEnd = endColor ?? theme.buttonPrimary.withOpacity(0.7);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgStart, bgEnd.withOpacity(0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 1.0],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: bgStart.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative bubbles
          Positioned(
            top: -20,
            left: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: 50,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          // Content on the left
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 20, bottom: 20, right: 150),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title.isNotEmpty) ...[
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
                if (actionLabel != null && onActionTap != null) ...[
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: onActionTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        actionLabel!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: bgStart,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Image positioned at bottom-right
          if (imagePath != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(borderRadius),
                ),
                child: Image.asset(
                  imagePath!,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          // Icon fallback (centered right)
          if (imagePath == null && icon != null)
            Positioned(
              right: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
