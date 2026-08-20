import 'package:flutter/material.dart';

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_text_styles.dart';

/// Индикатор отметок «10/11»: важна не доля, а какая задача не закрыта.
class MarksIndicator extends StatelessWidget {
  final int doneCount;
  final int totalCount;
  final bool diverged;
  final String? openTaskLabel; // «открыта 3.3»
  final String? tooltip;

  const MarksIndicator({
    super.key,
    required this.doneCount,
    required this.totalCount,
    this.diverged = false,
    this.openTaskLabel,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final incomplete = doneCount < totalCount;
    final color = diverged || incomplete
        ? AppColors.warning
        : AppColors.textSecondary;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$doneCount/$totalCount',
                style: AppTextStyles.monospace(12.5,
                    color: color, weight: FontWeight.w500)),
            if (diverged) ...const [
              SizedBox(width: 5),
              Icon(Icons.warning_amber_rounded,
                  size: 14, color: AppColors.warning),
            ],
          ],
        ),
        if (openTaskLabel != null)
          Text(openTaskLabel!,
              style:
                  const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
      ],
    );
    if (tooltip == null) return content;
    return Tooltip(message: tooltip!, child: content);
  }
}
