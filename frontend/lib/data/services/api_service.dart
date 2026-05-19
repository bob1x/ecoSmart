import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:http/http.dart' as http;

// ── API Base URL ────────────────────────────────────────────────
// UNIFIED DEPLOYMENT: Frontend + Backend served from the same origin.
// In release mode (flutter build web), API calls use relative paths.
// In debug mode (flutter run), uses localhost.
String get kApiBaseUrl {
  // Release build → same-origin (backend serves both API + static files)
  if (kReleaseMode) return '';
  // Local development
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

  Future<void> submitFeedback({
    required String predictedLabel,
    required String correctLabel,
  }) async {
    await _post('/feedback', {
      'predicted_label': predictedLabel,
      'correct_label': correctLabel,
    }, accept201: true);
  }

  Future<Map<String, dynamic>> fetchFeedbackStats() async {
    return _get('/feedback/stats');
  }

  Future<Map<String, dynamic>> fetchHealth() async {
    return _get('/health');
  }

  /// SHAP-like feature explanation for numeric prediction
  Future<Map<String, dynamic>> explainPrediction({
    required double poids,
    required double volume,
    required double conductivite,
    required double opacite,
    required double rigidite,
    required String source,
  }) async {
    return _post('/predict/explain', {
      'Poids': poids,
      'Volume': volume,
      'Conductivite': conductivite,
      'Opacite': opacite,
      'Rigidite': rigidite,
      'Source': source,
    });
  }

  /// Returns the full URL for CSV / PDF exports (opened via browser)
  String getExportUrl(String path) => '$kApiBaseUrl$path';

  /// Fetch real MLOps metrics from the backend
  Future<Map<String, dynamic>> fetchMlopsMetrics() async {
    return _get('/mlops/metrics');
  }

  // ── HTTP helpers ──────────────────────────────────────────────

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final uri = Uri.parse('$kApiBaseUrl$path');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw ApiException('GET $path failed', statusCode: response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    bool accept201 = false,
  }) async {
    try {
      final uri = Uri.parse('$kApiBaseUrl$path');
      final response = await _client
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || (accept201 && response.statusCode == 201)) {
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
