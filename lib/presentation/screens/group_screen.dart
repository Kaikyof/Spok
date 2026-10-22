import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_dimens.dart';
import '../../core/resources/app_text_styles.dart';
import '../../domain/entities/change_unit.dart';
import '../../domain/entities/console_snapshot.dart';
import '../../domain/entities/divergence.dart';
import '../../domain/entities/doc_artifact.dart';
import '../../domain/entities/spec_recognition.dart';
import '../../domain/entities/slash_command.dart';
import '../../domain/entities/stack_state.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/entities/work_stage.dart';
import '../../data/sources/redmine_status_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bloc/console_bloc.dart';
import '../bloc/sessions_bloc.dart';
import '../localization/text_formatters.dart';
import '../ui_kit/issue_link.dart';
import '../ui_kit/marks_indicator.dart';
import '../ui_kit/next_step_banner.dart';
import '../ui_kit/section_card.dart';
import '../ui_kit/skeleton.dart';
import '../ui_kit/status_badge.dart';
import '../widgets/create_change_dialog.dart';
import '../widgets/create_sprint_dialog.dart';
import '../widgets/stack_filter_bar.dart';
import '../ui_kit/tappable.dart';

/// Главный экран: за пять секунд показать, где работа и что мешает.
/// Группа — спринт, мастер-спека или просто все change'и спеки.
class GroupScreen extends StatelessWidget {
  const GroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return BlocBuilder<ConsoleBloc, ConsoleState>(
      builder: (context, state) {
        final snapshot = state.snapshot;
        if (snapshot == null) return const _GroupSkeleton();
        final changes = state.groupChanges;
        // Пусто — тоже состояние экрана: объяснение и первый шаг, а не
        // пустая рамка и не одинокая строка текста (борд 19).
        if (changes.isEmpty) {
          final wholeSpecEmpty = snapshot.changes.isEmpty;
          return _EmptyGroup(
            title: wholeSpecEmpty ? texts.groupEmptyAll : texts.sprintNoChanges(state.group?.title ?? ''),
            groupId: wholeSpecEmpty ? '' : (state.group?.id ?? ''),
            masterDoc: _masterDocOf(state),
          );
        }
        // Колонки таблицы: стеки спеки, а при их отсутствии — одна колонка
        // работы на уровне change'а.
        final columns = [
          for (final stack in state.stacks)
            if (state.allowsStack(stack)) stack,
        ];
        final visibleDivergences = snapshot.divergences
            .where((divergence) => state.allowsStack(divergence.stack))
            .toList();
        return ListView(
          padding: AppDimens.screenPadding,
          children: [
            const _FilterRow(),
            const SizedBox(height: AppDimens.gapM),
            // Полоса о трекере — только когда он объявлен спекой и не
            // ответил: у спеки без трекера нехватки нет.
            if (snapshot.trackerProblem == TrackerProblem.noApiKey ||
                snapshot.trackerProblem == TrackerProblem.unreachable) ...[
              _TrackerUnavailableBar(snapshot: snapshot),
              const SizedBox(height: AppDimens.gapM),
            ],
            if (!snapshot.profile.recognition.complete) ...[
              _UnrecognizedBlock(recognition: snapshot.profile.recognition),
              const SizedBox(height: AppDimens.gapM),
            ],
            if (visibleDivergences.isNotEmpty) ...[
              _DivergenceBlock(divergences: visibleDivergences),
              const SizedBox(height: AppDimens.gapL),
            ],
            _ChangesTable(changes: changes, columns: columns, divergences: snapshot.divergences, snapshot: snapshot),
            const SizedBox(height: AppDimens.gapL),
            _NextStepSection(changes: changes),
          ],
        );
      },
    );
  }
}

/// Мастер-спека выбранной группы в дереве документов; null — её нет.
DocArtifact? _masterDocOf(ConsoleState state) {
  final groupId = state.group?.id ?? '';
  final node = state.docTree.where((candidate) => candidate.id == groupId).firstOrNull;
  return node?.docs
      .where((doc) => doc.exists && (doc.id == DocArtifact.masterDocId || doc.id == DocArtifact.groupDocId))
      .firstOrNull;
}

