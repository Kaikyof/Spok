import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_dimens.dart';
import '../../core/resources/app_text_styles.dart';
import '../../domain/entities/agent_session.dart';
import '../../domain/entities/slash_command.dart';
import '../../domain/usecases/suggest_command_arguments.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bloc/sessions_bloc.dart';
import '../ui_kit/section_card.dart';
import '../ui_kit/suggestion_list.dart';

/// Агентные сессии: часть работы требует суждения и ведётся моделью
/// в диалоге (бриф §5.6). Визуально отличается от кнопок-действий.
class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return BlocBuilder<SessionsBloc, SessionsState>(
      builder: (context, state) {
        if (!state.cliAvailable) {
          return Center(
            child: Text(texts.sessionCliMissing,
                textAlign: TextAlign.center, style: AppTextStyles.body),
          );
        }
        return Padding(
          padding: AppDimens.screenPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 256, child: _SessionList(state: state)),
              const SizedBox(width: AppDimens.gapL),
              Expanded(child: _SessionPanel(state: state)),
            ],
          ),
        );
      },
    );
  }
}

class _SessionList extends StatelessWidget {
  final SessionsState state;

  const _SessionList({required this.state});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return SectionCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 4, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(texts.sessionsListTitle,
                      style: AppTextStyles.sectionTitle),
                ),
                IconButton(
                  onPressed: () =>
                      context.read<SessionsBloc>().add(SessionCreated()),
                  tooltip: texts.sessionNewTooltip,
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: const Icon(Icons.add, color: AppColors.accent),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final session in state.sessions)
                  _SessionListItem(
                      session: session,
                      active: session.id == state.selectedSessionId),
              ],
            ),
          ),
          if (state.workingDirectory.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Text(
                texts.sessionWorkingDir(
                    state.workingDirectory.split('/').last),
                style: AppTextStyles.monospace(9.5, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

class _SessionListItem extends StatefulWidget {
  final AgentSession session;
  final bool active;

  const _SessionListItem({required this.session, required this.active});

  @override
  State<_SessionListItem> createState() => _SessionListItemState();
}

class _SessionListItemState extends State<_SessionListItem> {
  bool _hovered = false;

  (Color, String) _statusOf(AppLocalizations texts) =>
      switch (widget.session.status) {
        AgentSessionStatus.idle => (AppColors.textMuted, texts.sessionIdle),
        AgentSessionStatus.running => (AppColors.warning, texts.sessionRunning),
        AgentSessionStatus.done => (AppColors.success, texts.sessionDone),
        AgentSessionStatus.failed => (AppColors.danger, texts.sessionFailed),
        AgentSessionStatus.stopped => (AppColors.textMuted, texts.sessionDone),
      };

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final (statusColor, statusLabel) = _statusOf(texts);
    final session = widget.session;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: () =>
            context.read<SessionsBloc>().add(SessionSelected(session.id)),
        borderRadius: BorderRadius.circular(AppDimens.controlRadius),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: widget.active ? AppColors.cardHighlight : null,
            borderRadius: BorderRadius.circular(AppDimens.controlRadius),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title.isEmpty
                          ? texts.sessionUntitled
                          : session.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: widget.active
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: session.title.isEmpty
                              ? AppColors.textMuted
                              : (widget.active
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary)),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                                color: statusColor, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '$statusLabel · ${DateFormat.Hm().format(session.startedAt)}'
                            '${session.messageCount > 1 ? ' · ${session.messageCount}' : ''}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 10.5, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 24,
                child: _hovered
                    ? IconButton(
                        onPressed: () => context
                            .read<SessionsBloc>()
                            .add(SessionDeleted(session.id)),
                        tooltip: texts.sessionDeleteTooltip,
                        iconSize: 14,
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 24, minHeight: 24),
                        icon: const Icon(Icons.close,
                            color: AppColors.textMuted),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionPanel extends StatelessWidget {
  final SessionsState state;

  const _SessionPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    final session = state.selected;
    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _PanelHeader(state: state, session: session),
          const Divider(height: 1),
          Expanded(
            child: session == null || session.isEmpty
                ? _CommandPalette(commands: state.commands)
                : _Transcript(session: session),
          ),
          const Divider(height: 1),
          _PromptInput(state: state),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final SessionsState state;
  final AgentSession? session;

  const _PanelHeader({required this.state, required this.session});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final running = session?.isRunning ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    session == null || session!.title.isEmpty
                        ? texts.sessionNew
                        : session!.title,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.sectionTitle),
                if ((session?.messageCount ?? 0) > 1)
                  Text(texts.sessionContinues, style: AppTextStyles.hint),
              ],
            ),
          ),
          if (running)
            TextButton(
              onPressed: () =>
                  context.read<SessionsBloc>().add(SessionStopRequested()),
              child: Text(texts.sessionStop,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.danger)),
            ),
          const SizedBox(width: AppDimens.gapS),
          _EffortPicker(effort: state.effort, enabled: !running),
          const SizedBox(width: AppDimens.gapS),
          _ModelPicker(model: state.model, enabled: !running),
        ],
      ),
    );
  }
}

