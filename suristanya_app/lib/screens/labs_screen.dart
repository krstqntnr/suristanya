import 'package:flutter/material.dart';
import '../services/screening_session.dart';
import '../theme/app_theme.dart';

class LabsScreen extends StatefulWidget {
  const LabsScreen({super.key});

  @override
  State<LabsScreen> createState() => _LabsScreenState();
}

class _LabsScreenState extends State<LabsScreen> {
  final _session = ScreeningSession.instance;
  final _ferritin = TextEditingController();
  final _hemoglobin = TextEditingController();
  final _mcv = TextEditingController();
  final _mch = TextEditingController();
  final _rdw = TextEditingController();
  final _tsat = TextEditingController();
  final _crp = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (_session.ferritin != null) _ferritin.text = _session.ferritin.toString();
    if (_session.hemoglobin != null) _hemoglobin.text = _session.hemoglobin.toString();
    if (_session.mcv != null) _mcv.text = _session.mcv.toString();
    if (_session.mch != null) _mch.text = _session.mch.toString();
    if (_session.rdw != null) _rdw.text = _session.rdw.toString();
    if (_session.tsat != null) _tsat.text = _session.tsat.toString();
    if (_session.crp != null) _crp.text = _session.crp.toString();
  }

  @override
  void dispose() {
    _ferritin.dispose();
    _hemoglobin.dispose();
    _mcv.dispose();
    _mch.dispose();
    _rdw.dispose();
    _tsat.dispose();
    _crp.dispose();
    super.dispose();
  }

  void _save() {
    _session.ferritin = num.tryParse(_ferritin.text);
    _session.hemoglobin = num.tryParse(_hemoglobin.text);
    _session.mcv = num.tryParse(_mcv.text);
    _session.mch = num.tryParse(_mch.text);
    _session.rdw = num.tryParse(_rdw.text);
    _session.tsat = num.tryParse(_tsat.text);
    _session.crp = num.tryParse(_crp.text);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Lab Values')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('If you have recent blood test results, enter them here. This helps the AI give a more accurate screening.', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              const SizedBox(height: 20),
              _buildField('Ferritin (ng/mL)', _ferritin),
              _buildField('Hemoglobin (g/dL)', _hemoglobin),
              _buildField('MCV (fL)', _mcv),
              _buildField('MCH (pg)', _mch),
              _buildField('RDW (%)', _rdw),
              _buildField('TSAT (%)', _tsat),
              _buildField('CRP (mg/L)', _crp),
              const SizedBox(height: 24),
              FilledButton(onPressed: _save, child: const Text('Save Labs')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }
}