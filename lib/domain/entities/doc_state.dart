/// Состояние файла документа в git спеки.
enum DocFileState {
  /// Файл под версионным контролем и совпадает с веткой.
  clean,

  /// Файл изменён локально — в ветке лежит другая версия.
  modified,

  /// Файла нет в индексе: его ещё не коммитили.
  untracked,

  /// Git не ответил (нет репозитория, нет самого git).
  unknown,
}

/// Ветка, в которой открыт документ, и состояние его файла.
class DocState {
  final String branch;
  final DocFileState file;

  const DocState({required this.branch, required this.file});

  static const unknown = DocState(branch: '', file: DocFileState.unknown);
}
