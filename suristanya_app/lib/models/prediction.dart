class Prediction {
  final String condition;
  final double confidence;
  final String severity;
  final String description;
  final List<String> recommendations;
  final List<String> detectedFrom;

  const Prediction({
    required this.condition,
    required this.confidence,
    required this.severity,
    required this.description,
    required this.recommendations,
    required this.detectedFrom,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      condition: json['condition'] as String? ?? 'Unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      severity: json['severity'] as String? ?? 'Low',
      description: json['description'] as String? ?? '',
      recommendations:
          (json['recommendations'] as List?)?.cast<String>() ?? const [],
      detectedFrom:
          (json['detected_from'] as List?)?.cast<String>() ?? const [],
    );
  }

  String get confidencePercent => '${(confidence * 100).toStringAsFixed(0)}%';
}

class HealthSummary {
  final int score;
  final String status;
  final double confidence;
  final String confidenceLabel;

  const HealthSummary({
    required this.score,
    required this.status,
    required this.confidence,
    required this.confidenceLabel,
  });

  factory HealthSummary.fromJson(Map<String, dynamic> json) {
    return HealthSummary(
      score: (json['score'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'Unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      confidenceLabel: json['confidence_label'] as String? ?? 'Low',
    );
  }

  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';
}
