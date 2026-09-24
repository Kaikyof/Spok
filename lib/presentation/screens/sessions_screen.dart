import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_dimens.dart';
import '../../core/resources/app_text_styles.dart';
import '../../domain/entities/agent_session.dart';
import '../../domain/entities/command_run.dart';
import '../../domain/entities/slash_command.dart';
import '../../domain/repositories/command_log.dart';
import '../../domain/usecases/suggest_command_arguments.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bloc/console_bloc.dart';
import '../bloc/sessions_bloc.dart';
import '../ui_kit/agent_markdown.dart';
import '../ui_kit/section_card.dart';
import '../ui_kit/suggestion_list.dart';
import '../ui_kit/tappable.dart';

/// Агентные сессии: часть работы требует суждения и ведётся моделью
/// в диалоге (бриф §5.6). Внизу экрана — терминал во всю ширину контента:
/// вывод последней команды, одна строка ввода «команда + задание словами»
/// и параметры запуска (макет, борды 05, 05b, 05c, 05d).
class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return BlocBuilder<SessionsBloc, SessionsState>(
      builder: (context, state) {
        if (!state.cliAvailable) {
          return Center(
            child: Text(
              texts.sessionCliMissing,
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
          );
        }
        return Padding(
          padding: AppDimens.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _SessionPanel(state: state)),
              const SizedBox(height: AppDimens.gapM),
              // Терминал не съедает экран: в узком окне вывод и палитра
              // ужимаются, а строка ввода остаётся на месте.
              LayoutBuilder(
                builder: (context, constraints) => Terminal(
                  state: state,
                  maxHeight: constraints.maxHeight * 0.7,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Быстрый запуск. Выделенная кнопка одна — роль «реализовать»; остальные
/// роли уходят в «Ещё», как на карточке change'а. Три равноправные кнопки
/// ломали строку заголовка, а у спеки ролей может быть и четыре.
class _QuickLaunch extends StatelessWidget {
  final Map<CommandRole, SlashCommand> roles;

  const _QuickLaunch({required this.roles});

  static String label(AppLocalizations texts, CommandRole role) =>
      switch (role) {
        CommandRole.apply => texts.roleApply,
        CommandRole.newChange => texts.roleNewChange,
        CommandRole.newGroup => texts.roleNewGroup,
        CommandRole.handover => texts.roleHandover,
      };

  /// Главной становится «реализовать»; нет её — первая, что нашлась.
  CommandRole get _primary => roles.containsKey(CommandRole.apply)
      ? CommandRole.apply
      : roles.keys.first;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final primary = _primary;
    final rest = [
      for (final role in roles.keys)
        if (role != primary) role,
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoleButton(
          label: label(texts, primary),
          command: roles[primary]!,
          primary: true,
        ),
        if (rest.isNotEmpty) ...[
          const SizedBox(width: AppDimens.gapS),
          PopupMenuButton<CommandRole>(
            tooltip: texts.sessionQuickLaunch,
            color: AppColors.cardHighlight,
            onSelected: (role) =>
                terminalKey.currentState?.insertCommand(roles[role]!),
            itemBuilder: (_) => [
              for (final role in rest)
                PopupMenuItem(
                  value: role,
                  child: Row(
                    children: [
                      Text(
                        label(texts, role),
                        style: const TextStyle(fontSize: 12.5),
                      ),
                      const SizedBox(width: AppDimens.gapM),
                      Text(
                        roles[role]!.invocation,
                        style: AppTextStyles.monospace(
                          11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            child: Tappable(
              tapHandledAbove: true,
              borderRadius: BorderRadius.circular(AppDimens.controlRadius),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardHighlight,
                  borderRadius: BorderRadius.circular(AppDimens.controlRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      texts.sessionMoreActions,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Icon(
                      Icons.expand_more,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String label;
  final SlashCommand command;
  final bool primary;

  const _RoleButton({
    required this.label,
    required this.command,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) => Tappable(
    onTap: () => terminalKey.currentState?.insertCommand(command),
    borderRadius: BorderRadius.circular(AppDimens.controlRadius),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primary ? AppColors.accentDim : AppColors.cardHighlight,
        borderRadius: BorderRadius.circular(AppDimens.controlRadius),
        border: primary ? Border.all(color: AppColors.accentDimBorder) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          // Видно, что именно уйдёт в строку ввода: подпись — сама команда.
          Text(
            command.invocation,
            style: AppTextStyles.monospace(10.5, color: AppColors.textMuted),
          ),
        ],
      ),
    ),
  );
}

/// Сессии — выпадающий список, а не колонка: диалогов у человека немного,
/// а вертикаль нужна ленте и терминалу.
class _SessionSelector extends StatelessWidget {
  final SessionsState state;

  const _SessionSelector({required this.state});

  static (Color, String) statusOf(
    AppLocalizations texts,
    AgentSessionStatus status,
  ) => switch (status) {
    AgentSessionStatus.idle => (AppColors.textMuted, texts.sessionIdle),
    AgentSessionStatus.running => (AppColors.warning, texts.sessionRunning),
    AgentSessionStatus.done => (AppColors.success, texts.sessionDone),
    AgentSessionStatus.failed => (AppColors.danger, texts.sessionFailed),
    AgentSessionStatus.stopped => (AppColors.textMuted, texts.sessionDone),
  };

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final session = state.selected;
    final title = session == null || session.title.isEmpty
        ? texts.sessionNew
        : session.title;
    return PopupMenuButton<String>(
      tooltip: texts.sessionsListTitle,
      color: AppColors.cardHighlight,
      constraints: const BoxConstraints(minWidth: 320, maxWidth: 460),
      onSelected: (value) => value.isEmpty
          ? context.read<SessionsBloc>().add(SessionCreated())
          : context.read<SessionsBloc>().add(SessionSelected(value)),
      itemBuilder: (_) => [
        for (final candidate in state.sessions)
          PopupMenuItem(
            value: candidate.id,
            child: _SessionMenuRow(
              session: candidate,
              active: candidate.id == state.selectedSessionId,
            ),
          ),
        if (state.sessions.isNotEmpty) const PopupMenuDivider(),
        PopupMenuItem(
          value: '',
          child: Row(
            children: [
              const Icon(Icons.add, size: 15, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                texts.sessionNewTooltip,
                style: const TextStyle(fontSize: 12.5),
              ),
            ],
          ),
        ),
      ],
      child: Tappable(
        tapHandledAbove: true,
        borderRadius: BorderRadius.circular(AppDimens.controlRadius),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (session != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: statusOf(texts, session.status).$1,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sectionTitle,
              ),
            ),
            if (state.sessions.length > 1) ...[
              const SizedBox(width: 8),
              Text(
                '${state.sessions.length}',
                style: AppTextStyles.monospace(11, color: AppColors.textMuted),
              ),
            ],
            const Icon(
              Icons.expand_more,
              size: 16,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionMenuRow extends StatelessWidget {
  final AgentSession session;
  final bool active;

  const _SessionMenuRow({required this.session, required this.active});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final (statusColor, statusLabel) = _SessionSelector.statusOf(
      texts,
      session.status,
    );
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                session.title.isEmpty ? texts.sessionUntitled : session.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              Text(
                '$statusLabel · ${DateFormat.Hm().format(session.startedAt)}'
                '${session.messageCount > 1 ? ' · ${session.messageCount}' : ''}',
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimens.gapS),
        IconButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.read<SessionsBloc>().add(SessionDeleted(session.id));
          },
          tooltip: texts.sessionDeleteTooltip,
          iconSize: 14,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          icon: const Icon(Icons.close, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _SessionPanel extends StatelessWidget {
  final SessionsState state;

  const _SessionPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final session = state.selected;
    final finished =
        session != null &&
        !session.isEmpty &&
        session.status == AgentSessionStatus.done;
    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _PanelHeader(state: state, session: session),
          const Divider(height: 1),
          Expanded(
            child: session == null || session.isEmpty
                ? _EmptySession(texts: texts)
                : _Transcript(session: session),
          ),
          if (finished) _NextSteps(state: state),
        ],
      ),
    );
  }
}

class _EmptySession extends StatelessWidget {
  final AppLocalizations texts;

  const _EmptySession({required this.texts});

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Text(
        texts.sessionEmptyHint,
        textAlign: TextAlign.center,
        style: AppTextStyles.captionMuted.copyWith(height: 1.6),
      ),
    ),
  );
}

/// Следующие шаги после завершения: кнопки собираются из команд спеки,
/// применимых к change'у, и подписаны её же словами — приложение не
/// придумывает за спеку, что делать дальше.
class _NextSteps extends StatelessWidget {
  final SessionsState state;

  const _NextSteps({required this.state});

  List<SlashCommand> get _steps => [
    for (final command in state.commands)
      if (command.scope == CommandScope.change &&
          state.roles[CommandRole.apply]?.id != command.id)
        command,
  ].take(3).toList();

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final steps = _steps;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: const BoxDecoration(
        color: AppColors.cardHighlight,
        border: Border(top: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            texts.sessionNextSteps,
            style: AppTextStyles.sectionLabel.copyWith(fontSize: 9.5),
          ),
          const SizedBox(height: AppDimens.gapS),
          Wrap(
            spacing: AppDimens.gapS,
            runSpacing: AppDimens.gapS,
            children: [
              for (final command in steps)
                _NextStepButton(
                  label: command.description,
                  hint: texts.sessionNextStepCommand(command.invocation),
                  onTap: () => terminalKey.currentState?.insertCommand(command),
                ),
              _NextStepButton(
                label: texts.sessionNextStepOpenChange,
                hint: texts.sessionNextStepOpenChangeHint,
                onTap: () => context.read<ConsoleBloc>().add(
                  ScreenSelected(ConsoleScreen.changes),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NextStepButton extends StatelessWidget {
  final String label;
  final String hint;
  final VoidCallback onTap;

  const _NextStepButton({
    required this.label,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Tappable(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppDimens.controlRadius),
    child: Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimens.controlRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.hint,
          ),
        ],
      ),
    ),
  );
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
                _SessionSelector(state: state),
                if ((session?.messageCount ?? 0) > 1)
                  Text(texts.sessionContinues, style: AppTextStyles.hint),
              ],
            ),
          ),
          if (state.roles.isNotEmpty)
            Flexible(flex: 2, child: _QuickLaunch(roles: state.roles)),
          if (running)
            TextButton(
              onPressed: () =>
                  context.read<SessionsBloc>().add(SessionStopRequested()),
              child: Text(
                texts.sessionStop,
                style: const TextStyle(fontSize: 12, color: AppColors.danger),
              ),
            ),
        ],
      ),
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
              width: 20,
              height: 20,
              child: FittedBox(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.warning,
                ),
              ),
            ),
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

  const _TranscriptEntry({
    required this.event,
    required this.session,
    required this.texts,
  });

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
        child: SelectableText(
          event.text,
          style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
        ),
      ),
    ),
    AgentEventKind.assistantText => Container(
      margin: const EdgeInsets.only(bottom: 10, right: 60),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardHighlight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: AgentMarkdown(data: event.text),
    ),
    // «Выполнено по ходу»: действия агента — чеклист, а не лента строк.
    AgentEventKind.toolAction => Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session.isRunning ? '●' : '✓',
            style: TextStyle(
              fontSize: 11,
              color: session.isRunning ? AppColors.warning : AppColors.success,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              event.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.monospace(
                11,
                color: AppColors.monospaceText,
              ),
            ),
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
              ((session.duration?.inMilliseconds ?? 0) / 1000).toStringAsFixed(
                1,
              ),
            ),
            style: AppTextStyles.sectionLabel.copyWith(fontSize: 9.5),
          ),
          const SizedBox(height: 6),
          AgentMarkdown(data: event.text),
        ],
      ),
    ),
    AgentEventKind.error => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        event.text,
        style: AppTextStyles.monospace(11, color: AppColors.danger),
      ),
    ),
  };
}

