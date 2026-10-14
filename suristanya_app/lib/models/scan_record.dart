import 'prediction.dart';

class ScanRecord {
  final String id;
  final DateTime timestamp;
  final HealthSummary summary;
  final List<Prediction> predictions;
  final String note;

  const ScanRecord({
    required this.id,
    required this.timestamp,
    required this.summary,
    required this.predictions,
    this.note = '',
  });

  factory ScanRecord.fromJson(Map<String, dynamic> json) {
    return ScanRecord(
      id: json['id'] as String? ?? '',
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      summary: HealthSummary.fromJson(
        (json['summary'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
      predictions: ((json['predictions'] as List?) ?? [])
          .map((p) => Prediction.fromJson((p as Map).cast<String, dynamic>()))
          .toList(),
      note: json['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'note': note,
    'summary': {
      'score': summary.score,
      'status': summary.status,
      'confidence': summary.confidence,
      'confidence_label': summary.confidenceLabel,
    },
    'predictions': predictions
        .map(
          (p) => {
            'condition': p.condition,
            'confidence': p.confidence,
            'severity': p.severity,
            'description': p.description,
            'recommendations': p.recommendations,
            'detected_from': p.detectedFrom,
          },
        )
        .toList(),
  };

  /// Raw API shape (used when re-opening a scan in ResultsScreen).
  Map<String, dynamic> toApiShape() => {
    'summary': {
      'score': summary.score,
      'status': summary.status,
      'confidence': summary.confidence,
      'confidence_label': summary.confidenceLabel,
    },
    'predictions': predictions
        .map(
          (p) => {
            'condition': p.condition,
            'confidence': p.confidence,
            'severity': p.severity,
            'description': p.description,
            'recommendations': p.recommendations,
            'detected_from': p.detectedFrom,
          },
        )
        .toList(),
  };

  ScanRecord copyWith({String? note}) => ScanRecord(
    id: id,
    timestamp: timestamp,
    summary: summary,
    predictions: predictions,
    note: note ?? this.note,
  );

  bool get hasNote => note.trim().isNotEmpty;

  String get dateLabel {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    }
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}
