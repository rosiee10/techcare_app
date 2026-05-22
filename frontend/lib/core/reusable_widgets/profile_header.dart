import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Profile header with avatar, name, and email
/// 
/// Features:
/// - Circular avatar with optional image or placeholder
/// - Name and email display
/// - Configurable layout (row or column)
class ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String? avatarUrl;
  final VoidCallback? onTap;
  final bool showAvatar;
  final double avatarSize;
  final EdgeInsets padding;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.onTap,
    this.showAvatar = true,
    this.avatarSize = 48,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    Widget content = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Text info (right side on mobile as per wireframe)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hi, $name',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 2),
              Text(
                email,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textSecondary,
                ),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (showAvatar) ...[
          const SizedBox(width: 12),
          _Avatar(
            imageUrl: avatarUrl,
            size: avatarSize,
            name: name,
          ),
        ],
      ],
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: padding,
          child: content,
        ),
      );
    } else {
      content = Padding(
        padding: padding,
        child: content,
      );
    }

    return content;
  }
}

/// Reusable avatar widget with fallback to initials
class _Avatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final String name;

  const _Avatar({
    this.imageUrl,
    required this.size,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.buttonPrimary, theme.buttonPrimary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.buttonPrimary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: imageUrl != null
          ? ClipOval(
              child: Image.network(
                imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallback(theme),
              ),
            )
          : _buildFallback(theme),
    );
  }

  Widget _buildFallback(AppThemeData theme) {
    final initials = name.isNotEmpty
        ? name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : '?';

    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
