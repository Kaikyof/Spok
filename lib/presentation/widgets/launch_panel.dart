import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_dimens.dart';
import '../../core/resources/app_text_styles.dart';
import '../../domain/entities/command_run.dart';
import '../../domain/repositories/command_log.dart';
import '../../l10n/gen/app_localizations.dart';

/// Нижняя сворачиваемая панель запуска (бриф §5.5): выполняемая команда
/// моноширинным, вывод, код возврата, длительность и копирование.
/// Вывод не приукрашивается — по нему человек повторит команду руками.
class LaunchPanel extends StatefulWidget {
  final CommandLog commandLog;

  const LaunchPanel({super.key, required this.commandLog});

  @override
  State<LaunchPanel> createState() => _LaunchPanelState();
}

class _LaunchPanelState extends State<LaunchPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => StreamBuilder<CommandRun>(
        stream: widget.commandLog.runs,
        initialData: widget.commandLog.last,
        builder: (context, snapshot) => _PanelBody(
          run: snapshot.data,
          expanded: _expanded,
          onToggle: () => setState(() => _expanded = !_expanded),
        ),
      );
}

class _PanelBody extends StatelessWidget {
  final CommandRun? run;
  final bool expanded;
  final VoidCallback onToggle;

  const _PanelBody(
      {required this.run, required this.expanded, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final currentRun = run;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.panel,
        border: Border(top: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Header(run: currentRun, expanded: expanded, onToggle: onToggle),
          if (expanded && currentRun != null) _Output(run: currentRun),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final CommandRun? run;
  final bool expanded;
  final VoidCallback onToggle;

  const _Header(
      {required this.run, required this.expanded, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final currentRun = run;
    return InkWell(
      onTap: currentRun == null ? null : onToggle,
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            const SizedBox(width: AppDimens.gapXl),
            Icon(expanded ? Icons.expand_more : Icons.expand_less,
                size: 14, color: AppColors.textMuted),
            const SizedBox(width: AppDimens.gapM),
            Expanded(
              child: Text(
                currentRun?.command ?? texts.launchPanelIdle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.monospace(12,
                    color: currentRun == null
                        ? AppColors.textMuted
                        : AppColors.monospaceText),
              ),
            ),
            if (currentRun != null) ...[
              const SizedBox(width: AppDimens.gapM),
              _StatusLabel(run: currentRun),
              const SizedBox(width: AppDimens.gapM),
              _CopyButton(
                  label: texts.launchCopyCommand, value: currentRun.command),
            ],
            const SizedBox(width: AppDimens.gapXl),
          ],
        ),
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  final CommandRun run;

  const _StatusLabel({required this.run});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    if (run.isRunning) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: AppColors.warning)),
          const SizedBox(width: 8),
          Text(texts.launchPanelRunning,
              style: AppTextStyles.monospace(11.5, color: AppColors.warning)),
        ],
      );
    }
    return Text(
      texts.launchPanelExit(
          run.exitCode ?? 0, (run.duration.inMilliseconds / 1000).toStringAsFixed(1)),
      style: AppTextStyles.monospace(11.5,
          color: run.succeeded ? AppColors.success : AppColors.danger),
    );
  }
}

class _Output extends StatelessWidget {
  final CommandRun run;

  const _Output({required this.run});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final output = run.output.isEmpty ? texts.launchNoOutput : run.output;
    return Container(
      height: 160,
      width: double.infinity,
      color: AppColors.logBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppDimens.gapXl, 8, AppDimens.gapXl, 0),
            child: Row(
              children: [
                const Spacer(),
                _CopyButton(
                    label: texts.launchCopyOutput, value: run.output),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  AppDimens.gapXl, 4, AppDimens.gapXl, AppDimens.gapM),
              child: SelectableText(
                output,
                style: AppTextStyles.monospace(11.5,
                        color: run.output.isEmpty
                            ? AppColors.textMuted
                            : AppColors.monospaceText)
                    .copyWith(height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  final String label;
  final String value;

  const _CopyButton({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return TextButton(
      onPressed: value.isEmpty
          ? null
          : () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(texts.launchCopied,
                    style: const TextStyle(fontSize: 12)),
                backgroundColor: AppColors.cardHighlight,
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                width: 200,
              ));
            },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 28),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
    );
  }
}