/// Первая загрузка: блоки той же высоты и в тех же местах, что у готового
/// экрана. Крутящийся индикатор в центре стирал раскладку — после него
/// таблица появлялась рывком, и человек заново искал нужную строку.
class _GroupSkeleton extends StatelessWidget {
  const _GroupSkeleton();

  /// Сколько колонок будет — на первой загрузке ещё неизвестно: стеки
  /// приходят из схемы спеки. Две колонки — середина между «без стеков»
  /// и «ios · android · backend», и таблица не прыгает ни в ту, ни в другую
  /// сторону сильно.
  static const _columns = 2;

  @override
  Widget build(BuildContext context) {
    const stackFlex = 58 ~/ _columns;
    return ListView(
      padding: AppDimens.screenPadding,
      children: [
        // Строка фильтров: та же высота, что у настоящих кнопок.
        const SizedBox(
          height: 36,
          child: Row(children: [SkeletonLine(width: 150, height: 30), Spacer(), SkeletonLine(width: 190, height: 30)]),
        ),
        const SizedBox(height: AppDimens.gapM),
        SectionCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
                ),
                child: Row(
                  children: [
                    const Expanded(flex: 42, child: SkeletonLine(height: 9, widthFactor: 0.35)),
                    for (var column = 0; column < _columns; column++)
                      const Expanded(flex: stackFlex, child: SkeletonLine(height: 9, widthFactor: 0.3)),
                  ],
                ),
              ),
              for (var row = 0; row < 4; row++)
                SkeletonRow(
                  columnFlex: const [42, stackFlex, stackFlex],
                  widthFactors: const [0.8, 0.6, 0.6],
                  showTopDivider: row > 0,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow();

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () => CreateSprintDialog.show(context),
          icon: const Icon(Icons.add, size: 15, color: AppColors.accent),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.border),
            backgroundColor: AppColors.card,
            foregroundColor: AppColors.textPrimary,
          ),
          label: Text(texts.sprintCreateTitle, style: const TextStyle(fontSize: 12)),
        ),
        const Spacer(),
        const StackFilterBar(),
      ],
    );
  }
}

/// Группа есть, а change'ей в ней нет: объясняем и даём первый шаг,
/// а не показываем пустую таблицу. Пустая рамка без объяснения — дефект,
/// а не состояние (борд 19).
class _EmptyGroup extends StatelessWidget {
  /// Почему пусто — своими словами для группы и для всей спеки.
  final String title;

  /// Мастер-спека группы; null — документа у неё нет, и кнопки тоже.
  final DocArtifact? masterDoc;

  final String groupId;

  const _EmptyGroup({required this.title, required this.groupId, this.masterDoc});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, textAlign: TextAlign.center, style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppDimens.gapS),
            Text(
              texts.sprintNoChangesHint,
              textAlign: TextAlign.center,
              style: AppTextStyles.captionMuted.copyWith(height: 1.5),
            ),
            const SizedBox(height: AppDimens.gapL),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () => CreateChangeDialog.show(context, groupId),
                  icon: const Icon(Icons.add, size: 16),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                  ),
                  label: Text(texts.sprintCreateChange),
                ),
                // Второй шаг, не менее частый: в мастер-спеке уже написано,
                // какие change'и должны появиться, — человек идёт читать её,
                // а не выдумывать первый change с нуля.
                if (masterDoc case final doc?) ...[
                  const SizedBox(width: AppDimens.gapM),
                  OutlinedButton.icon(
                    onPressed: () {
                      final console = context.read<ConsoleBloc>();
                      console.add(DocsFileOpened(doc));
                      console.add(ScreenSelected(ConsoleScreen.docs));
                    },
                    icon: const Icon(Icons.description_outlined, size: 15),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      backgroundColor: AppColors.card,
                      foregroundColor: AppColors.textPrimary,
                    ),
                    label: Text(texts.sprintOpenMasterDoc, style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppDimens.gapL),
            // Что именно произойдёт по кнопке: команду спеки показываем
            // заранее — она запустится в агентной сессии от лица человека.
            Text(texts.sprintCommandPreview, style: AppTextStyles.hint),
            const SizedBox(height: AppDimens.gapXs),
            Text(CreateChangeDialog.commandLine(groupId), style: AppTextStyles.monospace(11.5)),
          ],
        ),
      ),
    );
  }
}

