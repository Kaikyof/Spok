import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/sources/agent_cli_source.dart';
import '../../domain/entities/agent_session.dart';
import '../../domain/repositories/platform_repository.dart';

part 'sessions_event.dart';
part 'sessions_state.dart';

/// Агентные сессии: запуск Claude Code поверх репозитория платформы.
class SessionsBloc extends Bloc<SessionsEvent, SessionsState> {
  final PlatformRepository repository;
  final Map<String, AgentCliSource> _sources = {};

  SessionsBloc(this.repository)
      : super(SessionsState(
            cliAvailable: AgentCliSource.locateBinary() != null)) {
    on<SessionStarted>(_onStarted);
    on<SessionSelected>(
        (event, emit) => emit(state.copyWith(selectedSessionId: event.sessionId)));
    on<SessionStopRequested>(_onStopRequested);
    on<SessionModelChanged>(
        (event, emit) => emit(state.copyWith(model: event.model)));
    on<_SessionEventReceived>(_onEventReceived);
    on<_SessionFinished>(_onFinished);
  }

  Future<void> _onStarted(
      SessionStarted event, Emitter<SessionsState> emit) async {
    final binary = AgentCliSource.locateBinary();
    final workingDirectory = repository.rootPath;
    if (binary == null || workingDirectory == null) {
      emit(state.copyWith(cliAvailable: binary != null));
      return;
    }
    final prompt = event.prompt.trim();
    if (prompt.isEmpty) return;

    final session = AgentSession(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: prompt.length > 60 ? '${prompt.substring(0, 60)}…' : prompt,
      startedAt: DateTime.now(),
      model: state.model,
      events: [AgentEvent(AgentEventKind.userMessage, prompt)],
    );
    final source = AgentCliSource();
    _sources[session.id] = source;
    emit(state.copyWith(
      sessions: [session, ...state.sessions],
      selectedSessionId: session.id,
      revision: state.revision + 1,
    ));

    // Не await: процесс живёт минуты, события приходят через add().
    source.start(
      binary: binary,
      prompt: prompt,
      model: state.model,
      workingDirectory: workingDirectory,
      onEvent: (agentEvent) =>
          add(_SessionEventReceived(session.id, agentEvent)),
      onDone: (status, duration) =>
          add(_SessionFinished(session.id, status, duration)),
    );
  }

  void _onStopRequested(
      SessionStopRequested event, Emitter<SessionsState> emit) {
    _sources[state.selectedSessionId]?.stop();
  }

  void _onEventReceived(
      _SessionEventReceived event, Emitter<SessionsState> emit) {
    final session = _sessionById(event.sessionId);
    if (session == null) return;
    session.events.add(event.event);
    emit(state.copyWith(revision: state.revision + 1));
  }

  void _onFinished(_SessionFinished event, Emitter<SessionsState> emit) {
    final session = _sessionById(event.sessionId);
    if (session == null) return;
    session.status = event.status;
    session.duration = event.duration;
    _sources.remove(event.sessionId);
    emit(state.copyWith(revision: state.revision + 1));
  }

  AgentSession? _sessionById(String sessionId) =>
      state.sessions.where((session) => session.id == sessionId).firstOrNull;

  @override
  Future<void> close() {
    for (final source in _sources.values) {
      source.stop();
    }
    return super.close();
  }
}
