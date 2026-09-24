import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_dimens.dart';
import '../../core/resources/app_text_styles.dart';
import '../../domain/entities/feature_gate.dart';
import '../../domain/entities/project_profile.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bloc/console_bloc.dart';
import '../bloc/sessions_bloc.dart';
import '../localization/text_formatters.dart';
import '../ui_kit/section_card.dart';
import 'env_editor_dialog.dart';
import 'missing_key_block.dart';

/// Выключенная фича не прячется, а объясняет: чеклист требований, где их
/// искали и что сделать. Природа нехватки важнее самого факта — спеке нужен
/// процесс, человеку — свой ключ, системе — ответ.
class FeatureUnavailableView extends StatelessWidget {
  final SpecFeature feature;
  final FeatureGate gate;

  const FeatureUnavailableView(
      {super.key, required this.feature, required this.gate});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final personal = gate.requirements.where((requirement) =>
        !requirement.satisfied &&
        requirement.scope == RequirementScope.personal);
    final runtime = gate.requirements.where((requirement) =>
        !requirement.satisfied &&
        requirement.scope == RequirementScope.runtime);
    return ListView(
      padding: AppDimens.screenPadding,
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(texts.featureTitle(feature),
                        style: AppTextStyles.screenTitle),
                  ),
                  Text(
                      texts.gateProgress('${gate.satisfiedCount}',
                          '${gate.requirements.length}'),
                      style: AppTextStyles.captionMuted),
                ],
              ),
              const SizedBox(height: AppDimens.gapS),
              Text(texts.featureWhy(feature),
                  style: AppTextStyles.body.copyWith(height: 1.5)),
              const SizedBox(height: AppDimens.gapL),
              if (gate.mandatory.isNotEmpty) ...[
                Text(texts.gateMandatory,
                    style: AppTextStyles.sectionLabel.copyWith(fontSize: 9.5)),
                const SizedBox(height: AppDimens.gapS),
                for (final requirement in gate.mandatory)
                  _RequirementRow(requirement: requirement),
              ],
              if (gate.optional.isNotEmpty) ...[
                const SizedBox(height: AppDimens.gapM),
                Text(texts.gateOptional,
                    style: AppTextStyles.sectionLabel.copyWith(fontSize: 9.5)),
                const SizedBox(height: AppDimens.gapS),
                for (final requirement in gate.optional)
                  _RequirementRow(requirement: requirement),
              ],
              const SizedBox(height: AppDimens.gapL),
              _SpecActions(feature: feature, gate: gate),
            ],
          ),
        ),
        for (final requirement in personal) ...[
          const SizedBox(height: AppDimens.gapL),
          _PersonalBanner(requirement: requirement),
        ],
        for (final requirement in runtime) ...[
          const SizedBox(height: AppDimens.gapL),
          _RuntimeBanner(requirement: requirement),
        ],
      ],
    );
  }
}

class _RequirementRow extends StatelessWidget {
  final FeatureRequirement requirement;

  const _RequirementRow({required this.requirement});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final satisfied = requirement.satisfied;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(satisfied ? Icons.check : Icons.circle_outlined,
              size: 15,
              color: satisfied ? AppColors.success : AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(texts.requirementTitle(requirement.id),
                    style: AppTextStyles.rowTitle),
                const SizedBox(height: 2),
                // Где искали — чтобы «почему пусто» занимало секунды.
                Text(
                  [
                    requirement.lookedIn,
                    if (requirement.detail.isNotEmpty) requirement.detail,
                  ].where((part) => part.isNotEmpty).join(' · '),
                  style: AppTextStyles.monospace(10.5,
                      color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.gapM),
          Text(satisfied ? texts.gateFound : texts.gateMissing,
              style: AppTextStyles.hint.copyWith(
                  color:
                      satisfied ? AppColors.textMuted : AppColors.warning)),
        ],
      ),
    );
  }
}

/// Нехватка на стороне спеки правится её же процессом: заготовка файла
/// или запуск агента в репозитории спеки.
class _SpecActions extends StatelessWidget {
  final SpecFeature feature;
  final FeatureGate gate;

  const _SpecActions({required this.feature, required this.gate});

