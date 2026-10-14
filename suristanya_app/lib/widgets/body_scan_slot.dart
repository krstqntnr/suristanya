import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/body_scan.dart';
import '../theme/app_theme.dart';

class BodyScanSlot extends StatelessWidget {
  final int index;
  final BodyPart part;
  final XFile? image;
  final VoidCallback onTap;

  const BodyScanSlot({
    super.key,
    required this.index,
    required this.part,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = image != null;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasImage ? AppColors.accent : AppColors.border,
              width: hasImage ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Numbered badge
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$index',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (hasImage)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Image / icon area
              Expanded(
                child: Center(
                  child: hasImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: kIsWeb
                              ? Image.network(image!.path, fit: BoxFit.cover)
                              : Image.file(
                                  File(image!.path),
                                  fit: BoxFit.cover,
                                ),
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _iconForPart(part),
                            color: AppColors.accentDark,
                            size: 28,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),

              Text(
                part.label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hasImage ? 'Tap to retake' : 'Take photo / Upload',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForPart(BodyPart part) {
    switch (part) {
      case BodyPart.tongue:
        return Icons.sentiment_satisfied_alt_rounded;
      case BodyPart.palm:
        return Icons.back_hand_rounded;
      case BodyPart.nail:
        return Icons.ads_click_rounded;
      case BodyPart.eye:
        return Icons.remove_red_eye_rounded;
    }
  }
}
