import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/prediction.dart';
import '../models/screening_result.dart';

class PdfService {
  PdfService._();

  static Future<Uint8List> buildReport({
    required HealthSummary summary,
    required List<Prediction> predictions,
    ScreeningResult? screening,
    required DateTime generatedAt,
  }) async {
    final doc = pw.Document(
      title: 'Suristanya Health Report',
      author: 'Suristanya',
      creator: 'Suristanya App',
    );

    const navy = PdfColor.fromInt(0xFF1E3A8A);
    const cyan = PdfColor.fromInt(0xFF06B6D4);
    const success = PdfColor.fromInt(0xFF10B981);
    const warning = PdfColor.fromInt(0xFFF59E0B);
    const danger = PdfColor.fromInt(0xFFEF4444);
    const muted = PdfColor.fromInt(0xFF64748B);
    const border = PdfColor.fromInt(0xFFE2E8F0);
    const bg = PdfColor.fromInt(0xFFF5F7FB);

    PdfColor severityColor(String severity) {
      switch (severity.toLowerCase()) {
        case 'high':
          return danger;
        case 'moderate':
          return warning;
        default:
          return success;
      }
    }

    PdfColor screeningAccent(ScreeningResult s) {
      switch (s.severityRank) {
        case 3:
          return danger;
        case 2:
          return warning;
        case 1:
          return cyan;
        default:
          return success;
      }
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(),
        build: (context) => [
          // ── Header ────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: navy,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Suristanya',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: cyan,
                        borderRadius: pw.BorderRadius.circular(20),
                      ),
                      child: pw.Text(
                        'HEALTH REPORT',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'AI-powered health screening summary',
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 11,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Generated on ${_formatDate(generatedAt)}',
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // ── Score row ─────────────────────────────
          pw.Row(
            children: [
              _statBox(
                label: 'OVERALL SCORE',
                value: '${summary.score}',
                suffix: '/100',
                bg: bg,
                labelColor: muted,
                valueColor: navy,
              ),
              pw.SizedBox(width: 10),
              _statBox(
                label: 'STATUS',
                value: summary.status,
                bg: bg,
                labelColor: muted,
                valueColor: summary.status.toLowerCase() == 'healthy'
                    ? success
                    : warning,
              ),
              pw.SizedBox(width: 10),
              _statBox(
                label: 'CONFIDENCE',
                value: summary.confidencePercent,
                suffix: summary.confidenceLabel,
                bg: bg,
                labelColor: muted,
                valueColor: navy,
              ),
            ],
          ),
          pw.SizedBox(height: 24),

          // ── SCREENING section ─────────────────────
          if (screening != null) ...[
            pw.Text(
              'Clinical Screening',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: navy,
              ),
            ),
            pw.SizedBox(height: 6),

            // Headline card
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: bg,
                border: pw.Border.all(
                  color: screeningAccent(screening),
                  width: 1.2,
                ),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    screening.headline,
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: screeningAccent(screening),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    screening.message,
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.black,
                      lineSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // Findings
            ...screening.findings.map((f) {
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: border, width: 1),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      f.label,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      f.detail,
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.black,
                        lineSpacing: 2,
                      ),
                    ),
                    if (f.source.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Source: ${f.source}',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: muted,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),

            // Recommendations
            if (screening.recommendations.isNotEmpty) ...[
              pw.SizedBox(height: 6),
              pw.Text(
                'Recommended Steps',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: navy,
                ),
              ),
              pw.SizedBox(height: 4),
              ...screening.recommendations.map(
                (r) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '•  ',
                        style: const pw.TextStyle(fontSize: 10, color: navy),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          r,
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.black,
                            lineSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            pw.SizedBox(height: 20),
          ],

          // ── Image Analysis section ────────────────
          pw.Text(
            'Image Analysis',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: navy,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: bg,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              _summaryText(summary),
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.black,
                lineSpacing: 2,
              ),
            ),
          ),
          pw.SizedBox(height: 12),

          pw.Text(
            'Detailed Findings',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: navy,
            ),
          ),
          pw.SizedBox(height: 8),

