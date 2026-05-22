import 'package:flutter/material.dart';
import '../utils/colors.dart';

/// Gradient button matching the login page design
/// Features: Blue gradient, white text, 48px height, 10px border radius
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double height;
  final List<Color> gradientColors;
  final double borderRadius;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 48,
    this.gradientColors = const [Color(0xFF1E88E5), Color(0xFF1565C0)],
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null && !isLoading;

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          gradient: isEnabled
              ? LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : LinearGradient(
                  colors: [Colors.grey[300]!, Colors.grey[400]!],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double height;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 48,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF03A9F4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: AppColors.grey300,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class OutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? borderColor;
  final Color? textColor;
  final double? width;
  final double height;
  final IconData? icon;

  const OutlineButton({
    super.key,
    required this.text,
    this.onPressed,
    this.borderColor,
    this.textColor,
    this.width,
    this.height = 48,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor ?? AppColors.primaryBlue,
          side: BorderSide(
            color: borderColor ?? AppColors.primaryBlue,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TextButtonCustom extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? textColor;
  final IconData? icon;

  const TextButtonCustom({
    super.key,
    required this.text,
    this.onPressed,
    this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: textColor ?? AppColors.primaryBlue),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor ?? AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class IconButtonCustom extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? iconColor;
  final Color? backgroundColor;
  final double size;

  const IconButtonCustom({
    super.key,
    required this.icon,
    this.onPressed,
    this.iconColor,
    this.backgroundColor,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.grey100,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: iconColor ?? AppColors.textPrimary,
        iconSize: size * 0.5,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

/// Action Icon Button with Tooltip
class ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? iconColor;
  final double size;

  const ActionIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.iconColor,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: size,
            color: iconColor ?? const Color(0xFF666666),
          ),
        ),
      ),
    );
  }
}

/// Edit Action Button
class EditActionButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const EditActionButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ActionIconButton(
      icon: Icons.edit_outlined,
      tooltip: 'Edit',
      onPressed: onPressed,
      iconColor: const Color(0xFFFFA726),
    );
  }
}

/// View Action Button
class ViewActionButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const ViewActionButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ActionIconButton(
      icon: Icons.visibility_outlined,
      tooltip: 'View',
      onPressed: onPressed,
      iconColor: const Color(0xFF1976D2),
    );
  }
}

/// Delete Action Button
class DeleteActionButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const DeleteActionButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ActionIconButton(
      icon: Icons.delete_outline,
      tooltip: 'Delete',
      onPressed: onPressed,
      iconColor: const Color(0xFFDC3545),
    );
  }
}

/// Deactivate Action Button
class DeactivateActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isActive;

  const DeactivateActionButton({
    super.key,
    this.onPressed,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isActive ? 'Deactivate' : 'Activate',
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFDC3545) : const Color(0xFF4CAF50),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isActive ? 'Deactivate' : 'Activate',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Reset Password Action Button
class ResetPasswordActionButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const ResetPasswordActionButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ActionIconButton(
      icon: Icons.key,
      tooltip: 'Reset Password',
      onPressed: onPressed,
      iconColor: const Color(0xFFFF9800),
    );
  }
}
