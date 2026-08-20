part of 'sessions_bloc.dart';

/// Модели, доступные для сессии. Ключ — аргумент `--model` CLI.
const agentModels = ['sonnet', 'opus', 'haiku'];

class SessionsState {
  final List<AgentSession> sessions;
  final String selectedSessionId;
  final String model;
  final AgentEffort effort;
  final bool cliAvailable;
  final List<SlashCommand> commands;
  final List<String> changeIds;
  final List<String> sprintIds;
  final String workingDirectory;
  final int revision; // растёт с каждым событием — триггер перерисовки

  const SessionsState({
    this.sessions = const [],
    this.selectedSessionId = '',
    this.model = 'sonnet',
    this.effort = AgentEffort.medium,
    this.cliAvailable = true,
    this.commands = const [],
    this.changeIds = const [],
    this.sprintIds = const [],
    this.workingDirectory = '',
    this.revision = 0,
  });

  AgentSession? get selected =>
      sessions.where((session) => session.id == selectedSessionId).firstOrNull;

  SessionsState copyWith({
    List<AgentSession>? sessions,
    String? selectedSessionId,
    String? model,
    AgentEffort? effort,
    bool? cliAvailable,
    List<SlashCommand>? commands,
    List<String>? changeIds,
    List<String>? sprintIds,
    String? workingDirectory,
    int? revision,
  }) =>
      SessionsState(
        sessions: sessions ?? this.sessions,
        selectedSessionId: selectedSessionId ?? this.selectedSessionId,
        model: model ?? this.model,
        effort: effort ?? this.effort,
        cliAvailable: cliAvailable ?? this.cliAvailable,
        commands: commands ?? this.commands,
        changeIds: changeIds ?? this.changeIds,
        sprintIds: sprintIds ?? this.sprintIds,
        workingDirectory: workingDirectory ?? this.workingDirectory,
        revision: revision ?? this.revision,
      );
}
