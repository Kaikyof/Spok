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
import '../../domain/entities/feature_gate.dart';
import '../../domain/entities/issue_comment.dart';
import '../../domain/entities/merge_request_info.dart';
import '../../domain/entities/project_profile.dart';
import '../../domain/entities/slash_command.dart';
import '../../domain/entities/spec_schema.dart';
import '../../domain/entities/stack_state.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/usecases/list_change_artifacts.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bloc/console_bloc.dart';
import '../bloc/sessions_bloc.dart';
import '../localization/text_formatters.dart';
import '../ui_kit/doc_markdown.dart';
import '../ui_kit/marks_indicator.dart';
import '../ui_kit/redmine_issue_link.dart';
import '../ui_kit/section_card.dart';
import '../ui_kit/status_badge.dart';
import '../widgets/env_editor_dialog.dart';
import '../widgets/missing_key_block.dart';
import '../widgets/stack_filter_bar.dart';
import '../ui_kit/tappable.dart';

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
              allChanges: state.groupChanges,
              state: state,
              redmineBaseUrl: state.snapshot?.redmineBaseUrl ?? '',
              comments: state.comments,
              mergeRequests: state.mergeRequests,
            );
          }
          return _ChangeList(
            changes: state.groupChanges,
            state: state,
            redmineBaseUrl: state.snapshot?.redmineBaseUrl ?? '',
          );
        },
      );
}

class _ChangeList extends StatelessWidget {
  final List<ChangeUnit> changes;
  final ConsoleState state;
  final String redmineBaseUrl;

  const _ChangeList(
      {required this.changes,
      required this.state,
      required this.redmineBaseUrl});

  @override
  Widget build(BuildContext context) => ListView(
        padding: AppDimens.screenPadding,
        children: [
          const Row(children: [Spacer(), StackFilterBar()]),
          const SizedBox(height: AppDimens.gapM),
          for (final change in changes)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ChangeListRow(
                  change: change,
                  state: state,
                  redmineBaseUrl: redmineBaseUrl),
            ),
        ],
      );
}

class _ChangeListRow extends StatelessWidget {
  final ChangeUnit change;
  final ConsoleState state;
  final String redmineBaseUrl;

