import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/screening_result.dart';
import 'api_settings.dart';
import 'auth_store.dart';

/// Central API client for the Suristanya Flask backend.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static String get baseUrl => ApiSettings.instance.baseUrl;

  // Added ngrok-skip-browser-warning to prevent ngrok from blocking API calls
  Map<String, String> _jsonHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
    final token = AuthStore.instance.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Map<String, String> _authHeaders() {
    final headers = <String, String>{'ngrok-skip-browser-warning': 'true'};
    final token = AuthStore.instance.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ─── AUTH ────────────────────────────────────────────────────

  Future<AuthResult> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: _jsonHeaders(),
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    return _parseAuth(res);
  }

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/signin'),
      headers: _jsonHeaders(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _parseAuth(res);
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/forgot'),
      headers: _jsonHeaders(),
      body: jsonEncode({'email': email}),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> me() async {
    final res = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: _authHeaders(),
    );
    return _decode(res);
  }

  // ─── CHAT ────────────────────────────────────────────────────

  Future<ChatReply> chat({
    required String message,
    List<Map<String, String>> history = const [],
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/chat/'),
      headers: _jsonHeaders(),
      body: jsonEncode({'message': message, 'history': history}),
    );
    final data = _decode(res);
    return ChatReply(
      text: data['reply'] as String? ?? '(no reply)',
      suggestions: (data['suggestions'] as List?)?.cast<String>() ?? const [],
      intent: data['intent'] as String?,
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // ─── SCREEN (rule engine) ────────────────────────────────────

  Future<ScreeningResult> assessScreen(Map<String, dynamic> payload) async {
    final res = await http.post(
      Uri.parse('$baseUrl/screen/assess'),
      headers: _jsonHeaders(),
      body: jsonEncode(payload),
    );
    return ScreeningResult.fromJson(_decode(res));
  }

  Future<Map<String, dynamic>> screenSchema() async {
    final res = await http.get(
      Uri.parse('$baseUrl/screen/schema'),
      headers: _authHeaders(),
    );
    return _decode(res);
  }

  // ─── PREDICT ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> predictFromBytes({
    required Map<String, List<int>> images,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/predict/'),
    );

    request.headers['ngrok-skip-browser-warning'] = 'true';
    
    final token = AuthStore.instance.token;
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    images.forEach((key, bytes) {
      request.files.add(
        http.MultipartFile.fromBytes(key, bytes, filename: '$key.jpg'),
      );
    });

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _decode(res);
  }

  // ─── SCANS (history) ─────────────────────────────────────────

  Future<List<Map<String, dynamic>>> listScans({int limit = 50}) async {
    final res = await http.get(
      Uri.parse('$baseUrl/scans?limit=$limit'),
      headers: _authHeaders(),
    );
    final data = _decode(res);
    final list = (data['scans'] as List?) ?? const [];
    return list.map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  Future<Map<String, dynamic>> createScan({
    required Map<String, dynamic> summary,
    required List<Map<String, dynamic>> predictions,
    Map<String, dynamic>? screening,
    String note = '',
    String? timestamp,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/scans'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'summary': summary,
        'predictions': predictions,
        'screening': screening,
        'note': note,
        'timestamp': timestamp,
      }),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> updateScanNote(String id, String note) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/scans/$id'),
      headers: _jsonHeaders(),
      body: jsonEncode({'note': note}),
    );
    return _decode(res);
  }

  Future<void> deleteScan(String id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/scans/$id'),
      headers: _authHeaders(),
    );
    if (res.statusCode >= 400) {
      final data = _decode(res);
      throw ApiException(
        (data['error'] as String?) ?? 'Delete failed (${res.statusCode})',
      );
    }
  }

  Future<void> clearScans() async {
    final res = await http.delete(
      Uri.parse('$baseUrl/scans'),
      headers: _authHeaders(),
    );
    if (res.statusCode >= 400) {
      final data = _decode(res);
      throw ApiException(
        (data['error'] as String?) ?? 'Clear failed (${res.statusCode})',
      );
    }
  }

  // ─── HELPERS ─────────────────────────────────────────────────

  AuthResult _parseAuth(http.Response res) {
    final data = _decode(res);
    if (res.statusCode >= 400) {
      throw ApiException(
        (data['error'] as String?) ?? 'Request failed (${res.statusCode})',
      );
    }
    final user = (data['user'] as Map?)?.cast<String, dynamic>() ?? {};
    return AuthResult(
      token: data['token'] as String? ?? '',
      userId: user['id'] as String? ?? '',
      name: user['name'] as String? ?? '',
      email: user['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> _decode(http.Response res) {
    try {
      final body = res.body.isEmpty ? '{}' : res.body;
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Invalid response from server (${res.statusCode})');
    }
  }
}

class AuthResult {
  final String token;
  final String userId;
  final String name;
  final String email;
  const AuthResult({
    required this.token,
    required this.userId,
    required this.name,
    required this.email,
  });
}

class ChatReply {
  final String text;
  final List<String> suggestions;
  final String? intent;
  final double confidence;
  const ChatReply({
    required this.text,
    this.suggestions = const [],
    this.intent,
    this.confidence = 0.0,
  });
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}