class _TrackerUnavailableBar extends StatelessWidget {
  final ConsoleSnapshot snapshot;

  const _TrackerUnavailableBar({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    // Имя ключа и системы — от контракта трекера, а не из текста ядра.
    final reason = switch (snapshot.trackerProblem) {
      TrackerProblem.noApiKey => texts.trackerNoKey(snapshot.trackerKeys.join(', ')),
      TrackerProblem.platformNotFound => texts.platformRepoNotFound,
      _ => snapshot.trackerProblemDetail,
    };
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Сначала — что человек видит вместо живых статусов,
                // и только потом причина: она ему менее нужна.
                Text(texts.partialTrackerTitle, style: AppTextStyles.caption),
                if (reason.isNotEmpty) ...[const SizedBox(height: 2), Text(reason, style: AppTextStyles.hint)],
              ],
            ),
          ),
          const SizedBox(width: AppDimens.gapM),
          // Повтор рядом с сообщением: трекер чаще всего молчал секунду,
          // и второй запрос решает дело.
          OutlinedButton(
            onPressed: () => context.read<ConsoleBloc>().add(ConsoleRefreshed()),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 28),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              side: const BorderSide(color: AppColors.border),
              backgroundColor: AppColors.cardHighlight,
              foregroundColor: AppColors.textPrimary,
            ),
            child: Text(texts.partialRetry, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

/// Честный список «что поняли и что нет» (борд 19). Приложение читает
/// устройство спеки, а не знает его наперёд, — и там, где разобрать не
/// удалось, говорит об этом, а не показывает пустоту.
class _UnrecognizedBlock extends StatelessWidget {
  final SpecRecognition recognition;

  const _UnrecognizedBlock({required this.recognition});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  texts.unrecognizedTitle(recognition.recognizedCount, recognition.items.length),
                  style: AppTextStyles.sectionTitle,
                ),
              ),
              // Экран настроек проекта — очередь 3; до него правка ведёт
              // туда, где спека подключается.
              OutlinedButton(
                onPressed: () => context.read<ConsoleBloc>().add(SpecSwitchRequested(true)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  side: const BorderSide(color: AppColors.border),
                  backgroundColor: AppColors.cardHighlight,
                  foregroundColor: AppColors.textPrimary,
                ),
                child: Text(texts.unrecognizedManual, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gapS),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(texts.unrecognizedNote, style: AppTextStyles.hint.copyWith(height: 1.4)),
          ),
          const SizedBox(height: AppDimens.gapM),
          for (final item in recognition.items)
            Padding(
              padding: const EdgeInsets.only(left: 26, bottom: 6),
              child: Row(
                children: [
                  Icon(
                    item.recognized ? Icons.check_circle_outline : Icons.remove_circle_outline,
                    size: 14,
                    color: item.recognized ? AppColors.success : AppColors.warning,
                  ),
                  const SizedBox(width: AppDimens.gapS),
                  SizedBox(width: 180, child: Text(texts.recognizedPartTitle(item.part), style: AppTextStyles.caption)),
                  Expanded(
                    child: Text(
                      texts.recognizedValue(item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: item.recognized ? AppColors.textPrimary : AppColors.warning,
                      ),
                    ),
                  ),
                  // Где искали — чтобы человек мог проверить сам, а не
                  // верить на слово.
                  Text(item.lookedIn, style: AppTextStyles.monospace(10, color: AppColors.textMuted)),
                ],
              ),
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
              const Icon(Icons.warning_amber_rounded, size: 17, color: AppColors.warning),
              const SizedBox(width: 10),
              Text(
                texts.divergencesTitle(divergences.length),
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.warning),
              ),
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
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChangesTable extends StatelessWidget {
  final List<ChangeUnit> changes;
  final List<String> columns;
  final List<Divergence> divergences;

  /// Трекер слепка: активен ли, как зовётся и где его задачи.
  final ConsoleSnapshot snapshot;

  const _ChangesTable({
    required this.changes,
    required this.columns,
    required this.divergences,
    required this.snapshot,
  });

  bool _hasDivergence(ChangeUnit change, String stack) =>
      divergences.any((divergence) => divergence.changeId == change.id && divergence.stack == stack);

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    // Колонок нет (у спеки нет стеков) — показываем одну колонку работы.
    final columnStacks = columns.isEmpty ? [''] : columns;
    final stackFlex = (58 / columnStacks.length).round();
    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _TableHeader(columns: [for (final stack in columnStacks) texts.stackLabel(stack)], stackFlex: stackFlex),
          for (final (index, change) in changes.indexed)
            _ChangeRow(
              change: change,
              columns: columnStacks,
              stackFlex: stackFlex,
              snapshot: snapshot,
              showTopDivider: index > 0,
              divergedStacks: {
                for (final stack in columnStacks)
                  if (_hasDivergence(change, stack)) stack,
              },
            ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final List<String> columns;
  final int stackFlex;

  const _TableHeader({required this.columns, required this.stackFlex});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Row(
        children: [
          Expanded(flex: 42, child: Text(texts.tableHeaderChange, style: AppTextStyles.sectionLabel)),
          for (final label in columns)
            Expanded(
              flex: stackFlex,
              child: Text(label, style: AppTextStyles.sectionLabel.copyWith(color: AppColors.textSecondary)),
            ),
        ],
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  final ChangeUnit change;
  final List<String> columns;
  final int stackFlex;
  final ConsoleSnapshot snapshot;
  final bool showTopDivider;
  final Set<String> divergedStacks;

  const _ChangeRow({
    required this.change,
    required this.columns,
    required this.stackFlex,
    required this.snapshot,
    required this.showTopDivider,
    required this.divergedStacks,
  });

  /// Колонка без имени стека — единственный «стек работы» change'а.
  StackState? _stackFor(String stack) => stack.isEmpty ? change.stacks.firstOrNull : change.stack(stack);

  @override
  Widget build(BuildContext context) => Tappable(
    onTap: () => context.read<ConsoleBloc>().add(ChangeOpened(change)),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: showTopDivider ? const Border(top: BorderSide(color: AppColors.borderSoft)) : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 42,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(change.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.rowTitle),
                const SizedBox(height: 3),
                Text(change.id, style: AppTextStyles.monospace(10.5, color: AppColors.textMuted)),
              ],
            ),
          ),
          for (final stack in columns)
            Expanded(
              flex: stackFlex,
              child: _StackCell(stack: _stackFor(stack), diverged: divergedStacks.contains(stack), snapshot: snapshot),
            ),
        ],
      ),
    ),
  );
}

