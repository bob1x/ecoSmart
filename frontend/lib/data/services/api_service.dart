import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

// ── API Base URL ────────────────────────────────────────────────
// Web: localhost (same machine)
// Android emulator: 10.0.2.2 maps to host machine's localhost
// Production: replace with your server URL
String get kApiBaseUrl {
  if (kIsWeb) return 'http://localhost:8000';
  return 'http://10.0.2.2:8000';
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _headers = {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  Future<Map<String, dynamic>> predictNumeric({
    required double poids,
    required double volume,
    required double conductivite,
    required double opacite,
    required double rigidite,
    required String source,
  }) async {
    return _post('/predict/numeric', {
      'Poids': poids,
      'Volume': volume,
      'Conductivite': conductivite,
      'Opacite': opacite,
      'Rigidite': rigidite,
      'Source': source,
    });
  }

  Future<Map<String, dynamic>> predictMultimodal({
    required double poids,
    required double volume,
    required double conductivite,
    required double opacite,
    required double rigidite,
    required String source,
    required String rapport,
  }) async {
    return _post('/predict/multimodal', {
      'Poids': poids,
      'Volume': volume,
      'Conductivite': conductivite,
      'Opacite': opacite,
      'Rigidite': rigidite,
      'Source': source,
      'rapport': rapport,
    });
  }

  Future<Map<String, dynamic>> predictText(String rapport) async {
    return _post('/predict/text', {'rapport': rapport});
  }

  Future<Map<String, dynamic>> fetchHealth() async {
    try {
      final uri = Uri.parse('$kApiBaseUrl/health');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw ApiException('Health check failed', statusCode: response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final uri = Uri.parse('$kApiBaseUrl$path');
      final response = await _client
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      String detail = 'Request failed';
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        detail = err['detail']?.toString() ?? detail;
      } catch (_) {}

      throw ApiException(detail, statusCode: response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }
}
