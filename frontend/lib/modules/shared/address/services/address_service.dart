import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/address_models.dart';
import 'address_database.dart';
import 'package:frontend/core/config/api_config.dart';
import 'package:frontend/core/services/session_manager.dart';

class AddressService {
  static String get baseUrl => '${ApiConfig.baseUrl}/api';
  
  // Singleton pattern
  static final AddressService _instance = AddressService._internal();
  factory AddressService() => _instance;
  AddressService._internal();

  /// Initialize the address service and local database
  Future<void> initialize() async {
    print('[AddressService] Initializing...');
    await AddressDatabase.initialize();
    print('[AddressService] Initialized with local database');
  }

  /// Check if local database has data
  Future<bool> hasLocalData() async {
    try {
      final regions = await AddressDatabase.getRegions();
      return regions.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Fetch regions - uses local database (fully offline)
  Future<List<Region>> fetchRegions({bool forceRefresh = false}) async {
    // Always use local database first (fully offline)
    try {
      final regions = await AddressDatabase.getRegions();
      if (regions.isNotEmpty) {
        print('[AddressService] Loaded ${regions.length} regions from local database');
        return regions;
      }
    } catch (e) {
      print('[AddressService] Local database error: $e');
    }
    
    // Fallback to API if database is empty and online
    try {
      final url = Uri.parse('$baseUrl/locations/regions/');
      print('[AddressService] Fetching regions from API: $url');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);
        final List<dynamic> data = decodedData is List 
            ? decodedData 
            : (decodedData['results'] ?? []);
        
        print('[AddressService] Fetched ${data.length} regions from API');
        return data.map((item) => Region.fromJson(item)).toList();
      }
    } catch (e) {
      print('[AddressService] API error: $e');
    }
    
    return [];
  }

  /// Fetch provinces by region - uses local database (fully offline)
  Future<List<Province>> fetchProvinces({String? regionCode, bool forceRefresh = false}) async {
    // Use local database (fully offline)
    try {
      if (regionCode != null) {
        final provinces = await AddressDatabase.getProvinces(regionCode);
        print('[AddressService] Loaded ${provinces.length} provinces for region $regionCode from local database');
        return provinces;
      } else {
        // Fetch all provinces when no region specified
        final provinces = await AddressDatabase.getAllProvinces();
        print('[AddressService] Loaded ${provinces.length} all provinces from local database');
        return provinces;
      }
    } catch (e) {
      print('[AddressService] Local database error: $e');
    }
    
    // Fallback to API
    try {
      String url = '$baseUrl/locations/provinces/';
      if (regionCode != null) {
        url += '?region=$regionCode';
      }
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);
        final List<dynamic> data = decodedData is List 
            ? decodedData 
            : (decodedData['results'] ?? []);
        
        return data.map((item) => Province.fromJson(item)).toList();
      }
    } catch (e) {
      print('[AddressService] API error: $e');
    }
    
    return [];
  }

  /// Fetch cities by province - uses local database (fully offline)
  Future<List<City>> fetchCities({String? provinceCode, bool forceRefresh = false}) async {
    // Use local database (fully offline)
    if (provinceCode != null) {
      try {
        final cities = await AddressDatabase.getCities(provinceCode);
        print('[AddressService] Loaded ${cities.length} cities from local database');
        return cities;
      } catch (e) {
        print('[AddressService] Local database error: $e');
      }
    }
    
    // Fallback to API
    try {
      String url = '$baseUrl/locations/cities/';
      if (provinceCode != null) {
        url += '?province=$provinceCode';
      }
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);
        final List<dynamic> data = decodedData is List 
            ? decodedData 
            : (decodedData['results'] ?? []);
        
        return data.map((item) => City.fromJson(item)).toList();
      }
    } catch (e) {
      print('[AddressService] API error: $e');
    }
    
    return [];
  }

  /// Fetch barangays by city - uses local database (fully offline)
  Future<List<Barangay>> fetchBarangays({String? cityCode, String? provinceCode, bool forceRefresh = false}) async {
    // Use local database (fully offline)
    if (cityCode != null) {
      try {
        final barangays = await AddressDatabase.getBarangays(cityCode);
        print('[AddressService] Loaded ${barangays.length} barangays from local database');
        return barangays;
      } catch (e) {
        print('[AddressService] Local database error: $e');
      }
    }
    
    // Fallback to API
    try {
      String url = '$baseUrl/locations/barangays/';
      if (cityCode != null) {
        url += '?city=$cityCode';
      }
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);
        final List<dynamic> data = decodedData is List 
            ? decodedData 
            : (decodedData['results'] ?? []);
        
        print('[AddressService] Fetched ${data.length} barangays from API');
        return data.map((item) => Barangay.fromJson(item)).toList();
      }
    } catch (e) {
      print('[AddressService] Network error: $e');
    }
    
    return [];
  }

  /// Search addresses - uses local database (fully offline)
  Future<Map<String, List<dynamic>>> searchAddresses(String query) async {
    if (query.length < 2) return {};

    // Use local database first
    try {
      final results = await AddressDatabase.search(query);
      print('[AddressService] Search results from local database');
      return results;
    } catch (e) {
      print('[AddressService] Local search error: $e');
    }
    
    // Fallback to API
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/locations/search/?q=$query'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'regions': data['regions'] ?? [],
          'provinces': data['provinces'] ?? [],
          'cities': data['cities'] ?? [],
          'barangays': data['barangays'] ?? [],
        };
      }
    } catch (e) {
      print('[AddressService] API search error: $e');
    }
    
    return {};
  }

  /// Preload all address data - database already has bundled data
  Future<void> preloadAllData({List<String>? provinceCodes}) async {
    print('[AddressService] Local database already contains all address data');
    print('[AddressService] System is fully offline-capable');
    
    // Verify data is loaded
    final regions = await AddressDatabase.getRegions();
    print('[AddressService] Verified: ${regions.length} regions in local database');
  }

  /// Clear cache - also resets database
  Future<void> clearCache() async {
    // Clear SharedPreferences cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    // Note: SQLite database persists until app reinstall
    print('[AddressService] Cache cleared. Database persists until app reinstall.');
  }
}
