/// Человек, которому уйдёт передача: роль в Redmine × членство в канале.
class HandoffRecipient {
  final String username; // @username в мессенджере
  final String name;
  final int redmineId;

  const HandoffRecipient({
    required this.username,
    required this.name,
    required this.redmineId,
  });

  String get mention => '@$username';
}

/// Результат подбора получателей для одного стека.
class HandoffRecipients {
  final List<HandoffRecipient> testers;
  final List<HandoffRecipient> managers;
  final List<HandoffRecipient> developers;

  /// Сообщение об ошибке скрипта; пусто — получатели подобраны.
  final String error;

  const HandoffRecipients({
    this.testers = const [],
    this.managers = const [],
    this.developers = const [],
    this.error = '',
  });

  bool get resolved => error.isEmpty && testers.isNotEmpty && managers.isNotEmpty;
}
