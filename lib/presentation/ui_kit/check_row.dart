import 'package:flutter/material.dart';

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_text_styles.dart';
import '../../domain/entities/env_check.dart';

/// Строка проверки окружения: точка состояния, имя, пояснение, результат.
/// Все тексты приходят готовыми — компонент не знает о локализации.
class CheckRow extends StatelessWidget {
  final CheckLevel level;
  final String name;
  final String detail;
  final String result;
  final bool monospacedName;

  const CheckRow({
    super.key,
    required this.level,
    required this.name,
    required this.detail,
    required this.result,
    this.monospacedName = true,
  });

  Color get _levelColor => switch (level) {
        CheckLevel.ok => AppColors.success,
        CheckLevel.warn => AppColors.warning,
        CheckLevel.error => AppColors.danger,
      };

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration:
                  BoxDecoration(color: _levelColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 280,
              child: Text(
                name,
                style: monospacedName
                    ? AppTextStyles.monospace(12.5,
                        color: AppColors.textPrimary, weight: FontWeight.w500)
                    : AppTextStyles.rowTitle,
              ),
            ),
            Expanded(child: Text(detail, style: AppTextStyles.caption)),
            Text(
              result,
              style: TextStyle(
                fontSize: 11.5,
                color: level == CheckLevel.ok ? AppColors.textMuted : _levelColor,
                fontWeight:
                    level == CheckLevel.ok ? FontWeight.w400 : FontWeight.w500,
              ),
            ),
          ],
        ),
      );
}
