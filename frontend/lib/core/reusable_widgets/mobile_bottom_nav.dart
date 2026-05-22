import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

/// Mobile Bottom Navigation Bar using Google Nav Bar
/// 
/// Features:
/// - Google-style pill-shaped active indicator
/// - Customizable icons and labels
/// - Smooth animations
/// - Badge support for notifications
class MobileBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabChange;
  final List<NavItem> items;
  final Color? backgroundColor;
  final Color? activeColor;
  final Color? inactiveColor;
  final double? iconSize;
  final double? gap;
  final EdgeInsets? padding;

  const MobileBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTabChange,
    required this.items,
    this.backgroundColor,
    this.activeColor,
    this.inactiveColor,
    this.iconSize,
    this.gap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: GNav(
            selectedIndex: selectedIndex,
            onTabChange: onTabChange,
            gap: gap ?? 4,
            activeColor: activeColor ?? theme.primaryColor,
            iconSize: iconSize ?? 22,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            duration: const Duration(milliseconds: 400),
            tabBackgroundColor: (activeColor ?? theme.primaryColor).withOpacity(0.1),
            color: inactiveColor ?? Colors.grey[600]!,
            tabs: items.map((item) => GButton(
              icon: item.icon,
              text: item.label,
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              leading: item.badgeCount != null && item.badgeCount! > 0
                  ? Badge(
                      label: Text(item.badgeCount.toString()),
                      child: Icon(item.icon),
                    )
                  : null,
            )).toList(),
          ),
        ),
      ),
    );
  }
}

/// Navigation item data class
class NavItem {
  final IconData icon;
  final String label;
  final int? badgeCount;

  const NavItem({
    required this.icon,
    required this.label,
    this.badgeCount,
  });
}
