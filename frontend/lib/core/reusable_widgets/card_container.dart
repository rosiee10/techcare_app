import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable card container with shadow and rounded corners
/// Used for consistent card styling across the application
class CardContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? backgroundColor;

  const CardContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // Try to get theme, fallback to light theme if provider not available
    AppThemeData theme;
    try {
      theme = AppTheme.of(context);
    } catch (e) {
      theme = AppTheme.light;
    }

    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.cardBackground,
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
        boxShadow: [
          BoxShadow(
            color: theme.isDark
              ? Colors.black.withAlpha(77)
              : Colors.grey.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
