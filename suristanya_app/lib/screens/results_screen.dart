import 'package:flutter/material.dart';

import '../models/prediction.dart';
import '../models/scan_record.dart';
import '../services/scan_history_store.dart';
import '../theme/app_theme.dart';
import '../widgets/result_card.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is! Map<String, dynamic>) {
      return _scaffoldMessage(
        'No results to show.\nPlease complete a scan first.',
      );
    }

    final summaryJson = args['summary'] as Map<String, dynamic>?;
    final predictionsJson = args['predictions'] as List?;

    if (summaryJson == null || predictionsJson == null) {
      return _scaffoldMessage('Malformed response from server.');
    }

    final summary = HealthSummary.fromJson(summaryJson);
    final predictions = predictionsJson
        .map((p) => Prediction.fromJson(p as Map<String, dynamic>))
        .toList();

    if (predictions.isEmpty) {
      return _scaffoldMessage('No predictions returned.');
    }

    // ── Comparison against the previous scan ────────────────────
    // If this result was opened from history, the current record
    // is already in the store. We want the record *before* it.
    final records = ScanHistoryStore.instance.records;
    ScanRecord? previous;
    if (records.length >= 2) {
      // Find the current one by matching score + status, then take
      // the next-older record.
      final currentIdx = records.indexWhere(
        (r) =>
            r.summary.score == summary.score &&
            r.summary.status == summary.status,
      );
      if (currentIdx != -1 && currentIdx + 1 < records.length) {
        previous = records[currentIdx + 1];
      } else if (currentIdx == -1 && records.isNotEmpty) {
        // Fresh scan opened before being saved? fall back to newest.
        previous = records.first;
      }
    }

    final delta = previous != null
        ? summary.score - previous.summary.score
        : null;

    // ── Primary finding: highest severity ───────────────────────
    final severityRank = {'high': 3, 'moderate': 2, 'low': 1};
    final primary = predictions.reduce((a, b) {
      final ra = severityRank[a.severity.toLowerCase()] ?? 0;
      final rb = severityRank[b.severity.toLowerCase()] ?? 0;
      return ra >= rb ? a : b;
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Your Health Insights'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/chat',
            (route) => false,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Comparison banner ───────────────────────
              if (delta != null) ...[
                _ComparisonBanner(delta: delta),
                const SizedBox(height: 12),
              ],

              // ── Hero score card ─────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overall Health Score',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        SizedBox(
                          width: 96,
                          height: 96,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: summary.score / 100),
                            duration: const Duration(milliseconds: 1100),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 96,
                                    height: 96,
                                    child: CircularProgressIndicator(
                                      value: value,
                                      strokeWidth: 8,
                                      backgroundColor: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      valueColor: const AlwaysStoppedAnimation(
                                        AppColors.accent,
                                      ),
                                      strokeCap: StrokeCap.round,
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${(value * 100).round()}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          height: 1,
                                        ),
                                      ),
                                      const Text(
                                        '/ 100',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      summary.status.toLowerCase() == 'healthy'
                                      ? AppColors.success.withValues(alpha: 0.9)
                                      : AppColors.warning.withValues(
                                          alpha: 0.9,
                                        ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  summary.status,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Confidence: ${summary.confidencePercent}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '(${summary.confidenceLabel} confidence)',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Key findings ────────────────────────────
              Row(
                children: [
                  const Text(
                    'Key Findings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${predictions.length} markers',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ...predictions.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ResultCard(
                    prediction: p,
                    isPrimary: identical(p, primary),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── Disclaimer ──────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.warning,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This is a screening tool, not a diagnosis. Please consult a doctor for medical advice.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Actions ─────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/chat',
                          (route) => false,
                        );
                      },
                      child: const Text('Back to Ava'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/full-report',
                          arguments: args,
                        );
                      },
                      child: const Text('View Full Result'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Scan Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scaffoldMessage(String text) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Results')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
        ),
      ),
    );
  }
}

/// Banner that shows up at the top of results when there's a previous scan.
class _ComparisonBanner extends StatelessWidget {
  final int delta;
  const _ComparisonBanner({required this.delta});

  @override
  Widget build(BuildContext context) {
    final improved = delta > 0;
    final noChange = delta == 0;

    final bg = noChange
        ? AppColors.border.withValues(alpha: 0.4)
        : improved
        ? AppColors.success.withValues(alpha: 0.12)
        : AppColors.warning.withValues(alpha: 0.14);

    final fg = noChange
        ? AppColors.textMuted
        : improved
        ? AppColors.success
        : AppColors.warning;

    final icon = noChange
        ? Icons.trending_flat_rounded
        : improved
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;

    final headline = noChange
        ? 'No change since your last scan'
        : improved
        ? 'Your score improved by $delta points'
        : 'Your score dropped by ${delta.abs()} points';

    final sub = noChange
        ? 'Keep it up — consistency is key.'
        : improved
        ? 'Nice work! Keep up the healthy habits.'
        : 'Consider reviewing your recent scans for details.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: fg.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
