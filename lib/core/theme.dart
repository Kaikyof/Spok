import 'package:flutter/material.dart';

/// Палитра из Penpot-макета «Platform Console» (тёмная тема).
abstract class C {
  static const bg = Color(0xFF111318);
  static const panel = Color(0xFF171A20);
  static const card = Color(0xFF1E222A);
  static const cardHi = Color(0xFF242933);
  static const border = Color(0xFF2C323D);
  static const borderSoft = Color(0xFF252A33);
  static const text = Color(0xFFE8EBF1);
  static const text2 = Color(0xFFA6AEBC);
  static const text3 = Color(0xFF6E7683);
  static const accent = Color(0xFF5B9BFF);
  static const accentDim = Color(0xFF22314A);
  static const warn = Color(0xFFE8B33F);
  static const warnBg = Color(0xFF2B2414);
  static const warnBorder = Color(0xFF5C4A1E);
  static const danger = Color(0xFFE06A55);
  static const ok = Color(0xFF5FBF8A);
  static const mono = Color(0xFFC9D4E3);
  static const logBg = Color(0xFF0C0E12);

  // Статусная шкала Redmine — по стадии, не по «хорошо/плохо».
  static const stNew = Color(0xFF8B93A3);
  static const stWork = Color(0xFF5B9BFF);
  static const stReview = Color(0xFF9B7BFF);
  static const stReviewDone = Color(0xFF7FA6E8);
  static const stWaitTest = Color(0xFF3FB6C9);
  static const stTesting = Color(0xFF43C98F);
  static const stRelease = Color(0xFF5FBF8A);
  static const stReturned = Color(0xFFE8B33F);

  static Color statusColor(String status) => switch (status) {
        'Новая' => stNew,
        'В работе' => stWork,
        'На ревью' => stReview,
        'Ревью завершено' => stReviewDone,
        'Ожидает тестирования' => stWaitTest,
        'На тестировании' => stTesting,
        'Готово к релизу' => stRelease,
        'Возвращена с ревью' || 'Возвращена' => stReturned,
        _ => stNew,
      };
}

const monoFamily = 'Menlo';

TextStyle mono(double size, {Color color = C.mono, FontWeight? weight}) =>
    TextStyle(fontFamily: monoFamily, fontSize: size, color: color, fontWeight: weight);

ThemeData buildTheme() => ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: C.bg,
      fontFamily: '.AppleSystemUIFont',
      colorScheme: const ColorScheme.dark(
        surface: C.bg,
        primary: C.accent,
        error: C.danger,
      ),
      dividerColor: C.borderSoft,
      splashFactory: NoSplash.splashFactory,
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: C.cardHi,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: C.border),
        ),
        textStyle: const TextStyle(fontSize: 12, color: C.text),
      ),
    );
