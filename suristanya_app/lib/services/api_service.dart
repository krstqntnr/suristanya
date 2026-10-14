import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// Central API client for the Suristanya Flask backend.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  /// Base URL depends on where Flutter is running.
  ///
  /// - Web (Chrome):        `http://localhost:5000`
  /// - Android emulator:    `http://10.0.2.2:5000`
  /// - Real device (LAN):   `http://<your-pc-ip>:5000` (e.g. `http://192.168.1.10:5000`)
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:5000';
    } catch (_) {}
    return 'http://localhost:5000';
  }

  // ─── AUTH ────────────────────────────────────────────────────

  Future<AuthResult> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
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
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _parseAuth(res);
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/forgot'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
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
      headers: {'Content-Type': 'application/json'},
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

  // ─── PREDICT ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> predictFromBytes({
    required Map<String, List<int>> images,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/predict/'),
    );

    images.forEach((key, bytes) {
      request.files.add(
        http.MultipartFile.fromBytes(key, bytes, filename: '$key.jpg'),
      );
    });

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _decode(res);
  }

  // ─── HELPERS ─────────────────────────────────────────────────

  AuthResult _parseAuth(http.Response res) {
    final data = _decode(res);
    if (res.statusCode >= 400) {
      throw ApiException(
        data['error'] as String? ?? 'Request failed (${res.statusCode})',
      );
    }
    return AuthResult(
      token: data['token'] as String? ?? '',
      userId: (data['user']?['id'] as String?) ?? '',
      name: (data['user']?['name'] as String?) ?? '',
      email: (data['user']?['email'] as String?) ?? '',
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
