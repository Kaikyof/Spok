import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_dimens.dart';
import '../../core/resources/app_text_styles.dart';
import '../../domain/entities/env_field.dart';
import '../../domain/entities/operation_progress.dart';
import '../../domain/entities/secret_backend.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bloc/console_bloc.dart';
import '../localization/text_formatters.dart';
import '../ui_kit/progress_panel.dart';

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

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
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
            Text(texts.envEditEmptyHint, style: AppTextStyles.hint),
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
              if (hint.isNotEmpty) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.hint),
                ),
              ],
            ],
          ),
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
