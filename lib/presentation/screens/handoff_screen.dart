import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_dimens.dart';
import '../../core/resources/app_text_styles.dart';
import '../../domain/entities/build_info.dart';
import '../../domain/entities/change_unit.dart';
import '../../domain/entities/console_snapshot.dart';
import '../../domain/entities/handoff_blocker.dart';
import '../../domain/entities/handoff_recipient.dart';
import '../../domain/entities/group.dart';
import '../../domain/entities/project_profile.dart';
import '../../domain/usecases/assess_handoff_readiness.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bloc/console_bloc.dart';
import '../bloc/sessions_bloc.dart';
import '../localization/text_formatters.dart';
import '../ui_kit/section_card.dart';
import '../widgets/feature_unavailable_view.dart';
import '../widgets/missing_key_block.dart';
import '../widgets/stack_filter_bar.dart';

/// Передача группы: мастер из четырёх шагов, все видны сразу.
/// Шаг, для которого у спеки нет данных, не исчезает — он объясняет,
/// чего не хватает.
class HandoffScreen extends StatefulWidget {
  const HandoffScreen({super.key});

  @override
  State<HandoffScreen> createState() => _HandoffScreenState();
}

class _HandoffScreenState extends State<HandoffScreen> {
  HandoffRecipient? _tester;
  HandoffRecipient? _manager;

