/// Что мешает передать спринт. Блокер показывается причиной, а не кодом.
///
/// [statusUnknown] — статус стека не опрошен (нет ключа трекера либо он
/// молчит) и кэша в `redmine.yaml` change'а тоже нет. Это блокер, а не
/// пустое место: раньше такой стек молча попадал в готовые, и экран
/// обещал готовность, о которой ничего не знал.
enum HandoffBlockerKind { statusNotReady, statusUnknown, tasksOpen, buildMissing }

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

  /// Статусы части стеков не опрошены — готовность неизвестна, и шаг
  /// говорит это причиной, а не цифрой «0 из 3».
  bool get statusUnknown => blockers
      .any((blocker) => blocker.kind == HandoffBlockerKind.statusUnknown);
}
