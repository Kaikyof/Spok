import 'package:flutter/material.dart';

import '../../domain/entities/work_stage.dart';

/// Палитра из Penpot-макета «Platform Console» (тёмная тема).
abstract class AppColors {
  static const background = Color(0xFF111318);
  static const panel = Color(0xFF171A20);
  static const card = Color(0xFF1E222A);
  static const cardHighlight = Color(0xFF242933);
  static const border = Color(0xFF2C323D);
  static const borderSoft = Color(0xFF252A33);
  static const textPrimary = Color(0xFFE8EBF1);
  static const textSecondary = Color(0xFFA6AEBC);
  static const textMuted = Color(0xFF6E7683);
  static const accent = Color(0xFF5B9BFF);
  static const accentDim = Color(0xFF22314A);
  static const accentDimBorder = Color(0xFF31456B);
  static const warning = Color(0xFFE8B33F);
  static const warningBackground = Color(0xFF2B2414);
  static const warningBorder = Color(0xFF5C4A1E);
  static const danger = Color(0xFFE06A55);
  static const success = Color(0xFF5FBF8A);
  static const monospaceText = Color(0xFFC9D4E3);
  static const logBackground = Color(0xFF0C0E12);

  /// Плёнка под курсором: единственная подсветка наведения на всё
  /// приложение. Светлая и слабая — на тёмном фоне этого хватает, чтобы
  /// строка «ожила», и не хватает, чтобы перебить её содержимое.
  static const hoverOverlay = Color(0x14FFFFFF);

  // Статусная шкала — по стадии, не по «хорошо/плохо». Имена статусов
  // Redmine на неё кладёт адаптер (`redmine_status_colors.dart`).
  static const statusNew = Color(0xFF8B93A3);
  static const statusInProgress = Color(0xFF5B9BFF);
  static const statusInReview = Color(0xFF9B7BFF);
  static const statusReviewDone = Color(0xFF7FA6E8);
  static const statusWaitingTest = Color(0xFF3FB6C9);
  static const statusTesting = Color(0xFF43C98F);
  static const statusReadyToRelease = Color(0xFF5FBF8A);
  static const statusReturned = Color(0xFFE8B33F);

  /// Цвет точки стадии работы: та же шкала, что у статусов, — стадия
  /// описывает ход работы по файлам и есть у любой спеки.
  static Color forStage(WorkStage stage) => switch (stage) {
        PlanningStage() => statusNew,
        ReadyToApplyStage() => statusReviewDone,
        InProgressStage() => statusInProgress,
        DoneStage() => statusReadyToRelease,
        ArchivedStage() => textMuted,
      };
}
