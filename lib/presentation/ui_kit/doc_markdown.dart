import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_dimens.dart';
import '../../core/resources/app_text_styles.dart';

/// Рендер markdown-документа спеки в оформлении макета.
/// Один и тот же вид в карточке change'а и на экране «Документы»:
/// документ должен читаться одинаково, откуда бы его ни открыли.
class DocMarkdown extends StatelessWidget {
  final String data;
  final EdgeInsets padding;

  const DocMarkdown({
    super.key,
    required this.data,
    this.padding = const EdgeInsets.all(AppDimens.gapXl),
  });

  @override
  Widget build(BuildContext context) =>
      Markdown(data: data, padding: padding, styleSheet: styleSheet);

  static MarkdownStyleSheet get styleSheet => MarkdownStyleSheet(
        p: AppTextStyles.body.copyWith(height: 1.5),
        h1: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary),
        h2: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
        h3: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
        code: AppTextStyles.monospace(12),
        codeblockDecoration: BoxDecoration(
            color: AppColors.logBackground,
            borderRadius: BorderRadius.circular(AppDimens.controlRadius)),
        listBullet: AppTextStyles.body,
        blockquoteDecoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppDimens.controlRadius),
          border:
              const Border(left: BorderSide(color: AppColors.accent, width: 3)),
        ),
        tableBorder: TableBorder.all(color: AppColors.borderSoft),
        tableBody: AppTextStyles.caption,
      );
}
