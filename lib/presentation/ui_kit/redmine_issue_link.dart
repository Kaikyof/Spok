import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_text_styles.dart';
import 'tappable.dart';

/// Кликабельный номер задачи Redmine: «#63577 ↗».
class RedmineIssueLink extends StatelessWidget {
  final int? issueId;
  final String baseUrl;
  final String tooltip;
  final double fontSize;

  const RedmineIssueLink({
    super.key,
    required this.issueId,
    required this.baseUrl,
    required this.tooltip,
    this.fontSize = 10.5,
  });

  bool get _clickable => issueId != null && baseUrl.isNotEmpty;

  void _open() =>
      launchUrl(Uri.parse('$baseUrl/issues/$issueId'));

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