class _ModelPicker extends StatelessWidget {
  final String model;
  final bool enabled;

  const _ModelPicker({required this.model, required this.enabled});

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
        enabled: enabled,
        color: AppColors.cardHighlight,
        onSelected: (selectedModel) => context
            .read<SessionsBloc>()
            .add(SessionModelChanged(selectedModel)),
        itemBuilder: (_) => [
          for (final candidate in agentModels)
            PopupMenuItem(
              value: candidate,
              child: Text(candidate, style: const TextStyle(fontSize: 12.5)),
            ),
        ],
        child: _PickerChip(label: 'Claude · $model'),
      );
}

class _EffortPicker extends StatelessWidget {
  final AgentEffort effort;
  final bool enabled;

  const _EffortPicker({required this.effort, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return PopupMenuButton<AgentEffort>(
      enabled: enabled,
      color: AppColors.cardHighlight,
      onSelected: (selectedEffort) => context
          .read<SessionsBloc>()
          .add(SessionEffortChanged(selectedEffort)),
      itemBuilder: (_) => [
        for (final candidate in AgentEffort.values)
          PopupMenuItem(
            value: candidate,
            child:
                Text(candidate.name, style: const TextStyle(fontSize: 12.5)),
          ),
      ],
      child: _PickerChip(label: '${texts.sessionEffortLabel} · ${effort.name}'),
    );
  }
}

class _PickerChip extends StatelessWidget {
  final String label;

  const _PickerChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.cardHighlight,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11.5, color: AppColors.textSecondary)),
            const Icon(Icons.expand_more, size: 14, color: AppColors.textMuted),
          ],
        ),
      );
}

/// Пустая сессия — палитра команд платформы: тот же список и описания,
/// что у автокомплита в терминале (.claude/commands).
class _CommandPalette extends StatelessWidget {
  final List<SlashCommand> commands;

  const _CommandPalette({required this.commands});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    if (commands.isEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Text(texts.sessionEmptyHint,
              textAlign: TextAlign.center,
              style: AppTextStyles.captionMuted.copyWith(height: 1.6)),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(texts.sessionCommandsTitle,
            style: AppTextStyles.sectionLabel.copyWith(fontSize: 9.5)),
        const SizedBox(height: 4),
        Text(texts.sessionCommandsHint, style: AppTextStyles.hint),
        const SizedBox(height: AppDimens.gapM),
        SuggestionList(
          items: [
            for (final command in commands)
              SuggestionItem(
                  '${command.invocation}${command.argumentHint.isEmpty ? '' : ' ${command.argumentHint}'}',
                  command.description),
          ],
          activeIndex: -1,
          onSelected: (index) =>
              promptInputKey.currentState?.insertCommand(commands[index]),
          valueWidth: 260,
        ),
        const SizedBox(height: AppDimens.gapM),
        Text(texts.sessionEmptyHint,
            style: AppTextStyles.hint.copyWith(height: 1.6)),
      ],
    );
  }
}

