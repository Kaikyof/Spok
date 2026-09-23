import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_dimens.dart';
import '../../core/resources/app_text_styles.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bloc/console_bloc.dart';
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

  void _submit() {
    context
        .read<ConsoleBloc>()
        .add(PlatformPathSubmitted(_pathController.text));
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
                const SizedBox(height: AppDimens.gapL),
                // Кнопки переносятся: в узком окне строка не влезала.
                Wrap(
                  spacing: AppDimens.gapM,
                  runSpacing: AppDimens.gapS,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.background,
                      ),
                      child: Text(texts.setupSave),
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
                Text(texts.setupCloneHint,
                    style: AppTextStyles.hint.copyWith(height: 1.4)),
                const SizedBox(height: AppDimens.gapXs),
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