  const _ChangeListRow(
      {required this.change,
      required this.state,
      required this.redmineBaseUrl});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final visibleStacks = change.stacks
        .where((stack) => state.allowsStack(stack.stack))
        .toList();
    return Tappable(
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
  final ConsoleState state;
  final String redmineBaseUrl;
  final List<IssueComment>? comments;
  final List<MergeRequestInfo>? mergeRequests;

  const _ChangeCard({
    required this.change,
    required this.allChanges,
    required this.state,
    required this.redmineBaseUrl,
    required this.comments,
    required this.mergeRequests,
  });

  /// Список артефактов объявлен схемой спеки: у каждой команды он свой
  /// (у avelacom это ещё `test_case.md` и `specs/<capability>/spec.md`).
  /// `requires` из схемы задаёт порядок и подсказку «чего не хватает»:
  /// артефакт, у которого предшественники пусты, писать ещё рано.
  /// Схема карточки: своя у change'а (слой данных подставляет встроенную
  /// `spec-driven`, когда схемы в проекте нет), иначе схема спеки.
  /// Констант с именами файлов в коде больше нет.
  SpecSchema get _schema =>
      change.schema.isEmpty ? state.profile.schema : change.schema;

  List<_ArtifactState> _artifacts(AppLocalizations texts) {
    final states = const ListChangeArtifacts()(change, _schema);
    final labels = {
      for (final artifactState in states)
        artifactState.artifact.id:
            _artifactLabel(texts, artifactState.artifact),
    };
    return [
      for (final artifactState in states)
        _ArtifactState(
          doc: DocArtifact(
            labels[artifactState.artifact.id]!,
            artifactState.artifact.generates,
            // У маски открывается первая дельта; ненаписанному — нечего.
            artifactState.firstFile ??
                p.join(change.dir, artifactState.artifact.generates),
            artifactState.exists,
            id: artifactState.artifact.id,
          ),
          skipped: artifactState.skipped,
          waitingFor: [
            for (final required in artifactState.waitingFor)
              labels[required] ?? required,
          ],
        ),
    ];
  }

  String _artifactLabel(AppLocalizations texts, SchemaArtifact artifact) =>
      switch (artifact.id) {
        'proposal' => texts.artifactSpec,
        'design' => texts.artifactDesign,
        _ when artifact.stack.isNotEmpty =>
          texts.artifactTasksOfStack(texts.stackLabel(artifact.stack)),
        _ => artifact.description.isEmpty ? artifact.id : artifact.description,
      };

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final visibleStacks = change.stacks
        .where((stack) => state.allowsStack(stack.stack))
        .toList();
    final artifacts = _artifacts(texts);
    // Пропущенные по `skip_specs` в счёт не входят: их не ждут.
    final counted = artifacts.where((a) => !a.skipped).toList();
    final filledArtifacts = counted.where((a) => a.doc.exists).length;
    return ListView(
      padding: AppDimens.screenPadding,
      children: [
        Row(
          children: [
            Tappable(
              onTap: () =>
                  context.read<ConsoleBloc>().add(ChangeOpened(null)),
              effect: HoverEffect.underline,
              child:
                  Text(texts.backToChanges, style: AppTextStyles.captionMuted),
            ),
            const Spacer(),
            const StackFilterBar(),
          ],
        ),
        const SizedBox(height: 10),
        SelectableText(change.title, style: AppTextStyles.screenTitle),
        if (change.formatWarning.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(texts.changeFormatWarning(change.formatWarning),
              style: AppTextStyles.caption.copyWith(color: AppColors.warning)),
        ],
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
                  // Спека изменения — главный текст карточки: сперва
                  // «что меняем и зачем», потом «что осталось сделать».
                  _SpecCard(
                    artifact: artifacts
                        .where((a) => a.doc.fileName.contains('proposal'))
                        .map((a) => a.doc)
                        .firstOrNull,
                    content: state.changeSpec,
                  ),
                  const SizedBox(height: AppDimens.gapM),
                  for (final stackState in visibleStacks) ...[
                    _TaskChecklist(
                        stack: stackState,
                        changeId: change.id,
                        state: state),
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(texts.artifactsTitle,
                                  style: AppTextStyles.sectionTitle),
                            ),
                            Text(
                                texts.artifactsProgress(
                                    '$filledArtifacts', '${counted.length}'),
                                style: AppTextStyles.captionMuted),
                          ],
                        ),
                        const SizedBox(height: AppDimens.gapS),
                        for (final artifact in artifacts)
                          _ArtifactRow(state: artifact),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimens.gapM),
                  _DependenciesCard(change: change, allChanges: allChanges),
                  const SizedBox(height: AppDimens.gapM),
                  _CodeCard(
                    stacks: visibleStacks,
                    state: state,
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

/// Код: ветка change'а и цель MR. Блок выключается там, где спека не
/// работает с MR, — но с объяснением причины, а не пустотой.
class _CodeCard extends StatelessWidget {
  final List<StackState> stacks;
  final ConsoleState state;
  final List<MergeRequestInfo>? mergeRequests;
  final String changeId;

  const _CodeCard({
    required this.stacks,
    required this.state,
    required this.mergeRequests,
    required this.changeId,
  });

  String? _branchFor(String stack) => state.group?.branchFor(stack);

  /// Схема change'а, открытого на карточке; пустая — веток не будет.
  SpecSchema get _changeSchema =>
      state.selectedChange?.schema ?? SpecSchema.empty;

  MergeRequestInfo? _mrFor(String stack) =>
      mergeRequests?.where((mr) => mr.stack == stack).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    // Имя ветки объявлено схемой спеки (apply.instruction); не объявлено —
    // так и говорим: ни MR, ни ссылки без ветки быть не может.
    final schema =
        state.profile.schema.isEmpty ? _changeSchema : state.profile.schema;
    final sourceBranch = schema.branchFor(changeId);
    final mrEnabled = state.profile.enabled(SpecFeature.mergeRequests);

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
                value: sourceBranch ?? texts.codeBranchNotDeclared),
            if (_branchFor(stackState.stack) case final branch?)
              _CodeRow(label: texts.codeSprintBranch, value: branch),
            const SizedBox(height: 8),
            if (sourceBranch == null)
              const SizedBox.shrink()
            else if (mrEnabled)
              _MergeRequestRow(
                mergeRequest: _mrFor(stackState.stack),
                loading: mergeRequests == null,
                targetBranch: _branchFor(stackState.stack) ?? '',
              )
            else
              _CodeDisabledRow(
                  gate: state.profile.gate(SpecFeature.mergeRequests)),
            // Даже без токена человек может сходить в GitLab руками.
            if (sourceBranch == null
                ? null
                : state.profile.branchUrl(stackState.stack, sourceBranch)
                case final gitlabUrl?) ...[
              const SizedBox(height: 6),
              Tappable(
                onTap: () => launchUrl(Uri.parse(gitlabUrl)),
                effect: HoverEffect.underline,
                child: Text(texts.codeOpenInGitlab,
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.accent)),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Блок «Код» выключен — объясняем природу нехватки, а не молчим.
/// Своими руками правится только личный ключ, поэтому кнопка — там.
class _CodeDisabledRow extends StatelessWidget {
  final FeatureGate gate;

  const _CodeDisabledRow({required this.gate});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final blocker = gate.blocker;
    if (blocker == null) return const SizedBox.shrink();
    // Одна и та же выключённая фича означает три разные вещи, и путать их
    // нельзя: иначе человек пойдёт править общий файл спеки там, где ему
    // надо ввести свой ключ (сводный документ, 4.8).
    final reason = switch (blocker.scope) {
      RequirementScope.spec => texts.codeOffSpec,
      RequirementScope.personal => texts.codeOffPersonal,
      RequirementScope.runtime => texts.codeOffRuntime,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(reason, style: AppTextStyles.body),
        const SizedBox(height: 2),
        Text(
            blocker.detail.isEmpty
                ? blocker.lookedIn
                : '${blocker.lookedIn} · ${blocker.detail}',
            style: AppTextStyles.monospace(10.5, color: AppColors.textMuted)),
        if (blocker.scope == RequirementScope.personal) ...[
          const SizedBox(height: AppDimens.gapS),
          // Имя ключа известно — спрашиваем значение здесь же: человек уже
          // стоит там, где увидел нехватку (борд 19).
          if (blocker.keys.isNotEmpty)
            MissingKeyBlock(keys: blocker.keys, lookedIn: blocker.lookedIn)
          else
            _CodeGateButton(
                label: texts.gatePersonalFill,
                onTap: () => EnvEditorDialog.show(context)),
        ],
        if (blocker.scope == RequirementScope.runtime) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              _CodeGateButton(
                  label: texts.gateRuntimeRetry,
                  onTap: () =>
                      context.read<ConsoleBloc>().add(ConsoleRefreshed())),
              const SizedBox(width: AppDimens.gapS),
              _CodeGateButton(
                  label: texts.gateRuntimeChangeKey,
                  onTap: () => EnvEditorDialog.show(context)),
            ],
          ),
        ],
      ],
    );
  }
}

