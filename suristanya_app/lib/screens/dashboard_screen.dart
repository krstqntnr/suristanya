import 'package:flutter/material.dart';

import '../models/scan_record.dart';
import '../services/auth_store.dart';
import '../services/scan_history_store.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ScanHistoryStore.instance.load();
      await ScanHistoryStore.instance.refreshFromServer(); // <-- PULLS FROM DB
      if (mounted) setState(() {});
    });
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'healthy') return AppColors.success;
    if (s.contains('attention')) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final store = AuthStore.instance;
    final name = store.name ?? 'User';
    final email = store.email ?? 'Not signed in';
    final age = store.age ?? 'Not set';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    final records = ScanHistoryStore.instance.records;
    final recentRecords = records.take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Welcome back,', style: TextStyle(fontSize: 16, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              Text(name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5)),
              const SizedBox(height: 24),

              // Profile Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                child: Row(
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, Color(0xFF2563EB)]), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(email, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                          const SizedBox(height: 2),
                          Text('Age: $age', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Scan CTA
              InkWell(
                onTap: () => Navigator.pushNamed(context, '/chat'),
                borderRadius: BorderRadius.circular(20),
                child: Ink(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [AppColors.primary, Color(0xFF2563EB)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Start New Scan', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                            SizedBox(height: 4),
                            Text('Capture 4 images to check for signs of anemia.', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Recent History
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Scans', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                  if (records.isNotEmpty)
                    TextButton(onPressed: () => Navigator.pushNamed(context, '/history'), child: const Text('View All')),
                ],
              ),
              const SizedBox(height: 8),

              if (recentRecords.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                  child: const Column(
                    children: [
                      Icon(Icons.history_rounded, size: 40, color: AppColors.border),
                      SizedBox(height: 12),
                      Text('No scans yet', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                      SizedBox(height: 4),
                      Text('Your scan history will appear here.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                )
              else
                ...recentRecords.map((r) => _buildHistoryCard(r)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(ScanRecord r) {
    final statusColor = _statusColor(r.summary.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.pushNamed(context, '/results', arguments: {'predictions': r.toApiShape(), 'screening': r.screening}),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 48, height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(width: 48, height: 48, child: CircularProgressIndicator(value: r.summary.score / 100, strokeWidth: 4, backgroundColor: AppColors.border, valueColor: AlwaysStoppedAnimation(statusColor), strokeCap: StrokeCap.round)),
                      Text('${r.summary.score}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.dateLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('${r.predictions.length} markers • ${r.summary.status}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}