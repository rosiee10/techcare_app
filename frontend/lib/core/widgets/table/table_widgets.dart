import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Status badge for tables with enhanced styling
class StatusBadge extends StatelessWidget {
  final String status;
  final Color? backgroundColor;
  final Color? textColor;
  final bool showDot;

  const StatusBadge({
    super.key,
    required this.status,
    this.backgroundColor,
    this.textColor,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getStatusColors(status);
    final bgColor = backgroundColor ?? colors['bg']!;
    final textCol = textColor ?? colors['text']!;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: textCol,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textCol,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Color> _getStatusColors(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'outpatient':
        return {
          'bg': const Color(0xFFE8F5E9),
          'text': const Color(0xFF2E7D32),
        };
      case 'inactive':
      case 'inpatient':
        return {
          'bg': const Color(0xFFFFF3E0),
          'text': const Color(0xFFF57C00),
        };
      case 'emergency':
        return {
          'bg': const Color(0xFFFFEBEE),
          'text': const Color(0xFFC62828),
        };
      case 'discharged':
        return {
          'bg': const Color(0xFFE0E0E0),
          'text': const Color(0xFF424242),
        };
      case 'admin':
        return {
          'bg': const Color(0xFFE3F2FD),
          'text': const Color(0xFF1565C0),
        };
      case 'doctor':
        return {
          'bg': const Color(0xFFF3E5F5),
          'text': const Color(0xFF6A1B9A),
        };
      case 'nurse':
        return {
          'bg': const Color(0xFFE0F2F1),
          'text': const Color(0xFF00695C),
        };
      case 'clerk':
        return {
          'bg': const Color(0xFFFCE4EC),
          'text': const Color(0xFFC2185B),
        };
      default:
        return {
          'bg': const Color(0xFFF5F5F5),
          'text': const Color(0xFF616161),
        };
    }
  }
}

/// Avatar circle for table rows
class TableAvatar extends StatelessWidget {
  final String initials;
  final String? photoUrl;
  final String? userName;
  final Color? backgroundColor;
  final double size;

  const TableAvatar({
    super.key,
    required this.initials,
    this.photoUrl,
    this.userName,
    this.backgroundColor,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    
    // If no photo URL, show initials
    if (photoUrl == null || photoUrl!.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.buttonPrimary,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    // If photo URL exists, show image with loading indicator
    Widget avatarWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.buttonPrimary,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Image.network(
          photoUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return Center(
              child: SizedBox(
                width: size * 0.4,
                height: size * 0.4,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            );
          },
        ),
      ),
    );

    // Make photo clickable if photoUrl is available
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return GestureDetector(
        onTap: () => _showPhotoViewer(context),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: avatarWidget,
        ),
      );
    }

    return avatarWidget;
  }

  void _showPhotoViewer(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      photoUrl!,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }
                        return Container(
                          color: Colors.grey[800],
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 48,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              if (userName != null)
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        userName!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Action button for table rows
class TableActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  const TableActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final buttonColor = color ?? theme.buttonPrimary;
    
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: buttonColor),
      label: Text(
        label,
        style: TextStyle(color: buttonColor),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}

/// Icon button for table actions
class TableIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final String? tooltip;

  const TableIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final button = IconButton(
      icon: Icon(icon, size: 20, color: color ?? theme.buttonPrimary),
      onPressed: onPressed,
      splashRadius: 20,
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}

/// Text cell with primary/secondary text
class TableTextCell extends StatelessWidget {
  final String primaryText;
  final String? secondaryText;
  final TextStyle? primaryStyle;
  final TextStyle? secondaryStyle;

  const TableTextCell({
    super.key,
    required this.primaryText,
    this.secondaryText,
    this.primaryStyle,
    this.secondaryStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          primaryText,
          style: primaryStyle ?? TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: theme.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        if (secondaryText != null) ...[
          const SizedBox(height: 2),
          Text(
            secondaryText!,
            style: secondaryStyle ?? TextStyle(
              fontSize: 11,
              color: theme.textMuted,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

/// ID badge for table rows
class TableIdBadge extends StatelessWidget {
  final String id;
  final String? subtitle;

  const TableIdBadge({
    super.key,
    required this.id,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          id,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.buttonPrimary,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 11,
              color: theme.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}
