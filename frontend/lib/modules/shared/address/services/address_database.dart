import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/address_models.dart';

/// In-memory database for Philippine address data
/// Works on both mobile and web without complex setup
class AddressDatabase {
  static List<Region>? _regions;
  static List<Province>? _provinces;
  static List<City>? _cities;
  static List<Barangay>? _barangays;
  static bool _isInitialized = false;

  /// Initialize the database by loading JSON into memory
  static Future<void> initialize() async {
    if (_isInitialized) return;

    print('[AddressDatabase] Loading data from bundled JSON...');
    
    try {
      // Load the bundled JSON
      final jsonString = await rootBundle.loadString('assets/data/ph_address_data.json');
      final data = json.decode(jsonString);

      // Parse regions
      _regions = (data['regions'] as List)
          .map((r) => Region(code: r['code'], name: r['name']))
          .toList();
      print('[AddressDatabase] Loaded ${_regions!.length} regions');

      // Parse provinces
      _provinces = (data['provinces'] as List)
          .map((p) => Province(
            code: p['code'], 
            name: p['name'], 
            regionCode: p['region_code']
          ))
          .toList();
      print('[AddressDatabase] Loaded ${_provinces!.length} provinces');

      // Parse cities
      _cities = (data['cities'] as List)
          .map((c) => City(
            code: c['code'], 
            name: c['name'], 
            provinceCode: c['province_code']
          ))
          .toList();
      print('[AddressDatabase] Loaded ${_cities!.length} cities');

      // Parse barangays
      _barangays = (data['barangays'] as List)
          .map((b) => Barangay(
            code: b['code'], 
            name: b['name'], 
            cityCode: b['city_code']
          ))
          .toList();
      print('[AddressDatabase] Loaded ${_barangays!.length} barangays');

      _isInitialized = true;
      print('[AddressDatabase] Initialization complete - All data in memory');
    } catch (e) {
      print('[AddressDatabase] Error loading data: $e');
      rethrow;
    }
  }

  // ==================== PUBLIC API ====================

  /// Get all regions
  static Future<List<Region>> getRegions() async {
    await initialize();
    return _regions!;
  }

  /// Get provinces by region code
  static Future<List<Province>> getProvinces(String regionCode) async {
    await initialize();
    return _provinces!.where((p) => p.regionCode == regionCode).toList();
  }

  /// Get all provinces (when no region filter)
  static Future<List<Province>> getAllProvinces() async {
    await initialize();
    return _provinces!;
  }

  /// Get cities by province code
  static Future<List<City>> getCities(String provinceCode) async {
    await initialize();
    return _cities!.where((c) => c.provinceCode == provinceCode).toList();
  }

  /// Get barangays by city code
  static Future<List<Barangay>> getBarangays(String cityCode) async {
    await initialize();
    return _barangays!.where((b) => b.cityCode == cityCode).toList();
  }

  /// Search all address levels
  static Future<Map<String, List<dynamic>>> search(String query) async {
    await initialize();
    final lowerQuery = query.toLowerCase();

    return {
      'regions': _regions!
          .where((r) => r.name.toLowerCase().contains(lowerQuery))
          .toList(),
      'provinces': _provinces!
          .where((p) => p.name.toLowerCase().contains(lowerQuery))
          .toList(),
      'cities': _cities!
          .where((c) => c.name.toLowerCase().contains(lowerQuery))
          .toList(),
      'barangays': _barangays!
          .where((b) => b.name.toLowerCase().contains(lowerQuery))
          .toList(),
    };
  }

  /// Close the database (no-op for in-memory)
  static Future<void> close() async {
    // No cleanup needed for in-memory storage
  }
}
