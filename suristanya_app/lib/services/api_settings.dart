import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Stores the backend base URL that the user can point at their PC,
/// a tunnel, or any deployed server.
class ApiSettings {
  ApiSettings._();
  static final ApiSettings instance = ApiSettings._();

  static const _kBaseUrl = 'api_base_url';
  static const _defaultUrl = 'https://ferry-undoing-sphinx.ngrok-free.dev';

  String? _override;

  /// dart-define `API_BASE_URL` wins, then a saved value, then default.
  String get baseUrl {
    const buildTime = String.fromEnvironment('API_BASE_URL');
    if (buildTime.isNotEmpty) return buildTime;
    if (_override != null && _override!.isNotEmpty) return _override!;
    return _defaultUrl;
  }

  /// True when the user explicitly saved a URL (or a dart-define is set).
  bool get isConfigured {
    const buildTime = String.fromEnvironment('API_BASE_URL');
    if (buildTime.isNotEmpty) return true;
    return _override != null && _override!.isNotEmpty;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _override = prefs.getString(_kBaseUrl);
  }

  Future<void> set(String url) async {
    final cleaned = url.trim().replaceAll(RegExp(r'/+$'), '');
    _override = cleaned.isEmpty ? null : cleaned;
    final prefs = await SharedPreferences.getInstance();
    if (_override == null) {
      await prefs.remove(_kBaseUrl);
    } else {
      await prefs.setString(_kBaseUrl, _override!);
    }
  }

  Future<void> reset() => set('');

  /// Tries `GET <url>/health` and reports success.
  /// Used by the settings screen to verify the URL before saving.
  Future<HealthProbe> probe(String url) async {
    final cleaned = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (cleaned.isEmpty) {
      return const HealthProbe(ok: false, message: 'URL is empty');
    }
    final uri = Uri.tryParse('$cleaned/health');
    if (uri == null || !uri.hasScheme) {
      return const HealthProbe(
        ok: false,
        message: 'URL must include http:// or https://',
      );
    }

    try {
      final res = await http
          .get(uri)
          .timeout(const Duration(seconds: 5));

      if (res.statusCode != 200) {
        return HealthProbe(
          ok: false,
          message: 'Server responded ${res.statusCode}',
        );
      }
      return const HealthProbe(ok: true, message: 'Backend reachable');
    } on TimeoutException {
      return const HealthProbe(
        ok: false,
        message: 'Timed out — check the URL, Wi-Fi, and firewall',
      );
    } catch (e) {
      return HealthProbe(ok: false, message: 'Could not connect: $e');
    }
  }
}

class HealthProbe {
  final bool ok;
  final String message;
  const HealthProbe({required this.ok, required this.message});
}