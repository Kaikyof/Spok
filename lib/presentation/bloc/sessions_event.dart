part of 'sessions_bloc.dart';

sealed class SessionsEvent {}

/// Отправить сообщение в текущую сессию (продолжает диалог через --resume).
class SessionMessageSent extends SessionsEvent {
  final String prompt;
  SessionMessageSent(this.prompt);
}

class SessionCreated extends SessionsEvent {}

class SessionDeleted extends SessionsEvent {
  final String sessionId;
  SessionDeleted(this.sessionId);
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

class SessionPermissionModeChanged extends SessionsEvent {
  final AgentPermissionMode mode;
  SessionPermissionModeChanged(this.mode);
}

/// Запустить передачу спринта: команда платформы + режим, позволяющий
/// выполнить её без интерактивного подтверждения.
class HandoffRunRequested extends SessionsEvent {
  final String command;
  HandoffRunRequested(this.command);
}

class _SettingsRestored extends SessionsEvent {
  final String model;
  final AgentEffort effort;
  final AgentPermissionMode permissionMode;
  _SettingsRestored(this.model, this.effort, this.permissionMode);
}

class SessionEffortChanged extends SessionsEvent {
  final AgentEffort effort;
  SessionEffortChanged(this.effort);
}

class _SessionEventReceived extends SessionsEvent {
  final String sessionId;
  final AgentEvent event;
  _SessionEventReceived(this.sessionId, this.event);
}

class _SessionCliIdReceived extends SessionsEvent {
  final String sessionId;
  final String cliSessionId;
  _SessionCliIdReceived(this.sessionId, this.cliSessionId);
}

class _SessionFinished extends SessionsEvent {
  final String sessionId;
  final AgentSessionStatus status;
  final Duration duration;
  _SessionFinished(this.sessionId, this.status, this.duration);
}
