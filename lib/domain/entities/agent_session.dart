/// Запись в транскрипте агентной сессии.
enum AgentEventKind { userMessage, assistantText, toolAction, result, error }

class AgentEvent {
  final AgentEventKind kind;
  final String text;
  final String toolName; // для toolAction

  const AgentEvent(this.kind, this.text, {this.toolName = ''});
}

enum AgentSessionStatus { idle, running, done, failed, stopped }

/// Уровень усилий модели (флаг --effort у CLI).
enum AgentEffort { low, medium, high, xhigh, max }

/// Режим разрешений CLI (флаг --permission-mode).
/// В headless-режиме спросить человека не у кого: если агенту нужен
/// инструмент вне allow-списка платформы, он остановится и напишет
/// «approve running …». Поэтому режим выбирается заранее и явно.
enum AgentPermissionMode {
  ask, // по умолчанию: только разрешённое в .claude/settings платформы
  acceptEdits, // правки файлов без вопросов
  bypass; // полный доступ к инструментам

  /// Значение флага CLI; ask — флаг не передаём.
  String? get flagValue => switch (this) {
        ask => null,
        acceptEdits => 'acceptEdits',
        bypass => 'bypassPermissions',
      };
}

/// Агентная сессия — один диалог с Claude Code. Сообщения продолжают
/// разговор через --resume, а не начинают новый каждый раз.
class AgentSession {
  final String id;
  final DateTime startedAt;
  String title; // первая реплика пользователя
  AgentSessionStatus status;
  final List<AgentEvent> events;
  String model;
  AgentEffort effort;
  AgentPermissionMode permissionMode;
  Duration? duration;

  /// id разговора на стороне CLI; появляется после первого запуска.
  String? cliSessionId;

  AgentSession({
    required this.id,
    required this.title,
    required this.startedAt,
    required this.model,
    required this.effort,
    this.permissionMode = AgentPermissionMode.ask,
    this.status = AgentSessionStatus.idle,
    List<AgentEvent>? events,
  }) : events = events ?? [];

  bool get isEmpty => events.isEmpty;

  bool get isRunning => status == AgentSessionStatus.running;

  int get messageCount =>
      events.where((event) => event.kind == AgentEventKind.userMessage).length;
}
