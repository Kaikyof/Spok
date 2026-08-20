import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Типографика: интерфейсный шрифт — системный, моноширинный — для команд,
/// идентификаторов, веток и логов (бриф §9).
abstract class AppTextStyles {
  static const monospaceFamily = 'Menlo';

  static TextStyle monospace(
    double size, {
    Color color = AppColors.monospaceText,
    FontWeight? weight,
  }) =>
      TextStyle(
        fontFamily: monospaceFamily,
        fontSize: size,
        color: color,
        fontWeight: weight,
      );

  static const screenTitle = TextStyle(
      fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  static const sectionTitle = TextStyle(
      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  static const sectionLabel = TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w600,
      letterSpacing: 1,
      color: AppColors.textMuted);

  static const rowTitle = TextStyle(
      fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary);

  static const body = TextStyle(fontSize: 13, color: AppColors.textSecondary);

  static const caption = TextStyle(fontSize: 12, color: AppColors.textSecondary);

  static const captionMuted = TextStyle(fontSize: 12, color: AppColors.textMuted);

  static const hint = TextStyle(fontSize: 11.5, color: AppColors.textMuted);
}
