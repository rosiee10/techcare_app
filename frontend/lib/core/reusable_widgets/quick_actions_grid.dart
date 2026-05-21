import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Quick action item data
class QuickActionItem {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  const QuickActionItem({
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
  });
}

/// Horizontal scrollable quick actions
/// 
/// Features:
/// - Circular icon buttons
/// - Horizontal scroll
/// - Customizable colors
/// - Optional title
class QuickActionsGrid extends StatelessWidget {
  final List<QuickActionItem> actions;
  final String? title;
  final EdgeInsets margin;
  final double iconSize;
  final double spacing;

  const QuickActionsGrid({
    super.key,
    required this.actions,
    this.title,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
    this.iconSize = 56,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Container(
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
          ],
          SizedBox(
            height: iconSize + 30, // Icon + label space
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: actions.length,
              separatorBuilder: (_, __) => SizedBox(width: spacing),
              itemBuilder: (context, index) {
                final action = actions[index];
                return _ActionButton(
                  item: action,
                  iconSize: iconSize,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Single action button with label
class _ActionButton extends StatelessWidget {
  final QuickActionItem item;
  final double iconSize;

  const _ActionButton({
    required this.item,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final color = item.color ?? theme.buttonPrimary;

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.icon,
                color: Colors.white,
                size: iconSize * 0.45,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
