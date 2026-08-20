import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_dimens.dart';
import '../../core/resources/app_text_styles.dart';

/// Ответы агента приходят markdown'ом: списки, код и ссылки должны
/// выглядеть и работать как текст, а не как строка с решётками.
class AgentMarkdown extends StatelessWidget {
  final String data;
  final Color textColor;

  const AgentMarkdown({
    super.key,
    required this.data,
    this.textColor = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) => MarkdownBody(
        data: data,
        selectable: true,
        onTapLink: (text, href, title) {
          if (href != null) launchUrl(Uri.parse(href));
        },
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(fontSize: 12.5, color: textColor, height: 1.5),
          a: const TextStyle(
              fontSize: 12.5,
              color: AppColors.accent,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.accent),
          h1: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
          h2: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
          h3: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
          strong: TextStyle(
              fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          code: AppTextStyles.monospace(11.5),
          codeblockPadding: const EdgeInsets.all(10),
          codeblockDecoration: BoxDecoration(
              color: AppColors.logBackground,
              borderRadius: BorderRadius.circular(AppDimens.controlRadius)),
          listBullet: TextStyle(fontSize: 12.5, color: textColor),
          blockquoteDecoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppDimens.controlRadius),
            border:
                const Border(left: BorderSide(color: AppColors.accent, width: 3)),
          ),
          tableBorder: TableBorder.all(color: AppColors.borderSoft),
          tableBody: TextStyle(fontSize: 11.5, color: textColor),
          horizontalRuleDecoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderSoft))),
        ),
      );
}