class _StackCell extends StatelessWidget {
  final StackState? stack;
  final bool diverged;
  final ConsoleSnapshot snapshot;

  const _StackCell({required this.stack, required this.diverged, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final stackState = stack;
    if (stackState == null) {
      return const Text('—', style: TextStyle(color: AppColors.textMuted, fontSize: 12));
    }
    final stage = stackState.stage;
    final status = stackState.trackerStatus;
    final openTasks = stackState.openTasks;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Стадия — факт из файлов, он есть у любой спеки; цвет точки
              // тоже её. Статус трекера, если он есть, — ярлык под ней.
              Tooltip(
                message: texts.stageTooltip,
                child: StatusBadge(text: texts.stageLabel(stage), dotColor: AppColors.forStage(stage)),
              ),
              if (status != null) ...[
                const SizedBox(height: AppDimens.badgeGap),
                // Статус из файла показывается приглушённо и полой точкой:
                // человек не должен принять вчерашние данные за живые.
                Tooltip(
                  message: stackState.statusFromCache ? texts.statusFromCacheHint : '',
                  child: StatusBadge(
                    text: stackState.statusFromCache ? '$status · ${texts.statusFromCache}' : status,
                    dotColor: redmineStatusColor(status),
                    muted: stackState.statusFromCache,
                    hollow: stackState.statusFromCache,
                  ),
                ),
              ] else if (snapshot.trackerActive && stackState.issueId != null)
                // Задача в трекере есть, а статуса нет ни живого, ни из
                // файла — об этом сказано; без задачи говорить не о чем.
                Padding(
                  padding: const EdgeInsets.only(top: AppDimens.badgeGap),
                  child: Text(texts.statusUnavailable, style: AppTextStyles.hint),
                ),
              if (stackState.issueId case final issueId?) ...[
                const SizedBox(height: AppDimens.badgeGap),
                IssueLink(
                  issueId: issueId,
                  url: snapshot.issueUrl(issueId),
                  tooltip: texts.openInTrackerTooltip(snapshot.trackerName),
                ),
              ],
            ],
          ),
        ),
        if (stackState.tasks.isNotEmpty)
          MarksIndicator(
            doneCount: stackState.doneCount,
            totalCount: stackState.tasks.length,
            diverged: diverged,
            openTaskLabel: openTasks.isEmpty ? null : texts.marksOpenTask(openTasks.first.number),
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

  const _NextStepSection({required this.changes});

  /// Самая частая незакрытая задача по видимым стекам группы.
  (TaskItem, int)? _mostFrequentOpenTask(ConsoleState state) {
    final openTasks = changes
        .expand((change) => change.stacks)
        .where((stack) => state.allowsStack(stack.stack))
        .expand((stack) => stack.openTasks);
    final countsByNumber = <String, (TaskItem, int)>{};
    for (final task in openTasks) {
      final counted = countsByNumber[task.number];
      countsByNumber[task.number] = (task, (counted?.$2 ?? 0) + 1);
    }
    if (countsByNumber.isEmpty) return null;
    return countsByNumber.values.reduce((a, b) => a.$2 >= b.$2 ? a : b);
  }

  /// Самый «отстающий» change группы: его стадия и задаёт следующий шаг.
  ChangeUnit? _mostLagging() {
    final active = changes.where((change) => !change.archived).toList();
    if (active.isEmpty) return null;
    return active.reduce((a, b) => a.stage.rank <= b.stage.rank ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return BlocBuilder<ConsoleBloc, ConsoleState>(
      builder: (context, state) {
        // Стеков нет — работа одна на change, и следующий шаг решает
        // стадия, а не частота номера задачи по стекам.
        final noStacks = state.stacks.every((stack) => stack == StackState.singleWorkStack);
        if (noStacks) return _byStage(context, texts);
        final topOpenTask = _mostFrequentOpenTask(state);
        if (topOpenTask == null) return const SizedBox.shrink();
        final (task, occurrences) = topOpenTask;
        return NextStepBanner(
          title: texts.nextStepTitle(task.number, task.title, occurrences),
          reason: texts.nextStepReason,
          command: texts.nextStepCommand,
        );
      },
    );
  }

  /// Команда — из ролей команд спеки; роли нет — плашка без команды:
  /// выдумывать вызов за спеку нельзя.
  Widget _byStage(BuildContext context, AppLocalizations texts) {
    final change = _mostLagging();
    if (change == null) return const SizedBox.shrink();
    final roles = context.watch<SessionsBloc>().state.roles;
    String? invocation(CommandRole role) {
      final command = roles[role];
      return command == null ? null : '${command.invocation} ${change.id}';
    }

    final (title, reason, command) = switch (change.stage) {
      PlanningStage(:final next) => (
        texts.nextStepPlanning(texts.artifactIdLabel(next), change.title),
        texts.nextStepPlanningReason,
        invocation(CommandRole.newChange),
      ),
      ReadyToApplyStage() || InProgressStage() => (
        texts.nextStepApply(change.title),
        texts.nextStepApplyReason,
        invocation(CommandRole.apply),
      ),
      // Роль архивирования появится вместе с командами upstream; до неё
      // шаг называется, но команды у него нет.
      DoneStage() => (texts.nextStepArchive, texts.nextStepArchiveReason, null),
      ArchivedStage() => (null, null, null),
    };
    if (title == null) return const SizedBox.shrink();
    return NextStepBanner(title: title, reason: reason!, command: command);
  }
}
