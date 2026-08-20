part of 'sessions_bloc.dart';

sealed class SessionsEvent {}

class SessionStarted extends SessionsEvent {
  final String prompt;
  SessionStarted(this.prompt);
}

class SessionSelected extends SessionsEvent {
  final String sessionId;
  SessionSelected(this.sessionId);
}

class SessionStopRequested extends SessionsEvent {}

class SessionModelChanged extends SessionsEvent {
  final String model;
  SessionModelChanged(this.model);
}

class _SessionEventReceived extends SessionsEvent {
  final String sessionId;
  final AgentEvent event;
  _SessionEventReceived(this.sessionId, this.event);
}

class _SessionFinished extends SessionsEvent {
  final String sessionId;
  final AgentSessionStatus status;
  final Duration duration;
  _SessionFinished(this.sessionId, this.status, this.duration);
}