/// Ключ терминала: палитра, быстрый запуск и следующие шаги подставляют
/// команду в ту же строку ввода — отдельного поля «для команды» не бывает.
final terminalKey = GlobalKey<TerminalState>();

/// Терминал сессии: вывод последней команды, одна строка ввода и параметры
/// запуска. Высота меняется перетаскиванием и запоминается по проекту.
class Terminal extends StatefulWidget {
  final SessionsState state;

  /// Сколько высоты экрана терминал может занять в самом развёрнутом виде.
  final double maxHeight;

  Terminal({required this.state, this.maxHeight = double.infinity})
    : super(key: terminalKey);

  @override
  State<Terminal> createState() => TerminalState();
}

class TerminalState extends State<Terminal> {
  final _promptController = TextEditingController();
  final _focusNode = FocusNode();
  int _activeIndex = 0;
  bool _suppressed = false; // скрыто по Escape до следующей правки

  /// Черновик, уже перенесённый в поле: второй раз тот же не подставляем,
  /// иначе правка человека затиралась бы на каждой перерисовке.
  String _appliedDraft = '';

  @override
  void initState() {
    super.initState();
    _promptController.addListener(_onTextChanged);
    _applyDraft();
  }

  @override
  void didUpdateWidget(Terminal oldWidget) {
    super.didUpdateWidget(oldWidget);
    _applyDraft();
  }

