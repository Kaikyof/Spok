import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_dimens.dart';
import '../../core/resources/app_text_styles.dart';
import '../../domain/entities/change_unit.dart';
import '../../domain/entities/doc_artifact.dart';
import '../../domain/entities/issue_comment.dart';
import '../../domain/entities/merge_request_info.dart';
import '../../domain/entities/stack_state.dart';
import '../../domain/entities/task_item.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bloc/console_bloc.dart';
import '../bloc/sessions_bloc.dart';
import '../localization/text_formatters.dart';
import '../ui_kit/marks_indicator.dart';
import '../ui_kit/redmine_issue_link.dart';
import '../ui_kit/section_card.dart';
import '../ui_kit/stack_filter_control.dart';
import '../ui_kit/status_badge.dart';

/// Список change'ей → карточка change'а → просмотр документации.
class ChangeScreen extends StatelessWidget {
  const ChangeScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ConsoleBloc, ConsoleState>(
        builder: (context, state) {
          if (state.selectedDoc != null) {
            return _DocViewer(
                doc: state.selectedDoc!,
                content: state.docContent,
                backLabel: state.selectedChange?.title);
          }
          if (state.selectedChange != null) {
            return _ChangeCard(
              change: state.selectedChange!,
              allChanges: state.sprintChanges,
              filter: state.stackFilter,
              redmineBaseUrl: state.snapshot?.redmineBaseUrl ?? '',
              sprintBranchIos: state.sprint?.branchIos,
              sprintBranchAndroid: state.sprint?.branchAndroid,
              comments: state.comments,
              mergeRequests: state.mergeRequests,
            );
          }
          return _ChangeList(
            changes: state.sprintChanges,
            filter: state.stackFilter,
            redmineBaseUrl: state.snapshot?.redmineBaseUrl ?? '',
          );
        },
      );
}

class _ChangeList extends StatelessWidget {
  final List<ChangeUnit> changes;
  final StackFilter filter;
  final String redmineBaseUrl;

  const _ChangeList(
      {required this.changes,
      required this.filter,
      required this.redmineBaseUrl});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return ListView(
      padding: AppDimens.screenPadding,
      children: [
        Row(
          children: [
            const Spacer(),
            StackFilterControl<StackFilter>(
              options: [
                (StackFilter.all, texts.stackFilterAll),
                (StackFilter.ios, texts.stackIos),
                (StackFilter.android, texts.stackAndroid),
              ],
              selected: filter,
              onChanged: (newFilter) => context
                  .read<ConsoleBloc>()
                  .add(StackFilterChanged(newFilter)),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.gapM),
        for (final change in changes)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ChangeListRow(
                change: change,
                filter: filter,
                redmineBaseUrl: redmineBaseUrl),
          ),
      ],
    );
  }
}

class _ChangeListRow extends StatelessWidget {
  final ChangeUnit change;
  final StackFilter filter;
  final String redmineBaseUrl;

