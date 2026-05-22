import 'package:flutter/material.dart';
import '../services/geolocation_service.dart';
import '../services/address_service.dart';
import '../models/address_models.dart';

class DetectLocationButton extends StatefulWidget {
  final Function(
    Region? region,
    Province? province,
    City? city,
    List<Barangay> barangays,
  ) onLocationDetected;
  final ButtonStyle? style;

  const DetectLocationButton({
    super.key,
    required this.onLocationDetected,
    this.style,
  });

  @override
  State<DetectLocationButton> createState() => _DetectLocationButtonState();
}

class _DetectLocationButtonState extends State<DetectLocationButton> {
  final GeolocationService _geolocationService = GeolocationService();
  final AddressService _addressService = AddressService();
  bool _isLoading = false;

  Future<void> _detectLocation() async {
    setState(() => _isLoading = true);
    
    try {
      final detectedLocation = await _geolocationService.detectCurrentLocation();
      
      if (detectedLocation != null && mounted) {
        widget.onLocationDetected(
          detectedLocation.region,
          detectedLocation.province,
          detectedLocation.city,
          detectedLocation.barangays,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location detected successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not detect location. Please check your permissions.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      String errorMsg = e.toString().toLowerCase();
      String userMessage;
      
      if (errorMsg.contains('airplane') || errorMsg.contains('location unavailable')) {
        userMessage = 'Location unavailable. Please turn off Airplane Mode or enable location services.';
      } else if (errorMsg.contains('permission') || errorMsg.contains('denied')) {
        userMessage = 'Location permission denied. Please allow location access in browser settings.';
      } else if (errorMsg.contains('timeout')) {
        userMessage = 'Location detection timed out. Please try again or enter address manually.';
      } else {
        userMessage = 'Could not detect location. Please check your internet connection or enter address manually.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _detectLocation,
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.my_location, size: 18),
      label: Text(_isLoading ? 'Detecting...' : 'Detect My Location'),
      style: widget.style,
    );
  }
}

// Preload addresses button for offline caching
class PreloadAddressesButton extends StatefulWidget {
  final VoidCallback? onComplete;
  final ButtonStyle? style;

  const PreloadAddressesButton({
    super.key,
    this.onComplete,
    this.style,
  });

  @override
  State<PreloadAddressesButton> createState() => _PreloadAddressesButtonState();
}

class _PreloadAddressesButtonState extends State<PreloadAddressesButton> {
  final AddressService _addressService = AddressService();
  bool _isLoading = false;
  double _progress = 0;

  Future<void> _preloadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Preload regions
      setState(() => _progress = 0.1);
      await _addressService.fetchRegions(forceRefresh: true);
      
      // Preload provinces
      setState(() => _progress = 0.3);
      await _addressService.fetchProvinces(forceRefresh: true);
      
      // Preload cities
      setState(() => _progress = 0.6);
      await _addressService.fetchCities(forceRefresh: true);
      
      // Note: Not preloading barangays (42k+ records) - loaded on demand
      setState(() => _progress = 1.0);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address data cached for offline use!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error caching data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _progress = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _preloadData,
      icon: _isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: _progress > 0 ? _progress : null,
              ),
            )
          : const Icon(Icons.download, size: 18),
      label: Text(_isLoading ? 'Downloading...' : 'Cache for Offline'),
      style: widget.style,
    );
  }
}
