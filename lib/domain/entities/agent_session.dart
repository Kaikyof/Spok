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
  Duration? duration;

  /// id разговора на стороне CLI; появляется после первого запуска.
  String? cliSessionId;

  AgentSession({
    required this.id,
    required this.title,
    required this.startedAt,
    required this.model,
    required this.effort,
    this.status = AgentSessionStatus.idle,
    List<AgentEvent>? events,
  }) : events = events ?? [];

  bool get isEmpty => events.isEmpty;

  bool get isRunning => status == AgentSessionStatus.running;

  int get messageCount =>
      events.where((event) => event.kind == AgentEventKind.userMessage).length;
}