class _Transcript extends StatelessWidget {
  final AgentSession session;

  const _Transcript({required this.session});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return ListView(
      reverse: true,
      padding: const EdgeInsets.all(16),
      children: [
        if (session.isRunning)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: AppColors.warning)),
          ),
        for (final event in session.events.reversed)
          _TranscriptEntry(event: event, session: session, texts: texts),
      ],
    );
  }
}

class _TranscriptEntry extends StatelessWidget {
  final AgentEvent event;
  final AgentSession session;
  final AppLocalizations texts;

  const _TranscriptEntry(
      {required this.event, required this.session, required this.texts});

  @override
  Widget build(BuildContext context) => switch (event.kind) {
        AgentEventKind.userMessage => Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10, left: 60, top: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentDim,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(event.text,
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.textPrimary)),
            ),
          ),
        AgentEventKind.assistantText => Container(
            margin: const EdgeInsets.only(bottom: 10, right: 60),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardHighlight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText(event.text,
                style: AppTextStyles.caption.copyWith(height: 1.5)),
          ),
        AgentEventKind.toolAction => Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('✓',
                    style: TextStyle(fontSize: 11, color: AppColors.success)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(event.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.monospace(11,
                          color: AppColors.monospaceText)),
                ),
              ],
            ),
          ),
        AgentEventKind.result => Container(
            margin: const EdgeInsets.only(bottom: 10, top: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.logBackground,
              borderRadius: BorderRadius.circular(AppDimens.controlRadius),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    texts.sessionResultLabel(
                        ((session.duration?.inMilliseconds ?? 0) / 1000)
                            .toStringAsFixed(1)),
                    style: AppTextStyles.sectionLabel.copyWith(fontSize: 9.5)),
                const SizedBox(height: 6),
                SelectableText(event.text,
                    style: AppTextStyles.caption.copyWith(height: 1.5)),
              ],
            ),
          ),
        AgentEventKind.error => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(event.text,
                style: AppTextStyles.monospace(11, color: AppColors.danger)),
          ),
      };
}

/// Ключ, чтобы палитра команд могла вставить команду в поле ввода.
final promptInputKey = GlobalKey<_PromptInputState>();

class _PromptInput extends StatefulWidget {
  final SessionsState state;

  _PromptInput({required this.state}) : super(key: promptInputKey);

  @override
  State<_PromptInput> createState() => _PromptInputState();
}

class _PromptInputState extends State<_PromptInput> {
  final _promptController = TextEditingController();
  final _focusNode = FocusNode();
  int _activeIndex = 0;
  bool _suppressed = false; // скрыто по Escape до следующей правки

  @override
  void initState() {
    super.initState();
    _promptController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _promptController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {
        _activeIndex = 0;
        _suppressed = false;
      });

  void insertCommand(SlashCommand command) {
    _setText('${command.invocation} ');
    _focusNode.requestFocus();
  }

  void _setText(String text) {
    _promptController.text = text;
    _promptController.selection =
        TextSelection.collapsed(offset: text.length);
  }

  // ─── Подсказки ─────────────────────────────────────────────────────────────

  /// Команда, набранная в начале строки, если она распознана.
  SlashCommand? get _typedCommand {
    final input = _promptController.text;
    if (!input.startsWith('/')) return null;
    final head = input.split(' ').first.substring(1);
    return widget.state.commands
        .where((command) => command.id == head)
        .firstOrNull;
  }