class _CodeGateButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _CodeGateButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.border),
          backgroundColor: AppColors.cardHighlight,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(0, 32),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      );
}

/// Строка «подпись — значение» с копируемым моноширинным значением.
class _CodeRow extends StatelessWidget {
  final String label;
  final String value;

  const _CodeRow({required this.label, required this.value});

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
                  color: AppColors.monospaceText),
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
              Tappable(
                onTap: () => launchUrl(Uri.parse(mr.webUrl)),
                effect: HoverEffect.underline,
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
              Tappable(
                onTap: () => setState(() => _expanded = true),
                effect: HoverEffect.underline,
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

/// Артефакт и чего ему не хватает: пустой список — писать можно хоть сейчас.
class _ArtifactState {
  final DocArtifact doc;
  final List<String> waitingFor;

  /// Пропущен по `skip_specs` — не ненаписан, а нарочно отсутствует.
  final bool skipped;

  const _ArtifactState(
      {required this.doc, required this.waitingFor, this.skipped = false});
}

/// Спека изменения — главный текст карточки. Не написана — говорим об этом
/// прямо и показываем, какой файл ждёт схема.
class _SpecCard extends StatelessWidget {
  final DocArtifact? artifact;
  final String? content;

  const _SpecCard({required this.artifact, required this.content});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final doc = artifact;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(texts.changeSpecTitle,
                    style: AppTextStyles.sectionTitle),
              ),
              if (doc != null && doc.exists)
                Tappable(
                  onTap: () =>
                      context.read<ConsoleBloc>().add(DocOpened(doc)),
                  effect: HoverEffect.underline,
                  child: Text(texts.changeSpecOpen,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.accent)),
                ),
            ],
          ),
          if (doc != null) ...[
            const SizedBox(height: 2),
            Text(doc.fileName,
                style: AppTextStyles.monospace(10.5,
                    color: AppColors.textMuted)),
          ],
          const SizedBox(height: AppDimens.gapS),
          if (doc == null || !doc.exists)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(texts.changeSpecMissing, style: AppTextStyles.body),
                const SizedBox(height: 4),
                Text(
                    texts.changeSpecMissingHint(
                        doc?.fileName ?? 'proposal.md'),
                    style: AppTextStyles.captionMuted),
              ],
            )
          else if (content == null)
            Text(texts.changeSpecLoading, style: AppTextStyles.captionMuted)
          else
            _SpecBody(content: content!),
        ],
      ),
    );
  }
}

