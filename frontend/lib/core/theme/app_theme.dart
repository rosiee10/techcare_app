import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../modules/shared/widgets/dashboard_theme_wrapper.dart';

class AppTheme {
  // Light Theme Colors
  static const AppThemeData light = AppThemeData(
    isDark: false,
    pageBackground: Color(0xFFF5F6FA),
    headerBackground: Colors.white,
    headerText: Color(0xFF1A1A1A),
    sidebarBackground: Colors.white,
    sidebarText: Color(0xFF4A5568),
    sidebarActiveBackground: Color(0xFFEBF5FF),
    sidebarActiveText: Color(0xFF1E88E5),
    sidebarHoverBackground: Color(0xFFF7FAFC),
    cardBackground: Colors.white,
    cardBorder: Color(0xFFE2E8F0),
    cardShadow: Color(0x1A000000),
    buttonPrimary: Color(0xFF1E88E5),
    buttonPrimaryText: Colors.white,
    buttonSecondary: Color(0xFF718096),
    buttonSecondaryText: Colors.white,
    buttonHover: Color(0xFF1565C0),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF718096),
    textMuted: Color(0xFFA0AEC0),
    inputBackground: Colors.white,
    inputBorder: Color(0xFFE2E8F0),
    inputFocusBorder: Color(0xFF1E88E5),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    info: Color(0xFF3B82F6),
  );

  // Dark Theme Colors
  static const AppThemeData dark = AppThemeData(
    isDark: true,
    pageBackground: Color(0xFF111827),
    headerBackground: Color(0xFF1F2937),
    headerText: Colors.white,
    sidebarBackground: Color(0xFF1F2937),
    sidebarText: Color(0xFF9CA3AF),
    sidebarActiveBackground: Color(0xFF374151),
    sidebarActiveText: Colors.white,
    sidebarHoverBackground: Color(0xFF2D3748),
    cardBackground: Color(0xFF1F2937),
    cardBorder: Color(0xFF374151),
    cardShadow: Color(0x40000000),
    buttonPrimary: Color(0xFF3B82F6),
    buttonPrimaryText: Colors.white,
    buttonSecondary: Color(0xFF374151),
    buttonSecondaryText: Color(0xFFE5E7EB),
    buttonHover: Color(0xFF2563EB),
    textPrimary: Colors.white,
    textSecondary: Color(0xFF9CA3AF),
    textMuted: Color(0xFF6B7280),
    inputBackground: Color(0xFF1F2937),
    inputBorder: Color(0xFF374151),
    inputFocusBorder: Color(0xFF3B82F6),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    info: Color(0xFF3B82F6),
  );

  static AppThemeData of(BuildContext context) {
    // Check if we're inside a dashboard (has DashboardThemeProvider)
    final dashboardTheme = Provider.of<DashboardThemeProvider>(context);
    return dashboardTheme.isDarkMode ? dark : light;
  }
}

class AppThemeData {
  final bool isDark;
  final Color pageBackground;
  final Color headerBackground;
  final Color headerText;
  final Color sidebarBackground;
  final Color sidebarText;
  final Color sidebarActiveBackground;
  final Color sidebarActiveText;
  final Color sidebarHoverBackground;
  final Color cardBackground;
  final Color cardBorder;
  final Color cardShadow;
  final Color buttonPrimary;
  final Color buttonPrimaryText;
  final Color buttonSecondary;
  final Color buttonSecondaryText;
  final Color buttonHover;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color inputBackground;
  final Color inputBorder;
  final Color inputFocusBorder;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  const AppThemeData({
    required this.isDark,
    required this.pageBackground,
    required this.headerBackground,
    required this.headerText,
    required this.sidebarBackground,
    required this.sidebarText,
    required this.sidebarActiveBackground,
    required this.sidebarActiveText,
    required this.sidebarHoverBackground,
    required this.cardBackground,
    required this.cardBorder,
    required this.cardShadow,
    required this.buttonPrimary,
    required this.buttonPrimaryText,
    required this.buttonSecondary,
    required this.buttonSecondaryText,
    required this.buttonHover,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.inputBackground,
    required this.inputBorder,
    required this.inputFocusBorder,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
  });

  // Modern bold title style
  TextStyle get titleStyle => TextStyle(
    fontFamily: 'Poppins',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  // Subtitle style
  TextStyle get subtitleStyle => TextStyle(
    fontFamily: 'Poppins',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.3,
  );

  // Section header style
  TextStyle get sectionHeaderStyle => TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.2,
  );

  // Card title style
  TextStyle get cardTitleStyle => TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.1,
  );
}
