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
  final List<String> models;
  final AgentEffort effort;
  final AgentPermissionMode permissionMode;
  final double terminalHeight;
  _SettingsRestored(this.model, this.models, this.effort, this.permissionMode,
      this.terminalHeight);
}

/// Подставить команду в строку ввода: с карточки change'а и из меню
/// действий. Запуск не начинается — человек дописывает задание словами.
class SessionDraftSet extends SessionsEvent {
  final String text;
  SessionDraftSet(this.text);
}

/// Сменилась спека или группа: команды, значения аргументов и настройки
/// перечитываются. Иначе подсказки остаются от прежнего проекта, а
/// `--resume` уводит диалог в чужой репозиторий.
class SessionsContextChanged extends SessionsEvent {
  /// Change'и выбранной группы; пусто — подсказываем все change'и спеки.
  final List<String> changeIds;

  SessionsContextChanged({this.changeIds = const []});
}

/// Тянут границу терминала. Пока тянут — только перерисовка; [remember]
/// ставится в конце жеста, чтобы не писать конфиг на каждый пиксель.
class SessionTerminalHeightChanged extends SessionsEvent {
  final double height;
  final bool remember;
  SessionTerminalHeightChanged(this.height, {this.remember = false});
}

/// Палитра «все команды спеки»: открыта кнопкой, а не набором «/».
class SessionPaletteToggled extends SessionsEvent {
  final bool open;
  SessionPaletteToggled(this.open);
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
