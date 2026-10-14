import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/prediction.dart';
import '../models/scan_record.dart';

/// Persists scan history locally using SharedPreferences.
class ScanHistoryStore {
  ScanHistoryStore._();
  static final ScanHistoryStore instance = ScanHistoryStore._();

  static const _kKey = 'scan_history';
  static const _maxRecords = 50;

  final List<ScanRecord> _records = [];
  bool _loaded = false;

  List<ScanRecord> get records => List.unmodifiable(_records);
  bool get isEmpty => _records.isEmpty;
  bool get isLoaded => _loaded;

  /// Load persisted records. Call once on app start.
  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List;
        _records
          ..clear()
          ..addAll(
            list.map(
              (e) => ScanRecord.fromJson((e as Map).cast<String, dynamic>()),
            ),
          );
      } catch (_) {
        _records.clear();
      }
    }
    _loaded = true;
  }

  /// Save a new record from a fresh API response.
  Future<ScanRecord> add({required Map<String, dynamic> apiResponse}) async {
    final summaryJson =
        (apiResponse['summary'] as Map?)?.cast<String, dynamic>() ?? {};
    final predictionsJson = (apiResponse['predictions'] as List?) ?? [];

    final record = ScanRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      summary: HealthSummary.fromJson(summaryJson),
      predictions: predictionsJson
          .map((p) => Prediction.fromJson((p as Map).cast<String, dynamic>()))
          .toList(),
    );

    _records.insert(0, record);

    if (_records.length > _maxRecords) {
      _records.removeRange(_maxRecords, _records.length);
    }

    await _persist();
    return record;
  }

  /// Update the note attached to a specific record.
  Future<void> updateNote(String id, String note) async {
    final idx = _records.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    _records[idx] = _records[idx].copyWith(note: note.trim());
    await _persist();
  }

  Future<void> remove(String id) async {
    _records.removeWhere((r) => r.id == id);
    await _persist();
  }

  Future<void> clear() async {
    _records.clear();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_records.map((r) => r.toJson()).toList());
    await prefs.setString(_kKey, raw);
  }
}