  const _ChangeListRow(
      {required this.change,
      required this.filter,
      required this.redmineBaseUrl});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final visibleStacks = change.stacks
        .where((stack) => filter.allows(stack.stack))
        .toList();
    return InkWell(
      onTap: () => context.read<ConsoleBloc>().add(ChangeOpened(change)),
      borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      child: SectionCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(change.title, style: AppTextStyles.rowTitle),
                  const SizedBox(height: 3),
                  Text(change.id,
                      style: AppTextStyles.monospace(10.5,
                          color: AppColors.textMuted)),
                ],
              ),
            ),
            for (final stackState in visibleStacks) ...[
              SizedBox(
                width: 230,
                child: Row(
                  children: [
                    Expanded(
                      child: StatusBadge(
                        text:
                            '${texts.stackLabel(stackState.stack)} · ${stackState.redmineStatus ?? texts.statusUnavailable}',
                        dotColor: stackState.redmineStatus == null
                            ? AppColors.textMuted
                            : AppColors.forRedmineStatus(
                                stackState.redmineStatus!),
                        muted: stackState.redmineStatus == null,
                      ),
                    ),
                    RedmineIssueLink(
                      issueId: stackState.issueId,
                      baseUrl: redmineBaseUrl,
                      tooltip: texts.openInRedmineTooltip,
                      fontSize: 11.5,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimens.gapM),
              MarksIndicator(
                doneCount: stackState.doneCount,
                totalCount: stackState.tasks.length,
              ),
              const SizedBox(width: AppDimens.gapM),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChangeCard extends StatelessWidget {
  final ChangeUnit change;
  final List<ChangeUnit> allChanges;
  final StackFilter filter;
  final String redmineBaseUrl;
  final String? sprintBranchIos;
  final String? sprintBranchAndroid;
  final List<IssueComment>? comments;
  final List<MergeRequestInfo>? mergeRequests;

  const _ChangeCard({
    required this.change,
    required this.allChanges,
    required this.filter,
    required this.redmineBaseUrl,
    required this.sprintBranchIos,
    required this.sprintBranchAndroid,
    required this.comments,
    required this.mergeRequests,
  });

  List<DocArtifact> _artifacts(AppLocalizations texts) {
    final labelsToFiles = [
      (texts.artifactSpec, 'proposal.md'),
      (texts.artifactDesign, 'design.md'),
      (texts.artifactTasksIos, 'tasks_ios.md'),
      (texts.artifactTasksAndroid, 'tasks_android.md'),
    ];
    return [
      for (final (label, fileName) in labelsToFiles)
        DocArtifact(label, fileName, p.join(change.dir, fileName),
            File(p.join(change.dir, fileName)).existsSync()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final visibleStacks = change.stacks
        .where((stack) => filter.allows(stack.stack))
        .toList();
    return ListView(
      padding: AppDimens.screenPadding,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () =>
                  context.read<ConsoleBloc>().add(ChangeOpened(null)),
              child:
                  Text(texts.backToChanges, style: AppTextStyles.captionMuted),
            ),
            const Spacer(),
            StackFilterControl<StackFilter>(
              options: [
                (StackFilter.all, texts.stackFilterAll),
                (StackFilter.ios, texts.stackIos),
                (StackFilter.android, texts.stackAndroid),
              ],
              selected: filter,
              onChanged: (newFilter) => context
                  .read<ConsoleBloc>()
                  .add(StackFilterChanged(newFilter)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SelectableText(change.title, style: AppTextStyles.screenTitle),
        const SizedBox(height: 6),
        Row(
          children: [
            SelectableText(change.id,
                style:
                    AppTextStyles.monospace(11.5, color: AppColors.textMuted)),
            const SizedBox(width: AppDimens.gapM),
            for (final stackState in change.stacks) ...[
              StatusBadge(
                text:
                    '${texts.stackLabel(stackState.stack)} · ${stackState.redmineStatus ?? texts.statusUnavailable}',
                dotColor: stackState.redmineStatus == null
                    ? AppColors.textMuted
                    : AppColors.forRedmineStatus(stackState.redmineStatus!),
                muted: stackState.redmineStatus == null,
              ),
              const SizedBox(width: 6),
              RedmineIssueLink(
                issueId: stackState.issueId,
                baseUrl: redmineBaseUrl,
                tooltip: texts.openInRedmineTooltip,
                fontSize: 12,
              ),
              const SizedBox(width: AppDimens.gapL),
            ],
          ],
        ),
        const SizedBox(height: AppDimens.gapL),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 55,
              child: Column(
                children: [
                  for (final stackState in visibleStacks) ...[
                    _TaskChecklist(stack: stackState, changeId: change.id),
                    const SizedBox(height: AppDimens.gapM),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppDimens.gapL),
            Expanded(
              flex: 45,
              child: Column(
                children: [
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(texts.artifactsTitle,
                            style: AppTextStyles.sectionTitle),
                        const SizedBox(height: AppDimens.gapS),
                        for (final artifact in _artifacts(texts))
                          _ArtifactRow(artifact: artifact),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimens.gapM),
                  _DependenciesCard(change: change, allChanges: allChanges),
                  const SizedBox(height: AppDimens.gapM),
                  _CodeCard(
                    stacks: visibleStacks,
                    branchIos: sprintBranchIos,
                    branchAndroid: sprintBranchAndroid,
                    mergeRequests: mergeRequests,
                    changeId: change.id,
                  ),
                  const SizedBox(height: AppDimens.gapM),
                  _CommentsCard(comments: comments),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Код: ветка спринта по стекам. Состояние MR подключится вместе
/// с GitLab API — пока показываем только то, что знаем наверняка.
class _CodeCard extends StatelessWidget {
  final List<StackState> stacks;
  final String? branchIos;
  final String? branchAndroid;
  final List<MergeRequestInfo>? mergeRequests;
  final String changeId;

  const _CodeCard({
    required this.stacks,
    required this.branchIos,
    required this.branchAndroid,
    required this.mergeRequests,
    required this.changeId,
  });

  String? _branchFor(String stack) =>
      stack == 'ios' ? branchIos : branchAndroid;

  MergeRequestInfo? _mrFor(String stack) =>
      mergeRequests?.where((mr) => mr.stack == stack).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (index, stackState) in stacks.indexed) ...[
            if (index > 0) ...[
              const SizedBox(height: AppDimens.gapM),
              const Divider(height: 1),
              const SizedBox(height: AppDimens.gapM),
            ],
            Text(texts.codeSectionTitle(texts.stackLabel(stackState.stack)),
                style: AppTextStyles.sectionTitle),
            const SizedBox(height: 8),
            _CodeRow(
              label: texts.codeChangeBranch,
              value: 'features/$changeId',
            ),
            _CodeRow(
              label: texts.codeSprintBranch,
              value: _branchFor(stackState.stack) ?? texts.codeNoBranch,
              muted: _branchFor(stackState.stack) == null,
            ),
            const SizedBox(height: 8),
            _MergeRequestRow(
              mergeRequest: _mrFor(stackState.stack),
              loading: mergeRequests == null,
              targetBranch: _branchFor(stackState.stack) ?? '',
            ),
          ],
        ],
      ),
    );
  }
}

/// Строка «подпись — значение» с копируемым моноширинным значением.
class _CodeRow extends StatelessWidget {
  final String label;
  final String value;
  final bool muted;

  const _CodeRow(
      {required this.label, required this.value, this.muted = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.hint),
            SelectableText(
              value,
              style: AppTextStyles.monospace(12,
                  color: muted ? AppColors.textMuted : AppColors.monospaceText),
            ),
          ],
        ),
      );
}

/// Ярлык MR и факт влития рядом: где они расходятся — это видно.
class _MergeRequestRow extends StatelessWidget {
  final MergeRequestInfo? mergeRequest;
  final bool loading;
  final String targetBranch;

  const _MergeRequestRow({
    required this.mergeRequest,
    required this.loading,
    required this.targetBranch,
  });

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    if (loading) {
      return const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 1.5));
    }
    final mr = mergeRequest;
    if (mr == null) {
      return Text(texts.codeGitlabUnavailable,
          style: AppTextStyles.captionMuted);
    }
    final (stateText, stateColor) = switch (mr.state) {
      MergeRequestState.opened => (
          texts.codeMrOpened(mr.iid ?? 0),
          AppColors.statusInReview
        ),
      MergeRequestState.merged => (
          texts.codeMrMerged(mr.iid ?? 0),
          AppColors.success
        ),
      MergeRequestState.closed => (
          texts.codeMrClosed(mr.iid ?? 0),
          AppColors.textMuted
        ),
      MergeRequestState.none => (texts.codeMrNone, AppColors.textMuted),
    };
    final (factText, factColor) = switch (mr.mergedIntoTarget) {
      true => (texts.codeFactMerged(targetBranch), AppColors.success),
      false => (texts.codeFactMissing(targetBranch), AppColors.warning),
      null => (texts.codeFactUnknown, AppColors.textMuted),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: stateColor, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(stateText,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary)),
            ),
            if (mr.webUrl.isNotEmpty)
              InkWell(
                onTap: () => launchUrl(Uri.parse(mr.webUrl)),
                child: Text(texts.codeOpenMr,
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.accent)),
              ),
          ],
        ),
        if (mr.state != MergeRequestState.none) ...[
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration:
                    BoxDecoration(color: factColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(factText,
                    style: TextStyle(fontSize: 12, color: factColor)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Лента комментариев Redmine — то, чем обмениваются разработчик
/// и тестировщик по задаче.
class _CommentsCard extends StatefulWidget {
  final List<IssueComment>? comments;

  const _CommentsCard({required this.comments});

  @override
  State<_CommentsCard> createState() => _CommentsCardState();
}

class _CommentsCardState extends State<_CommentsCard> {
  static const _collapsedCount = 3;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final loaded = widget.comments;
    final visible = loaded == null
        ? const <IssueComment>[]
        : (_expanded ? loaded : loaded.take(_collapsedCount).toList());
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(texts.commentsTitle, style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppDimens.gapS),
          if (loaded == null)
            const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 1.5))
          else if (loaded.isEmpty)
            Text(texts.commentsEmpty, style: AppTextStyles.captionMuted)
          else ...[
            for (final comment in visible) _CommentRow(comment: comment),
            if (!_expanded && loaded.length > _collapsedCount)
              InkWell(
                onTap: () => setState(() => _expanded = true),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(texts.commentsShowAll(loaded.length),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.accent)),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  final IssueComment comment;

  const _CommentRow({required this.comment});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${comment.author} · #${comment.issueId} · '
              '${DateFormat('d MMM, HH:mm', 'ru').format(comment.createdAt.toLocal())}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: 3),
            // Текст не обрезаем: в комментариях лежат ссылки на MR и
            // номера задач — они нужны целиком и копируемыми.
            SelectableText(comment.text,
                style: AppTextStyles.caption.copyWith(height: 1.45)),
          ],
        ),
      );
}

class _DependenciesCard extends StatelessWidget {
  final ChangeUnit change;
  final List<ChangeUnit> allChanges;

  const _DependenciesCard({required this.change, required this.allChanges});

  String _titleOf(String changeId) => allChanges
      .where((candidate) => candidate.id == changeId)
      .map((candidate) => candidate.title)
      .firstOrNull ??
      changeId;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final dependents = allChanges
        .where((candidate) => candidate.dependsOn.contains(change.id))
        .toList();
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(texts.dependenciesTitle, style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppDimens.gapS),
          if (change.dependsOn.isEmpty && dependents.isEmpty)
            Text(texts.dependenciesNone, style: AppTextStyles.captionMuted),
          if (change.dependsOn.isNotEmpty) ...[
            Text(texts.dependsOnLabel,
                style: AppTextStyles.sectionLabel.copyWith(fontSize: 9.5)),
            const SizedBox(height: 6),
            for (final dependencyId in change.dependsOn)
              _DependencyRow(
                  title: _titleOf(dependencyId),
                  dotColor: AppColors.success),
            const SizedBox(height: AppDimens.gapS),
          ],
          if (dependents.isNotEmpty) ...[
            Text(texts.dependentsLabel,
                style: AppTextStyles.sectionLabel.copyWith(fontSize: 9.5)),
            const SizedBox(height: 6),
            for (final dependent in dependents)
              _DependencyRow(
                  title: dependent.title, dotColor: AppColors.statusTesting),
          ],
        ],
      ),
    );
  }
}

