import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/routes.dart';
import 'storage_service.dart';

class ApiService {
  // L'URL de base est centralisée dans AppRoutes.baseUrl (ex: http://10.0.2.2:8000/api)
  static String get baseUrl => AppRoutes.baseUrl;

  /// Construit proprement l'URI pour éviter les doublons de préfixe /api
  static Uri _buildUri(String endpoint) {
    String base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    String path = endpoint.startsWith('/') ? endpoint : '/$endpoint';

    if (base.endsWith('/api') && path.startsWith('/api/')) {
      path = path.substring(4);
    } else if (!base.endsWith('/api') && !path.startsWith('/api/')) {
      path = '/api$path';
    }

    return Uri.parse('$base$path');
  }

  static Future<Map<String, String>> _getHeaders({bool isPrivate = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final storage = await StorageService.getInstance();
    final token = storage.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static Future<void> _handleTokenExpiration(http.Response response) async {
    if (response.statusCode == 401) {
      debugPrint('🔑 [API 401] Token expiré ou non-autorisé. Conservation du profil local passager pour mode hors-ligne.');
    }
  }

  static Future<http.Response> get(String endpoint, {bool isPrivate = true}) async {
    final headers = await _getHeaders(isPrivate: isPrivate);
    final uri = _buildUri(endpoint);
    debugPrint('🌐 [API GET] $uri');
    try {
      final response = await http.get(uri, headers: headers);
      debugPrint('📥 [API RESPONSE ${response.statusCode}] ${response.body}');
      await _handleTokenExpiration(response);
      return response;
    } catch (e) {
      debugPrint('❌ [API GET ERROR] $uri -> $e');
      rethrow;
    }
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body, {bool isPrivate = false}) async {
    final headers = await _getHeaders(isPrivate: isPrivate);
    final uri = _buildUri(endpoint);
    debugPrint('🌐 [API POST] $uri | Body: ${jsonEncode(body)}');
    try {
      final response = await http.post(uri, headers: headers, body: jsonEncode(body));
      debugPrint('📥 [API RESPONSE ${response.statusCode}] ${response.body}');
      await _handleTokenExpiration(response);
      return response;
    } catch (e) {
      debugPrint('❌ [API POST ERROR] $uri -> $e');
      rethrow;
    }
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> body, {bool isPrivate = true}) async {
    final headers = await _getHeaders(isPrivate: isPrivate);
    final uri = _buildUri(endpoint);
    debugPrint('🌐 [API PUT] $uri | Body: ${jsonEncode(body)}');
    try {
      final response = await http.put(uri, headers: headers, body: jsonEncode(body));
      debugPrint('📥 [API RESPONSE ${response.statusCode}] ${response.body}');
      await _handleTokenExpiration(response);
      return response;
    } catch (e) {
      debugPrint('❌ [API PUT ERROR] $uri -> $e');
      rethrow;
    }
  }
}