  @override
  Widget build(BuildContext context) => BlocBuilder<ConsoleBloc, ConsoleState>(
        builder: (context, state) {
          final snapshot = state.snapshot;
          if (snapshot == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final group = state.group;
          if (!state.profile.enabled(SpecFeature.handoff) || group == null) {
            return FeatureUnavailableView(
                feature: SpecFeature.handoff,
                gate: state.profile.gate(SpecFeature.handoff));
          }
          final groupChanges = state.groupChanges;
          final readiness = AssessHandoffReadiness()(
            group: group,
            changes: groupChanges,
            semantics: state.profile.statuses,
            stackVisible: state.allowsStack,
          );
          return ListView(
            padding: AppDimens.screenPadding,
            children: [
              const _FilterRow(),
              const SizedBox(height: AppDimens.gapM),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 50,
                    child: Column(
                      children: [
                        _ReadinessStep(
                            readiness: readiness,
                            problem: snapshot.redmineProblem),
                        const SizedBox(height: AppDimens.gapL),
                        _BuildStep(group: group, stacks: state.stacks),
                        const SizedBox(height: AppDimens.gapL),
                        _RecipientsStep(
                          stack: state.handoffStack,
                          selectedTester: _tester,
                          selectedManager: _manager,
                          onTesterSelected: (person) =>
                              setState(() => _tester = person),
                          onManagerSelected: (person) =>
                              setState(() => _manager = person),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimens.gapXl),
                  Expanded(
                    flex: 50,
                    child: _PreviewStep(
                      group: group,
                      changes: groupChanges,
                      readiness: readiness,
                      stack: state.handoffStack,
                      recipients: state.recipientsStack == state.handoffStack
                          ? state.recipients
                          : null,
                      chosenTester: _tester,
                      chosenManager: _manager,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
}

class _FilterRow extends StatelessWidget {
  const _FilterRow();

  @override
  Widget build(BuildContext context) =>
      const Row(children: [Spacer(), StackFilterBar()]);
}

class _StepHeader extends StatelessWidget {
  final int number;
  final String title;
  final Color color;
  final bool dimmed;

  const _StepHeader({
    required this.number,
    required this.title,
    required this.color,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppDimens.gapS),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text('$number',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            ),
            const SizedBox(width: 10),
            Text(title,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: dimmed
                        ? AppColors.textMuted
                        : AppColors.textPrimary)),
          ],
        ),
      );
}

class _ReadinessStep extends StatelessWidget {
  final HandoffReadiness readiness;

  /// Почему трекер молчит: без этого «статус не опрошен» — полуправда,
  /// а человеку нужно знать, заполнять ему ключ или ждать Redmine.
  final RedmineProblem problem;

  const _ReadinessStep({required this.readiness, required this.problem});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    // Четвёртое состояние шага: не «готов» и не «есть блокеры», а
    // «неизвестно» — приложение не смогло спросить трекер.
    final unknown = readiness.statusUnknown;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
          number: 1,
          title: texts.handoffStepReadiness,
          color: unknown
              ? AppColors.textMuted
              : (readiness.ready ? AppColors.success : AppColors.warning),
          dimmed: unknown,
        ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  unknown
                      ? texts.handoffReadinessUnknown
                      : texts.handoffReadyCount(
                          readiness.readyCount, readiness.totalCount),
                  style: AppTextStyles.rowTitle),
              const SizedBox(height: AppDimens.gapS),
              if (unknown) ...[
                Text(
                    switch (problem) {
                      RedmineProblem.noApiKey => texts.handoffStatusNoKey,
                      RedmineProblem.unreachable =>
                        texts.handoffStatusUnreachable,
                      _ => texts.handoffStatusNotAsked,
                    },
                    style: AppTextStyles.hint.copyWith(height: 1.4)),
                const SizedBox(height: AppDimens.gapM),
                // Ключ личный — поле прямо здесь, без похода в форму ключей
                // за одним значением. Молчащий трекер поля не требует:
                // ему нужен повтор.
                if (problem == RedmineProblem.noApiKey)
                  const MissingKeyBlock(
                      keys: ['REDMINE_API_KEY'], lookedIn: 'REDMINE_API_KEY · .env')
                else
                  OutlinedButton(
                    onPressed: () =>
                        context.read<ConsoleBloc>().add(ConsoleRefreshed()),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 28),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      side: const BorderSide(color: AppColors.border),
                      backgroundColor: AppColors.cardHighlight,
                      foregroundColor: AppColors.textPrimary,
                    ),
                    child: Text(texts.partialRetry,
                        style: const TextStyle(fontSize: 12)),
                  ),
                const SizedBox(height: AppDimens.gapM),
              ],
              if (readiness.blockers.isEmpty)
                Text(texts.handoffNoBlockers,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.success))
              else ...[
                Text(texts.handoffBlockersLabel,
                    style: AppTextStyles.sectionLabel.copyWith(fontSize: 9.5)),
                const SizedBox(height: 6),
                for (final blocker in readiness.blockers)
                  _BlockerRow(blocker: blocker),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BlockerRow extends StatelessWidget {
  final HandoffBlocker blocker;

  const _BlockerRow({required this.blocker});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final stackLabel = texts.stackLabel(blocker.stack);
    final message = switch (blocker.kind) {
      HandoffBlockerKind.statusNotReady => texts.handoffBlockerStatus(
          blocker.changeTitle, blocker.stack == 'ios' ? 'iOS' : 'Android',
          blocker.status),
      HandoffBlockerKind.tasksOpen => texts.handoffBlockerTasks(
          blocker.changeTitle, stackLabel,
          blocker.openTaskNumbers.join(', ')),
      HandoffBlockerKind.statusUnknown =>
        texts.handoffBlockerStatusUnknown(blocker.changeTitle, stackLabel),
      HandoffBlockerKind.buildMissing =>
        texts.handoffBlockerBuild(stackLabel),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 4),
            decoration: const BoxDecoration(
                color: AppColors.warning, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: AppTextStyles.caption)),
        ],
      ),
    );
  }
}

/// Сборки ведёт не каждая спека: нет builds.yaml — шаг показывается
/// недоступным с причиной, а не пустыми строками «не записана».
class _BuildStep extends StatelessWidget {
  final Group group;
  final List<String> stacks;

  const _BuildStep({required this.group, required this.stacks});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final tracked = group.builds.isNotEmpty;
    final rows = stacks.isEmpty ? group.builds.keys.toList() : stacks;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
          number: 2,
          title: texts.handoffStepBuild,
          color: tracked ? AppColors.success : AppColors.textMuted,
          dimmed: !tracked,
        ),
        SectionCard(
          child: tracked
              ? Column(
                  children: [
                    for (final (index, stack) in rows.indexed) ...[
                      if (index > 0) const SizedBox(height: 10),
                      _BuildRow(
                          label: texts.stackLabel(stack),
                          buildInfo: group.buildFor(stack)),
                    ],
                  ],
                )
              : Align(
                  alignment: Alignment.centerLeft,
                  child: Text(texts.buildsNotTracked,
                      style: AppTextStyles.captionMuted),
                ),
        ),
      ],
    );
  }
}

