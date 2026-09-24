import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_dimens.dart';
import '../../core/resources/app_text_styles.dart';
import '../../data/sources/git_clone_source.dart';
import '../../domain/entities/clone_progress.dart';
import '../../domain/entities/operation_progress.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bloc/console_bloc.dart';
import '../localization/text_formatters.dart';
import '../ui_kit/progress_panel.dart';
import '../ui_kit/section_card.dart';

/// Настройка спеки: путь к её репозиторию. Показывается, когда спека не
/// найдена, и когда человек меняет её сам из шапки.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _pathController = TextEditingController();
  String _configPath = '';

  @override
  void initState() {
    super.initState();
    // Подсказка под полем меняется по мере ввода: человек должен видеть,
    // что именно произойдёт — скачивание или открытие каталога.
    _pathController.addListener(() => setState(() {}));
    context
        .read<ConsoleBloc>()
        .repository
        .configFilePath()
        .then((path) => setState(() => _configPath = path));
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  /// Путь проще выбрать, чем набрать: каталог спеки лежит глубоко.
  Future<void> _pickDirectory() async {
    final directory = await getDirectoryPath();
    if (directory == null || !mounted) return;
    _pathController.text = directory;
    _submit();
  }

  /// Одно поле на оба случая: человек приносит либо ссылку, которую ему
  /// дали в команде, либо путь к уже склонированной спеке. Различать их
  /// умеет сам адрес — спрашивать об этом человека незачем.
  void _submit() {
    final value = _pathController.text.trim();
    final console = context.read<ConsoleBloc>();
    if (GitCloneSource.looksLikeUrl(value)) {
      console.add(SpecCloneRequested(value));
    } else {
      console.add(PlatformPathSubmitted(value));
    }
  }

  bool get _isUrl => GitCloneSource.looksLikeUrl(_pathController.text);

  /// Что произойдёт по кнопке — до её нажатия.
  String _intentHint(AppLocalizations texts) {
    final value = _pathController.text.trim();
    if (value.isEmpty) return texts.setupCloneHint;
    if (!_isUrl) return texts.cloneLocalHint;
    return texts.cloneTargetHint(
        p.join(GitCloneSource.defaultRoot().path, GitCloneSource.slugOf(value)));
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SectionCard(
            padding: const EdgeInsets.all(AppDimens.gapXl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(texts.setupTitle, style: AppTextStyles.screenTitle),
                const SizedBox(height: AppDimens.gapS),
                Text(texts.setupNote,
                    style: AppTextStyles.body.copyWith(height: 1.5)),
                const SizedBox(height: AppDimens.gapL),
                TextField(
                  controller: _pathController,
                  style: AppTextStyles.monospace(13,
                      color: AppColors.textPrimary),
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: texts.setupFieldLabel,
                    labelStyle: AppTextStyles.caption,
                    hintText: texts.setupHintPath,
                    hintStyle: AppTextStyles.monospace(13,
                        color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimens.controlRadius),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimens.controlRadius),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.gapS),
                Text(_intentHint(texts), style: AppTextStyles.hint),
                BlocBuilder<ConsoleBloc, ConsoleState>(
                  buildWhen: (previous, current) =>
                      previous.pathRejected != current.pathRejected,
                  builder: (context, state) => state.pathRejected
                      ? Padding(
                          padding: const EdgeInsets.only(top: AppDimens.gapS),
                          child: Text(texts.setupError,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.danger)),
                        )
                      : const SizedBox.shrink(),
                ),
                _CloneStep(onRetry: _submit),
                const SizedBox(height: AppDimens.gapL),
                // Кнопки переносятся: в узком окне строка не влезала.
                Wrap(
                  spacing: AppDimens.gapM,
                  runSpacing: AppDimens.gapS,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    BlocBuilder<ConsoleBloc, ConsoleState>(
                      buildWhen: (previous, current) =>
                          previous.clone.isRunning != current.clone.isRunning,
                      builder: (context, state) => FilledButton(
                        // Пока git работает, вторая попытка только помешает.
                        onPressed: state.clone.isRunning ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.background,
                        ),
                        child: Text(_isUrl
                            ? texts.cloneConnect
                            : texts.setupSave),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickDirectory,
                      icon: const Icon(Icons.folder_open,
                          size: 15, color: AppColors.accent),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        backgroundColor: AppColors.card,
                        foregroundColor: AppColors.textPrimary,
                      ),
                      label: Text(texts.setupBrowse,
                          style: const TextStyle(fontSize: 12)),
                    ),
                    // Отменить можно только когда есть куда вернуться.
                    if (!context.read<ConsoleBloc>().state.specMissing)
                      TextButton(
                        onPressed: () => context
                            .read<ConsoleBloc>()
                            .add(SpecSwitchRequested(false)),
                        child: Text(texts.setupCancel,
                            style: const TextStyle(
                                color: AppColors.textSecondary)),
                      ),
                  ],
                ),
                const SizedBox(height: AppDimens.gapM),
                if (_configPath.isNotEmpty)
                  Text(texts.setupConfigHint(_configPath),
                      style: AppTextStyles.hint.copyWith(height: 1.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Шаг клонирования: прогресс с объёмом, отмена рядом и человеческий текст
/// ошибки вместо кода git (сводный документ, 4.1).
class _CloneStep extends StatelessWidget {
  /// Повторить ту же попытку: чаще всего человек успел поправить ключ
  /// или сеть, и адрес менять ему не нужно.
  final VoidCallback onRetry;

  const _CloneStep({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return BlocBuilder<ConsoleBloc, ConsoleState>(
      buildWhen: (previous, current) => previous.clone != current.clone,
      builder: (context, state) {
        final clone = state.clone;
        if (clone.stage == OperationStage.idle) return const SizedBox.shrink();
        final failure = clone.failure;
        return Padding(
          padding: const EdgeInsets.only(top: AppDimens.gapM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProgressPanel(
                title: switch (clone.stage) {
                  OperationStage.done => texts.cloneDone,
                  OperationStage.failed when failure != null =>
                    texts.cloneFailureText(failure),
                  _ => clone.phase == ClonePhase.receiving ||
                          clone.phase == ClonePhase.starting
                      ? texts.cloneTitle
                      : texts.clonePulling,
                },
                progress: clone.operation,
                // Объём и скорость — как их напечатал git.
                measure: clone.volume.isEmpty
                    ? ''
                    : texts.cloneMeasure(clone.volume, clone.speed),
                onCancel: () =>
                    context.read<ConsoleBloc>().add(SpecCloneCancelled()),
                onRetry: onRetry,
              ),
            ],
          ),
        );
      },
    );
  }
}