class _ArtifactRow extends StatelessWidget {
  final _ArtifactState state;

  const _ArtifactRow({required this.state});

  DocArtifact get artifact => state.doc;

  @override
  Widget build(BuildContext context) => Tappable(
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
                    size: 16, color: AppColors.textMuted)
              else
                _ArtifactHint(state: state),
            ],
          ),
        ),
      );
}

/// Почему артефакта нет: ждёт предшественника или его просто не написали.
class _ArtifactHint extends StatelessWidget {
  final _ArtifactState state;

  const _ArtifactHint({required this.state});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final waiting = state.waitingFor;
    return Text(
      state.skipped
          ? texts.artifactSkipped
          : waiting.isEmpty
              ? texts.artifactMissing
              : texts.artifactWaits(waiting.join(', ')),
      style: AppTextStyles.hint,
    );
  }
}

class _TaskChecklist extends StatelessWidget {
  final StackState stack;
  final String changeId;
  final ConsoleState state;

  const _TaskChecklist(
      {required this.stack, required this.changeId, required this.state});

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
          Row(
            children: [
              Flexible(
                child: _ApplyButton(
                    stack: stack, changeId: changeId, allDone: allDone),
              ),
              const SizedBox(width: AppDimens.gapS),
              _MoreActionsMenu(changeId: changeId, stack: stack.stack),
            ],
          ),
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
            // Стека может не быть вовсе — тогда и флага не нужно.
            final stackFlag = stack.stack == StackState.singleWorkStack
                ? ''
                : ' --stack ${stack.stack}';
            context
                .read<SessionsBloc>()
                .add(HandoffRunRequested('/opsx-apply $changeId$stackFlag'));
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

/// Меню действий карточки. Состав выводится из сигнатур команд спеки:
/// принимает `[change]` — попадает сюда. Роль «реализовать» уже вынесена
/// отдельной кнопкой, а применимых команд нет вовсе — нет и меню.
class _MoreActionsMenu extends StatelessWidget {
  final String changeId;
  final String stack;

  const _MoreActionsMenu({required this.changeId, required this.stack});

  /// Известное подставляем из контекста, остальное человек допишет словами.
  String _promptFor(SlashCommand command) {
    final wantsStack = command.slots.any((slot) => slot.contains('stack'));
    final stackFlag = wantsStack && stack != StackState.singleWorkStack
        ? ' --stack $stack'
        : '';
    return '${command.invocation} $changeId$stackFlag ';
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final sessions = context.watch<SessionsBloc>().state;
    final applyId = sessions.roles[CommandRole.apply]?.id;
    final actions = [
      for (final command in sessions.commands)
        if (command.scope == CommandScope.change && command.id != applyId)
          command,
    ];
    if (actions.isEmpty) return const SizedBox.shrink();
    return PopupMenuButton<SlashCommand>(
      tooltip: texts.changeActionsHint,
      color: AppColors.cardHighlight,
      onSelected: (command) {
        context.read<SessionsBloc>().add(SessionDraftSet(_promptFor(command)));
        context.read<ConsoleBloc>().add(ScreenSelected(ConsoleScreen.sessions));
      },
      itemBuilder: (_) => [
        for (final command in actions)
          PopupMenuItem(
            value: command,
            child: Row(
              children: [
                Text(command.invocation,
                    style: AppTextStyles.monospace(11.5,
                        color: AppColors.monospaceText)),
                const SizedBox(width: AppDimens.gapM),
                Flexible(
                  child: Text(command.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption),
                ),
              ],
            ),
          ),
      ],
      child: Tappable(
        tapHandledAbove: true,
        borderRadius: BorderRadius.circular(AppDimens.controlRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cardHighlight,
            borderRadius: BorderRadius.circular(AppDimens.controlRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(texts.changeMoreActions,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textPrimary)),
              const Icon(Icons.expand_more,
                  size: 15, color: AppColors.textMuted),
            ],
          ),
        ),
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
              Tappable(
                onTap: () => context.read<ConsoleBloc>().add(DocOpened(null)),
                effect: HoverEffect.underline,
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
            child: DocMarkdown(data: content ?? texts.docReadError(doc.path)),
          ),
        ),
      ],
    );
  }
}


