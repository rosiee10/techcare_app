import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

/// Enhanced Result Dialog Widget for Success and Error Messages
/// Reusable across the application
class ResultDialog extends StatelessWidget {
  final String title;
  final String message;
  final ResultType type;
  final VoidCallback? onDismiss;
  final String buttonLabel;

  const ResultDialog({
    super.key,
    required this.title,
    required this.message,
    required this.type,
    this.onDismiss,
    this.buttonLabel = 'OK',
  });

  /// Factory constructor for success dialog
  factory ResultDialog.success({
    required String title,
    required String message,
    VoidCallback? onDismiss,
  }) {
    return ResultDialog(
      title: title,
      message: message,
      type: ResultType.success,
      onDismiss: onDismiss,
      buttonLabel: 'OK',
    );
  }

  /// Factory constructor for error dialog
  factory ResultDialog.error({
    required String title,
    required String message,
    VoidCallback? onDismiss,
  }) {
    return ResultDialog(
      title: title,
      message: message,
      type: ResultType.error,
      onDismiss: onDismiss,
      buttonLabel: 'OK',
    );
  }

  /// Factory constructor for info dialog
  factory ResultDialog.info({
    required String title,
    required String message,
    VoidCallback? onDismiss,
  }) {
    return ResultDialog(
      title: title,
      message: message,
      type: ResultType.info,
      onDismiss: onDismiss,
      buttonLabel: 'OK',
    );
  }

  /// Factory constructor for warning dialog
  factory ResultDialog.warning({
    required String title,
    required String message,
    VoidCallback? onDismiss,
  }) {
    return ResultDialog(
      title: title,
      message: message,
      type: ResultType.warning,
      onDismiss: onDismiss,
      buttonLabel: 'OK',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    
    // Responsive sizing
    final dialogWidth = isMobile 
        ? screenSize.width * 0.85 
        : 500.0;
    final iconSize = isMobile ? 56.0 : 64.0;
    final iconRadius = isMobile ? 28.0 : 32.0;
    final titleFontSize = isMobile ? 16.0 : 18.0;
    final messageFontSize = isMobile ? 13.0 : 14.0;
    final padding = isMobile ? 20.0 : 24.0;
    final spacingLarge = isMobile ? 16.0 : 20.0;
    final spacingSmall = isMobile ? 8.0 : 12.0;
    final buttonPadding = isMobile ? 10.0 : 12.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetAnimationDuration: const Duration(milliseconds: 200),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: screenSize.height * 0.8,
        ),
        child: Container(
          padding: EdgeInsets.all(padding),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: _getIconBackgroundColor(),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      _getIcon(),
                      color: _getIconColor(),
                      size: iconRadius,
                    ),
                  ),
                ),
                SizedBox(height: spacingLarge),

                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w700,
                    color: theme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: spacingSmall),

                // Message
                Text(
                  message,
                  style: TextStyle(
                    fontSize: messageFontSize,
                    color: theme.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: spacingLarge),

                // Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onDismiss?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getButtonColor(),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: buttonPadding),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      buttonLabel,
                      style: TextStyle(
                        fontSize: messageFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (type) {
      case ResultType.success:
        return Icons.check_circle;
      case ResultType.error:
        return Icons.error;
      case ResultType.warning:
        return Icons.warning;
      case ResultType.info:
        return Icons.info;
    }
  }

  Color _getIconColor() {
    switch (type) {
      case ResultType.success:
        return const Color(0xFF22C55E);
      case ResultType.error:
        return const Color(0xFFEF4444);
      case ResultType.warning:
        return const Color(0xFFF59E0B);
      case ResultType.info:
        return const Color(0xFF2563EB);
    }
  }

  Color _getIconBackgroundColor() {
    switch (type) {
      case ResultType.success:
        return const Color(0xFFDCFCE7);
      case ResultType.error:
        return const Color(0xFFFEE2E2);
      case ResultType.warning:
        return const Color(0xFFFEF3C7);
      case ResultType.info:
        return const Color(0xFFDEF2FF);
    }
  }

  Color _getButtonColor() {
    switch (type) {
      case ResultType.success:
        return const Color(0xFF22C55E);
      case ResultType.error:
        return const Color(0xFFEF4444);
      case ResultType.warning:
        return const Color(0xFFF59E0B);
      case ResultType.info:
        return const Color(0xFF2563EB);
    }
  }
}

/// Enum for result dialog types
enum ResultType {
  success,
  error,
  warning,
  info,
}

/// Helper function to show result dialogs
void showResultDialog(
  BuildContext context, {
  required String title,
  required String message,
  required ResultType type,
  VoidCallback? onDismiss,
}) {
  showDialog(
    context: context,
    builder: (context) => ResultDialog(
      title: title,
      message: message,
      type: type,
      onDismiss: onDismiss,
    ),
  );
}

/// Helper function to show success dialog
void showSuccessDialog(
  BuildContext context, {
  required String title,
  required String message,
  VoidCallback? onDismiss,
}) {
  showDialog(
    context: context,
    builder: (context) => ResultDialog.success(
      title: title,
      message: message,
      onDismiss: onDismiss,
    ),
  );
}

/// Helper function to show error dialog
void showErrorDialog(
  BuildContext context, {
  required String title,
  required String message,
  VoidCallback? onDismiss,
}) {
  showDialog(
    context: context,
    builder: (context) => ResultDialog.error(
      title: title,
      message: message,
      onDismiss: onDismiss,
    ),
  );
}

/// Helper function to show warning dialog
void showWarningDialog(
  BuildContext context, {
  required String title,
  required String message,
  VoidCallback? onDismiss,
}) {
  showDialog(
    context: context,
    builder: (context) => ResultDialog.warning(
      title: title,
      message: message,
      onDismiss: onDismiss,
    ),
  );
}

/// Helper function to show info dialog
void showInfoDialog(
  BuildContext context, {
  required String title,
  required String message,
  VoidCallback? onDismiss,
}) {
  showDialog(
    context: context,
    builder: (context) => ResultDialog.info(
      title: title,
      message: message,
      onDismiss: onDismiss,
    ),
  );
}
