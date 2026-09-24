import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_dimens.dart';
import '../../core/resources/app_text_styles.dart';
import '../../domain/entities/env_check.dart';
import '../../domain/entities/env_task.dart';
import '../../domain/entities/secret_backend.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bloc/console_bloc.dart';
import '../localization/text_formatters.dart';
import '../ui_kit/check_row.dart';
import '../bloc/sessions_bloc.dart';
import '../ui_kit/section_card.dart';
import '../ui_kit/tappable.dart';
import '../ui_kit/skeleton.dart';
import '../widgets/env_editor_dialog.dart';

/// Экран «Окружение»: поймать проблему до запуска, а не в середине.
class EnvScreen extends StatelessWidget {
  const EnvScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return BlocBuilder<ConsoleBloc, ConsoleState>(
      builder: (context, state) {
        final envReport = state.snapshot?.env;
        if (envReport == null) return const _EnvSkeleton();
        return ListView(
          padding: AppDimens.screenPadding,
          children: [
            _EnvHeader(problemCount: envReport.problemCount),
            const SizedBox(height: AppDimens.gapL),
            _CheckSection(
                title: texts.envKeysSection,
                checks: envReport.keys,
                detailFromHint: true,
                task: EnvTask.keys,
                footer: _SecretBackendNote(backend: envReport.backend)),
            const SizedBox(height: AppDimens.gapM),
            _CheckSection(
                title: texts.envReposSection,
                checks: envReport.repos,
                task: EnvTask.repos),
            const SizedBox(height: AppDimens.gapM),
            _CheckSection(
                title: texts.envSystemsSection,
                checks: envReport.systems,
                task: EnvTask.systems,
                monospacedNames: false),
          ],
        );
      },
    );
  }
}

/// Первая загрузка: три секции проверок той же высоты и в тех же местах.
class _EnvSkeleton extends StatelessWidget {
  const _EnvSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
        padding: AppDimens.screenPadding,
        children: [
          const SizedBox(
            height: 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLine(width: 120),
                      SizedBox(height: AppDimens.gapS),
                      SkeletonLine(width: 180, height: 9),
                    ],
                  ),
                ),
                SkeletonLine(width: 130, height: 30),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.gapL),
          for (final rows in [4, 2, 3]) ...[
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonLine(width: 220),
                  const SizedBox(height: AppDimens.gapS),
                  for (var row = 0; row < rows; row++)
                    SkeletonRow(
                      columnFlex: const [50, 30],
                      widthFactors: const [0.6, 0.8],
                      showTopDivider: row > 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.gapM),
          ],
        ],
      );
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
              Text(
                texts.envTitle,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppDimens.gapXs),
              Text(
                problemCount == 0 ? texts.envAllGood : texts.envProblems(problemCount),
                style: TextStyle(fontSize: 12, color: problemCount == 0 ? AppColors.success : AppColors.danger),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: () => EnvEditorDialog.show(context),
          icon: const Icon(Icons.key, size: 15),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.background,
          ),
          label: Text(texts.envEditOpen,
              style: const TextStyle(fontSize: 12)),
        ),
        const SizedBox(width: AppDimens.gapS),
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

/// Где лежат секреты: связка ключей или файл. Умолчание здесь читается
/// как обман — человек вправе знать, куда уйдёт введённый токен.
class _SecretBackendNote extends StatelessWidget {
  final SecretBackend backend;

  const _SecretBackendNote({required this.backend});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final keyring = backend.isKeyring;
    return Row(
      children: [
        Icon(keyring ? Icons.lock_outline : Icons.folder_outlined,
            size: 14,
            color: keyring ? AppColors.textMuted : AppColors.warning),
        const SizedBox(width: AppDimens.gapS),
        Expanded(
          child: Text(texts.secretBackendNote(backend),
              style: TextStyle(
                  fontSize: 11.5,
                  color: keyring ? AppColors.textMuted : AppColors.warning)),
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

  /// Раздел окружения: по нему подбирается команда спеки, которой эта
  /// нехватка лечится.
  final EnvTask task;

  /// Строка под списком: у ключей это пометка о хранилище секретов.
  final Widget? footer;

  const _CheckSection({required this.title, required this.checks, required this.task, this.monospacedNames = true, this.detailFromHint = false, this.footer});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppTextStyles.sectionTitle)),
              _TaskCommandButton(task: task),
            ],
          ),
          const SizedBox(height: AppDimens.gapS),
          for (final (index, check) in checks.indexed) ...[
            if (index > 0) const Divider(height: 1),
            CheckRow(
              level: check.level,
              name: check.name,
              // Подсказку пишет сама спека в .env.example; своя —
              // только для ключей, которые она не прокомментировала.
              detail: detailFromHint && check.subtitle.isEmpty
                  ? texts.envKeyHint(check.name)
                  : check.subtitle,
              result: texts.checkResultText(check),
              monospacedName: monospacedNames,
            ),
          ],
          if (footer case final note?) ...[
            const SizedBox(height: AppDimens.gapM),
            note,
          ],
        ],
      ),
    );
  }
}

/// Команда спеки, которой лечится нехватка этого раздела: у одной спеки
/// это `make init`, у другой `pnpm workspace:init`, у третьей — ничего.
/// Поэтому имя команды не зашито, а взято из распознанных, и кнопки нет
/// вовсе, когда спека такой команды не объявляет.
class _TaskCommandButton extends StatelessWidget {
  final EnvTask task;

  const _TaskCommandButton({required this.task});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return BlocBuilder<ConsoleBloc, ConsoleState>(
      buildWhen: (previous, current) => previous.profile != current.profile,
      builder: (context, state) {
        final command = state.profile.envCommands[task];
        if (command == null) return const SizedBox.shrink();
        return Tappable(
          // Выполняем не мы: команда уходит в сессию, где виден её вывод
          // и код возврата.
          onTap: () {
            context
                .read<SessionsBloc>()
                .add(SessionDraftSet(command.invocation));
            context
                .read<ConsoleBloc>()
                .add(ScreenSelected(ConsoleScreen.sessions));
          },
          borderRadius: BorderRadius.circular(AppDimens.controlRadius),
          tooltip: command.description.isEmpty
              ? texts.envTaskCommandTooltip
              : '${command.description}\n${texts.envTaskCommandTooltip}',
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.cardHighlight,
              borderRadius: BorderRadius.circular(AppDimens.controlRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_arrow,
                    size: 14, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(command.invocation,
                    style: AppTextStyles.monospace(11.5,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
        );
      },
    );
  }
}
