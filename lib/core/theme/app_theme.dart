import 'package:flutter/material.dart';

import '../resources/app_colors.dart';

abstract class AppTheme {
  /// Подсветка кнопок под курсором. Своя, потому что подсветка по умолчанию
  /// берётся от цвета текста кнопки с прозрачностью 8 % — на тёмном фоне
  /// её попросту не видно, и кнопка не отвечает на наведение ничем.
  /// Цвет тот же, что у `Tappable`: одно приложение — одна подсветка.
  static final _overlay = WidgetStateProperty.resolveWith<Color?>(
    (states) => states.contains(WidgetState.hovered)
        ? AppColors.hoverOverlay
        : null,
  );

  static final ButtonStyle _buttonStyle = ButtonStyle(overlayColor: _overlay);

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
        outlinedButtonTheme: OutlinedButtonThemeData(style: _buttonStyle),
        textButtonTheme: TextButtonThemeData(style: _buttonStyle),
        filledButtonTheme: FilledButtonThemeData(style: _buttonStyle),
        elevatedButtonTheme: ElevatedButtonThemeData(style: _buttonStyle),
        iconButtonTheme: IconButtonThemeData(style: _buttonStyle),
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
