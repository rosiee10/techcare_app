import 'package:flutter/material.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/responsive.dart';

/// Reusable success dialog widget
class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onConfirm;
  final String confirmText;

  const SuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.onConfirm,
    this.confirmText = 'OK',
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = isMobile ? 24.0 : 32.0;
    final titleFontSize = isMobile ? 20.0 : 22.0;
    final messageFontSize = isMobile ? 14.0 : 15.0;
    final iconSize = isMobile ? 56.0 : 64.0;
    final buttonHeight = isMobile ? 45.0 : 50.0;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 24,
      ),
      child: Container(
        width: isMobile ? screenWidth * 0.9 : 400,
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: iconSize,
                color: Colors.green[600],
              ),
            ),

            SizedBox(height: isMobile ? 20 : 24),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: isMobile ? 10 : 12),

            // Message
            Text(
              message,
              style: TextStyle(
                fontSize: messageFontSize,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: isMobile ? 28 : 32),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: buttonHeight,
              child: ElevatedButton(
                onPressed: () {
                  onConfirm?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  confirmText,
                  style: TextStyle(
                    fontSize: isMobile ? 15 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
