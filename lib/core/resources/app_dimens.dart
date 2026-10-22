import 'package:flutter/material.dart';

/// Размеры и отступы. Раскладка обязана переживать узкую ширину (бриф §9).
abstract class AppDimens {
  static const minWindowSize = Size(1100, 700);
  static const defaultWindowSize = Size(1280, 800);

  static const sidebarWidth = 216.0;
  static const headerHeight = 88.0;

  static const screenPadding = EdgeInsets.all(24);
  static const cardPadding = EdgeInsets.all(16);

  static const cardRadius = 9.0;
  static const controlRadius = 7.0;

  static const gapXs = 4.0;
  static const gapS = 8.0;
  static const gapM = 16.0;
  static const gapL = 20.0;
  static const gapXl = 24.0;

  /// Зазор между бейджами одной ячейки: стадия, ярлык трекера, ссылка.
  static const badgeGap = 3.0;

  /// Колонка стадии и статуса в строке списка change'ей.
  static const stackStatusWidth = 260.0;

  /// Плашка следующего шага: внутренний отступ и зазоры вокруг стрелки.
  static const bannerPadding = EdgeInsets.symmetric(horizontal: 18, vertical: 12);
  static const bannerArrowGap = 14.0;
}
