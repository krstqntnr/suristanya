class ScreeningResult {
  final String level;
  final String headline;
  final String message;
  final List<ScreeningFinding> findings;
  final List<String> recommendations;
  final String disclaimer;

  const ScreeningResult({
    required this.level,
    required this.headline,
    required this.message,
    required this.findings,
    required this.recommendations,
    required this.disclaimer,
  });

  factory ScreeningResult.fromJson(Map<String, dynamic> json) {
    return ScreeningResult(
      level: json['level'] as String? ?? 'low_risk',
      headline: json['headline'] as String? ?? '',
      message: json['message'] as String? ?? '',
      findings: ((json['findings'] as List?) ?? [])
          .map(
            (f) =>
                ScreeningFinding.fromJson((f as Map).cast<String, dynamic>()),
          )
          .toList(),
      recommendations:
          (json['recommendations'] as List?)?.cast<String>() ?? const [],
      disclaimer: json['disclaimer'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'level': level,
        'headline': headline,
        'message': message,
        'findings': findings.map((f) => f.toJson()).toList(),
        'recommendations': recommendations,
        'disclaimer': disclaimer,
      };

  /// 0 = calm, 1 = watch, 2 = warn, 3 = urgent
  int get severityRank {
    switch (level) {
      case 'urgent':
        return 3;
      case 'likely_ida':
      case 'likely_iron_deficiency':
        return 2;
      case 'possible_iron_deficiency':
      case 'needs_testing':
        return 1;
      default:
        return 0;
    }
  }
}

class ScreeningFinding {
  final String id;
  final String label;
  final String detail;
  final String source;

  const ScreeningFinding({
    required this.id,
    required this.label,
    required this.detail,
    required this.source,
  });

  factory ScreeningFinding.fromJson(Map<String, dynamic> json) {
    return ScreeningFinding(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
      source: json['source'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'detail': detail,
        'source': source,
      };
}