class _BuildRow extends StatelessWidget {
  final String label;
  final BuildInfo? buildInfo;

  const _BuildRow({required this.label, required this.buildInfo});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final info = buildInfo;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
        ),
        Expanded(
          child: info == null
              ? Text(texts.handoffBuildMissingShort,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.warning))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(info.versionName,
                        style: AppTextStyles.monospace(12,
                            color: AppColors.monospaceText)),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (info.channel != null) info.channel!,
                        if (info.publishedAt != null)
                          texts.handoffBuildRecordedAt(DateFormat('d.MM HH:mm')
                              .format(info.publishedAt!.toLocal())),
                      ].join(' · '),
                      style: AppTextStyles.hint,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _RecipientsStep extends StatelessWidget {
  final String stack;
  final HandoffRecipient? selectedTester;
  final HandoffRecipient? selectedManager;
  final ValueChanged<HandoffRecipient> onTesterSelected;
  final ValueChanged<HandoffRecipient> onManagerSelected;

  const _RecipientsStep({
    required this.stack,
    required this.selectedTester,
    required this.selectedManager,
    required this.onTesterSelected,
    required this.onManagerSelected,
  });

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return BlocBuilder<ConsoleBloc, ConsoleState>(
      builder: (context, state) {
        final recipients =
            state.recipientsStack == stack ? state.recipients : null;
        final resolved = recipients?.resolved ?? false;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepHeader(
              number: 3,
              title: texts.handoffStepRecipients,
              color: resolved ? AppColors.success : AppColors.textMuted,
              dimmed: !resolved,
            ),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.recipientsLoading &&
                      state.recipientsStack == stack) ...[
                    Row(
                      children: [
                        const SizedBox(
                            width: 12,
                            height: 12,
                            child:
                                CircularProgressIndicator(strokeWidth: 1.5)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(texts.handoffRecipientsResolving,
                              style: AppTextStyles.captionMuted),
                        ),
                      ],
                    ),
                  ] else if (recipients == null) ...[
                    Text(texts.handoffRecipientsHint,
                        style: AppTextStyles.captionMuted),
                    const SizedBox(height: AppDimens.gapS),
                    OutlinedButton(
                      onPressed: () => context
                          .read<ConsoleBloc>()
                          .add(RecipientsRequested(stack)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        backgroundColor: AppColors.cardHighlight,
                        foregroundColor: AppColors.textPrimary,
                      ),
                      child: Text(texts.handoffRecipientsResolve,
                          style: const TextStyle(fontSize: 12)),
                    ),
                  ] else if (recipients.error.isNotEmpty) ...[
                    Text(texts.handoffRecipientsError(recipients.error),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.danger)),
                  ] else ...[
                    _RecipientGroup(
                      role: texts.handoffRecipientTester,
                      people: recipients.testers,
                      selected: selectedTester ?? recipients.testers.firstOrNull,
                      onSelected: onTesterSelected,
                    ),
                    const SizedBox(height: AppDimens.gapM),
                    _RecipientGroup(
                      role: texts.handoffRecipientManager,
                      people: recipients.managers,
                      selected:
                          selectedManager ?? recipients.managers.firstOrNull,
                      onSelected: onManagerSelected,
                    ),
                  ],
                  const SizedBox(height: AppDimens.gapS),
                  Text(texts.handoffRecipientsSource,
                      style: AppTextStyles.hint.copyWith(height: 1.4)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Роль и подобранные под неё люди: выбранный получит передачу.
/// Список открытый — видно, из кого выбираем.
class _RecipientGroup extends StatelessWidget {
  final String role;
  final List<HandoffRecipient> people;
  final HandoffRecipient? selected;
  final ValueChanged<HandoffRecipient> onSelected;

  const _RecipientGroup({
    required this.role,
    required this.people,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    if (people.isEmpty) {
      return Row(
        children: [
          _RoleChip(role: role),
          const SizedBox(width: 12),
          Text(texts.handoffRecipientPending,
              style: AppTextStyles.captionMuted),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RoleChip(role: role),
        const SizedBox(height: 6),
        for (final person in people)
          _RecipientOption(
            person: person,
            selected: person.redmineId == selected?.redmineId,
            onTap: () => onSelected(person),
          ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String role;

  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.cardHighlight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(role,
            style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary)),
      );
}

class _RecipientOption extends StatelessWidget {
  final HandoffRecipient person;
  final bool selected;
  final VoidCallback onTap;

  const _RecipientOption({
    required this.person,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.controlRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          children: [
            Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 15,
                color: selected ? AppColors.accent : AppColors.textMuted),
            const SizedBox(width: 10),
            SelectableText(person.mention,
                style: AppTextStyles.monospace(12,
                    color: selected
                        ? AppColors.monospaceText
                        : AppColors.textMuted)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(person.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12,
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary)),
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              Text(texts.handoffRecipientChosen,
                  style: const TextStyle(
                      fontSize: 10.5, color: AppColors.accent)),
            ],
          ],
        ),
      ),
    );
  }
}

class _PreviewStep extends StatelessWidget {
  final Group group;
  final List<ChangeUnit> changes;
  final HandoffReadiness readiness;
  final String stack;
  final HandoffRecipients? recipients;
  final HandoffRecipient? chosenTester;
  final HandoffRecipient? chosenManager;

  const _PreviewStep({
    required this.group,
    required this.changes,
    required this.readiness,
    required this.stack,
    required this.recipients,
    required this.chosenTester,
    required this.chosenManager,
  });

  HandoffRecipient? get _tester =>
      chosenTester ?? recipients?.testers.firstOrNull;

  HandoffRecipient? get _manager =>
      chosenManager ?? recipients?.managers.firstOrNull;

  /// Стек сообщения: передача идёт по одному стеку за раз.
  String get _messageStack => stack;

  /// Точная команда платформы — она же уйдёт в агентную сессию.
  /// Стека может не быть вовсе — тогда и флага в команде нет.
  String get _handoffCommand =>
      '/opsx-sprint ${group.id} handover'
      '${_messageStack.isEmpty ? '' : ' --stack $_messageStack'}';

  /// Команда с уточнением получателей: скрипт подбирает список, а кого
  /// именно назначить — решает человек здесь.
  String get _handoffPrompt {
    final tester = _tester;
    final manager = _manager;
    if (tester == null || manager == null) return _handoffCommand;
    return '$_handoffCommand\n\n'
        'Тестировщик: ${tester.mention} — ${tester.name} (Redmine ${tester.redmineId}).\n'
        'Менеджер: ${manager.mention} — ${manager.name} (Redmine ${manager.redmineId}).\n'
        'Используй именно их, не подбирай других.';
  }

  /// Ничего не уходит наружу без предпросмотра (бриф §3.4): подтверждаем,
  /// затем запускаем команду платформы в сессии, где виден каждый шаг.
  Future<void> _confirmAndRun(
      BuildContext context, AppLocalizations texts) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(texts.handoffSendButton,
            style: AppTextStyles.sectionTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(texts.handoffSendConfirm, style: AppTextStyles.body),
            const SizedBox(height: AppDimens.gapM),
            SelectableText(_handoffPrompt,
                style: AppTextStyles.monospace(12)),
            const SizedBox(height: AppDimens.gapS),
            Text(texts.handoffRunsWithBypass,
                style: AppTextStyles.hint.copyWith(height: 1.4)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(texts.handoffSendCancel,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background),
            child: Text(texts.handoffSendRun),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    context.read<SessionsBloc>().add(HandoffRunRequested(_handoffPrompt));
    context.read<ConsoleBloc>().add(ScreenSelected(ConsoleScreen.sessions));
  }

  String _buildMessage(AppLocalizations texts) {
    final stack = _messageStack;
    final build = group.buildFor(stack);
    final stackChanges = changes
        .where((change) =>
            change.stacks.any((candidate) => candidate.stack == stack))
        .toList();
    final issueOf = {
      for (final change in stackChanges)
        change.id: change.stacks
            .firstWhere((candidate) => candidate.stack == stack)
    };
    final lines = [
      texts.handoverMsgTitle,
      texts.handoverMsgSprint(group.title),
      texts.handoverMsgStack(texts.stackLabel(stack)),
      texts.handoverMsgRecipients(
          _tester?.mention ?? '@—', _manager?.mention ?? '@—'),
      if (build != null)
        texts.handoverMsgBuild(
            '${build.versionName}${build.channel != null ? ' · ${build.channel}' : ''}'),
      '',
      texts.handoverMsgComposition,
      for (final change in stackChanges)
        texts.handoverMsgTaskLine(
          '${issueOf[change.id]?.issueId ?? '—'}',
          change.title,
          issueOf[change.id]?.redmineStatus ?? '—',
          '${issueOf[change.id]?.doneCount}/${issueOf[change.id]?.tasks.length}',
        ),
      '',
      texts.handoverMsgOrder,
      for (final (index, change) in stackChanges.indexed)
        '  ${index + 1}. ${issueOf[change.id]?.issueId ?? change.id}'
            '${change.dependsOn.isEmpty ? '' : texts.handoverMsgOrderAfter(change.dependsOn.map((id) => '${issueOf[id]?.issueId ?? id}').join(', '))}',
    ];
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final affectedCount = changes
        .where((change) =>
            change.stacks.any((candidate) => candidate.stack == _messageStack))
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
            number: 4,
            title: texts.handoffStepPreview,
            color: readiness.ready ? AppColors.accent : AppColors.textMuted,
            dimmed: !readiness.ready),
        Opacity(
          opacity: readiness.ready ? 1 : 0.55,
          child: SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(texts.handoffPreviewLabel,
                    style: AppTextStyles.sectionLabel.copyWith(fontSize: 9.5)),
                const SizedBox(height: AppDimens.gapS),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.logBackground,
                    borderRadius:
                        BorderRadius.circular(AppDimens.controlRadius),
                  ),
                  child: SelectableText(
                    _buildMessage(texts),
                    style: AppTextStyles.monospace(11).copyWith(height: 1.55),
                  ),
                ),
                const SizedBox(height: AppDimens.gapM),
                Text(texts.handoffEffectsLabel,
                    style: AppTextStyles.sectionLabel.copyWith(fontSize: 9.5)),
                const SizedBox(height: AppDimens.gapS),
                _EffectRow(text: texts.handoffEffectAssignee(affectedCount)),
                _EffectRow(text: texts.handoffEffectComment(affectedCount)),
                _EffectRow(text: texts.handoffEffectMessage),
                const SizedBox(height: AppDimens.gapM),
                FilledButton(
                  onPressed: readiness.ready
                      ? () => _confirmAndRun(context, texts)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    disabledBackgroundColor:
                        AppColors.accent.withValues(alpha: 0.35),
                    foregroundColor: AppColors.background,
                    disabledForegroundColor:
                        AppColors.background.withValues(alpha: 0.7),
                  ),
                  child: Text(texts.handoffSendButton),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDimens.gapS),
        Text(
          switch (readiness) {
            // «Готовность 0 из 3» тут соврало бы: дело не в блокерах,
            // а в том, что статусы неизвестны.
            final state when state.statusUnknown =>
              texts.handoffSendUnknown,
            final state when state.ready =>
              texts.handoffStackNotice(texts.stackLabel(_messageStack)),
            final state => texts.handoffSendBlocked(
                state.readyCount, state.totalCount),
          },
          style: TextStyle(
              fontSize: 11.5,
              color:
                  readiness.ready ? AppColors.textMuted : AppColors.warning),
        ),
        const SizedBox(height: 4),
        SelectableText(_handoffCommand,
            style: AppTextStyles.monospace(11.5, color: AppColors.textMuted)),
      ],
    );
  }
}

class _EffectRow extends StatelessWidget {
  final String text;

  const _EffectRow({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                    color: AppColors.accent, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Text(text, style: AppTextStyles.caption),
          ],
        ),
      );
}
