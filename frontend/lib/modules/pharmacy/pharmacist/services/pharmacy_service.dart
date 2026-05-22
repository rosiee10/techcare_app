import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/utils/logger.dart';

class PharmacyService {
  static String get baseUrl => ApiConfig.pharmacyBase;

  // Get auth headers with token
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Dashboard Stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      AppLogger.apiRequest('GET', ApiConfig.pharmacyDashboardStats);
      final response = await http.get(
        Uri.parse(ApiConfig.pharmacyDashboardStats),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load dashboard stats: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching dashboard stats: $e');
      rethrow;
    }
  }

  // Medicines
  Future<List<dynamic>> getMedicines() async {
    try {
      AppLogger.apiRequest('GET', ApiConfig.pharmacyMedicines);
      final response = await http.get(
        Uri.parse(ApiConfig.pharmacyMedicines),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        // Handle paginated response
        return body is List ? body : (body['results'] ?? []);
      } else {
        throw Exception('Failed to load medicines: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching medicines: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createMedicine(Map<String, dynamic> data) async {
    try {
      AppLogger.apiRequest('POST', ApiConfig.pharmacyMedicines);
      final response = await http.post(
        Uri.parse(ApiConfig.pharmacyMedicines),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create medicine: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error creating medicine: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> removeMedicine(int medicineId, String reason) async {
    try {
      final url = '${ApiConfig.pharmacyBase}/medicines/$medicineId/remove-medicine/';
      AppLogger.apiRequest('POST', url);
      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(),
        body: jsonEncode({'reason': reason.toUpperCase()}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Failed to remove medicine: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error removing medicine: $e');
      rethrow;
    }
  }

  // Stock Batches
  Future<List<dynamic>> getStockBatches() async {
    try {
      AppLogger.apiRequest('GET', ApiConfig.pharmacyStockBatches);
      final response = await http.get(
        Uri.parse(ApiConfig.pharmacyStockBatches),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body is List ? body : (body['results'] ?? []);
      } else {
        throw Exception('Failed to load stock batches: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching stock batches: $e');
      rethrow;
    }
  }

  // Get batches for a specific medicine
  Future<List<dynamic>> getMedicineBatches(int medicineId) async {
    try {
      final url = '${ApiConfig.pharmacyBase}/medicines/$medicineId/batches/';
      AppLogger.apiRequest('GET', url);
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        throw Exception('Failed to load medicine batches: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching medicine batches: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createStockBatch(Map<String, dynamic> data) async {
    try {
      AppLogger.apiRequest('POST', ApiConfig.pharmacyStockBatches);
      final response = await http.post(
        Uri.parse(ApiConfig.pharmacyStockBatches),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create stock batch: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error creating stock batch: $e');
      rethrow;
    }
  }

  // Low Stock Alerts
  Future<List<dynamic>> getLowStockAlerts({int threshold = 50}) async {
    try {
      final url = '${ApiConfig.pharmacyLowStockAlerts}?threshold=$threshold';
      AppLogger.apiRequest('GET', url);
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body is List ? body : (body['results'] ?? []);
      } else {
        throw Exception('Failed to load low stock alerts: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching low stock alerts: $e');
      rethrow;
    }
  }

  // Expiry Alerts
  Future<List<dynamic>> getExpiryAlerts({int days = 30}) async {
    try {
      final url = '${ApiConfig.pharmacyExpiryAlerts}?days=$days';
      AppLogger.apiRequest('GET', url);
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body is List ? body : (body['results'] ?? []);
      } else {
        throw Exception('Failed to load expiry alerts: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching expiry alerts: $e');
      rethrow;
    }
  }

  // Inventory Balances
  Future<List<dynamic>> getInventoryBalances() async {
    try {
      // Add timestamp to prevent caching
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = '${ApiConfig.pharmacyInventoryBalances}?_t=$timestamp';
      AppLogger.apiRequest('GET', url);
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        // Handle paginated response - extract results list
        final data = body is List ? body : (body['results'] ?? []);
        AppLogger.apiResponse(url, 200, data: data);
        return data;
      } else {
        AppLogger.apiResponse(url, response.statusCode, data: response.body);
        throw Exception('Failed to load inventory balances: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error getting inventory balances: $e');
      rethrow;
    }
  }

  // Get Inventory Balances by Location (for Cart location_id=2 or Main Pharmacy location_id=1)
  Future<List<dynamic>> getInventoryBalancesByLocation(int locationId) async {
    try {
      // Add timestamp to prevent caching and filter by location
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = '${ApiConfig.pharmacyInventoryBalances}?location_id=$locationId&_t=$timestamp';
      AppLogger.apiRequest('GET', url);
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body is List ? body : (body['results'] ?? []);
      } else {
        throw Exception('Failed to load inventory balances: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching inventory balances: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createInventoryBalance(Map<String, dynamic> data) async {
    try {
      AppLogger.apiRequest('POST', ApiConfig.pharmacyInventoryBalances);
      final response = await http.post(
        Uri.parse(ApiConfig.pharmacyInventoryBalances),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create inventory balance: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error creating inventory balance: $e');
      rethrow;
    }
  }

  // Purchase Requests
  Future<List<dynamic>> getPurchaseRequests() async {
    try {
      AppLogger.apiRequest('GET', ApiConfig.pharmacyPurchaseRequests);
      final response = await http.get(
        Uri.parse(ApiConfig.pharmacyPurchaseRequests),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body is List ? body : (body['results'] ?? []);
      } else {
        throw Exception('Failed to load purchase requests: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching purchase requests: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createPurchaseRequest(Map<String, dynamic> data) async {
    try {
      AppLogger.apiRequest('POST', ApiConfig.pharmacyPurchaseRequests);
      final response = await http.post(
        Uri.parse(ApiConfig.pharmacyPurchaseRequests),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        // Try to get error message from response body
        String errorMessage = 'Failed to create purchase request: ${response.statusCode}';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody['message'] != null) {
            errorMessage = errorBody['message'];
          } else if (errorBody is Map && errorBody['detail'] != null) {
            errorMessage = errorBody['detail'];
          } else {
            errorMessage = '${errorMessage} - ${response.body}';
          }
        } catch (_) {
          // If we can't parse the error body, just include the raw body
          errorMessage = '${errorMessage} - ${response.body}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      AppLogger.error('Error creating purchase request: $e');
      rethrow;
    }
  }

  // Charge Slips (Billing)
  Future<List<dynamic>> getChargeSlips() async {
    try {
      final url = '${ApiConfig.pharmacyBase}/dispense-receipts/billing-list/';
      AppLogger.apiRequest('GET', url);
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body is List ? body : (body['results'] ?? []);
      } else {
        throw Exception('Failed to load billing records: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching billing records: $e');
      rethrow;
    }
  }

  // Pharmacy Charge Slips (for pending prescriptions)
  Future<List<dynamic>> getPharmacyChargeSlips() async {
    try {
      AppLogger.apiRequest('GET', ApiConfig.pharmacyChargeSlips);
      final response = await http.get(
        Uri.parse(ApiConfig.pharmacyChargeSlips),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body is List ? body : (body['results'] ?? []);
      } else {
        throw Exception('Failed to load pharmacy charge slips: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching pharmacy charge slips: $e');
      rethrow;
    }
  }

  // OPD Prescriptions (for pending prescriptions)
  Future<List<dynamic>> getOpdPrescriptions() async {
    try {
      final url = '${ApiConfig.pharmacyBase}/opd-prescriptions/';
      AppLogger.apiRequest('GET', url);
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body is List ? body : (body['results'] ?? []);
      } else {
        throw Exception('Failed to load OPD prescriptions: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching OPD prescriptions: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> finalizeBilling(int receiptId, List<Map<String, dynamic>> items) async {
    try {
      final url = '${ApiConfig.pharmacyBase}/dispense-receipts/$receiptId/finalize-billing/';
      AppLogger.apiRequest('POST', url);
      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(),
        body: jsonEncode({'items': items}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to finalize billing: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error finalizing billing: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendToBilling(int receiptId) async {
    try {
      final url = '${ApiConfig.pharmacyBase}/dispense-receipts/$receiptId/send-to-billing/';
      AppLogger.apiRequest('POST', url);
      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to send to billing: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error sending to billing: $e');
      rethrow;
    }
  }

  // Create charge slip from OPD prescription
  Future<Map<String, dynamic>> createChargeSlip({
    required int patientId,
    required int rxId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final url = '${ApiConfig.pharmacyBase}/charge-slips/generate-from-opd/';
      AppLogger.apiRequest('POST', url);
      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(),
        body: jsonEncode({
          'patient_id': patientId,
          'rx_id': rxId,
          'items': items,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create charge slip: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error creating charge slip: $e');
      rethrow;
    }
  }

  // Forecasting Stats
  Future<Map<String, dynamic>> getForecastingStats() async {
    try {
      final url = '${ApiConfig.pharmacyBase}/forecasting-stats/';
      AppLogger.apiRequest('GET', url);
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load forecasting stats: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching forecasting stats: $e');
      rethrow;
    }
  }

  // Dispense Receipts
  Future<List<dynamic>> getDispenseReceipts() async {
    try {
      AppLogger.apiRequest('GET', ApiConfig.pharmacyDispenseReceipts);
      final response = await http.get(
        Uri.parse(ApiConfig.pharmacyDispenseReceipts),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body is List ? body : (body['results'] ?? []);
      } else {
        throw Exception('Failed to load dispense receipts: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching dispense receipts: $e');
      rethrow;
    }
  }

  // IPD Nurse Dispensing Sheets (Nurse Requests)
  Future<List<dynamic>> getIpdDispensingSheets() async {
    try {
      final url = '${ApiConfig.baseUrl}/api/ipd/requests/dispensing/';
      AppLogger.apiRequest('GET', url);
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body is List ? body : (body['results'] ?? []);
      } else {
        throw Exception('Failed to load nurse dispensing sheets: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching nurse dispensing sheets: $e');
      rethrow;
    }
  }

  // Dispense Medicine
  Future<Map<String, dynamic>> dispenseMedicine(Map<String, dynamic> data) async {
    try {
      AppLogger.apiRequest('POST', ApiConfig.pharmacyDispense);
      final response = await http.post(
        Uri.parse(ApiConfig.pharmacyDispense),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to dispense medicine: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error dispensing medicine: $e');
      rethrow;
    }
  }

  // Reports
  Future<Map<String, dynamic>> getWeeklyInventoryReport() async {
    try {
      final url = '${ApiConfig.pharmacyBase}/reports/weekly-inventory/';
      AppLogger.apiRequest('GET', url);
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load weekly inventory report: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching weekly inventory report: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getQuarterlyDispensingReport({int? year, int? quarter}) async {
    try {
      final queryParams = <String, String>{};
      if (year != null) queryParams['year'] = year.toString();
      if (quarter != null) queryParams['quarter'] = quarter.toString();
      final uri = Uri.parse('${ApiConfig.pharmacyBase}/reports/quarterly-dispensing/').replace(queryParameters: queryParams);
      AppLogger.apiRequest('GET', uri.toString());
      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load quarterly dispensing report: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching quarterly dispensing report: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMonthlyDispensingReport({int? year, int? month}) async {
    try {
      final queryParams = <String, String>{};
      if (year != null) queryParams['year'] = year.toString();
      if (month != null) queryParams['month'] = month.toString();
      final uri = Uri.parse('${ApiConfig.pharmacyBase}/reports/monthly-dispensing/').replace(queryParameters: queryParams);
      AppLogger.apiRequest('GET', uri.toString());
      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load monthly dispensing report: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching monthly dispensing report: $e');
      rethrow;
    }
  }

  Future<dynamic> generateReport(String reportType, String dateRange) async {
    try {
      final queryParams = {
        'report_type': reportType,
        'date_range': dateRange,
      };
      final uri = Uri.parse(ApiConfig.pharmacyReports).replace(queryParameters: queryParams);
      
      AppLogger.apiRequest('GET', uri.toString());
      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to generate report: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error generating report: $e');
      rethrow;
    }
  }

  /// Confirm delivery of a purchase request
  /// Creates goods receipt, stock batches, and updates inventory
  Future<Map<String, dynamic>> confirmDelivery(Map<String, dynamic> deliveryData) async {
    try {
      final url = Uri.parse('$baseUrl/confirm-delivery/');
      final headers = await _getHeaders();

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(deliveryData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to confirm delivery');
      }
    } catch (e) {
      AppLogger.error('Error confirming delivery: $e');
      rethrow;
    }
  }

  /// Manual return of medicine to Main Pharmacy (Location 1)
  Future<Map<String, dynamic>> manualReturn(Map<String, dynamic> data) async {
    try {
      final url = '${ApiConfig.pharmacyInventoryBalances}manual-return/';
      AppLogger.apiRequest('POST', url);
      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        // Force the app to clear any cached data for inventory balances
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? error['detail'] ?? 'Failed to return medicine');
      }
    } catch (e) {
      AppLogger.error('Error returning medicine: $e');
      rethrow;
    }
  }

  /// Add a new batch to a medicine
  Future<Map<String, dynamic>> addBatch(Map<String, dynamic> data) async {
    try {
      AppLogger.apiRequest('POST', ApiConfig.pharmacyStockBatches);
      final response = await http.post(
        Uri.parse(ApiConfig.pharmacyStockBatches),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? error['detail'] ?? 'Failed to add batch');
      }
    } catch (e) {
      AppLogger.error('Error adding batch: $e');
      rethrow;
    }
  }

  /// Restock a cart (Location 2) from Main Pharmacy (Location 1)
  Future<Map<String, dynamic>> restockCart(Map<String, dynamic> data) async {
    try {
      final url = '${ApiConfig.pharmacyInventoryBalances}restock-cart/';
      AppLogger.apiRequest('POST', url);
      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? error['detail'] ?? 'Failed to restock cart');
      }
    } catch (e) {
      AppLogger.error('Error restocking cart: $e');
      rethrow;
    }
  }

  /// Remove a batch totally and log adjustment
  Future<Map<String, dynamic>> removeBatch(int batchId, String reason, String remarks) async {
    try {
      final url = '${ApiConfig.pharmacyStockBatches}$batchId/remove-batch/';
      AppLogger.apiRequest('POST', url);
      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(),
        body: jsonEncode({
          'reason': reason,
          'remarks': remarks,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? error['detail'] ?? 'Failed to remove batch');
      }
    } catch (e) {
      AppLogger.error('Error removing batch: $e');
      rethrow;
    }
  }
}
