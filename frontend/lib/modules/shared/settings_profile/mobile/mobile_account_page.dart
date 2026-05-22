import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/provider/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../pages/profile_page.dart';
import '../pages/settings_page.dart';
import '../pages/change_password_page.dart';

/// Mobile Account Page - Simplified account management for mobile
/// Shows user info and navigation to profile, settings, and other account options
class MobileAccountPage extends StatelessWidget {
  const MobileAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final userData = authProvider.userData;
    final profileData = authProvider.userProfile;
    final fullName = authProvider.fullName ?? 'User';
    final initials = userData?['firstname']?[0] ?? 'U';

    // Convert relative URL to full URL for mobile
    String? photoUrl = profileData?['profile_photo_url'];
    if (photoUrl != null && photoUrl.startsWith('/media/')) {
      photoUrl = 'http://10.0.2.2:8000$photoUrl';
    }

    return WillPopScope(
      onWillPop: () async {
        // Allow back navigation from account page
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          color: Colors.white,
          child: CustomScrollView(
            slivers: [
          // Header with back button - matches Home and Patient List styling
          SliverAppBar(
            pinned: true,
            floating: false,
            elevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            expandedHeight: 56,
            toolbarHeight: 56,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.white,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            centerTitle: true,
          ),

          // Account Header Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildAccountHeader(
                context,
                theme,
                fullName,
                initials,
                photoUrl,
                userData?['email'] ?? '',
              ),
            ),
          ),

          // Account Options List
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                  _buildAccountOption(
                    context,
                    icon: Icons.person_outline,
                    title: 'Personal Information',
                    subtitle: 'Edit your profile details',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilePage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildAccountOption(
                    context,
                    icon: Icons.help_outline,
                    title: 'FAQs',
                    subtitle: 'Frequently asked questions',
                    onTap: () {
                      // TODO: Navigate to FAQs page
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildAccountOption(
                    context,
                    icon: Icons.info_outline,
                    title: 'About TECHCARE',
                    subtitle: 'Learn more about us',
                    onTap: () {
                      // TODO: Navigate to About page
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildAccountOption(
                    context,
                    icon: Icons.phone_outlined,
                    title: 'Contact Us',
                    subtitle: 'Get in touch with support',
                    onTap: () {
                      // TODO: Navigate to Contact page
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildAccountOption(
                    context,
                    icon: Icons.star_outline,
                    title: 'Rate our app',
                    subtitle: 'Share your feedback',
                    onTap: () {
                      // TODO: Open app store rating
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildAccountOption(
                    context,
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    subtitle: 'App preferences and notifications',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildAccountOption(
                    context,
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    subtitle: 'Update your password',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildAccountOption(
                    context,
                    icon: Icons.logout,
                    title: 'Logout',
                    subtitle: 'Sign out from your account',
                    onTap: () {
                      _showLogoutConfirmation(context, authProvider);
                    },
                    isDestructive: true,
                  ),
                  const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountHeader(
    BuildContext context,
    AppThemeData theme,
    String fullName,
    String initials,
    String? photoUrl,
    String email,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.buttonPrimary,
              borderRadius: BorderRadius.circular(24),
              image: photoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(photoUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: photoUrl == null
                ? Center(
                    child: Text(
                      initials.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),

                // Email
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Weather icon (optional decoration)
          Icon(
            Icons.wb_sunny_outlined,
            color: Colors.amber[600],
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = AppTheme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
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
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? Colors.red.withOpacity(0.1)
                      : theme.buttonPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isDestructive ? Colors.red : theme.buttonPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDestructive ? Colors.red : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout from your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              authProvider.logout();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