  /// Заготовка того, чего не хватает: человек кладёт её в спеку сам.
  String? _template(FeatureRequirement requirement) =>
      switch (requirement.id) {
        RequirementId.buildsFile => '''
# builds.yaml в каталоге группы. Первая запись — последняя сборка.
<stack>:
  builds:
    - version_name: "1.4.0"
      version_code: 152
      channel: "TestFlight"
      published_at: 2026-08-20T14:03:00Z
      url: https://…
''',
        RequirementId.grouping => '''
# openspec/doc/<group>/sprint.yaml — ветки группы и режим сдачи.
branches:
  <stack>:
    name: sprint/2026-08-<group>
delivery: batch
''',
        RequirementId.statusSemantics => '''
# openspec/redmine.yaml — что значат статусы этой спеки.
sync:
  on_push_new_issue_status_id: 7
  on_dev_start_status_id: 2
  on_mr_open_status_id: 12
  on_change_complete_status_id: 16
statuses:
  - id: 7
    name: Новая
    closing: false
    completes_task: false
''',
        _ => null,
      };

  String _agentPrompt(AppLocalizations texts, FeatureRequirement requirement) =>
      'В этой спеке не хватает: ${texts.requirementTitle(requirement.id)} '
      '(искали: ${requirement.lookedIn}). '
      'Нужно для фичи «${texts.featureTitle(feature)}» консоли. '
      'Предложи изменение спеки и выполни его.';

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final unmet = gate.requirements.where((requirement) =>
        !requirement.satisfied && requirement.scope == RequirementScope.spec);
    final first = unmet.firstOrNull;
    if (first == null) return const SizedBox.shrink();
    final template = _template(first);
    return Wrap(
      spacing: AppDimens.gapM,
      runSpacing: AppDimens.gapS,
      children: [
        FilledButton(
          onPressed: () {
            context
                .read<SessionsBloc>()
                .add(HandoffRunRequested(_agentPrompt(texts, first)));
            context
                .read<ConsoleBloc>()
                .add(ScreenSelected(ConsoleScreen.sessions));
          },
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.background),
          child: Text(texts.gateAskAgent),
        ),
        if (template != null)
          OutlinedButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: template));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(texts.gateTemplateCopied)));
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              backgroundColor: AppColors.card,
              foregroundColor: AppColors.textPrimary,
            ),
            child: Text(texts.gateCopyTemplate,
                style: const TextStyle(fontSize: 12)),
          ),
      ],
    );
  }
}

/// Самый частый случай у нового человека: спека всё поддерживает, а ключей
/// на машине ещё нет. Это не недоделанная спека — и выглядеть так не должно.
class _PersonalBanner extends StatelessWidget {
  final FeatureRequirement requirement;

  const _PersonalBanner({required this.requirement});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    // Имена ключей известны — спрашиваем значение прямо здесь, а не гоняем
    // человека в форму ключей за одним токеном.
    if (requirement.keys.isNotEmpty) {
      return MissingKeyBlock(
          keys: requirement.keys, lookedIn: requirement.lookedIn);
    }
    return SectionCard(
      color: AppColors.cardHighlight,
      borderColor: AppColors.accent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(texts.gatePersonalTitle,
                    style: AppTextStyles.sectionTitle),
                const SizedBox(height: 4),
                Text(texts.gatePersonalNote, style: AppTextStyles.caption),
                const SizedBox(height: 6),
                Text(requirement.lookedIn,
                    style: AppTextStyles.monospace(10.5,
                        color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.gapM),
          FilledButton(
            onPressed: () => EnvEditorDialog.show(context),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background),
            child: Text(texts.gatePersonalFill),
          ),
        ],
      ),
    );
  }
}

class _RuntimeBanner extends StatelessWidget {
  final FeatureRequirement requirement;

  const _RuntimeBanner({required this.requirement});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return SectionCard(
      color: AppColors.warningBackground,
      borderColor: AppColors.warningBorder,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(texts.gateRuntimeTitle,
                    style: AppTextStyles.sectionTitle),
                const SizedBox(height: 4),
                Text(
                    [requirement.lookedIn, requirement.detail]
                        .where((part) => part.isNotEmpty)
                        .join(' · '),
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.gapM),
          OutlinedButton(
            onPressed: () =>
                context.read<ConsoleBloc>().add(ConsoleRefreshed()),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              backgroundColor: AppColors.card,
              foregroundColor: AppColors.textPrimary,
            ),
            child: Text(texts.gateRuntimeRetry,
                style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: AppDimens.gapS),
          TextButton(
            onPressed: () => EnvEditorDialog.show(context),
            child: Text(texts.gateRuntimeEditKey,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
