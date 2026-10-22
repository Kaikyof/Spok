import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_text_styles.dart';
import 'tappable.dart';

/// Кликабельный номер задачи трекера: «#63577 ↗». Адрес даёт контракт
/// трекера, а не экран: ссылка не собирается из ключа `*_URL` здесь.
class IssueLink extends StatelessWidget {
  final int? issueId;

  /// Адрес задачи; null — системы нет или адрес не задан, номер без ссылки.
  final String? url;
  final String tooltip;
  final double fontSize;

  const IssueLink({
    super.key,
    required this.issueId,
    required this.url,
    required this.tooltip,
    this.fontSize = AppTextStyles.fontSizeXs,
  });

  bool get _clickable => issueId != null && (url?.isNotEmpty ?? false);

  void _open() => launchUrl(Uri.parse(url!));

  @override
  Widget build(BuildContext context) {
    final label = Text(
      _clickable ? '#$issueId ↗' : '#${issueId ?? '—'}',
      style: AppTextStyles.monospace(fontSize,
          color: _clickable ? AppColors.accent : AppColors.textMuted),
    );
    if (!_clickable) return label;
    return Tooltip(
      message: tooltip,
      child: Tappable(
          onTap: _open, effect: HoverEffect.underline, child: label),
    );
  }
}
