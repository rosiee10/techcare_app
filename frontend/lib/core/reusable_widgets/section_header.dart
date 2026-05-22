import 'package:flutter/material.dart';

/// Reusable section header widget
/// Used for consistent section titles across the application
class SectionHeader extends StatelessWidget {
  final String title;
  final double? fontSize;
  final Color? color;
  final FontWeight? fontWeight;

  const SectionHeader({
    super.key,
    required this.title,
    this.fontSize,
    this.color,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: fontSize ?? 18,
        fontWeight: fontWeight ?? FontWeight.bold,
        color: color ?? Colors.black87,
      ),
    );
  }
}
