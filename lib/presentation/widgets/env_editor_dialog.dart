import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_dimens.dart';
import '../../core/resources/app_text_styles.dart';
import '../../domain/entities/env_field.dart';
import '../../domain/entities/env_task.dart';
import '../../domain/entities/operation_progress.dart';
import '../../domain/entities/secret_backend.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bloc/console_bloc.dart';
import '../localization/text_formatters.dart';
import '../bloc/sessions_bloc.dart';
import '../ui_kit/progress_panel.dart';
import '../ui_kit/tappable.dart';

/// Откуда берётся путь к принесённому файлу. Системный диалог выбора
/// файла в тесте не открыть, поэтому выбор вынесен сюда: проверяется то,
/// что делается с прочитанными значениями, а не сам диалог macOS.
typedef EnvFilePicker = Future<String?> Function();

EnvFilePicker envFilePicker = () async => (await openFile())?.path;

/// Форма ключей спеки: поля строятся из `.env.example`, значения пишутся
/// в `.env`. Правка ключей в терминале — лишний переход из приложения.
class EnvEditorDialog extends StatelessWidget {
  const EnvEditorDialog({super.key});

  static Future<void> show(BuildContext context) {
    context.read<ConsoleBloc>().add(EnvFormRequested());
    return showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<ConsoleBloc>(),
        child: const EnvEditorDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return BlocConsumer<ConsoleBloc, ConsoleState>(
      buildWhen: (previous, current) =>
          previous.envForm != current.envForm ||
          previous.envSaving != current.envSaving,
      // Диалог закрывается, когда запись действительно закончилась:
      // связка ключей может спросить разрешение, и до её ответа
      // говорить «сохранено» нельзя.
      listenWhen: (previous, current) =>
          previous.envSaving && !current.envSaving,
      listener: (context, state) => Navigator.of(context).maybePop(),
      builder: (context, state) {
        final form = state.envForm;
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(texts.envEditTitle, style: AppTextStyles.sectionTitle),
          content: SizedBox(
            width: 620,
            child: form == null
                ? const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator()))
                : _EnvFields(form: form, saving: state.envSaving),
          ),
        );
      },
    );
  }
}

class _EnvFields extends StatefulWidget {
  final EnvForm form;

  /// Значения уже пишутся: связка ключей может спросить разрешение,
  /// и человеку нужно видеть, что операция идёт.
  final bool saving;

  const _EnvFields({required this.form, required this.saving});

  @override
  State<_EnvFields> createState() => _EnvFieldsState();
}

class _EnvFieldsState extends State<_EnvFields> {
  late final Map<String, TextEditingController> _controllers = {
    for (final field in widget.form.fields)
      field.key: TextEditingController(text: field.value),
  };
  final _revealed = <String>{};

  /// Итог последнего импорта: что подставлено, что пропущено пустым
  /// и чего спека не спрашивает. null — не импортировали.
  ({int filled, List<String> empty, List<String> extra})? _imported;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Импорт `.env` из другого места: человек приносит готовый файл из
  /// соседнего проекта или из переписки, и перебивать десяток ключей
  /// руками ему незачем.
  ///
  /// Значения только подставляются в поля — сохранения не происходит:
  /// в чужом файле могут оказаться не те ключи, и человек должен увидеть
  /// их до записи в `.env` и в связку ключей.
  ///
  /// Пустое значение в файле прежнее не затирает: `KEY=` в чужом `.env`
  /// значит «у меня не заполнено», а не «сотри у себя». Но и молчать об
  /// этом нельзя — иначе заполненный ключ просто остаётся старым, и
  /// непонятно почему; такие ключи названы в итоге импорта.
  Future<void> _import() async {
    // Репозиторий забираем до диалога выбора файла: после ожидания
    // обращаться к context нельзя, экран мог закрыться.
    final repository = context.read<ConsoleBloc>().repository;
    final path = await envFilePicker();
    if (path == null) return;
    final values = await repository.readEnvFile(path);
    if (!mounted) return;
    var filled = 0;
    final empty = <String>[];
    final extra = <String>[];
    values.forEach((key, value) {
      final controller = _controllers[key];
      if (controller == null) {
        extra.add(key);
        return;
      }
      if (value.isEmpty) {
        // Прежнее значение осталось — но только если оно было.
        if (controller.text.trim().isNotEmpty) empty.add(key);
        return;
      }
      controller.text = value;
      filled++;
    });
    setState(
        () => _imported = (filled: filled, empty: empty, extra: extra));
  }