          ...predictions.asMap().entries.map((entry) {
            final i = entry.key + 1;
            final p = entry.value;
            final color = severityColor(p.severity);

            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: border, width: 1),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 22,
                        height: 22,
                        alignment: pw.Alignment.center,
                        decoration: pw.BoxDecoration(
                          color: navy,
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Text(
                          '$i',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Expanded(
                        child: pw.Text(
                          p.condition,
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                          ),
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: pw.BoxDecoration(
                          color: color,
                          borderRadius: pw.BorderRadius.circular(10),
                        ),
                        child: pw.Text(
                          p.severity.toUpperCase(),
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 6),
                      pw.Text(
                        p.confidencePercent,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  _progressBar(
                    value: p.confidence.clamp(0.0, 1.0),
                    color: color,
                    background: border,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    p.description,
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.black,
                      lineSpacing: 2,
                    ),
                  ),
                  if (p.detectedFrom.isNotEmpty) ...[
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Detected from: ${p.detectedFrom.join(", ")}',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: muted,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ],
                  if (p.recommendations.isNotEmpty) ...[
                    pw.SizedBox(height: 8),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: bg,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'RECOMMENDATIONS',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: navy,
                              letterSpacing: 0.5,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          ...p.recommendations.map(
                            (r) => pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 2),
                              child: pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    '•  ',
                                    style: const pw.TextStyle(
                                      fontSize: 10,
                                      color: navy,
                                    ),
                                  ),
                                  pw.Expanded(
                                    child: pw.Text(
                                      r,
                                      style: const pw.TextStyle(
                                        fontSize: 10,
                                        color: PdfColors.black,
                                        lineSpacing: 2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),

          pw.SizedBox(height: 12),

          // ── Disclaimer ────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFFFF7ED),
              border: pw.Border.all(color: warning, width: 0.6),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '!',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: warning,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(
                    'This report is generated by an AI screening tool and is not a medical diagnosis. '
                    'Always consult a qualified healthcare professional before making health decisions.',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.black,
                      lineSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 16),
          pw.Center(
            child: pw.Text(
              'Generated by Suristanya  ·  Not a medical diagnosis',
              style: const pw.TextStyle(fontSize: 8, color: muted),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _progressBar({
    required double value,
    required PdfColor color,
    required PdfColor background,
  }) {
    final filled = (value.clamp(0.0, 1.0) * 1000).round();
    final empty = 1000 - filled;

    return pw.Container(
      height: 5,
      decoration: pw.BoxDecoration(
        color: background,
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Row(
        children: [
          if (filled > 0)
            pw.Expanded(
              flex: filled,
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  color: color,
                  borderRadius: pw.BorderRadius.circular(3),
                ),
              ),
            ),
          if (empty > 0) pw.Expanded(flex: empty, child: pw.SizedBox()),
        ],
      ),
    );
  }

  static pw.Widget _statBox({
    required String label,
    required String value,
    required PdfColor bg,
    required PdfColor labelColor,
    required PdfColor valueColor,
    String? suffix,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 8,
                color: labelColor,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  value,
                  style: pw.TextStyle(
                    fontSize: 16,
                    color: valueColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (suffix != null) ...[
                  pw.SizedBox(width: 3),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Text(
                      suffix,
                      style: pw.TextStyle(fontSize: 9, color: labelColor),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _summaryText(HealthSummary s) {
    final status = s.status.toLowerCase();
    if (status == 'healthy') {
      return 'Your overall screening score is ${s.score}/100, indicating a healthy presentation. '
          'The visual markers captured are within normal ranges. Continue regular checkups and a balanced lifestyle.';
    }
    if (status.contains('attention')) {
      return 'Your overall screening score is ${s.score}/100, suggesting some areas to monitor. '
          'One or more visual markers showed patterns worth attention. Consider a follow-up with a healthcare professional.';
    }
    return 'Your overall screening score is ${s.score}/100. '
        'The AI detected visual markers warranting closer attention. Please consult a doctor for a full evaluation.';
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $h:$m';
  }
}
