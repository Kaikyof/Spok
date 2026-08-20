/// Вид расхождения: статус или отметка не совпадает с фактом.
enum DivergenceKind {
  /// Статус тестовый, а задачи в файле не закрыты.
  tasksNotClosed,

  /// Галочки полные, а задача ещё в рабочем статусе.
  marksAheadOfStatus,

  /// Есть задачи «Ожидает тестирования», а сборка стека не записана.
  buildMissing,
}

/// Расхождение — структура без текста: формулировку даёт слой представления
/// из локализации.
class Divergence {
  final DivergenceKind kind;
  final String changeId;
  final String changeTitle;
  final String stack; // ios | android
  final String? redmineStatus;
  final List<String> openTaskNumbers;
  final int doneCount;
  final int totalCount;

  const Divergence({
    required this.kind,
    required this.changeId,
    required this.changeTitle,
    required this.stack,
    this.redmineStatus,
    this.openTaskNumbers = const [],
    this.doneCount = 0,
    this.totalCount = 0,
  });
}
