/// Запись в транскрипте агентной сессии.
enum AgentEventKind { userMessage, assistantText, toolAction, result, error }

class AgentEvent {
  final AgentEventKind kind;
  final String text;
  final String toolName; // для toolAction

  const AgentEvent(this.kind, this.text, {this.toolName = ''});
}

enum AgentSessionStatus { running, done, failed, stopped }

/// Агентная сессия — один диалог с Claude Code в headless-режиме.
class AgentSession {
  final String id;
  final String title; // первая реплика пользователя
  final DateTime startedAt;
  AgentSessionStatus status;
  final List<AgentEvent> events;
  String model;
  Duration? duration;

  AgentSession({
    required this.id,
    required this.title,
    required this.startedAt,
    required this.model,
    this.status = AgentSessionStatus.running,
    List<AgentEvent>? events,
  }) : events = events ?? [];

  List<AgentEvent> get toolActions => events
      .where((event) => event.kind == AgentEventKind.toolAction)
      .toList();
}
