import 'package:flutter/material.dart';

/// A reusable styled page title widget for consistent typography across login and form pages.
/// 
/// Features:
/// - Customizable text content
/// - Configurable color (defaults to primary blue)
/// - Optional subtitle support
/// - Built-in shadow and styling
class PageTitle extends StatelessWidget {
  /// The main title text to display
  final String title;
  
  /// Optional subtitle text displayed below the title
  final String? subtitle;
  
  /// The color of the title text
  final Color titleColor;
  
  /// The color of the subtitle text
  final Color? subtitleColor;
  
  /// Font size of the title
  final double titleFontSize;
  
  /// Font size of the subtitle
  final double subtitleFontSize;
  
  /// Spacing between title and subtitle
  final double spacing;
  
  /// Whether to add a subtle shadow to the title
  final bool addShadow;
  
  /// Text alignment
  final TextAlign textAlign;

  const PageTitle({
    Key? key,
    required this.title,
    this.subtitle,
    this.titleColor = const Color(0xFF1565C0),
    this.subtitleColor,
    this.titleFontSize = 28,
    this.subtitleFontSize = 13,
    this.spacing = 8,
    this.addShadow = true,
    this.textAlign = TextAlign.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w700,
            color: titleColor,
            letterSpacing: 0.5,
            shadows: addShadow
                ? [
                    Shadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          textAlign: textAlign,
        ),
        if (subtitle != null) ...[
          SizedBox(height: spacing),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: subtitleFontSize,
              color: subtitleColor ?? Colors.grey[600],
              height: 1.4,
            ),
            textAlign: textAlign,
          ),
        ],
      ],
    );
  }
}