/// Текст спеки в карточке.
///
/// Своей прокрутки у блока нет намеренно. Раньше спека жила в окне
/// высотой 420 внутри прокрутки страницы, и это упиралось в тупик:
/// докрутив спеку до конца, человек упирался — страница дальше не шла.
/// Вложенные прокрутки во Flutter не передают колесо наружу: сигнал
/// забирает самый внутренний список и, дойдя до края, просто молчит
/// (`ScrollPositionWithSingleContext.pointerScroll` ничего не делает,
/// когда двигаться некуда). Поэтому прокрутка на странице одна, а длинная
/// спека складывается — задачи и код остаются под рукой, как и задумано.
class _SpecBody extends StatefulWidget {
  final String content;

  const _SpecBody({required this.content});

  @override
  State<_SpecBody> createState() => _SpecBodyState();
}

class _SpecBodyState extends State<_SpecBody> {
  /// Высота, после которой спека складывается: примерно экран текста.
  static const _collapsedHeight = 420.0;

  final _controller = ScrollController();

  bool _expanded = false;

  /// Спека не поместилась в сложенный вид — есть что разворачивать.
  bool _clipped = false;

  @override
  void didUpdateWidget(_SpecBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Открыли другой change — меряем заново и показываем его спеку
    // с начала, а не в том виде, в каком оставили прошлую.
    if (oldWidget.content != widget.content) {
      _expanded = false;
      _clipped = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Померить можно только после раскладки: сам markdown знает свою высоту
  /// лишь когда отрисован. Контроллер сложенного вида отвечает на это
  /// точно — `maxScrollExtent` больше нуля ровно тогда, когда текст
  /// не поместился.
  void _measure() {
    if (_expanded || _clipped || !_controller.hasClients) return;
    if (_controller.position.maxScrollExtent > 0.5) {
      setState(() => _clipped = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    final markdown = Markdown(
      data: widget.content,
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      selectable: true,
      controller: _controller,
      // Прокрутка на странице одна — эта в неё не вмешивается.
      physics: const NeverScrollableScrollPhysics(),
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(
            fontSize: 12.5, height: 1.5, color: AppColors.textSecondary),
        h1: AppTextStyles.sectionTitle,
        h2: AppTextStyles.sectionTitle,
        h3: AppTextStyles.rowTitle,
        code: AppTextStyles.monospace(11.5, color: AppColors.monospaceText),
        listBullet:
            const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_expanded)
          markdown
        else
          ClipRect(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxHeight: _collapsedHeight),
              child: _clipped
                  // Текст тает к нижнему краю: видно, что он не кончился,
                  // и обрыв на полуслове не читается как сбой.
                  ? ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black,
                          Colors.black,
                          Colors.transparent
                        ],
                        stops: [0, 0.85, 1],
                      ).createShader(bounds),
                      blendMode: BlendMode.dstIn,
                      child: markdown,
                    )
                  : markdown,
            ),
          ),
        if (_clipped)
          Padding(
            padding: const EdgeInsets.only(top: AppDimens.gapS),
            child: Tappable(
              onTap: () => setState(() => _expanded = !_expanded),
              effect: HoverEffect.underline,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      size: 16, color: AppColors.accent),
                  const SizedBox(width: 4),
                  Text(
                      _expanded
                          ? texts.changeSpecCollapse
                          : texts.changeSpecExpandHere,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.accent)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
