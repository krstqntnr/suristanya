import 'prediction.dart';
import 'screening_result.dart';

class ScanRecord {
  final String id;
  final DateTime timestamp;
  final HealthSummary summary;
  final List<Prediction> predictions;
  final ScreeningResult? screening;
  final String note;
  final Map<String, dynamic> images; // <-- ADDED

  const ScanRecord({
    required this.id,
    required this.timestamp,
    required this.summary,
    required this.predictions,
    this.screening,
    this.note = '',
    this.images = const {}, // <-- ADDED
  });

  factory ScanRecord.fromJson(Map<String, dynamic> json) {
    ScreeningResult? screening;
    final scr = json['screening'];
    if (scr is Map) {
      try {
        screening = ScreeningResult.fromJson(scr.cast<String, dynamic>());
      } catch (_) {}
    }

    return ScanRecord(
      id: json['id'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      summary: HealthSummary.fromJson((json['summary'] as Map?)?.cast<String, dynamic>() ?? {}),
      predictions: ((json['predictions'] as List?) ?? []).map((p) => Prediction.fromJson((p as Map).cast<String, dynamic>())).toList(),
      screening: screening,
      note: json['note'] as String? ?? '',
      images: (json['images'] as Map?)?.cast<String, dynamic>() ?? {}, // <-- ADDED
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'note': note,
    'images': images, // <-- ADDED
    'summary': {
      'score': summary.score,
      'status': summary.status,
      'confidence': summary.confidence,
      'confidence_label': summary.confidenceLabel,
    },
    'predictions': predictions.map((p) => {
      'condition': p.condition,
      'confidence': p.confidence,
      'severity': p.severity,
      'description': p.description,
      'recommendations': p.recommendations,
      'detected_from': p.detectedFrom,
    }).toList(),
    if (screening != null) 'screening': screening!.toJson(),
  };

  Map<String, dynamic> toApiShape() => {
    'summary': {
      'score': summary.score,
      'status': summary.status,
      'confidence': summary.confidence,
      'confidence_label': summary.confidenceLabel,
    },
    'predictions': predictions.map((p) => {
      'condition': p.condition,
      'confidence': p.confidence,
      'severity': p.severity,
      'description': p.description,
      'recommendations': p.recommendations,
      'detected_from': p.detectedFrom,
    }).toList(),
  };

  ScanRecord copyWith({String? note}) => ScanRecord(
    id: id,
    timestamp: timestamp,
    summary: summary,
    predictions: predictions,
    screening: screening,
    note: note ?? this.note,
    images: images,
  );

  bool get hasNote => note.trim().isNotEmpty;
  bool get hasScreening => screening != null;

  String get dateLabel {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}