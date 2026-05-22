import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Separate theme provider for dashboard only
/// This keeps landing pages unaffected by dashboard dark mode
class DashboardThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  
  bool get isDarkMode => _isDarkMode;
  
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  
  DashboardThemeProvider() {
    _loadTheme();
  }
  
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('dashboard_dark_mode') ?? false;
    notifyListeners();
  }
  
  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dashboard_dark_mode', value);
    notifyListeners();
  }
  
  void toggleTheme() {
    setDarkMode(!_isDarkMode);
  }
}

/// Wrapper widget that provides dashboard-specific theme
/// Use this to wrap admin pages only
class DashboardThemeWrapper extends StatelessWidget {
  final Widget child;
  
  const DashboardThemeWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Use existing DashboardThemeProvider from main.dart
    return Consumer<DashboardThemeProvider>(
      builder: (context, themeProvider, _) {
        return AnimatedTheme(
          data: themeProvider.isDarkMode 
            ? _buildDarkTheme()
            : _buildLightTheme(),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
          child: child,
        );
      },
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: const Color(0xFFF5F6FA),
      cardColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1E88E5),
        surface: Colors.white,
        background: Color(0xFFF5F6FA),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF111827),
      cardColor: const Color(0xFF1F2937),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF3B82F6),
        surface: const Color(0xFF1F2937),
        background: const Color(0xFF111827),
      ),
    );
  }
}
