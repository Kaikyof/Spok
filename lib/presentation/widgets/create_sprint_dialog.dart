import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_dimens.dart';
import '../../core/resources/app_text_styles.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bloc/console_bloc.dart';
import '../bloc/sessions_bloc.dart';

/// Новый спринт из ТЗ: текст или файл уходят в /opsx-doc, который
/// составляет мастер-спеку и файлы спринта. Приложение не генерирует
/// артефакты само — это работа платформы.
class CreateSprintDialog extends StatefulWidget {
  const CreateSprintDialog({super.key});

  static Future<void> show(BuildContext context) => showDialog(
        context: context,
        builder: (_) => BlocProvider.value(
          value: context.read<SessionsBloc>(),
          child: BlocProvider.value(
            value: context.read<ConsoleBloc>(),
            child: const CreateSprintDialog(),
          ),
        ),
      );

  @override
  State<CreateSprintDialog> createState() => _CreateSprintDialogState();
}

class _CreateSprintDialogState extends State<CreateSprintDialog> {
  final _nameController = TextEditingController();
  final _briefController = TextEditingController();
  String _attachedName = '';
  String _error = '';

  static final _namePattern = RegExp(r'^[a-z0-9][a-z0-9-]*$');

  @override
  void dispose() {
    _nameController.dispose();
    _briefController.dispose();
    super.dispose();
  }

  Future<void> _attachFile() async {
    final file = await openFile(acceptedTypeGroups: const [
      XTypeGroup(label: 'ТЗ', extensions: ['md', 'txt', 'markdown']),
    ]);
    if (file == null) return;
    final content = await file.readAsString();
    setState(() {
      _attachedName = file.name;
      _briefController.text = content;
    });
  }

  void _submit(AppLocalizations texts) {
    final name = _nameController.text.trim();
    final brief = _briefController.text.trim();
    if (!_namePattern.hasMatch(name)) {
      setState(() => _error = texts.sprintCreateNameError);
      return;
    }
    if (brief.isEmpty) {
      setState(() => _error = texts.sprintCreateBriefError);
      return;
    }
    final source = _attachedName.isEmpty ? 'текст' : 'файл $_attachedName';
    context.read<SessionsBloc>().add(HandoffRunRequested(
          '/opsx-doc $name\n\n'
          'Исходное ТЗ ($source):\n\n$brief',
        ));
    context.read<ConsoleBloc>().add(ScreenSelected(ConsoleScreen.sessions));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(texts.sprintCreateTitle, style: AppTextStyles.sectionTitle),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Field(
              controller: _nameController,
              label: texts.sprintCreateNameLabel,
              hint: 'profile-v2',
              monospaced: true,
            ),
            const SizedBox(height: AppDimens.gapM),
            _Field(
              controller: _briefController,
              label: texts.sprintCreateBriefLabel,
              hint: 'Вставьте текст технического задания…',
              maxLines: 8,
            ),
            const SizedBox(height: AppDimens.gapS),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _attachFile,
                  icon: const Icon(Icons.attach_file, size: 15),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    foregroundColor: AppColors.textPrimary,
                  ),
                  label: Text(texts.sprintCreateAttach,
                      style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 12),
                if (_attachedName.isNotEmpty)
                  Flexible(
                    child: Text(texts.sprintCreateAttached(_attachedName),
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.hint),
                  ),
              ],
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: AppDimens.gapS),
              Text(_error,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.danger)),
            ],
            const SizedBox(height: AppDimens.gapM),
            Text(texts.sprintCreateHint,
                style: AppTextStyles.hint.copyWith(height: 1.4)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(texts.handoffSendCancel,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
        FilledButton(
          onPressed: () => _submit(texts),
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.background),
          child: Text(texts.sprintCreateRun),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final bool monospaced;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.monospaced = false,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.hint),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: monospaced
                ? AppTextStyles.monospace(12.5,
                    color: AppColors.textPrimary)
                : const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.captionMuted,
              filled: true,
              fillColor: AppColors.background,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      );
}