  void _applyDraft() {
    final draft = widget.state.draft;
    if (draft.isEmpty || draft == _appliedDraft) return;
    _appliedDraft = draft;
    _setText(draft);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNode.requestFocus());
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
    _closePalette();
    _focusNode.requestFocus();
  }

  void _setText(String text) {
    _promptController.text = text;
    _promptController.selection = TextSelection.collapsed(offset: text.length);
  }

  void _closePalette() {
    if (widget.state.paletteOpen) {
      context.read<SessionsBloc>().add(SessionPaletteToggled(false));
    }
  }

  // ─── Палитра и подсказки ───────────────────────────────────────────────────

  /// Команда, набранная в начале строки, если она распознана.
  SlashCommand? get _typedCommand {
    final input = _promptController.text;
    if (!input.startsWith('/')) return null;
    final head = input.split(' ').first.substring(1);
    return widget.state.commands
        .where((command) => command.id == head)
        .firstOrNull;
  }

  /// Отбор палитры: то, что набрано до первого пробела.
  String get _paletteFilter {
    final input = _promptController.text;
    if (!input.startsWith('/') || input.contains(' ')) return '';
    return input.substring(1);
  }

  /// Команды в палитре. Строка пуста и палитра открыта кнопкой — весь
  /// список, включая скрипты; набрано «/opsx» — только подходящие.
  List<SlashCommand> get _paletteCommands {
    if (_suppressed) return const [];
    final input = _promptController.text;
    final typing = input.startsWith('/') && _typedCommand == null;
    if (!typing && !(widget.state.paletteOpen && input.trim().isEmpty)) {
      return const [];
    }
    final filter = _paletteFilter.toLowerCase();
    return [
      for (final command in widget.state.commands)
        if (command.id.toLowerCase().contains(filter)) command,
    ];
  }

  /// Подсказки значений аргументов — когда имя команды уже набрано.
  List<SuggestionItem> get _argumentSuggestions {
    if (_suppressed) return const [];
    final command = _typedCommand;
    if (command == null) return const [];
    final parts = _promptController.text.split(' ');
    final typedArguments = parts.length < 2
        ? const <String>[]
        : parts
              .sublist(1, parts.length - 1)
              .where((argument) => argument.isNotEmpty)
              .toList();
    final currentPrefix = parts.length < 2 ? '' : parts.last;
    final suggester = SuggestCommandArguments(
      changeIds: widget.state.changeIds,
      groupIds: widget.state.groupIds,
    );
    return [
      for (final suggestion in suggester(
        command,
        typedArguments,
        currentPrefix,
      ))
        SuggestionItem(suggestion.value, suggestion.hint),
    ];
  }

  void _acceptPalette(int index) {
    final commands = _paletteCommands;
    if (index < 0 || index >= commands.length) return;
    insertCommand(commands[index]);
  }

  void _acceptArgument(int index) {
    final suggestions = _argumentSuggestions;
    if (index < 0 || index >= suggestions.length) return;
    final value = suggestions[index].value;
    final parts = _promptController.text.split(' ');
    // Без пробела аргумент ещё не начат — дописываем его первым.
    if (parts.length < 2) {
      _setText('${parts.first} $value ');
    } else {
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
    final optionCount = _paletteCommands.isNotEmpty
        ? _paletteCommands.length
        : _argumentSuggestions.length;
    final hasOptions = optionCount > 0;

    void accept() => _paletteCommands.isNotEmpty
        ? _acceptPalette(_activeIndex)
        : _acceptArgument(_activeIndex);

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown when hasOptions:
        setState(() => _activeIndex = (_activeIndex + 1) % optionCount);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp when hasOptions:
        setState(
          () => _activeIndex = (_activeIndex - 1 + optionCount) % optionCount,
        );
        return KeyEventResult.handled;
      case LogicalKeyboardKey.tab when hasOptions:
        accept();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape when hasOptions:
        setState(() => _suppressed = true);
        _closePalette();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter when hasOptions:
        // Enter при открытых подсказках принимает выбранную, как в терминале.
        accept();
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
    _closePalette();
  }

  /// Перетаскивание верхней границы: вверх — выше, вниз — ниже.
  /// Высота идёт за курсором пиксель в пиксель; у самого низа вывод
  /// сворачивается целиком, чтобы не оставлять бесполезную полоску.
  void _onDrag(double delta) {
    final available = widget.maxHeight.isFinite
        ? widget.maxHeight - _chromeHeight
        : double.infinity;
    var next = widget.state.terminalHeight - delta;
    if (next < TerminalHeights.collapseThreshold) next = 0;
    if (available.isFinite && next > available) next = available;
    if (next == widget.state.terminalHeight) return;
    context.read<SessionsBloc>().add(SessionTerminalHeightChanged(next));
  }

  /// Высота неподвижной части терминала: ручка, строка ввода и параметры.
  static const _chromeHeight = 120.0;

  void _rememberHeight() => context.read<SessionsBloc>().add(
    SessionTerminalHeightChanged(widget.state.terminalHeight, remember: true),
  );

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final height = widget.state.terminalHeight;
    final running = widget.state.selected?.isRunning ?? false;
    final palette = _paletteCommands;
    final suggestions = _argumentSuggestions;
    final log = context.read<SessionsBloc>().commandLog;
    return Container(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DragHandle(
            tooltip: texts.sessionTerminalHeightTooltip,
            onDrag: _onDrag,
            onDragEnd: _rememberHeight,
          ),
          // Журнала может не быть (например, в тестах) — тогда вывода нет,
          // а строка ввода и параметры работают как обычно.
          if (height > 0 && log != null)
            Flexible(
              child: SizedBox(
                height: height,
                child: _Output(log: log),
              ),
            ),
          if (palette.isNotEmpty)
            Flexible(
              child: _PaletteView(
                commands: palette,
                activeIndex: _activeIndex,
                filter: _paletteFilter,
                total: widget.state.commands.length,
                onSelected: _acceptPalette,
              ),
            )
          else if (suggestions.isNotEmpty)
            Flexible(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  color: AppColors.cardHighlight,
                  borderRadius: BorderRadius.circular(AppDimens.controlRadius),
                  border: Border.all(color: AppColors.border),
                ),
                child: SingleChildScrollView(
                  child: SuggestionList(
                    items: suggestions,
                    activeIndex: _activeIndex,
                    onSelected: _acceptArgument,
                    header: texts.sessionArgumentsFor(
                      _typedCommand?.invocation ?? '',
                    ),
                    footer: texts.sessionPaletteFooter,
                    valueWidth: 220,
                  ),
                ),
              ),
            ),
          _inputRow(texts, height, running),
          if (height > 0) _ParamsRow(state: widget.state, running: running),
        ],
      ),
    );
  }

  Widget _inputRow(AppLocalizations texts, double height, bool running) {
    final command = _typedCommand;
    final hasText = _promptController.text.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 9),
            child: Text(
              r'$',
              style: AppTextStyles.monospace(12.5, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(width: AppDimens.gapS),
          Expanded(
            child: Focus(
              onKeyEvent: _onKey,
              child: TextField(
                controller: _promptController,
                focusNode: _focusNode,
                enabled: !running,
                minLines: 1,
                // Поле растёт вместе с терминалом: свёрнутый — одна
                // строка, высокий — место под вставленное ТЗ.
                maxLines: height <= 0 ? 1 : (height < 260 ? 4 : 10),
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  // Команда подставлена — подсказываем дописать задание
                  // словами: «как есть» её запускают редко.
                  hintText: command != null
                      ? texts.sessionInputCommandHint
                      : texts.sessionInputEmptyHint,
                  hintStyle: AppTextStyles.captionMuted,
                  filled: true,
                  fillColor: AppColors.background,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimens.controlRadius,
                    ),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimens.controlRadius,
                    ),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),
          ),
          if (running) ...[
            const SizedBox(width: AppDimens.gapS),
            TextButton(
              onPressed: () =>
                  context.read<SessionsBloc>().add(SessionStopRequested()),
              child: Text(
                texts.sessionStop,
                style: const TextStyle(fontSize: 12, color: AppColors.danger),
              ),
            ),
          ] else ...[
            // Свёрнутый терминал прячет параметры за «⋯», чтобы строка
            // ввода осталась одной строкой.
            if (height <= 0)
              TextButton(
                onPressed: () => context.read<SessionsBloc>().add(
                  SessionTerminalHeightChanged(
                    TerminalHeights.normal,
                    remember: true,
                  ),
                ),
                child: Text(
                  texts.sessionParamsShort,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            IconButton(
              onPressed: hasText ? _submit : null,
              tooltip: texts.sessionRunHint,
              icon: const Icon(
                Icons.arrow_upward,
                size: 18,
                color: AppColors.accent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  final String tooltip;
  final ValueChanged<double> onDrag;
  final VoidCallback onDragEnd;

  const _DragHandle({
    required this.tooltip,
    required this.onDrag,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.resizeUpDown,
    child: GestureDetector(
      onVerticalDragUpdate: (details) => onDrag(details.delta.dy),
      onVerticalDragEnd: (_) => onDragEnd(),
      child: Tooltip(
        message: tooltip,
        child: Container(
          height: 12,
          alignment: Alignment.center,
          color: Colors.transparent,
          child: Container(
            width: 44,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Вывод последней выполненной команды — то же, что показывает панель
/// запуска, но целиком и без сворачивания.
class _Output extends StatelessWidget {
  final CommandLog log;

  const _Output({required this.log});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return StreamBuilder<CommandRun>(
      stream: log.runs,
      initialData: log.last,
      builder: (context, snapshot) {
        final run = snapshot.data;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            color: AppColors.logBackground,
            borderRadius: BorderRadius.circular(AppDimens.controlRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      run == null ? texts.launchPanelIdle : '\$ ${run.command}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.monospace(
                        11.5,
                        color: run == null
                            ? AppColors.textMuted
                            : AppColors.monospaceText,
                      ),
                    ),
                  ),
                  if (run != null && run.output.isNotEmpty)
                    TextButton(
                      onPressed: () =>
                          Clipboard.setData(ClipboardData(text: run.output)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 26),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        texts.launchCopyOutput,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    run == null || run.output.isEmpty
                        ? texts.launchNoOutput
                        : run.output,
                    style: AppTextStyles.monospace(
                      11.5,
                      color: run == null || run.output.isEmpty
                          ? AppColors.textMuted
                          : AppColors.monospaceText,
                    ).copyWith(height: 1.5),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Палитра команд спеки: сигнатура и источник видны до запуска, а счётчик
/// показывает, сколько команд отсеял набранный отбор.
class _PaletteView extends StatelessWidget {
  final List<SlashCommand> commands;
  final int activeIndex;
  final String filter;
  final int total;
  final ValueChanged<int> onSelected;

  const _PaletteView({
    required this.commands,
    required this.activeIndex,
    required this.filter,
    required this.total,
    required this.onSelected,
  });

  static String sourceLabel(AppLocalizations texts, CommandSource source) =>
      switch (source) {
        CommandSource.schema => texts.commandSourceSchema,
        CommandSource.claude => texts.commandSourceClaude,
        CommandSource.mirror => texts.commandSourceMirror,
        CommandSource.packageScript => texts.commandSourcePackage,
        CommandSource.makeTarget => texts.commandSourceMake,
      };

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: AppColors.cardHighlight,
        borderRadius: BorderRadius.circular(AppDimens.controlRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    texts.sessionPaletteTitle,
                    style: AppTextStyles.sectionLabel.copyWith(fontSize: 9.5),
                  ),
                ),
                Text(
                  filter.isEmpty
                      ? texts.sessionPaletteAll(total)
                      : texts.sessionPaletteFilter(
                          '/$filter',
                          commands.length,
                          total,
                        ),
                  style: AppTextStyles.hint,
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: commands.length,
              itemBuilder: (context, index) => _PaletteRow(
                command: commands[index],
                active: index == activeIndex,
                onTap: () => onSelected(index),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Text(texts.sessionPaletteFooter, style: AppTextStyles.hint),
          ),
        ],
      ),
    );
  }
}

class _PaletteRow extends StatelessWidget {
  final SlashCommand command;
  final bool active;
  final VoidCallback onTap;

  const _PaletteRow({
    required this.command,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return Tappable(
      onTap: onTap,
      child: Container(
        color: active ? AppColors.card : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    command.invocation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.monospace(
                      12,
                      color: AppColors.monospaceText,
                    ),
                  ),
                  if (command.description.isNotEmpty)
                    Text(
                      command.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.hint,
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppDimens.gapM),
            SizedBox(
              width: 170,
              child: Text(
                // Без сигнатуры команда не пропадает: это нормальный исход,
                // и его надо показать, а не спрятать.
                command.argumentHint.isEmpty
                    ? texts.sessionNoArguments
                    : command.argumentHint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.monospace(
                  11,
                  color: command.argumentHint.isEmpty
                      ? AppColors.textMuted
                      : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: AppDimens.gapS),
            _SourceBadge(source: command.source),
          ],
        ),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final CommandSource source;

  const _SourceBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Text(
        _PaletteView.sourceLabel(texts, source),
        style: AppTextStyles.monospace(10, color: AppColors.textMuted),
      ),
    );
  }
}

/// Строка параметров запуска под полем ввода: модель · доступ · effort.
/// Они меняются от задачи к задаче, поэтому живут рядом с вводом, а не
/// в настройках; значения запоминаются по проекту.
class _ParamsRow extends StatelessWidget {
  final SessionsState state;
  final bool running;

  const _ParamsRow({required this.state, required this.running});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Row(
        children: [
          Flexible(
            child: _ModelPicker(state: state, enabled: !running),
          ),
          const SizedBox(width: AppDimens.gapS),
          Flexible(
            child: _PermissionPicker(
              mode: state.permissionMode,
              enabled: !running,
            ),
          ),
          const SizedBox(width: AppDimens.gapS),
          Flexible(
            child: _EffortPicker(effort: state.effort, enabled: !running),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => context.read<SessionsBloc>().add(
              SessionPaletteToggled(!state.paletteOpen),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              texts.sessionAllCommands,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppDimens.gapS),
          Text(texts.sessionRunHint, style: AppTextStyles.hint),
        ],
      ),
    );
  }
}

class _ModelPicker extends StatelessWidget {
  final SessionsState state;
  final bool enabled;

  const _ModelPicker({required this.state, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return PopupMenuButton<String>(
      enabled: enabled,
      color: AppColors.cardHighlight,
      onSelected: (selected) => selected.isEmpty
          ? _askModel(context, texts)
          : context.read<SessionsBloc>().add(SessionModelChanged(selected)),
      itemBuilder: (_) => [
        for (final candidate in state.models)
          PopupMenuItem(
            value: candidate,
            child: Text(candidate, style: const TextStyle(fontSize: 12.5)),
          ),
        const PopupMenuDivider(),
        // Своё имя модели: список — не константа в коде, новая модель
        // не должна ждать релиза приложения.
        PopupMenuItem(value: '', child: Text(texts.sessionCustomModel)),
      ],
      child: _PickerChip(label: '${texts.sessionModelLabel} · ${state.model}'),
    );
  }

  Future<void> _askModel(BuildContext context, AppLocalizations texts) async {
    final controller = TextEditingController(text: state.model);
    final bloc = context.read<SessionsBloc>();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          texts.sessionCustomModelTitle,
          style: AppTextStyles.sectionTitle,
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTextStyles.monospace(12.5),
          decoration: InputDecoration(
            hintText: texts.sessionCustomModelHint,
            hintStyle: AppTextStyles.captionMuted,
          ),
          onSubmitted: (text) => Navigator.of(dialogContext).pop(text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(texts.cancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(texts.confirm),
          ),
        ],
      ),
    );
    if (value != null && value.isNotEmpty) {
      bloc.add(SessionModelChanged(value));
    }
  }
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
      onSelected: (selectedEffort) => context.read<SessionsBloc>().add(
        SessionEffortChanged(selectedEffort),
      ),
      itemBuilder: (_) => [
        for (final candidate in AgentEffort.values)
          PopupMenuItem(
            value: candidate,
            child: Text(candidate.name, style: const TextStyle(fontSize: 12.5)),
          ),
      ],
      child: _PickerChip(label: '${texts.sessionEffortLabel} · ${effort.name}'),
    );
  }
}

/// Режим разрешений: в headless-режиме ответить на запрос агента некому,
/// поэтому выбор делается заранее и виден рядом со строкой ввода.
class _PermissionPicker extends StatelessWidget {
  final AgentPermissionMode mode;
  final bool enabled;

  const _PermissionPicker({required this.mode, required this.enabled});

  String _label(AppLocalizations texts, AgentPermissionMode value) =>
      switch (value) {
        AgentPermissionMode.ask => texts.permissionAsk,
        AgentPermissionMode.acceptEdits => texts.permissionAcceptEdits,
        AgentPermissionMode.bypass => texts.permissionBypass,
      };

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return Tooltip(
      message: texts.permissionHint,
      child: PopupMenuButton<AgentPermissionMode>(
        enabled: enabled,
        color: AppColors.cardHighlight,
        onSelected: (value) => context.read<SessionsBloc>().add(
          SessionPermissionModeChanged(value),
        ),
        itemBuilder: (_) => [
          for (final value in AgentPermissionMode.values)
            PopupMenuItem(
              value: value,
              child: Text(
                _label(texts, value),
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
        ],
        child: _PickerChip(
          label: '${texts.permissionLabel} · ${_label(texts, mode)}',
          warning: mode == AgentPermissionMode.bypass,
        ),
      ),
    );
  }
}

class _PickerChip extends StatelessWidget {
  final String label;
  final bool warning;

  const _PickerChip({required this.label, this.warning = false});

  @override
  // Нажатие забирает `PopupMenuButton` выше — за курсор и подсветку
  // отвечаем мы.
  Widget build(BuildContext context) => Tappable(
    tapHandledAbove: true,
    borderRadius: BorderRadius.circular(13),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.cardHighlight,
        borderRadius: BorderRadius.circular(13),
        // Полный доступ к инструментам подсвечен рамкой: режим виден сразу.
        border: warning ? Border.all(color: AppColors.warningBorder) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Окно бывает узким (бриф §9) — подпись ужимается, а не ломает ряд.
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Icon(Icons.expand_more, size: 14, color: AppColors.textMuted),
        ],
      ),
    ),
  );
}