class _DependencyRow extends StatelessWidget {
  final String title;
  final Color dotColor;

  const _DependencyRow({required this.title, required this.dotColor});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: dotColor, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption),
            ),
          ],
        ),
      );
}

class _ArtifactRow extends StatelessWidget {
  final DocArtifact artifact;

  const _ArtifactRow({required this.artifact});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: artifact.exists
            ? () => context.read<ConsoleBloc>().add(DocOpened(artifact))
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: artifact.exists
                        ? AppColors.success
                        : AppColors.textMuted,
                    shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(artifact.label,
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary)),
                    Text(artifact.fileName,
                        style: AppTextStyles.monospace(10.5,
                            color: AppColors.textMuted)),
                  ],
                ),
              ),
              if (artifact.exists)
                const Icon(Icons.chevron_right,
                    size: 16, color: AppColors.textMuted),
            ],
          ),
        ),
      );
}

class _TaskChecklist extends StatelessWidget {
  final StackState stack;
  final String changeId;

  const _TaskChecklist({required this.stack, required this.changeId});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final allDone = stack.openTasks.isEmpty;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(texts.tasksOfStack(texts.stackLabel(stack.stack)),
                    style: AppTextStyles.sectionTitle),
              ),
              Text('${stack.doneCount} / ${stack.tasks.length}',
                  style: AppTextStyles.monospace(12.5,
                      color: allDone
                          ? AppColors.textSecondary
                          : AppColors.warning,
                      weight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 10),
          for (final task in stack.tasks) _TaskRow(task: task),
          const SizedBox(height: AppDimens.gapS),
          _ApplyButton(stack: stack, changeId: changeId, allDone: allDone),
        ],
      ),
    );
  }
}

