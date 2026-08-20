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
import '../ui_kit/section_card.dart';
import '../ui_kit/status_badge.dart';

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
        if (snapshot.changes.isEmpty) {
          return Center(
            child: Text(texts.sprintEmpty,
                textAlign: TextAlign.center, style: AppTextStyles.body),
          );
        }
        return ListView(
          padding: AppDimens.screenPadding,
          children: [
            if (snapshot.redmineProblem != RedmineProblem.none) ...[
              _RedmineUnavailableBar(snapshot: snapshot),
              const SizedBox(height: AppDimens.gapM),
            ],
            if (snapshot.divergences.isNotEmpty) ...[
              _DivergenceBlock(divergences: snapshot.divergences),
              const SizedBox(height: AppDimens.gapL),
            ],
            _ChangesTable(
                changes: snapshot.changes, divergences: snapshot.divergences),
            const SizedBox(height: AppDimens.gapL),
            _NextStepSection(changes: snapshot.changes),
          ],
        );
      },
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

  const _ChangesTable({required this.changes, required this.divergences});

  bool _hasDivergence(ChangeUnit change, String stack) => divergences.any(
      (divergence) =>
          divergence.changeId == change.id && divergence.stack == stack);

  @override
  Widget build(BuildContext context) => SectionCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            const _TableHeader(),
            for (final (index, change) in changes.indexed)
              _ChangeRow(
                change: change,
                showTopDivider: index > 0,
                iosDiverged: _hasDivergence(change, 'ios'),
                androidDiverged: _hasDivergence(change, 'android'),
              ),
          ],
        ),
      );
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

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
              child:
                  Text(texts.tableHeaderChange, style: AppTextStyles.sectionLabel)),
          Expanded(
              flex: 29,
              child: Text(texts.tableHeaderIos,
                  style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary))),
          Expanded(
              flex: 29,
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
  final bool showTopDivider;
  final bool iosDiverged;
  final bool androidDiverged;

  const _ChangeRow({
    required this.change,
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
              Expanded(
                flex: 29,
                child:
                    _StackCell(stack: change.ios, diverged: iosDiverged),
              ),
              Expanded(
                flex: 29,
                child: _StackCell(
                    stack: change.android, diverged: androidDiverged),
              ),
            ],
          ),
        ),
      );
}

class _StackCell extends StatelessWidget {
  final StackState? stack;
  final bool diverged;

  const _StackCell({required this.stack, required this.diverged});

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
              Text('#${stackState.issueId ?? '—'}',
                  style: AppTextStyles.monospace(10.5,
                      color: AppColors.textMuted)),
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

  String _openTasksSummary(List<TaskItem> openTasks) => openTasks
      .map((task) => '${task.number} ${task.title}')
      .join('\n');
}

class _NextStepSection extends StatelessWidget {
  final List<ChangeUnit> changes;

  const _NextStepSection({required this.changes});

  /// Самая частая незакрытая задача по всем стекам спринта.
  (TaskItem, int)? _mostFrequentOpenTask() {
    final openTasks = changes
        .expand((change) => change.stacks)
        .expand((stack) => stack.openTasks);
    final countsByNumber = <String, (TaskItem, int)>{};
    for (final task in openTasks) {
      final counted = countsByNumber[task.number];
      countsByNumber[task.number] = (task, (counted?.$2 ?? 0) + 1);
    }
    if (countsByNumber.isEmpty) return null;
    return countsByNumber.values
        .reduce((a, b) => a.$2 >= b.$2 ? a : b);
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
