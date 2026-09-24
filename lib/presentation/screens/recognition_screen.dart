import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_dimens.dart';
import '../../core/resources/app_text_styles.dart';
import '../../domain/entities/feature_gate.dart';
import '../../domain/entities/project_profile.dart';
import '../../domain/entities/spec_recognition.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bloc/console_bloc.dart';
import '../localization/text_formatters.dart';
import '../ui_kit/section_card.dart';

/// Шаг 3 подключения — «Что распознано» (борд 10).
///
/// Экран доверия: спека чужая, приложение вывело её устройство из файлов, и
/// человек должен увидеть результат до того, как начнёт на него опираться.
/// Поэтому шаг не проматывается сам — из него выходят кнопкой.
///
/// «Изменить» открывает файл спеки, по которому часть разобрана: источник
/// правды — сама спека, а не настройка в приложении. Правка поверх спеки
/// (стратегия, статусы, список стеков) живёт в «Настройках проекта» —
/// это следующий пункт очереди 3.
class RecognitionScreen extends StatelessWidget {
  const RecognitionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return ColoredBox(
      color: AppColors.background,
      child: BlocBuilder<ConsoleBloc, ConsoleState>(
        buildWhen: (previous, current) =>
            previous.snapshot != current.snapshot,
        builder: (context, state) {
          final profile = state.profile;
          final recognition = profile.recognition;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              // Прокрутка одна на весь шаг: карточек шесть, плюс матрица
              // фич — в низкое окно это не влезает.
              child: SingleChildScrollView(
                padding: AppDimens.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Head(recognition: recognition),
                    const SizedBox(height: AppDimens.gapM),
                    for (final item in recognition.items) ...[
                      _PartCard(item: item),
                      const SizedBox(height: AppDimens.gapS),
                    ],
                    const SizedBox(height: AppDimens.gapS),
                    _FeatureMatrix(profile: profile),
                    const SizedBox(height: AppDimens.gapL),
                    Wrap(
                      spacing: AppDimens.gapM,
                      runSpacing: AppDimens.gapS,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FilledButton(
                          onPressed: () => context
                              .read<ConsoleBloc>()
                              .add(SpecRecognitionConfirmed()),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: AppColors.background,
                          ),
                          child: Text(texts.recognizedOpen),
                        ),
                        // Не та спека — вернуться к адресу, а не искать
                        // выход через шапку уже открытого приложения.
                        TextButton(
                          onPressed: () => context
                              .read<ConsoleBloc>()
                              .add(SpecSwitchRequested(true)),
                          child: Text(texts.recognizedAnotherSpec,
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Head extends StatelessWidget {
  final SpecRecognition recognition;

  const _Head({required this.recognition});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final path = context.read<ConsoleBloc>().repository.rootPath ?? '';
    return SectionCard(
      padding: const EdgeInsets.all(AppDimens.gapL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(texts.recognizedTitle, style: AppTextStyles.screenTitle),
          const SizedBox(height: AppDimens.gapXs),
          if (path.isNotEmpty)
            Text(path,
                style:
                    AppTextStyles.monospace(11, color: AppColors.textMuted)),
          const SizedBox(height: AppDimens.gapM),
          Row(
            children: [
              Icon(
                  recognition.complete
                      ? Icons.check_circle_outline
                      : Icons.help_outline,
                  size: 16,
                  color: recognition.complete
                      ? AppColors.success
                      : AppColors.warning),
              const SizedBox(width: AppDimens.gapS),
              Expanded(
                child: Text(
                    texts.recognizedSummary(
                        recognition.recognizedCount, recognition.items.length),
                    style: AppTextStyles.sectionTitle),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gapS),
          Text(texts.recognizedNote,
              style: AppTextStyles.hint.copyWith(height: 1.5)),
        ],
      ),
    );
  }
}

/// Одна разобранная часть устройства спеки: что понято, чем именно и куда
/// идти, если понято не так.
class _PartCard extends StatelessWidget {
  final RecognizedItem item;

  const _PartCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
              item.recognized
                  ? Icons.check_circle_outline
                  : Icons.remove_circle_outline,
              size: 15,
              color:
                  item.recognized ? AppColors.success : AppColors.warning),
          const SizedBox(width: AppDimens.gapS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(texts.recognizedPartTitle(item.part),
                    style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(texts.recognizedValue(item),
                    style: item.recognized
                        ? AppTextStyles.rowTitle
                        : AppTextStyles.rowTitle
                            .copyWith(color: AppColors.warning)),
                const SizedBox(height: AppDimens.gapXs),
                // Где искали — чтобы «почему не понято» занимало секунды.
                Text(item.lookedIn,
                    style: AppTextStyles.monospace(10.5,
                        color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.gapM),
          _EditAction(item: item),
        ],
      ),
    );
  }
}

/// «Изменить» — открыть в редакторе тот файл спеки, который решает. Файла
/// нет или источников несколько — кнопки нет: неработающая кнопка хуже,
/// чем строка о том, откуда собрано значение.
class _EditAction extends StatelessWidget {
  final RecognizedItem item;

  const _EditAction({required this.item});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    if (item.sourcePath.isEmpty) {
      return SizedBox(
        width: 120,
        child: Text(texts.recognizedManySources,
            style: AppTextStyles.hint.copyWith(height: 1.3),
            textAlign: TextAlign.right),
      );
    }
    return OutlinedButton(
      onPressed: () => context
          .read<ConsoleBloc>()
          .add(RecognitionSourceOpened(item.sourcePath)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 28),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        side: const BorderSide(color: AppColors.border),
        backgroundColor: AppColors.cardHighlight,
        foregroundColor: AppColors.textPrimary,
      ),
      child: Tooltip(
        message: texts.recognizedEditTooltip(p.basename(item.sourcePath)),
        child: Text(texts.recognizedEdit,
            style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}

/// Матрица «что будет работать»: разбор сам по себе человеку мало говорит,
/// ему важно, какие экраны от него зажгутся, а какие останутся с
/// объяснением.
class _FeatureMatrix extends StatelessWidget {
  final ProjectProfile profile;

  const _FeatureMatrix({required this.profile});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(texts.recognizedMatrixTitle, style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppDimens.gapXs),
          Text(texts.recognizedMatrixNote,
              style: AppTextStyles.hint.copyWith(height: 1.4)),
          const SizedBox(height: AppDimens.gapM),
          for (final feature in SpecFeature.values)
            _FeatureRow(feature: feature, gate: profile.gate(feature)),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final SpecFeature feature;
  final FeatureGate gate;

  const _FeatureRow({required this.feature, required this.gate});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final blocker = gate.blocker;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(gate.available ? Icons.check : Icons.circle_outlined,
              size: 15,
              color:
                  gate.available ? AppColors.success : AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(texts.featureTitle(feature),
                    style: AppTextStyles.rowTitle),
                // Выключено — говорим, чего именно не хватило: иначе
                // человек решит, что приложение не умеет этого вовсе.
                if (!gate.available && blocker != null) ...[
                  const SizedBox(height: 2),
                  Text(
                      texts.recognizedFeatureBlocker(
                          texts.requirementTitle(blocker.id)),
                      style: AppTextStyles.hint.copyWith(height: 1.3)),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppDimens.gapM),
          Text(
              gate.available
                  ? texts.recognizedFeatureOn
                  : texts.recognizedFeatureOff,
              style: AppTextStyles.hint.copyWith(
                  color: gate.available
                      ? AppColors.textMuted
                      : AppColors.warning)),
        ],
      ),
    );
  }
}
