import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/api_config.dart';

/// Inventory Cart Service
/// Manages medicines that have been moved from inventory to carts
/// Uses local storage to persist cart items and syncs with backend
class InventoryCartService {
  static final InventoryCartService _instance = InventoryCartService._internal();
  factory InventoryCartService() => _instance;
  InventoryCartService._internal();

  static const String _cartKey = 'inventory_cart_items';
  
  // API Configuration - Use the same base URL as other pharmacy services
  static String get _baseUrl => ApiConfig.pharmacyBase;

  // Get auth headers with token
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  List<Map<String, dynamic>> _cartItems = [];
  bool _initialized = false;

  /// Initialize and load cart from storage
  Future<void> init() async {
    if (_initialized) return;
    await _loadCart();
    _initialized = true;
  }

  /// Get all items in the cart
  List<Map<String, dynamic>> getCartItems() {
    return List.from(_cartItems);
  }

  /// Check if a medicine is in the cart
  bool isInCart(int medicineId) {
    return _cartItems.any((item) => item['medicine_id'] == medicineId);
  }

  /// Add medicine to cart - calls backend API to transfer inventory
  Future<Map<String, dynamic>> addToCart(Map<String, dynamic> medicine, {int quantity = 1}) async {
    final medicineId = medicine['medicine_id'] ?? medicine['id'];
    
    try {
      // First, call backend API to transfer inventory to cart
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/transfer-to-cart/'),
        headers: headers,
        body: jsonEncode({
          'medicine_id': medicineId,
          'quantity': quantity,
          'batch_id': medicine['batch_id'], // Optional specific batch
        }),
      );
      
      final responseData = jsonDecode(response.body);
      
      // Debug logging
      print('=== Transfer to Cart Debug ===');
      print('Status Code: ${response.statusCode}');
      print('Response: $responseData');
      print('Medicine ID sent: $medicineId');
      print('================================');
      
      if (response.statusCode == 201 && responseData['success'] == true) {
        // Backend transfer successful, update local cart
        final existingIndex = _cartItems.indexWhere((item) => item['medicine_id'] == medicineId);
        
        if (existingIndex >= 0) {
          // Update quantity if already in cart
          _cartItems[existingIndex]['quantity'] = 
            (_cartItems[existingIndex]['quantity'] ?? 0) + quantity;
          _cartItems[existingIndex]['added_at'] = DateTime.now().toIso8601String();
        } else {
          // Add new item
          _cartItems.add({
            'medicine_id': medicineId,
            'medicine_name': medicine['medicine_name'] ?? medicine['generic_name'] ?? 'Unknown',
            'category': medicine['category'] ?? 'Uncategorized',
            'unit': medicine['unit'] ?? medicine['unit_of_measure'] ?? 'N/A',
            'quantity': quantity,
            'added_at': DateTime.now().toIso8601String(),
            'status': 'In Cart',
            'transaction_id': responseData['batch_id'], // Store batch reference
          });
        }
        
        await _saveCart();
        return {'success': true, 'message': 'Added to cart', 'data': responseData};
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Failed to transfer to cart'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Dispense from cart to patient - calls backend API
  Future<Map<String, dynamic>> dispenseFromCart(int patientId, List<Map<String, dynamic>> medicines) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/dispense-from-cart/'),
        headers: headers,
        body: jsonEncode({
          'patient_id': patientId,
          'medicines': medicines,
        }),
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 201 && responseData['success'] == true) {
        // Dispensing successful, remove items from local cart
        for (final med in medicines) {
          await removeFromCart(med['medicine_id']);
        }
        return {'success': true, 'message': 'Dispensed successfully', 'data': responseData};
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Failed to dispense'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> removeFromCart(int medicineId, {String? reason}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/medicines/$medicineId/remove-medicine/'),
        headers: headers,
        body: jsonEncode({
          'reason': reason ?? 'Removed from cart',
          'location_id': 2, // Cart Location
        }),
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        _cartItems.removeWhere((item) => item['medicine_id'] == medicineId);
        await _saveCart();
        return {'success': true, 'message': 'Removed from cart and database'};
      } else {
        return {'success': false, 'message': responseData['error'] ?? 'Failed to remove from database'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Update cart item quantity
  Future<void> updateQuantity(int medicineId, int newQuantity) async {
    final index = _cartItems.indexWhere((item) => item['medicine_id'] == medicineId);
    if (index >= 0) {
      if (newQuantity <= 0) {
        await removeFromCart(medicineId);
      } else {
        _cartItems[index]['quantity'] = newQuantity;
        await _saveCart();
      }
    }
  }

  /// Clear all items from cart
  Future<void> clearCart() async {
    _cartItems.clear();
    await _saveCart();
  }

  /// Get cart count
  int getCartCount() => _cartItems.length;

  /// Get total items count (sum of quantities)
  int getTotalItemCount() {
    return _cartItems.fold(0, (sum, item) => sum + (item['quantity'] ?? 0) as int);
  }

  /// Sync cart items with backend data (replace local with backend)
  Future<void> syncWithBackend(List<Map<String, dynamic>> backendItems) async {
    _cartItems = List.from(backendItems);
    await _saveCart();
  }

  /// Save cart to local storage
  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = jsonEncode(_cartItems);
      await prefs.setString(_cartKey, cartJson);
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  /// Load cart from local storage
  Future<void> _loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartKey);
      if (cartJson != null) {
        final List<dynamic> decoded = jsonDecode(cartJson);
        _cartItems = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (e) {
      print('Error loading cart: $e');
      _cartItems = [];
    }
  }
}
