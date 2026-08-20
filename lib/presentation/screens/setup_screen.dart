import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_dimens.dart';
import '../../core/resources/app_text_styles.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bloc/console_bloc.dart';
import '../ui_kit/section_card.dart';

/// Первичная настройка: путь к репозиторию платформы.
/// Показывается, когда платформа не найдена ни по одному из путей.
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
                    hintText: '/Users/…/avtoto-platform',
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
                FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                  ),
                  child: Text(texts.setupSave),
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