  List<SuggestionItem> get _suggestions {
    if (_suppressed) return const [];
    final input = _promptController.text;
    if (!input.startsWith('/')) return const [];

    final command = _typedCommand;
    if (command == null) {
      // Ещё набирается имя команды.
      if (input.contains(' ')) return const [];
      final prefix = input.substring(1).toLowerCase();
      return [
        for (final candidate in widget.state.commands)
          if (candidate.id.toLowerCase().contains(prefix))
            SuggestionItem(
                '${candidate.invocation}${candidate.argumentHint.isEmpty ? '' : ' ${candidate.argumentHint}'}',
                candidate.description),
      ];
    }

    // Имя набрано — подсказываем значения аргументов.
    final parts = input.split(' ');
    final typedArguments =
        parts.sublist(1, parts.length - 1).where((p) => p.isNotEmpty).toList();
    final currentPrefix = parts.last;
    final suggester = SuggestCommandArguments(
      changeIds: widget.state.changeIds,
      sprintIds: widget.state.sprintIds,
    );
    return [
      for (final suggestion
          in suggester(command, typedArguments, currentPrefix))
        SuggestionItem(suggestion.value, suggestion.hint),
    ];
  }

  void _acceptSuggestion(int index) {
    final suggestions = _suggestions;
    if (index < 0 || index >= suggestions.length) return;
    final value = suggestions[index].value;
    final command = _typedCommand;
    if (command == null) {
      // Подсказка команды: значение содержит и argument-hint — берём имя.
      _setText('${value.split(' ').first} ');
    } else {
      final parts = _promptController.text.split(' ');
      parts[parts.length - 1] = value;
      _setText('${parts.join(' ')} ');
    }
    _focusNode.requestFocus();
  }

  // ─── Клавиатура ────────────────────────────────────────────────────────────

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final suggestions = _suggestions;
    final hasSuggestions = suggestions.isNotEmpty;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown when hasSuggestions:
        setState(() =>
            _activeIndex = (_activeIndex + 1) % suggestions.length);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp when hasSuggestions:
        setState(() => _activeIndex =
            (_activeIndex - 1 + suggestions.length) % suggestions.length);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.tab when hasSuggestions:
        _acceptSuggestion(_activeIndex);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape when hasSuggestions:
        setState(() => _suppressed = true);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter when hasSuggestions:
        // Enter при открытых подсказках принимает выбранную, как в терминале.
        _acceptSuggestion(_activeIndex);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
        _submit();
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _submit() {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;
    context.read<SessionsBloc>().add(SessionMessageSent(prompt));
    _promptController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final suggestions = _suggestions;
    final command = _typedCommand;
    final running = widget.state.selected?.isRunning ?? false;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              constraints: const BoxConstraints(maxHeight: 240),
              decoration: BoxDecoration(
                color: AppColors.cardHighlight,
                borderRadius: BorderRadius.circular(AppDimens.controlRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: SuggestionList(
                items: suggestions,
                activeIndex: _activeIndex,
                onSelected: _acceptSuggestion,
                header: command == null
                    ? texts.sessionCommandsTitle
                    : texts.sessionArgumentsFor(command.invocation),
                footer: texts.sessionKeyboardHint,
                valueWidth: command == null ? 260 : 220,
              ),
            ),
          _inputRow(texts, running),
        ],
      ),
    );
  }

  Widget _inputRow(AppLocalizations texts, bool running) => Row(
        children: [
          Expanded(
            child: Focus(
              onKeyEvent: _onKey,
              child: TextField(
                controller: _promptController,
                focusNode: _focusNode,
                enabled: !running,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: texts.sessionInputHint,
                  hintStyle: AppTextStyles.captionMuted,
                  filled: true,
                  fillColor: AppColors.background,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
            ),
          ),
          const SizedBox(width: AppDimens.gapS),
          IconButton(
            onPressed: running ? null : _submit,
            icon: const Icon(Icons.arrow_upward,
                size: 18, color: AppColors.accent),
          ),
        ],
      );
}
