/// Что мешает передать спринт. Блокер показывается причиной, а не кодом.
enum HandoffBlockerKind { statusNotReady, tasksOpen, buildMissing }

class HandoffBlocker {
  final HandoffBlockerKind kind;
  final String changeTitle;
  final String stack;
  final String status;
  final List<String> openTaskNumbers;

  const HandoffBlocker({
    required this.kind,
    required this.changeTitle,
    required this.stack,
    this.status = '',
    this.openTaskNumbers = const [],
  });
}

/// Готовность спринта к передаче по выбранным стекам.
class HandoffReadiness {
  final int readyCount;
  final int totalCount;
  final List<HandoffBlocker> blockers;

  const HandoffReadiness({
    required this.readyCount,
    required this.totalCount,
    required this.blockers,
  });

  bool get ready => blockers.isEmpty && totalCount > 0;
}
