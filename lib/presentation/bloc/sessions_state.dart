part of 'sessions_bloc.dart';

/// Модели, доступные для сессии. Ключ — аргумент `--model` CLI.
const agentModels = ['sonnet', 'opus', 'haiku'];

class SessionsState {
  final List<AgentSession> sessions;
  final String selectedSessionId;
  final String model;
  final bool cliAvailable;
  final List<SlashCommand> commands;
  final int revision; // растёт с каждым событием — триггер перерисовки

  const SessionsState({
    this.sessions = const [],
    this.selectedSessionId = '',
    this.model = 'sonnet',
    this.cliAvailable = true,
    this.commands = const [],
    this.revision = 0,
  });

  AgentSession? get selected => sessions
      .where((session) => session.id == selectedSessionId)
      .firstOrNull;

  SessionsState copyWith({
    List<AgentSession>? sessions,
    String? selectedSessionId,
    String? model,
    bool? cliAvailable,
    List<SlashCommand>? commands,
    int? revision,
  }) =>
      SessionsState(
        sessions: sessions ?? this.sessions,
        selectedSessionId: selectedSessionId ?? this.selectedSessionId,
        model: model ?? this.model,
        cliAvailable: cliAvailable ?? this.cliAvailable,
        commands: commands ?? this.commands,
        revision: revision ?? this.revision,
      );
}
