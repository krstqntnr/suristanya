import 'package:flutter/material.dart';

import '../models/prediction.dart';
import '../theme/app_theme.dart';

class ResultCard extends StatelessWidget {
  final Prediction prediction;
  final bool isPrimary;

  const ResultCard({
    super.key,
    required this.prediction,
    this.isPrimary = false,
  });

  Color get _severityColor {
    switch (prediction.severity.toLowerCase()) {
      case 'high':
        return AppColors.danger;
      case 'moderate':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  IconData get _icon {
    final label = prediction.detectedFrom.join(' ').toLowerCase();
    if (label.contains('tongue')) return Icons.sentiment_satisfied_alt_rounded;
    if (label.contains('palm')) return Icons.back_hand_rounded;
    if (label.contains('nail')) return Icons.ads_click_rounded;
    if (label.contains('eye')) return Icons.remove_red_eye_rounded;
    return Icons.health_and_safety_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _severityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon, size: 18, color: _severityColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  prediction.condition,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                prediction.confidencePercent,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _severityColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Mini progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: prediction.confidence,
              minHeight: 5,
              color: _severityColor,
              backgroundColor: AppColors.border,
            ),
          ),
          const SizedBox(height: 10),

          Text(
            prediction.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),

          if (isPrimary && prediction.recommendations.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recommended action',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    prediction.recommendations.first,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