  void _save() {
    context.read<ConsoleBloc>().add(EnvSaved({
          for (final entry in _controllers.entries)
            entry.key: entry.value.text.trim(),
        }));
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.form.ignoredByGit) ...[
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 15, color: AppColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(texts.envEditGitWarning,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.warning)),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gapM),
        ],
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: widget.saving ? null : _import,
              icon: const Icon(Icons.file_open_outlined, size: 15),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                backgroundColor: AppColors.cardHighlight,
                foregroundColor: AppColors.textPrimary,
              ),
              label: Text(texts.envImportFromFile,
                  style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: AppDimens.gapM),
            const Expanded(child: _KeysCommandHint()),
          ],
        ),
        const SizedBox(height: AppDimens.gapXs),
        Text(
            _imported == null
                ? texts.envImportHint
                : texts.envImportResult(_imported!.filled),
            style: AppTextStyles.hint.copyWith(height: 1.35)),
        // Пустые в файле ключи — главный источник «а почему значение
        // не изменилось»: называем их поимённо.
        if (_imported?.empty.isNotEmpty ?? false) ...[
          const SizedBox(height: 2),
          Text(texts.envImportEmpty(_imported!.empty.join(', ')),
              style: AppTextStyles.hint.copyWith(
                  height: 1.35, color: AppColors.warning)),
        ],
        // Лишние ключи не молчим: файл может быть от другой спеки, и это
        // первый признак, что человек взял не тот.
        if (_imported?.extra.isNotEmpty ?? false) ...[
          const SizedBox(height: 2),
          Text(texts.envImportExtra(_imported!.extra.join(', ')),
              style: AppTextStyles.hint.copyWith(
                  height: 1.35, color: AppColors.warning)),
        ],
        const SizedBox(height: AppDimens.gapM),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final field in widget.form.fields)
                  _EnvRow(
                    field: field,
                    controller: _controllers[field.key]!,
                    obscured: field.secret && !_revealed.contains(field.key),
                    onToggleReveal: () => setState(() =>
                        _revealed.contains(field.key)
                            ? _revealed.remove(field.key)
                            : _revealed.add(field.key)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDimens.gapM),
        // Пока идёт запись — общий вид длинной операции: связка ключей
        // спрашивает разрешение, и это занимает секунды.
        if (widget.saving) ...[
          ProgressPanel(
              title: texts.envEditSaving,
              progress: const OperationProgress.running()),
          const SizedBox(height: AppDimens.gapM),
        ],
        Row(
          children: [
            Icon(
                widget.form.backend.isKeyring
                    ? Icons.lock_outline
                    : Icons.folder_outlined,
                size: 14,
                color: widget.form.backend.isKeyring
                    ? AppColors.success
                    : AppColors.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Text(texts.secretBackendNote(widget.form.backend),
                  style: AppTextStyles.hint.copyWith(
                      height: 1.4,
                      color: widget.form.backend.isKeyring
                          ? AppColors.textSecondary
                          : AppColors.warning)),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.gapXs),
        Text(texts.envEditSecretNote,
            style: AppTextStyles.hint.copyWith(height: 1.4)),
        const SizedBox(height: AppDimens.gapXs),
        Text(texts.envEditPath(widget.form.path),
            style: AppTextStyles.monospace(10.5, color: AppColors.textMuted)),
        const SizedBox(height: AppDimens.gapM),
        Row(
          children: [
            FilledButton(
              onPressed: widget.saving ? null : _save,
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background),
              child: Text(texts.envEditSave),
            ),
            const SizedBox(width: AppDimens.gapM),
            TextButton(
              onPressed:
                  widget.saving ? null : () => Navigator.of(context).pop(),
              child: Text(texts.setupCancel,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ),
            const Spacer(),
            // Подсказка ужимается: в узком диалоге ряд кнопок с ней
            // не помещался и вылезал за край.
            Flexible(
              child: Text(texts.envEditEmptyHint,
                  textAlign: TextAlign.right, style: AppTextStyles.hint),
            ),
          ],
        ),
      ],
    );
  }
}

class _EnvRow extends StatelessWidget {
  final EnvField field;
  final TextEditingController controller;
  final bool obscured;
  final VoidCallback onToggleReveal;

  const _EnvRow({
    required this.field,
    required this.controller,
    required this.obscured,
    required this.onToggleReveal,
  });

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    // Подсказку пишет сама спека в .env.example; своя — только для ключей,
    // которые она не прокомментировала.
    final hint =
        field.hint.isNotEmpty ? field.hint : texts.envKeyHint(field.key);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.gapM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(field.key,
                  style: AppTextStyles.monospace(12,
                      color: AppColors.textPrimary, weight: FontWeight.w500)),
              if (field.optional) ...[
                const SizedBox(width: 8),
                Text(texts.envEditOptional, style: AppTextStyles.hint),
              ],
            ],
          ),
          // Подсказка — отдельной строкой во всю ширину: в строке с именем
          // ключа она обрывалась на многоточии, а это единственное место,
          // где спека объясняет, что за ключ и где его взять.
          if (hint.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(hint, style: AppTextStyles.hint.copyWith(height: 1.35)),
          ],
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            obscureText: obscured,
            style: AppTextStyles.monospace(12.5, color: AppColors.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              suffixIcon: field.secret
                  ? IconButton(
                      tooltip: obscured ? texts.envEditShow : texts.envEditHide,
                      icon: Icon(
                          obscured ? Icons.visibility : Icons.visibility_off,
                          size: 16,
                          color: AppColors.textMuted),
                      onPressed: onToggleReveal,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.controlRadius),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.controlRadius),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Команда спеки, которой заполняется окружение, — если спека её объявляет.
/// Для avelacom таких нет, и строки не будет: придумывать `make init`
/// там, где его нет, нельзя.
class _KeysCommandHint extends StatelessWidget {
  const _KeysCommandHint();

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return BlocBuilder<ConsoleBloc, ConsoleState>(
      buildWhen: (previous, current) => previous.profile != current.profile,
      builder: (context, state) {
        final command = state.profile.envCommands[EnvTask.keys];
        if (command == null) return const SizedBox.shrink();
        return Tappable(
          onTap: () {
            context
                .read<SessionsBloc>()
                .add(SessionDraftSet(command.invocation));
            context
                .read<ConsoleBloc>()
                .add(ScreenSelected(ConsoleScreen.sessions));
            Navigator.of(context).maybePop();
          },
          effect: HoverEffect.underline,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_arrow, size: 14, color: AppColors.accent),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  texts.envKeysCommand(command.invocation),
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.hint,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
