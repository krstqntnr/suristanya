import 'package:flutter/material.dart';

import '../services/health_service.dart';
import '../theme/app_theme.dart';

/// Wraps the whole app and shows a red banner at the top
/// when the Flask backend is unreachable.
class ConnectionBanner extends StatefulWidget {
  final Widget child;
  const ConnectionBanner({super.key, required this.child});

  @override
  State<ConnectionBanner> createState() => _ConnectionBannerState();
}

class _ConnectionBannerState extends State<ConnectionBanner> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HealthService.instance.start();
    });
  }

  @override
  void dispose() {
    HealthService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ValueListenableBuilder<BackendStatus>(
            valueListenable: HealthService.instance.status,
            builder: (context, status, _) {
              final offline = status == BackendStatus.offline;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: offline
                    ? _buildBanner()
                    : const SizedBox.shrink(key: ValueKey('online')),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBanner() {
    return Material(
      key: const ValueKey('offline'),
      color: AppColors.danger,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Backend offline — some features may not work',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => HealthService.instance.checkNow(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
