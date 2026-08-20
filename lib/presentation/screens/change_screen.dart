import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:path/path.dart' as p;

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_dimens.dart';
import '../../core/resources/app_text_styles.dart';
import '../../domain/entities/change_unit.dart';
import '../../domain/entities/doc_artifact.dart';
import '../../domain/entities/stack_state.dart';
import '../../domain/entities/task_item.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bloc/console_bloc.dart';
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
              allChanges: state.snapshot?.changes ?? const [],
              filter: state.stackFilter,
              redmineBaseUrl: state.snapshot?.redmineBaseUrl ?? '',
            );
          }
          return _ChangeList(
            changes: state.snapshot?.changes ?? const [],
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

  const _ChangeCard({
    required this.change,
    required this.allChanges,
    required this.filter,
    required this.redmineBaseUrl,
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
        Text(change.title, style: AppTextStyles.screenTitle),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(change.id,
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
              flex: 62,
              child: Column(
                children: [
                  for (final stackState in visibleStacks) ...[
                    _TaskChecklist(stack: stackState),
                    const SizedBox(height: AppDimens.gapM),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppDimens.gapL),
            Expanded(
              flex: 38,
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
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
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

  const _TaskChecklist({required this.stack});

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
        ],
      ),
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
            child: Text(
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
