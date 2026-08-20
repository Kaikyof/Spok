import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_dimens.dart';
import '../../core/resources/app_text_styles.dart';
import '../../domain/entities/build_info.dart';
import '../../domain/entities/change_unit.dart';
import '../../domain/entities/handoff_blocker.dart';
import '../../domain/entities/sprint.dart';
import '../../domain/usecases/assess_handoff_readiness.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bloc/console_bloc.dart';
import '../bloc/sessions_bloc.dart';
import '../localization/text_formatters.dart';
import '../ui_kit/section_card.dart';
import '../ui_kit/stack_filter_control.dart';

/// Передача спринта: мастер из четырёх шагов, все видны сразу,
/// недоступные приглушены (бриф §5.3).
class HandoffScreen extends StatelessWidget {
  const HandoffScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<ConsoleBloc, ConsoleState>(
        builder: (context, state) {
          final snapshot = state.snapshot;
          final sprint = state.sprint;
          if (snapshot == null || sprint == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final readiness = AssessHandoffReadiness()(
            sprint: sprint,
            changes: snapshot.changes,
            stackVisible: state.stackFilter.allows,
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
                        _ReadinessStep(readiness: readiness),
                        const SizedBox(height: AppDimens.gapL),
                        _BuildStep(sprint: sprint),
                        const SizedBox(height: AppDimens.gapL),
                        const _RecipientsStep(),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimens.gapXl),
                  Expanded(
                    flex: 50,
                    child: _PreviewStep(
                      sprint: sprint,
                      changes: snapshot.changes,
                      readiness: readiness,
                      stackFilter: state.stackFilter,
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
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return BlocBuilder<ConsoleBloc, ConsoleState>(
      buildWhen: (previous, current) =>
          previous.stackFilter != current.stackFilter,
      builder: (context, state) => Row(
        children: [
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

  const _ReadinessStep({required this.readiness});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
          number: 1,
          title: texts.handoffStepReadiness,
          color: readiness.ready ? AppColors.success : AppColors.warning,
        ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  texts.handoffReadyCount(
                      readiness.readyCount, readiness.totalCount),
                  style: AppTextStyles.rowTitle),
              const SizedBox(height: AppDimens.gapS),
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

class _BuildStep extends StatelessWidget {
  final Sprint sprint;

  const _BuildStep({required this.sprint});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final recorded = sprint.buildIos != null || sprint.buildAndroid != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
          number: 2,
          title: texts.handoffStepBuild,
          color: recorded ? AppColors.success : AppColors.warning,
        ),
        SectionCard(
          child: Column(
            children: [
              _BuildRow(label: texts.stackIos, buildInfo: sprint.buildIos),
              const SizedBox(height: 10),
              _BuildRow(
                  label: texts.stackAndroid, buildInfo: sprint.buildAndroid),
            ],
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
  const _RecipientsStep();

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
            number: 3,
            title: texts.handoffStepRecipients,
            color: AppColors.textMuted,
            dimmed: true),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RecipientRow(role: texts.handoffRecipientTester),
              const SizedBox(height: AppDimens.gapS),
              _RecipientRow(role: texts.handoffRecipientManager),
              const SizedBox(height: AppDimens.gapS),
              Text(texts.handoffRecipientsNote,
                  style: AppTextStyles.hint.copyWith(height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecipientRow extends StatelessWidget {
  final String role;

  const _RecipientRow({required this.role});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return Row(
      children: [
        Container(
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
        ),
        const SizedBox(width: 12),
        Text(texts.handoffRecipientPending, style: AppTextStyles.captionMuted),
      ],
    );
  }
}

class _PreviewStep extends StatelessWidget {
  final Sprint sprint;
  final List<ChangeUnit> changes;
  final HandoffReadiness readiness;
  final StackFilter stackFilter;

  const _PreviewStep({
    required this.sprint,
    required this.changes,
    required this.readiness,
    required this.stackFilter,
  });

  /// Стек сообщения: передача идёт по одному стеку за раз.
  String get _messageStack =>
      stackFilter == StackFilter.android ? 'android' : 'ios';

  /// Точная команда платформы — она же уйдёт в агентную сессию.
  String get _handoffCommand =>
      '/opsx-sprint ${sprint.id} handover --stack $_messageStack';

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
            SelectableText(_handoffCommand,
                style: AppTextStyles.monospace(12)),
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
    context.read<SessionsBloc>().add(SessionMessageSent(_handoffCommand));
    context.read<ConsoleBloc>().add(ScreenSelected(ConsoleScreen.sessions));
  }

  String _buildMessage(AppLocalizations texts) {
    final stack = _messageStack;
    final build =
        stack == 'ios' ? sprint.buildIos : sprint.buildAndroid;
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
      texts.handoverMsgSprint(sprint.title),
      texts.handoverMsgStack(texts.stackLabel(stack)),
      texts.handoverMsgRecipients('@—', '@—'),
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
          readiness.ready
              ? texts.handoffStackNotice(texts.stackLabel(_messageStack))
              : texts.handoffSendBlocked(
                  readiness.readyCount, readiness.totalCount),
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
