import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_service.dart';

enum BackendStatus { unknown, online, offline }

/// Pings the Flask `/health` endpoint on a schedule and exposes
/// a reactive status any widget can listen to.
class HealthService {
  HealthService._();
  static final HealthService instance = HealthService._();

  final ValueNotifier<BackendStatus> status = ValueNotifier(
    BackendStatus.unknown,
  );

  Timer? _timer;
  bool _checking = false;

  /// Starts periodic checks (every 20s) and runs one immediately.
  void start() {
    _check();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _check());
  }

  /// Stops the periodic checker.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Manual check (used by the Retry button).
  Future<bool> checkNow() => _check();

  Future<bool> _check() async {
    if (_checking) return status.value == BackendStatus.online;
    _checking = true;
    try {
      final res = await http
          .get(Uri.parse('${ApiService.baseUrl}/health'))
          .timeout(const Duration(seconds: 5));
      final ok = res.statusCode == 200;
      status.value = ok ? BackendStatus.online : BackendStatus.offline;
      return ok;
    } catch (_) {
      status.value = BackendStatus.offline;
      return false;
    } finally {
      _checking = false;
    }
  }
}