/// Реализация стека — работа, требующая суждения: запускаем /opsx-apply
/// в агентной сессии прямо отсюда, чтобы не переключаться в терминал.
class _ApplyButton extends StatelessWidget {
  final StackState stack;
  final String changeId;
  final bool allDone;

  const _ApplyButton({
    required this.stack,
    required this.changeId,
    required this.allDone,
  });

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    if (allDone) {
      return Row(
        children: [
          const Icon(Icons.check_circle_outline,
              size: 14, color: AppColors.success),
          const SizedBox(width: 8),
          Text(texts.applyDone, style: AppTextStyles.hint),
        ],
      );
    }
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () {
            context.read<SessionsBloc>().add(HandoffRunRequested(
                '/opsx-apply $changeId --stack ${stack.stack}'));
            context
                .read<ConsoleBloc>()
                .add(ScreenSelected(ConsoleScreen.sessions));
          },
          icon: const Icon(Icons.play_arrow, size: 15, color: AppColors.accent),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.border),
            backgroundColor: AppColors.cardHighlight,
            foregroundColor: AppColors.textPrimary,
          ),
          label: Text(texts.applyRun(texts.stackLabel(stack.stack)),
              style: const TextStyle(fontSize: 12)),
        ),
        const SizedBox(width: 12),
        Flexible(child: Text(texts.applyHint, style: AppTextStyles.hint)),
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  final TaskItem task;

  const _TaskRow({required this.task});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: task.done
          ? null
          : BoxDecoration(
              color: AppColors.warningBackground,
              borderRadius: BorderRadius.circular(6)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(task.done ? Icons.check_box : Icons.check_box_outline_blank,
              size: 15,
              color: task.done ? AppColors.success : AppColors.warning),
          const SizedBox(width: 10),
          Text(task.number,
              style: AppTextStyles.monospace(12,
                  color: task.done ? AppColors.textMuted : AppColors.warning)),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              task.title,
              style: TextStyle(
                  fontSize: 12.5,
                  color: task.done
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  fontWeight: task.done ? FontWeight.w400 : FontWeight.w500),
            ),
          ),
          if (!task.done)
            Text(texts.blocksHandover,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.warning)),
        ],
      ),
    );
  }
}

class _DocViewer extends StatelessWidget {
  final DocArtifact doc;
  final String? content;
  final String? backLabel;

  const _DocViewer(
      {required this.doc, required this.content, required this.backLabel});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.gapXl, vertical: 12),
          child: Row(
            children: [
              InkWell(
                onTap: () => context.read<ConsoleBloc>().add(DocOpened(null)),
                child: Text(
                    backLabel != null ? '← $backLabel' : texts.backFallback,
                    style: AppTextStyles.captionMuted),
              ),
              const Spacer(),
              Text(doc.fileName,
                  style: AppTextStyles.monospace(11.5,
                      color: AppColors.textMuted)),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(
                AppDimens.gapXl, 0, AppDimens.gapXl, AppDimens.gapXl),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppDimens.cardRadius),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Markdown(
              data: content ?? texts.docReadError(doc.path),
              padding: const EdgeInsets.all(AppDimens.gapXl),
              styleSheet: _markdownStyle(),
            ),
          ),
        ),
      ],
    );
  }

  MarkdownStyleSheet _markdownStyle() => MarkdownStyleSheet(
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
