import 'package:flutter/material.dart';

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_dimens.dart';
import '../../core/resources/app_text_styles.dart';
import 'section_card.dart';

/// Плашка следующего шага: одна на экран, с командой и объяснением почему.
class NextStepBanner extends StatelessWidget {
  final String title;
  final String reason;

  /// Команда спеки для шага; null — спека такой команды не объявляет,
  /// и плашка называет шаг без неё.
  final String? command;

  const NextStepBanner({super.key, required this.title, required this.reason, this.command});

  @override
  Widget build(BuildContext context) => SectionCard(
    color: AppColors.accentDim,
    borderColor: AppColors.accentDimBorder,
    padding: AppDimens.bannerPadding,
    child: Row(
      children: [
        const Text('→', style: AppTextStyles.bannerArrow),
        const SizedBox(width: AppDimens.bannerArrowGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.rowTitle),
              const SizedBox(height: AppDimens.badgeGap),
              Text(reason, style: AppTextStyles.hint),
            ],
          ),
        ),
        if (command case final line? when line.isNotEmpty) ...[
          const SizedBox(width: AppDimens.gapM),
          SelectableText(line, style: AppTextStyles.monospace(AppTextStyles.fontSizeM)),
        ],
      ],
    ),
  );
}
