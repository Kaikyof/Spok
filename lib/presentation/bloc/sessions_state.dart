part of 'sessions_bloc.dart';

/// Модели, доступные для сессии. Ключ — аргумент `--model` CLI.
const agentModels = ['sonnet', 'opus', 'haiku'];

class SessionsState {
  final List<AgentSession> sessions;
  final String selectedSessionId;
  final String model;
  final bool cliAvailable;
  final int revision; // растёт с каждым событием — триггер перерисовки

  const SessionsState({
    this.sessions = const [],
    this.selectedSessionId = '',
    this.model = 'sonnet',
    this.cliAvailable = true,
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
    int? revision,
  }) =>
      SessionsState(
        sessions: sessions ?? this.sessions,
        selectedSessionId: selectedSessionId ?? this.selectedSessionId,
        model: model ?? this.model,
        cliAvailable: cliAvailable ?? this.cliAvailable,
        revision: revision ?? this.revision,
      );
}
