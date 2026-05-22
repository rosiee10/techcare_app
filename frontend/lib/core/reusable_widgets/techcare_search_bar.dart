import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// TechCare branded search bar
/// 
/// Features:
/// - Rounded container with icon
/// - Customizable hint text
/// - Callback on search
/// - Can be used as read-only (tap to navigate) or editable
class TechCareSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool readOnly;
  final FocusNode? focusNode;
  final EdgeInsets margin;

  const TechCareSearchBar({
    super.key,
    this.controller,
    this.hintText = 'Search...',
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.readOnly = false,
    this.focusNode,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        focusNode: focusNode,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: theme.textSecondary.withOpacity(0.7),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: theme.buttonPrimary,
            size: 22,
          ),
          suffixIcon: onChanged != null
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: theme.buttonPrimary,
                    size: 18,
                  ),
                  onPressed: () {
                    controller?.clear();
                    onChanged?.call('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

/// Read-only search bar that opens search page on tap
class TechCareSearchBarButton extends StatelessWidget {
  final String hintText;
  final VoidCallback onTap;
  final EdgeInsets margin;

  const TechCareSearchBarButton({
    super.key,
    this.hintText = 'Search patients, services...',
    required this.onTap,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Container(
      margin: margin,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.search,
                color: theme.buttonPrimary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hintText,
                  style: TextStyle(
                    color: theme.textSecondary.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: theme.buttonPrimary.withOpacity(0.6),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
