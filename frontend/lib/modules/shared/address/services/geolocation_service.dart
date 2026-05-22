import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/address_service.dart';
import '../models/address_models.dart';
import '../../../../core/services/session_manager.dart';

class GeolocationService {
  final AddressService _addressService = AddressService();

  // Check and request location permissions
  Future<bool> _handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check permission status
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Get current position
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await _handlePermission();
    if (!hasPermission) {
      print('[GeolocationService] Permission denied or location services disabled');
      return null;
    }

    try {
      print('[GeolocationService] Getting current position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print('[GeolocationService] Got position: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('[GeolocationService] Error getting position: $e');
      return null;
    }
  }

  // Get address from coordinates
  Future<Map<String, String>?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) return null;

      final placemark = placemarks.first;
      return {
        'street': placemark.street ?? '',
        'subLocality': placemark.subLocality ?? '',
        'locality': placemark.locality ?? '',
        'subAdministrativeArea': placemark.subAdministrativeArea ?? '',
        'administrativeArea': placemark.administrativeArea ?? '',
        'country': placemark.country ?? '',
        'postalCode': placemark.postalCode ?? '',
      };
    } catch (e) {
      return null;
    }
  }

  // Detect current location and match with PSGC data
  Future<DetectedLocation?> detectCurrentLocation() async {
    final position = await getCurrentPosition();
    if (position == null) return null;

    final addressData = await getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (addressData == null) return null;

    // Try to match the detected location with PSGC data
    final cityName = addressData['locality']?.toLowerCase() ?? '';
    final provinceName = addressData['subAdministrativeArea']?.toLowerCase() ?? '';

    // Search through cached cities
    final cities = await _addressService.fetchCities();
    City? matchedCity;
    for (final city in cities) {
      if (city.name.toLowerCase().contains(cityName) ||
          cityName.contains(city.name.toLowerCase())) {
        matchedCity = city;
        break;
      }
    }

    if (matchedCity == null) return null;

    // Get province
    final provinces = await _addressService.fetchProvinces();
    Province? matchedProvince = provinces.firstWhere(
      (p) => p.code == matchedCity?.provinceCode,
    );

    // Get region
    final regions = await _addressService.fetchRegions();
    Region? matchedRegion = regions.firstWhere(
      (r) => r.code == matchedProvince?.regionCode,
    );

    // Get barangays for the matched city
    final barangays = await _addressService.fetchBarangays(cityCode: matchedCity?.code);

    return DetectedLocation(
      region: matchedRegion,
      province: matchedProvince,
      city: matchedCity,
      barangays: barangays,
      rawAddress: addressData,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  // Search for a specific barangay by name in the current city
  Future<Barangay?> findBarangayByName(String cityCode, String barangayName) async {
    final barangays = await _addressService.fetchBarangays(cityCode: cityCode);
    try {
      return barangays.firstWhere(
        (b) => b.name.toLowerCase().contains(barangayName.toLowerCase()) ||
               barangayName.toLowerCase().contains(b.name.toLowerCase()),
      );
    } catch (e) {
      return null;
    }
  }
}

class DetectedLocation {
  final Region? region;
  final Province? province;
  final City? city;
  final List<Barangay> barangays;
  final Map<String, String>? rawAddress;
  final double latitude;
  final double longitude;

  DetectedLocation({
    this.region,
    this.province,
    this.city,
    required this.barangays,
    this.rawAddress,
    required this.latitude,
    required this.longitude,
  });
}
