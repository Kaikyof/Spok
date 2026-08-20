import 'package:flutter/material.dart';

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_text_styles.dart';
import 'section_card.dart';

/// Плашка следующего шага: одна на экран, с командой и объяснением почему.
class NextStepBanner extends StatelessWidget {
  final String title;
  final String reason;
  final String command;

  const NextStepBanner({
    super.key,
    required this.title,
    required this.reason,
    required this.command,
  });

  @override
  Widget build(BuildContext context) => SectionCard(
        color: AppColors.accentDim,
        borderColor: AppColors.accentDimBorder,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: [
            const Text('→',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.rowTitle),
                  const SizedBox(height: 3),
                  Text(reason, style: AppTextStyles.hint),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SelectableText(command, style: AppTextStyles.monospace(12)),
          ],
        ),
      );
}
