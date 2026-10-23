import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/prediction.dart';
import '../models/screening_result.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';

class FullReportScreen extends StatefulWidget {
  const FullReportScreen({super.key});

  @override
  State<FullReportScreen> createState() => _FullReportScreenState();
}

class _FullReportScreenState extends State<FullReportScreen> {
  HealthSummary? _summary;
  List<Prediction>? _predictions;
  ScreeningResult? _screening;
  bool _exporting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_summary != null) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! Map<String, dynamic>) return;

    Map<String, dynamic>? predsResponse;
    ScreeningResult? screening;

    if (args['predictions'] is Map) {
      predsResponse = (args['predictions'] as Map).cast<String, dynamic>();
      final scr = args['screening'];
      if (scr is ScreeningResult) {
        screening = scr;
      } else if (scr is Map) {
        try {
          screening = ScreeningResult.fromJson(scr.cast<String, dynamic>());
        } catch (_) {}
      }
    } else if (args['summary'] is Map) {
      predsResponse = args;
    }

    if (predsResponse == null) return;

    final summaryJson = (predsResponse['summary'] as Map?)?.cast<String, dynamic>();
    final predictionsJson = predsResponse['predictions'] as List?;
    if (summaryJson == null || predictionsJson == null) return;

    _summary = HealthSummary.fromJson(summaryJson);
    _predictions = predictionsJson.map((p) => Prediction.fromJson((p as Map).cast<String, dynamic>())).toList();
    _screening = screening;
  }

  Future<void> _exportPdf() async {
    if (_summary == null || _predictions == null) return;

    setState(() => _exporting = true);
    try {
      final bytes = await PdfService.buildReport(
        summary: _summary!,
        predictions: _predictions!,
        screening: _screening,
        generatedAt: DateTime.now(),
      );

      // CHANGED FROM layoutPdf TO sharePdf
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'Suristanya_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not export PDF: $e'), behavior: SnackBarBehavior.floating, backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_summary == null || _predictions == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Full Report')),
        body: const Center(child: Text('No report to display.')),
      );
    }

    final summary = _summary!;
    final predictions = _predictions!;
    final screening = _screening;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Full Report'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            tooltip: 'Export PDF',
            onPressed: _exporting ? null : _exportPdf,
            icon: _exporting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.picture_as_pdf_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ... (UI code stays the same as your original file)
            ],
          ),
        ),
      ),
    );
  }
}