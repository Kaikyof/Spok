import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_dimens.dart';
import '../../core/resources/app_text_styles.dart';
import '../../domain/entities/change_unit.dart';
import '../../domain/entities/console_snapshot.dart';
import '../../domain/entities/divergence.dart';
import '../../domain/entities/stack_state.dart';
import '../../domain/entities/task_item.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bloc/console_bloc.dart';
import '../localization/text_formatters.dart';
import '../ui_kit/marks_indicator.dart';
import '../ui_kit/next_step_banner.dart';
import '../ui_kit/redmine_issue_link.dart';
import '../ui_kit/section_card.dart';
import '../ui_kit/stack_filter_control.dart';
import '../ui_kit/status_badge.dart';
import '../widgets/create_change_dialog.dart';
import '../widgets/create_sprint_dialog.dart';

/// Главный экран: за пять секунд показать, где спринт и что мешает.
class SprintScreen extends StatelessWidget {
  const SprintScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return BlocBuilder<ConsoleBloc, ConsoleState>(
      builder: (context, state) {
        final snapshot = state.snapshot;
        if (snapshot == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final sprintChanges = state.sprintChanges;
        if (snapshot.sprints.isEmpty) {
          return Center(
            child: Text(texts.sprintEmpty,
                textAlign: TextAlign.center, style: AppTextStyles.body),
          );
        }
        if (sprintChanges.isEmpty) {
          return _EmptySprint(sprintTitle: state.sprint?.title ?? '');
        }
        final filter = state.stackFilter;
        final visibleDivergences = snapshot.divergences
            .where((divergence) => filter.allows(divergence.stack))
            .toList();
        return ListView(
          padding: AppDimens.screenPadding,
          children: [
            const _FilterRow(),
            const SizedBox(height: AppDimens.gapM),
            if (snapshot.redmineProblem != RedmineProblem.none) ...[
              _RedmineUnavailableBar(snapshot: snapshot),
              const SizedBox(height: AppDimens.gapM),
            ],
            if (visibleDivergences.isNotEmpty) ...[
              _DivergenceBlock(divergences: visibleDivergences),
              const SizedBox(height: AppDimens.gapL),
            ],
            _ChangesTable(
              changes: sprintChanges,
              divergences: snapshot.divergences,
              filter: filter,
              redmineBaseUrl: snapshot.redmineBaseUrl,
            ),
            const SizedBox(height: AppDimens.gapL),
            _NextStepSection(changes: sprintChanges, filter: filter),
          ],
        );
      },
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow();

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return BlocBuilder<ConsoleBloc, ConsoleState>(
      buildWhen: (previous, current) =>
          previous.stackFilter != current.stackFilter,
      builder: (context, state) => Row(
        children: [
          OutlinedButton.icon(
            onPressed: () => CreateSprintDialog.show(context),
            icon: const Icon(Icons.add, size: 15, color: AppColors.accent),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              backgroundColor: AppColors.card,
              foregroundColor: AppColors.textPrimary,
            ),
            label: Text(texts.sprintCreateTitle,
                style: const TextStyle(fontSize: 12)),
          ),
          const Spacer(),
          StackFilterControl<StackFilter>(
            options: [
              (StackFilter.all, texts.stackFilterAll),
              (StackFilter.ios, texts.stackIos),
              (StackFilter.android, texts.stackAndroid),
            ],
            selected: state.stackFilter,
            onChanged: (filter) =>
                context.read<ConsoleBloc>().add(StackFilterChanged(filter)),
          ),
        ],
      ),
    );
  }
}

/// Спринт создан, но change'ей ещё нет: объясняем и даём первый шаг,
/// а не показываем пустую таблицу (бриф §8, состояние «Пусто»).
class _EmptySprint extends StatelessWidget {
  final String sprintTitle;

  const _EmptySprint({required this.sprintTitle});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(texts.sprintNoChanges(sprintTitle),
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppDimens.gapS),
            Text(texts.sprintNoChangesHint,
                textAlign: TextAlign.center,
                style: AppTextStyles.captionMuted.copyWith(height: 1.5)),
            const SizedBox(height: AppDimens.gapL),
            FilledButton.icon(
              onPressed: () => CreateChangeDialog.show(
                  context, context.read<ConsoleBloc>().state.sprint?.id ?? ''),
              icon: const Icon(Icons.add, size: 16),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background),
              label: Text(texts.sprintCreateChange),
            ),
          ],
        ),
      ),
    );
  }
}

class _RedmineUnavailableBar extends StatelessWidget {
  final ConsoleSnapshot snapshot;

  const _RedmineUnavailableBar({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final reason = switch (snapshot.redmineProblem) {
      RedmineProblem.noApiKey => texts.redmineNoKey,
      RedmineProblem.platformNotFound => texts.platformRepoNotFound,
      _ => snapshot.redmineProblemDetail,
    };
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texts.redmineUnavailable(reason),
                style: AppTextStyles.caption),
          ),
        ],
      ),
    );
  }
}

class _DivergenceBlock extends StatelessWidget {
  final List<Divergence> divergences;

