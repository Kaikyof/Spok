import 'package:flutter/material.dart';

import '../resources/app_colors.dart';

abstract class AppTheme {
  static ThemeData dark() => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: '.AppleSystemUIFont',
        colorScheme: const ColorScheme.dark(
          surface: AppColors.background,
          primary: AppColors.accent,
          error: AppColors.danger,
        ),
        dividerColor: AppColors.borderSoft,
        splashFactory: NoSplash.splashFactory,
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: AppColors.cardHighlight,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          textStyle:
              const TextStyle(fontSize: 12, color: AppColors.textPrimary),
        ),
      );
}
