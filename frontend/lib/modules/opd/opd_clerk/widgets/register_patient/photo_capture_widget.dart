import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show MethodChannel;
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:io' show Platform;
import '../../../../../core/theme/app_theme.dart';
import '../../services/patient_service.dart';
import '../../../../shared/settings_profile/widgets/web_camera_widget.dart';
import '../../../../shared/settings_profile/widgets/camera_capture_widget.dart';

class PhotoCaptureWidget extends StatefulWidget {
  final String? photoUrl;
  final Function(String?) onPhotoUrlChanged;
  final VoidCallback onClearPhoto;

  const PhotoCaptureWidget({
    super.key,
    this.photoUrl,
    required this.onPhotoUrlChanged,
    required this.onClearPhoto,
  });

  @override
  State<PhotoCaptureWidget> createState() => _PhotoCaptureWidgetState();
}

class _PhotoCaptureWidgetState extends State<PhotoCaptureWidget> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Column(
      children: [
        Text(
          'Profile Photo',
          style: TextStyle(
            fontSize: 12,
            color: theme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        _buildPhotoContainer(theme),
        const SizedBox(height: 12),
        SizedBox(
          width: 180,
          child: OutlinedButton(
            onPressed: _isUploading ? null : () => _openCamera(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.textPrimary,
              side: BorderSide(color: theme.cardBorder),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isUploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Open Cam'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 180,
          child: ElevatedButton(
            onPressed: _isUploading ? null : () => _openFilePicker(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.buttonPrimary,
              foregroundColor: theme.buttonPrimaryText,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isUploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Open File'),
          ),
        ),
        if (widget.photoUrl != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: 180,
            child: TextButton.icon(
              onPressed: widget.onClearPhoto,
              icon: Icon(Icons.delete_outline, color: theme.error, size: 18),
              label: Text(
                'Remove Photo',
                style: TextStyle(color: theme.error),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPhotoContainer(AppThemeData theme) {
    return Container(
      width: 180,
      height: 150,
      decoration: BoxDecoration(
        color: theme.pageBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.buttonPrimary.withOpacity(0.3),
          style: BorderStyle.solid,
        ),
      ),
      child: widget.photoUrl != null && widget.photoUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.photoUrl!,
                width: 180,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.person, size: 60, color: Colors.grey),
                  );
                },
              ),
            )
          : Center(
              child: Text(
                'PHOTO',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textSecondary,
                ),
              ),
            ),
    );
  }

  Future<void> _openCamera(BuildContext context) async {
    try {
      // Use native camera on mobile (Android/iOS), web camera on web
      bool isMobileApp = false;
      if (!kIsWeb) {
        try {
          isMobileApp = Platform.isAndroid || Platform.isIOS;
        } catch (e) {
          isMobileApp = false;
        }
      }
      
      final XFile? photo = await Navigator.push<XFile>(
        context,
        MaterialPageRoute(
          builder: (context) => isMobileApp
              ? const CameraCaptureWidget()
              : const WebCameraWidget(),
          fullscreenDialog: true,
        ),
      );

      if (photo != null) {
        await _uploadPhoto(photo, context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening camera: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openFilePicker(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        await _uploadPhoto(photo, context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadPhoto(XFile photo, BuildContext context) async {
    try {
      // Read photo bytes
      final bytes = await photo.readAsBytes();

      // Check file size (max 5MB)
      if (bytes.length > 5 * 1024 * 1024) {
        if (context.mounted) {
          _showErrorDialog(context, 'Image size must be less than 5MB');
        }
        return;
      }

      // Show progress dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Uploading photo...',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.of(context).textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }

      // Generate filename if not provided
      final filename = photo.name.isNotEmpty 
          ? photo.name 
          : 'patient_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload photo using PatientService
      final patientService = PatientService();
      final result = await patientService.uploadPatientPhoto(
        Uint8List.fromList(bytes),
        filename,
      );

      // Close progress dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (result['success']) {
        // Get the photo URL from the response
        final photoUrl = result['photo_url'];
        if (photoUrl != null) {
          // Convert relative URL to full URL
          String fullPhotoUrl = photoUrl;
          if (photoUrl.startsWith('/media/')) {
            fullPhotoUrl = 'http://127.0.0.1:8000$photoUrl';
          }
          
          widget.onPhotoUrlChanged(fullPhotoUrl);
          
          if (context.mounted) {
            _showSuccessDialog(context, 'Photo uploaded successfully');
          }
        }
      } else {
        if (context.mounted) {
          _showErrorDialog(context, result['error'] ?? 'Failed to upload photo');
        }
      }
    } catch (e) {
      // Close progress dialog if still open
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      if (context.mounted) {
        _showErrorDialog(context, 'Error uploading photo: ${e.toString()}');
      }
    }
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              const Text('Success'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 8),
              const Text('Error'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