  const _DivergenceBlock({required this.divergences});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return SectionCard(
      color: AppColors.warningBackground,
      borderColor: AppColors.warningBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 17, color: AppColors.warning),
              const SizedBox(width: 10),
              Text(texts.divergencesTitle(divergences.length),
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning)),
            ],
          ),
          const SizedBox(height: AppDimens.gapS),
          for (final divergence in divergences)
            Padding(
              padding: const EdgeInsets.only(left: 27, top: 4),
              child: Text(
                '${divergence.changeTitle} — '
                '${texts.stackLabel(divergence.stack)}: '
                '${texts.divergenceText(divergence)}',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textPrimary),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChangesTable extends StatelessWidget {
  final List<ChangeUnit> changes;
  final List<Divergence> divergences;
  final StackFilter filter;
  final String redmineBaseUrl;

  const _ChangesTable({
    required this.changes,
    required this.divergences,
    required this.filter,
    required this.redmineBaseUrl,
  });

  bool _hasDivergence(ChangeUnit change, String stack) => divergences.any(
      (divergence) =>
          divergence.changeId == change.id && divergence.stack == stack);

  @override
  Widget build(BuildContext context) => SectionCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _TableHeader(filter: filter),
            for (final (index, change) in changes.indexed)
              _ChangeRow(
                change: change,
                filter: filter,
                redmineBaseUrl: redmineBaseUrl,
                showTopDivider: index > 0,
                iosDiverged: _hasDivergence(change, 'ios'),
                androidDiverged: _hasDivergence(change, 'android'),
              ),
          ],
        ),
      );
}

class _TableHeader extends StatelessWidget {
  final StackFilter filter;

  const _TableHeader({required this.filter});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borderSoft))),
      child: Row(
        children: [
          Expanded(
              flex: 42,
              child: Text(texts.tableHeaderChange,
                  style: AppTextStyles.sectionLabel)),
          if (filter.allows('ios'))
            Expanded(
                flex: filter == StackFilter.all ? 29 : 58,
                child: Text(texts.tableHeaderIos,
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary))),
          if (filter.allows('android'))
            Expanded(
                flex: filter == StackFilter.all ? 29 : 58,
                child: Text(texts.tableHeaderAndroid,
                    style: AppTextStyles.sectionLabel
                        .copyWith(color: AppColors.textSecondary))),
        ],
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  final ChangeUnit change;
  final StackFilter filter;
  final String redmineBaseUrl;
  final bool showTopDivider;
  final bool iosDiverged;
  final bool androidDiverged;

  const _ChangeRow({
    required this.change,
    required this.filter,
    required this.redmineBaseUrl,
    required this.showTopDivider,
    required this.iosDiverged,
    required this.androidDiverged,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => context.read<ConsoleBloc>().add(ChangeOpened(change)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: showTopDivider
                ? const Border(top: BorderSide(color: AppColors.borderSoft))
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 42,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(change.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.rowTitle),
                    const SizedBox(height: 3),
                    Text(change.id,
                        style: AppTextStyles.monospace(10.5,
                            color: AppColors.textMuted)),
                  ],
                ),
              ),
              if (filter.allows('ios'))
                Expanded(
                  flex: filter == StackFilter.all ? 29 : 58,
                  child: _StackCell(
                      stack: change.ios,
                      diverged: iosDiverged,
                      redmineBaseUrl: redmineBaseUrl),
                ),
              if (filter.allows('android'))
                Expanded(
                  flex: filter == StackFilter.all ? 29 : 58,
                  child: _StackCell(
                      stack: change.android,
                      diverged: androidDiverged,
                      redmineBaseUrl: redmineBaseUrl),
                ),
            ],
          ),
        ),
      );
}

class _StackCell extends StatelessWidget {
  final StackState? stack;
  final bool diverged;
  final String redmineBaseUrl;

  const _StackCell(
      {required this.stack,
      required this.diverged,
      required this.redmineBaseUrl});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final stackState = stack;
    if (stackState == null) {
      return const Text('—',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12));
    }
    final status = stackState.redmineStatus;
    final openTasks = stackState.openTasks;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusBadge(
                text: status ?? texts.statusUnavailable,
                dotColor: status == null
                    ? AppColors.textMuted
                    : AppColors.forRedmineStatus(status),
                muted: status == null,
              ),
              const SizedBox(height: 3),
              RedmineIssueLink(
                issueId: stackState.issueId,
                baseUrl: redmineBaseUrl,
                tooltip: texts.openInRedmineTooltip,
              ),
            ],
          ),
        ),
        MarksIndicator(
          doneCount: stackState.doneCount,
          totalCount: stackState.tasks.length,
          diverged: diverged,
          openTaskLabel: openTasks.isEmpty
              ? null
              : texts.marksOpenTask(openTasks.first.number),
          tooltip: openTasks.isEmpty
              ? (diverged ? texts.marksTooltipDiverged : null)
              : texts.marksTooltipNotClosed(_openTasksSummary(openTasks)),
        ),
        const SizedBox(width: AppDimens.gapS),
      ],
    );
  }

  String _openTasksSummary(List<TaskItem> openTasks) =>
      openTasks.map((task) => '${task.number} ${task.title}').join('\n');
}

class _NextStepSection extends StatelessWidget {
  final List<ChangeUnit> changes;
  final StackFilter filter;

  const _NextStepSection({required this.changes, required this.filter});

  /// Самая частая незакрытая задача по видимым стекам спринта.
  (TaskItem, int)? _mostFrequentOpenTask() {
    final openTasks = changes
        .expand((change) => change.stacks)
        .where((stack) => filter.allows(stack.stack))
        .expand((stack) => stack.openTasks);
    final countsByNumber = <String, (TaskItem, int)>{};
    for (final task in openTasks) {
      final counted = countsByNumber[task.number];
      countsByNumber[task.number] = (task, (counted?.$2 ?? 0) + 1);
    }
    if (countsByNumber.isEmpty) return null;
    return countsByNumber.values.reduce((a, b) => a.$2 >= b.$2 ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final topOpenTask = _mostFrequentOpenTask();
    if (topOpenTask == null) return const SizedBox.shrink();
    final (task, occurrences) = topOpenTask;
    return NextStepBanner(
      title: texts.nextStepTitle(task.number, task.title, occurrences),
      reason: texts.nextStepReason,
      command: texts.nextStepCommand,
    );
  }
}
