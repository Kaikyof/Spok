part of 'sessions_bloc.dart';

/// Псевдонимы моделей на случай, когда список не задан настройкой.
/// Именно псевдонимы, а не версии: `sonnet` всегда указывает на текущую
/// модель, а закреплённый идентификатор с датой протухает. Список
/// редактируется человеком (ключ `SESSION_MODELS` в конфиге приложения)
/// и пополняется, когда он вводит своё имя модели, — чтобы новая модель
/// не ждала релиза приложения.
const agentModelAliases = ['opus', 'sonnet', 'haiku'];

/// Высота вывода в терминале, в пикселях. Тянется мышью плавно:
/// 0 — свёрнут (одна строка ввода), по умолчанию — 4–5 строк вывода,
/// дальше — до половины экрана под длинное ТЗ.
abstract class TerminalHeights {
  static const collapsed = 0.0;
  static const normal = 150.0;

  /// Ниже этого порога вывод не показываем: полоска в пару строк
  /// бесполезна, честнее свернуть.
  static const collapseThreshold = 40.0;
}

class SessionsState {
  final List<AgentSession> sessions;
  final String selectedSessionId;
  final String model;

  /// Что показывает селектор модели: из настройки, иначе псевдонимы.
  final List<String> models;
  final AgentEffort effort;
  final AgentPermissionMode permissionMode;
  final bool cliAvailable;
  final List<SlashCommand> commands;
  final List<String> changeIds;
  final List<String> groupIds;
  final String workingDirectory;

  /// Высота вывода терминала в пикселях — запоминается по проекту.
  final double terminalHeight;

  /// Палитра открыта кнопкой «Все команды спеки» — показывается без отбора.
  final bool paletteOpen;

  /// Заготовка строки ввода: меню действий карточки change'а подставляет
  /// команду с известными аргументами, дописывает задание человек.
  final String draft;
  final int revision; // растёт с каждым событием — триггер перерисовки

  const SessionsState({
    this.sessions = const [],
    this.selectedSessionId = '',
    this.model = 'sonnet',
    this.models = agentModelAliases,
    this.effort = AgentEffort.medium,
    this.permissionMode = AgentPermissionMode.ask,
    this.cliAvailable = true,
    this.commands = const [],
    this.changeIds = const [],
    this.groupIds = const [],
    this.workingDirectory = '',
    this.terminalHeight = TerminalHeights.normal,
    this.paletteOpen = false,
    this.draft = '',
    this.revision = 0,
  });

  /// Команды с ролями — выделенные кнопки быстрого запуска.
  Map<CommandRole, SlashCommand> get roles => resolveCommandRoles(commands);

  AgentSession? get selected =>
      sessions.where((session) => session.id == selectedSessionId).firstOrNull;

  SessionsState copyWith({
    List<AgentSession>? sessions,
    String? selectedSessionId,
    String? model,
    List<String>? models,
    AgentEffort? effort,
    AgentPermissionMode? permissionMode,
    bool? cliAvailable,
    List<SlashCommand>? commands,
    List<String>? changeIds,
    List<String>? groupIds,
    String? workingDirectory,
    double? terminalHeight,
    bool? paletteOpen,
    String? draft,
    int? revision,
  }) =>
      SessionsState(
        sessions: sessions ?? this.sessions,
        selectedSessionId: selectedSessionId ?? this.selectedSessionId,
        model: model ?? this.model,
        models: models ?? this.models,
        effort: effort ?? this.effort,
        permissionMode: permissionMode ?? this.permissionMode,
        cliAvailable: cliAvailable ?? this.cliAvailable,
        commands: commands ?? this.commands,
        changeIds: changeIds ?? this.changeIds,
        groupIds: groupIds ?? this.groupIds,
        workingDirectory: workingDirectory ?? this.workingDirectory,
        terminalHeight: terminalHeight ?? this.terminalHeight,
        paletteOpen: paletteOpen ?? this.paletteOpen,
        draft: draft ?? this.draft,
        revision: revision ?? this.revision,
      );
}
