import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_dimens.dart';
import '../../core/resources/app_text_styles.dart';
import '../../domain/entities/env_check.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bloc/console_bloc.dart';
import '../localization/text_formatters.dart';
import '../ui_kit/check_row.dart';
import '../ui_kit/section_card.dart';

/// Экран «Окружение»: поймать проблему до запуска, а не в середине.
class EnvScreen extends StatelessWidget {
  const EnvScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return BlocBuilder<ConsoleBloc, ConsoleState>(
      builder: (context, state) {
        final envReport = state.snapshot?.env;
        if (envReport == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: AppDimens.screenPadding,
          children: [
            _EnvHeader(problemCount: envReport.problemCount),
            const SizedBox(height: AppDimens.gapL),
            _CheckSection(
                title: texts.envKeysSection,
                checks: envReport.keys,
                detailFromHint: true),
            const SizedBox(height: AppDimens.gapM),
            _CheckSection(title: texts.envReposSection, checks: envReport.repos),
            const SizedBox(height: AppDimens.gapM),
            _CheckSection(
                title: texts.envSystemsSection,
                checks: envReport.systems,
                monospacedNames: false),
          ],
        );
      },
    );
  }
}

class _EnvHeader extends StatelessWidget {
  final int problemCount;

  const _EnvHeader({required this.problemCount});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(texts.envTitle,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: AppDimens.gapXs),
              Text(
                problemCount == 0
                    ? texts.envAllGood
                    : texts.envProblems(problemCount),
                style: TextStyle(
                    fontSize: 12,
                    color: problemCount == 0
                        ? AppColors.success
                        : AppColors.danger),
              ),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: () => context.read<ConsoleBloc>().add(ConsoleRefreshed()),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.border),
            backgroundColor: AppColors.cardHighlight,
            foregroundColor: AppColors.textPrimary,
          ),
          child: Text(texts.envRecheck, style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}

class _CheckSection extends StatelessWidget {
  final String title;
  final List<EnvCheck> checks;
  final bool monospacedNames;
  final bool detailFromHint;

  const _CheckSection({
    required this.title,
    required this.checks,
    this.monospacedNames = true,
    this.detailFromHint = false,
  });

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppDimens.gapS),
          for (final (index, check) in checks.indexed) ...[
            if (index > 0) const Divider(height: 1),
            CheckRow(
              level: check.level,
              name: check.name,
              detail: detailFromHint
                  ? texts.envKeyHint(check.name)
                  : check.subtitle,
              result: texts.checkResultText(check),
              monospacedName: monospacedNames,
            ),
          ],
        ],
      ),
    );
  }
}
