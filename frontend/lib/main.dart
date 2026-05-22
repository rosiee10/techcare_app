import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:shared_preferences/shared_preferences.dart';
import 'core/provider/auth_provider.dart';
import 'core/provider/theme_provider.dart';
import 'modules/admin/provider/manage_users_provider.dart';
import 'modules/shared/widgets/dashboard_theme_wrapper.dart';
import 'modules/shared/address/services/address_service.dart';
import 'modules/patient/providers/patient_provider.dart';
import 'modules/chief_nurse/providers/chief_nurse_provider.dart';
import 'core/routes/app_routes.dart';
import 'core/utils/platform_detector.dart';
import 'core/services/session_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize address database for offline support
  await AddressService().initialize();
  runApp(const TechCareApp());
}

class TechCareApp extends StatefulWidget {
  const TechCareApp({super.key});
  @override
  State<TechCareApp> createState() => _TechCareAppState();
}

class _TechCareAppState extends State<TechCareApp> {
  late Future<String> _initialRouteFuture;
  @override
  void initState() {
    super.initState();
    _initialRouteFuture = _determineInitialRoute();
  }

  Future<String> _determineInitialRoute() async {
    // Wait for auth provider to initialize
    final authProvider = AuthProvider();
    // Give auth provider time to check authentication status
    await Future.delayed(const Duration(milliseconds: 500));
    if (authProvider.isAuthenticated) {
      // User is authenticated, route to their dashboard
      final userRole = authProvider.role;
      final deployment = authProvider.deployment;
      final subRole = authProvider.subRole;

      return AppRoutes.getDashboardRouteForRole(
        userRole,
        deployment: deployment,
        subRole: subRole,
      );
    } else {
      // User is not authenticated, route to landing page
      return PlatformDetector.isMobileApp 
        ? AppRoutes.mobileHome 
        : AppRoutes.landing;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => DashboardThemeProvider()),
          ChangeNotifierProvider(create: (_) => ManageUsersProvider()),
          ChangeNotifierProvider(create: (_) => PatientProvider()),
          ChangeNotifierProvider(create: (_) => ChiefNurseProvider()),
        ],
        child: FutureBuilder<String>(
          future: _initialRouteFuture,
          builder: (context, snapshot) {
            // Show loading screen while determining route
            if (snapshot.connectionState == ConnectionState.waiting) {
              return MaterialApp(
                home: Scaffold(
                  backgroundColor: Colors.white,
                  body: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              );
            }

            final initialRoute = snapshot.data ?? AppRoutes.landing;
            return MaterialApp(
              navigatorKey: navigatorKey,
              title: 'TechCare - Hospital Management System',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.blue,
                  brightness: Brightness.light,
                ),
                useMaterial3: true,
                fontFamily: 'Roboto',
              ),
              themeMode: ThemeMode.light,
              initialRoute: initialRoute,
              routes: AppRoutes.getRoutes(),
              onGenerateRoute: AppRoutes.onGenerateRoute,
            );
          },
        ),
      ),
    );
  }
}
