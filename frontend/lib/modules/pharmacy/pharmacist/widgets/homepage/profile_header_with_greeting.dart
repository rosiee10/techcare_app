import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/provider/auth_provider.dart';
import '../../../../../core/theme/app_theme.dart';

/// Profile header with time-based greeting and morning/evening images for Pharmacist
class ProfileHeaderWithGreeting extends StatelessWidget {
  final VoidCallback? onTap;

  const ProfileHeaderWithGreeting({
    super.key,
    this.onTap,
  });

  /// Determine greeting message and image based on current time
  Map<String, dynamic> _getGreetingData() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return {
        'greeting': 'Good Morning',
        'image': 'assets/images/morning.png',
        'isEvening': false,
      };
    } else if (hour >= 12 && hour < 17) {
      return {
        'greeting': 'Good Afternoon',
        'image': 'assets/images/morning.png',
        'isEvening': false,
      };
    } else {
      return {
        'greeting': 'Good Evening',
        'image': 'assets/images/night.png',
        'isEvening': true,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final greetingData = _getGreetingData();

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final firstName = authProvider.fullName?.split(' ').first ?? 'Pharmacist';
        final email = authProvider.userData?['email'] ?? '';

        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Avatar with initials (left side)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.buttonPrimary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      firstName.isNotEmpty ? firstName[0].toUpperCase() : 'P',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // User info (stacked vertically in middle)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Hi, $firstName',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Time-based greeting image (right side)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    greetingData['image'] as String,
                    width: 75,
                    height: 75,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      final isEvening = greetingData['isEvening'] as bool;
                      return Container(
                        width: 75,
                        height: 75,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isEvening
                              ? const Color(0xFF2C3E50)
                              : const Color(0xFFFDB813),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 12,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            isEvening ? Icons.nights_stay : Icons.wb_sunny,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
